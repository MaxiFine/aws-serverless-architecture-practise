# Lambda@Edge functions for the Web EC2 scenario

This directory contains the source and Terraform configuration to package and deploy Lambda@Edge functions used by the Web EC2 scenario. The functions are implemented in ESM JavaScript (`.mjs`) and are packaged as a ZIP which Terraform uploads when creating CloudFront / Lambda@Edge resources.

## Files
```
.
├── README.md                      # Module documentation
├── lambda_functions               # Lambda@Edge function source
│   ├── index.mjs                  # Entry-point handler (exports handler)
│   └── lib                        # Helper modules used by the handler
│       ├── config.mjs             # Loads config.json and exports cfg
│       ├── pkce.mjs               # Builds Cognito authorize URL and exchanges code (PKCE)
│       ├── routes.mjs             # Protected route rules and isProtected helper
│       └── utils.mjs              # Cookies, redirects, crypto (sha256, randomBytes), helpers
├── lambda_functions.zip           # Packaged function bundle (artifact)
├── main.tf                        # Terraform for config file, Lambda, permissions, and wiring
├── outputs.tf                     # Exports module outputs
├── providers.tf                   # AWS providers (includes us-east-1 for Lambda@Edge)
└── variables.tf                   # Input variables (region, project_name, tags, Cognito params)
```

## Purpose / contract
- Input: CloudFront events (viewer-request, origin-request, viewer-response, etc.)
- Output: Modified HTTP request/response or redirect depending on routing logic
- Error modes: missing config, malformed PKCE flow, or runtime exceptions — see CloudWatch logs

### What this Lambda@Edge does
This function acts as an authentication gateway for selected routes in front of your origin:

- Route protection: `lib/routes.mjs` defines `PROTECTED_RULES`. Only routes matching these rules require auth; all others pass through.
- PKCE + Cognito Hosted UI: On protected routes, if no valid cookies are present, it returns a 401 with `X-Auth-Redirect` pointing to the Cognito login URL (PKCE S256 flow). It sets short-lived cookies for `pkce_state` and `pkce_verifier` and a `ret` cookie to remember where to return after login.
- OAuth callback: At `REDIRECT_PATH` (default `/callback`), it validates `code` and `state`, exchanges the code for tokens, then sets `id_token` and `access_token` cookies and redirects back to the original `ret` path (or `/`).
- Propagating auth to origin: When a user is authenticated on a protected route, the function injects `Authorization: Bearer <access_token|id_token>` into the request headers so your origin/API can validate the token.
- CORS and preflight: For `OPTIONS` it returns a 204 with permissive CORS headers keyed to the request host. For protected 401 responses, it includes CORS headers and exposes `X-Auth-Redirect` so SPAs can read it.
- Default open: Any route that does not match a protected rule is forwarded unmodified.

Key cookies
- `id_token` and `access_token`: issued after successful callback, with max-age bounded by token expiry and a safety cap.
- `pkce_state` and `pkce_verifier`: short-lived, used during the PKCE flow, cleared on success or error.
- `ret`: the path to return to after login; for non-GET requests, the function sends users to `/` so the frontend can replay actions as needed.

## Quick workflow

This folder is part of the broader `web-ec2-scenario` Terraform stack.

1. Make code changes under `lambda_functions/`.
2. From the parent `web-ec2-scenario` folder, run Terraform as usual:

	```sh
	terraform init
	terraform plan
	terraform apply
	```

	Terraform will:
	- Render `lambda_edge/lambda_functions/config.json`.
	- Upload and publish the Lambda in `us-east-1`, then attach it for Lambda@Edge.
	Note: CloudFront propagation can take several minutes.

	## Inputs
	- `region` (string): AWS region
	- `project_name` (string): Name of the project/stack
	- `tags` (map(string)): Tags to apply to resources
	- `user_pool_id` (string): Cognito User Pool ID
	- `user_pool_client_id` (string): Cognito User Pool Client ID
	- `user_pool_client_secret` (string): Cognito User Pool Client secret
	- `user_pool_domain` (string): Cognito User Pool domain prefix

	## Outputs
	- `lambda_edge_arn` (string): Qualified ARN of the published Lambda@Edge version

## Local testing
- Lambda@Edge cannot be executed locally exactly as CloudFront does. For unit tests and quick validation:
	- Use Node 22+ (the code uses ESM modules).
	- Add a small test harness script that imports the `index.mjs` handler and invokes it with a mock CloudFront event shape.
		- Example minimal harness (create `test-harness.mjs` inside `lambda_functions/`):

			```js
			import { handler } from './index.mjs';
			const event = { Records: [ { cf: { request: { uri: '/', method: 'GET', headers: {} } } } ] };
			handler(event, {}, (err, res) => { console.log(err || res); });
			```

## Troubleshooting
- If Terraform fails to deploy the Lambda in a different region, ensure `providers.tf` pins the AWS provider region to `us-east-1` for Lambda@Edge resources.
- Check CloudWatch Logs for the deployed Lambda for runtime errors.

