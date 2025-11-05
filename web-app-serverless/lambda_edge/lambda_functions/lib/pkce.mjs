/**
 * PKCE OAuth helpers for Cognito.
 * Exports:
 *  - buildAuthorizeUrl({ state, codeChallenge, cfg, redirectUri }): string
 *  - exchangeCode({ code, verifier, cfg, redirectUri }): Promise<{ id_token, access_token, expires_in, ... }>
 * Requires:
 *  - cfg with CLIENT_ID and COGNITO_DOMAIN
 *  - redirectUri assembled from request host + callback path
 */
export function buildAuthorizeUrl({ state, codeChallenge, cfg, redirectUri }) {
  const scope = encodeURIComponent(cfg.SCOPES || "openid email profile");
  const ru = encodeURIComponent(redirectUri);
  return `https://${
    cfg.COGNITO_DOMAIN
  }/login?response_type=code&client_id=${
    cfg.CLIENT_ID
  }&redirect_uri=${ru}&code_challenge=${codeChallenge}&code_challenge_method=S256&scope=${scope}&state=${encodeURIComponent(
    state
  )}`;
}

export async function exchangeCode({ code, verifier, cfg, redirectUri }) {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: cfg.CLIENT_ID,
    code,
    redirect_uri: redirectUri,
    code_verifier: verifier,
  }).toString();

  const resp = await fetch(`https://${cfg.COGNITO_DOMAIN}/oauth2/token`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!resp.ok) {
    const text = await resp.text().catch(() => "");
    throw new Error(`Token exchange failed: ${resp.status} ${text}`);
  }
  return resp.json();
}
