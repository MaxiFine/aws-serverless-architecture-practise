/**
 * Loads JSON configuration for the Lambda@Edge handlers.
 * - Reads ../config.json relative to the bundled handler location
 * - Exports: cfg (parsed object)
 * Notes: Uses ESM-friendly __dirname via fileURLToPath.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load config.json colocated with the handler bundle
export const cfg = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../config.json"), "utf8")
);
