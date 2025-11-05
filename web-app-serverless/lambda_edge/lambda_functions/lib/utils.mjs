/**
 * Utility functions for Lambda@Edge auth flow and responses.
 * Exports:
 *  - ONE_MIN, TEN_MIN, cookieBase
 *  - b64url(buffer|Uint8Array): string
 *  - sha256(input: string|Uint8Array): Promise<Uint8Array>
 *  - randomBytes(n?): Uint8Array
 *  - parseCookies(headers): Record<string,string>
 *  - setCookie(headers, name, value, attrs?) / delCookie(headers, name)
 *  - redirect(location, extraHeaders?, status?): CloudFront response
 */
import { webcrypto as _wc } from "crypto";

export const ONE_MIN = 60;
export const TEN_MIN = 10 * ONE_MIN;
export const cookieBase = "; Path=/; Secure; HttpOnly; SameSite=Lax";

const subtle = (globalThis.crypto?.subtle || _wc.subtle);

export const b64url = (buf) =>
  Buffer.from(buf).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");

export async function sha256(input) {
  const data = typeof input === "string" ? Buffer.from(input) : input;
  const hash = await subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}

export function randomBytes(n = 32) {
  const a = new Uint8Array(n);
  (_wc || globalThis.crypto).getRandomValues(a);
  return a;
}

export function parseCookies(headers) {
  const cookieHeader = headers.cookie?.[0]?.value || "";
  return Object.fromEntries(
    cookieHeader.split(";").filter(Boolean).map((c) => {
      const i = c.indexOf("=");
      return [c.slice(0, i).trim(), decodeURIComponent(c.slice(i + 1))];
    }),
  );
}

export function setCookie(headers, name, value, attrs = cookieBase) {
  headers["set-cookie"] = headers["set-cookie"] || [];
  headers["set-cookie"].push({ key: "Set-Cookie", value: `${name}=${encodeURIComponent(value)}${attrs}` });
}

export function delCookie(headers, name) {
  setCookie(headers, name, "", `${cookieBase}; Max-Age=0`);
}

export function redirect(location, extraHeaders = {}, status = "302") {
  const desc = status === "301" ? "Moved Permanently"
    : status === "302" ? "Found"
    : status === "303" ? "See Other"
    : status === "307" ? "Temporary Redirect"
    : status === "308" ? "Permanent Redirect"
    : "Found";
  return {
    status,
    statusDescription: desc,
    headers: { location: [{ key: "Location", value: location }], ...extraHeaders },
  };
}
