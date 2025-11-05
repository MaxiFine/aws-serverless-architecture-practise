/**
 * Route protection configuration and matcher.
 * - PROTECTED_RULES: [{ prefix: string (supports trailing *), methods?: string[] }]
 * - Default behavior: routes NOT matching any rule are open (no auth)
 * - Matching: if prefix ends with *, prefix match; else exact or segment-aware prefix
 * - methods: empty => protect all methods; otherwise string-matched, case-insensitive
 */
import { cfg } from "./config.mjs";

// Use only rules from config.json; if none are provided, no routes are protected.
const rawRules = Array.isArray(cfg.PROTECTED_RULES) ? cfg.PROTECTED_RULES : [];
export const PROTECTED_RULES = rawRules.map((rule) => ({
  prefix: typeof rule?.prefix === "string" ? rule.prefix : "/",
  methods: Array.isArray(rule?.methods)
    ? rule.methods.map((m) => String(m).toUpperCase())
    : [], // empty => protect all methods for matching prefix (handled in isProtected)
}));

export function isProtected({ uri, method }) {
  const m = (method || "GET").toUpperCase();
  for (const rule of PROTECTED_RULES) {
    const p = rule.prefix || "/";
    const star = p.endsWith("*");
    const base = star ? p.slice(0, -1) : p;
    // Segment-aware matching: for non-star rules, require exact match or a '/' boundary
    const match = star
      ? uri.startsWith(base)
      : (uri === base || uri.startsWith(base.endsWith("/") ? base : base + "/"));
    if (!match) continue;
    if (!rule.methods || rule.methods.length === 0) return true; // all methods protected
    if (rule.methods.map(x => x.toUpperCase()).includes(m)) return true;
  }
  return false;
}
