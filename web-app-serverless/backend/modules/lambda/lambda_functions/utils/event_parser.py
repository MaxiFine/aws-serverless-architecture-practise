class EventParser:
    def __init__(self, event):
        self.event = event or {}
        self.path_params = {}
    
    def get_route_key(self):
        return self.event.get("routeKey", "")

    def get_http_method(self, default="GET"):
        return self.event.get("requestContext", {}).get("http", {}).get("method", default)

    def get_path(self, default="/"):
        return self.event.get("rawPath", default)

    def get_headers(self):
        return self.event.get("headers", {}) or {}

    def get_authorization_token(self):
        token = self.get_headers().get(
            "authorization") or self.get_headers().get("Authorization")
        if token and token.startswith("Bearer "):
            return token[len("Bearer "):]
        return token

    def get_body_json(self):
        import json
        try:
            body = self.event.get("body")
            if body:
                return json.loads(body)
            return {}
        except Exception:
            return {}

    def get_query_params(self):
        return self.event.get("queryStringParameters", {}) or {}

    def get_path_params(self):
        return self.event.get("pathParameters", {}) or {}
    
    