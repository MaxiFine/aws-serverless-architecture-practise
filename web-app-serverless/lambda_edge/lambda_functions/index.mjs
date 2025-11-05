/**
 * Lambda@Edge origin-request handler implementing Cognito PKCE auth gate.
 * Flow:
 *  - Derives redirectUri from request host + cfg.REDIRECT_PATH (default /callback)
 *  - If request is to callback path: exchanges code for tokens, sets cookies, redirects
 *  - For OPTIONS: returns CORS preflight response
 *  - For protected routes: if no token cookies, returns 401 with X-Auth-Redirect to Cognito
 *  - Otherwise: forwards request to origin; if tokens exist, adds Authorization header
 * Requires cfg fields: COGNITO_DOMAIN, CLIENT_ID, SCOPES (optional), PROTECTED_RULES (optional)
 */
import { cfg } from "./lib/config.mjs";
import { ONE_MIN, TEN_MIN, cookieBase, b64url, sha256, randomBytes, parseCookies, setCookie, delCookie, redirect } from "./lib/utils.mjs";
import { buildAuthorizeUrl, exchangeCode } from "./lib/pkce.mjs";
import { isProtected } from "./lib/routes.mjs";

export const handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers || {};
  const cookies = parseCookies(headers);
  const uri = request.uri || "/";
  const qs = request.querystring || "";
  const host = headers.host?.[0]?.value;
  const callbackPath = cfg.REDIRECT_PATH || "/callback";
  // Require redirectUri to be derived from the request host; if host is missing, allow pass-through
  if (!host) {
    return request;
  }
  const redirectUri = `https://${host}${callbackPath}`;
  const allowOrigin = `https://${host}`;

  // Handle OAuth callback
  if (uri === callbackPath) {
    const qsObj = Object.fromEntries(
      qs.split("&").filter(Boolean).map(kv => {
        const [k, v = ""] = kv.split("=");
        return [decodeURIComponent(k), decodeURIComponent(v)];
      })
    );
    const { code, state } = qsObj;

    if (!code || !state || !cookies.pkce_state || !cookies.pkce_verifier || cookies.pkce_state !== state) {
      return redirect("/", {
        "set-cookie": [
          { key: "Set-Cookie", value: "pkce_state=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax" },
          { key: "Set-Cookie", value: "pkce_verifier=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax" },
          { key: "Set-Cookie", value: "ret=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax" },
        ],
      });
    }

    try {
  const tokens = await exchangeCode({ code, verifier: cookies.pkce_verifier, cfg, redirectUri });
      const out = {};
      const maxAge = Math.max(ONE_MIN, Math.min(tokens.expires_in || 3600, 6 * 3600));
      setCookie(out, "id_token", tokens.id_token, `${cookieBase}; Max-Age=${maxAge}`);
      setCookie(out, "access_token", tokens.access_token, `${cookieBase}; Max-Age=${maxAge}`);
      delCookie(out, "pkce_state");
      delCookie(out, "pkce_verifier");
      const retPath = cookies.ret && cookies.ret.startsWith("/") ? cookies.ret : "/";
      delCookie(out, "ret");
      return redirect(retPath, out);
    } catch (e) {
      const out = {};
      delCookie(out, "pkce_state");
      delCookie(out, "pkce_verifier");
      delCookie(out, "ret");
      return redirect("/", out);
    }
  }

  // Only protect if route+method matches a protected rule; default-open otherwise
  const method = (request.method || "GET").toUpperCase();
  // Let CORS preflight pass through to origin or handle here with permissive response
  if (method === "OPTIONS") {
    return {
      status: "204",
      statusDescription: "No Content",
      headers: {
        "access-control-allow-origin": [{ key: "Access-Control-Allow-Origin", value: allowOrigin }],
        "access-control-allow-methods": [{ key: "Access-Control-Allow-Methods", value: "GET,POST,PUT,DELETE,OPTIONS" }],
        "access-control-allow-headers": [{ key: "Access-Control-Allow-Headers", value: "*,Authorization,Content-Type" }],
        "access-control-allow-credentials": [{ key: "Access-Control-Allow-Credentials", value: "true" }],
        "vary": [{ key: "Vary", value: "Origin" }],
      },
    };
  }

  if (isProtected({ uri, method })) {
    if (cookies.id_token || cookies.access_token) {
      // Propagate bearer token to origin so API can authorize requests
      request.headers = request.headers || {};
      request.headers.authorization = [
        { key: "Authorization", value: `Bearer ${cookies.access_token || cookies.id_token}` },
      ];
      return request;
    }
    const verifier = b64url(randomBytes(32));
    const codeChallenge = b64url(await sha256(verifier));
    const state = b64url(randomBytes(16));
    const out = {};
    setCookie(out, "pkce_verifier", verifier, `${cookieBase}; Max-Age=${TEN_MIN}`);
    setCookie(out, "pkce_state", state, `${cookieBase}; Max-Age=${TEN_MIN}`);
  // For non-idempotent methods (e.g., POST), return to the root page after login
  // so the frontend can replay the pending action. For GET, preserve the original path.
  const returnTo = method === "GET" ? (uri + (qs ? `?${qs}` : "")) : "/";
    setCookie(out, "ret", returnTo, `${cookieBase}; Max-Age=${TEN_MIN}`);
    const authUrl = buildAuthorizeUrl({ state, codeChallenge, cfg, redirectUri });
    const accept = headers.accept?.[0]?.value || "";
    return {
      status: "401",
      statusDescription: "Unauthorized",
      headers: {
        ...out,
        "access-control-allow-origin": [{ key: "Access-Control-Allow-Origin", value: allowOrigin }],
        "access-control-allow-credentials": [{ key: "Access-Control-Allow-Credentials", value: "true" }],
        "access-control-expose-headers": [{ key: "Access-Control-Expose-Headers", value: "X-Auth-Redirect,Set-Cookie" }],
        "vary": [{ key: "Vary", value: "Origin" }],
        "cache-control": [{ key: "Cache-Control", value: "no-store" }],
        "content-type": [{ key: "Content-Type", value: accept.includes("html") ? "text/html" : "application/json" }],
        "x-auth-redirect": [{ key: "X-Auth-Redirect", value: authUrl }],
      },
      body: accept.includes("html")
        ? `<html><body><script>window.location.assign(${JSON.stringify(authUrl)})</script></body></html>`
        : JSON.stringify({ error: "unauthorized", login: authUrl }),
    };
  }

  // Default allow (not protected)
  return request;
};