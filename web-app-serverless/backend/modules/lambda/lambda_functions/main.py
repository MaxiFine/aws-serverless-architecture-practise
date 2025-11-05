import json
import os
import logging
import time
import boto3
import mysql.connector
from mysql.connector import Error as MySQLError
from utils.event_parser import EventParser

# --- Logging ---
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(__name__)

# --- Environment Variables ---
DB_HOST = os.getenv("DB_PROXY_ENDPOINT")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER")
DB_NAME = os.getenv("DB_NAME")
# Prefer Lambda-provided region if not explicitly set
AWS_REGION = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION")

# Path to bundled RDS CA bundle in the Lambda package
CA_PATH = "/var/task/rds-combined-ca-bundle.pem"

# Connection retry settings
CONNECT_RETRIES = int(os.getenv("DB_CONNECT_RETRIES", "2"))
CONNECT_BACKOFF = float(os.getenv("DB_CONNECT_BACKOFF", "0.5"))  # seconds exponential base

def get_iam_token():
    """
    Generate an IAM auth token for connecting to MySQL via RDS/RDS Proxy.
    Do NOT log the token itself (security).
    """
    try:
        rds = boto3.client("rds", region_name=AWS_REGION if AWS_REGION else None)
        token = rds.generate_db_auth_token(
            DBHostname=DB_HOST,
            Port=DB_PORT,
            DBUsername=DB_USER
        )
        logger.debug("Generated IAM auth token (not logged for security).", extra={"db_host": DB_HOST, "db_user": DB_USER})
        return token
    except Exception:
        logger.exception("Failed to generate IAM DB auth token", extra={"region": AWS_REGION, "db_host": DB_HOST, "db_user": DB_USER})
        raise

def get_connection():
    """
    Establish a DB connection using IAM auth with mysql-connector-python.
    Retries a small number of times for transient errors.
    """
    # validate env
    missing = [name for name, val in {
        "DB_PROXY_ENDPOINT": DB_HOST,
        "DB_USER": DB_USER,
        "DB_NAME": DB_NAME,
        "DB_PORT": DB_PORT,
    }.items() if val in (None, "")]
    if missing:
        msg = f"Missing required database environment variables: {', '.join(missing)}"
        logger.error(msg)
        raise RuntimeError(msg)

    last_err = None
    for attempt in range(1, CONNECT_RETRIES + 2):  # e.g. 0..retries -> attempts = retries+1
        try:
            logger.info("Attempting DB connection", extra={"db_host": DB_HOST, "db_user": DB_USER, "db_port": DB_PORT, "db_name": DB_NAME, "attempt": attempt})
            token = get_iam_token()

            # mysql-connector expects ssl_ca path and auth_plugin for IAM token (cleartext plugin)
            ssl_kwargs = {}
            if os.path.exists(CA_PATH):
                ssl_kwargs["ssl_ca"] = CA_PATH
            else:
                # Fallback: let connector use system CA store (may work on AWS Lambda runtimes)
                logger.debug("CA bundle not found at %s; falling back to system CA", CA_PATH)

            conn = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                port=DB_PORT,
                password=token,
                database=DB_NAME,
                connection_timeout=10,
                auth_plugin="mysql_clear_password",
                **ssl_kwargs
            )
            logger.info("DB connection established")
            return conn
        except MySQLError as err:
            last_err = err
            logger.warning("MySQL connection attempt failed", extra={"attempt": attempt, "error": str(err)})
            # If auth error (1045) return early (no point retrying)
            try:
                errno = err.errno
            except Exception:
                errno = None
            if errno == 1045:
                logger.error("Authentication failed (invalid token / user). Not retrying.", extra={"errno": errno})
                raise
            # transient network/timeout errors: retry with backoff
            if attempt <= CONNECT_RETRIES:
                sleep_time = CONNECT_BACKOFF * (2 ** (attempt - 1))
                logger.info("Retrying DB connection after backoff", extra={"sleep_seconds": sleep_time})
                time.sleep(sleep_time)
                continue
            break
        except Exception:
            logger.exception("Unexpected error during DB connection")
            raise

    # if we exit loop with no connection
    logger.error("All DB connection attempts failed", extra={"last_error": str(last_err) if last_err else None})
    # re-raise last MySQL error or generic error
    if isinstance(last_err, Exception):
        raise last_err
    raise RuntimeError("Failed to connect to the database")

# --- Lambda Handler ---
def lambda_handler(event, context):
    try:
        logger.info("Event received", extra={"routeKey": event.get("routeKey"), "requestId": event.get("requestContext", {}).get("requestId")})
        parser = EventParser(event)
        route_key = parser.get_route_key()
        logger.info("Handling request", extra={"route_key": route_key, "http_method": parser.get_http_method()})

        if route_key == "GET /api/health":
            return respond(200, {"status": "ok"})
        elif route_key == "GET /api/items":
            return get_items()
        elif route_key == "POST /api/items":
            body = json.loads(event.get("body", "{}"))
            return add_item(body)
        else:
            return respond(404, {"error": "Not Found"})
    except Exception:
        logger.exception("Unhandled exception in lambda_handler")
        return respond(500, {"error": "Internal Server Error"})

# --- API Operations ---
def get_items():
    conn = None
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS items (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255)
            );
        """)
        cur.execute("SELECT id, name FROM items ORDER BY id DESC LIMIT 10;")
        rows = cur.fetchall()
        cur.close()
        items = [{"id": r[0], "name": r[1]} for r in rows]
        return respond(200, items)
    except MySQLError as e:
        errno = getattr(e, "errno", None)
        logger.exception("Operational DB error while fetching items", extra={"errno": errno})
        if errno == 1045:
            return respond(500, {"error": "Database authentication failed"})
        return respond(500, {"error": "Database error"})
    except Exception:
        logger.exception("Unexpected error in get_items")
        return respond(500, {"error": "Internal Server Error"})
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                logger.debug("Error closing DB connection", exc_info=True)

def add_item(data):
    conn = None
    try:
        name = data.get("name") if isinstance(data, dict) else None
        if not name:
            logger.info("Validation failed: missing 'name' in request body")
            return respond(400, {"error": "Missing 'name'"})

        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS items (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255)
            );
        """)
        cur.execute("INSERT INTO items (name) VALUES (%s)", (name,))
        conn.commit()
        cur.close()
        return respond(201, {"message": "Item added"})
    except MySQLError as e:
        errno = getattr(e, "errno", None)
        logger.exception("Operational DB error while adding item", extra={"errno": errno})
        if errno == 1045:
            return respond(500, {"error": "Database authentication failed"})
        return respond(500, {"error": "Database error"})
    except Exception:
        logger.exception("Unexpected error in add_item")
        return respond(500, {"error": "Internal Server Error"})
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                logger.debug("Error closing DB connection", exc_info=True)

# --- Helper for consistent responses ---
def respond(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

