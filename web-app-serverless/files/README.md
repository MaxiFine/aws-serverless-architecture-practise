# Web EC2 Scenario — Static Files

These are example frontend assets that can be uploaded to the S3 bucket used by CloudFront in this scenario. They’re handy for smoke-testing the stack end-to-end (S3 → CloudFront for static, and CloudFront → ALB for `/api/*`).

## What’s here

- `index.html` — Main landing page; links to basic app actions.
- `items.html` — Sample page to validate static delivery and demonstrate simple list rendering.
- `script.js` — Small helper script (e.g., can be wired from pages to call your API under `/api/*`).

## How it fits in

- The frontend Terraform creates an S3 bucket (origin) and a CloudFront distribution.
- Static files in this folder are uploaded to that S3 bucket.
- Requests to `/api/*` are routed by CloudFront to the ALB (backend module). The Lambda@Edge viewer-request function may require authentication for protected routes depending on your `PROTECTED_RULES` config.

### Where to find values

- CloudFront domain: exposed as a Terraform output in the frontend module (used in root to update Cognito). You can also find it in the AWS console under CloudFront Distributions.
- S3 bucket name: output of the S3 module or visible in the AWS console. It’s the origin for this distribution.

### Invalidate CloudFront cache

If changes don’t show up due to caching, invalidate the distribution (replace `<DIST_ID>`):

```bash
aws cloudfront create-invalidation --distribution-id <DIST_ID> --paths "/*"
```

## Troubleshooting

- Seeing 403 on static files: confirm objects are in the bucket path you’re requesting and OAC is configured by Terraform.
- Seeing 401 on API calls: your route may be protected by Lambda@Edge. Sign in via the Hosted UI or adjust `PROTECTED_RULES`.
- Mixed content or CORS issues: ensure you’re calling the correct CloudFront domain over HTTPS and that your backend/API sets appropriate CORS headers.

## Auth-protected endpoints

Some routes (e.g., under `/api/*`) may be protected by the Lambda@Edge function. When a request isn’t authenticated, the function returns a 401 with an `X-Auth-Redirect` header (and a minimal HTML auto-redirect for browsers). After signing in with Cognito Hosted UI, cookies are set and subsequent requests include an `Authorization` header to your origin.

Example fetch handler that follows the auth redirect on 401:

```js
async function apiGet(path) {
	const res = await fetch(path, { credentials: "include" });
	if (res.status === 401) {
		const login = res.headers.get("x-auth-redirect");
		if (login) window.location.assign(login);
		throw new Error("Unauthorized; redirecting to login...");
	}
	return res.json();
}

// Usage: apiGet('/api/health').then(console.log).catch(console.error);
```