#!/usr/bin/env node
/**
 * decode-wa.js — Decode WeakAuras / M33kAura export strings (WA:2! format).
 *
 * Chain: EncodeForPrint → zlib (raw deflate) → LibSerialize blob → text
 *
 * Usage:
 *   node scripts/decode-wa.js "WA:2!nFv3QT..."
 *   node scripts/decode-wa.js --file export.txt
 *   echo "WA:2!nFv3..." | node scripts/decode-wa.js --stdin
 */
"use strict";

const zlib = require("zlib");
const fs = require("fs");

// ── EncodeForPrint decode table ──────────────────────────────────
// a-z=0-25, A-Z=26-51, 0-9=52-61, (=62, )=63
const decodeMap = {};
for (let i = 0; i < 26; i++) { decodeMap[String.fromCharCode(97 + i)] = i; }
for (let i = 0; i < 26; i++) { decodeMap[String.fromCharCode(65 + i)] = i + 26; }
for (let i = 0; i < 10; i++) { decodeMap[String.fromCharCode(48 + i)] = i + 52; }
decodeMap["("] = 62;
decodeMap[")"] = 63;

function decodeForPrint(str) {
  str = str.replace(/^[\x00-\x20]+/, "").replace(/[\x00-\x20]+$/, "");
  if (str.length < 2) return null;
  const bytes = [];
  const strlen = str.length;
  let i = 0;
  while (i + 3 < strlen) {
    const x1 = decodeMap[str[i]], x2 = decodeMap[str[i + 1]];
    const x3 = decodeMap[str[i + 2]], x4 = decodeMap[str[i + 3]];
    if (x1 === undefined || x2 === undefined || x3 === undefined || x4 === undefined) return null;
    i += 4;
    const cache = x1 + x2 * 64 + x3 * 4096 + x4 * 262144;
    bytes.push(cache & 0xff, (cache >> 8) & 0xff, (cache >> 16) & 0xff);
  }
  let cache = 0, bits = 0;
  while (i < strlen) {
    const x = decodeMap[str[i++]];
    if (x === undefined) return null;
    cache += x * (1 << bits);
    bits += 6;
  }
  while (bits >= 8) {
    bytes.push(cache & 0xff);
    cache >>= 8;
    bits -= 8;
  }
  return Buffer.from(bytes);
}

// ── Main ─────────────────────────────────────────────────────────

function decodeWAString(raw) {
  let encoded = raw.trim();
  const prefixMatch = encoded.match(/^(WA:2!|WA:2)/);
  if (prefixMatch) encoded = encoded.substring(prefixMatch[0].length);
  if (!encoded || encoded.length < 4) {
    console.error("Error: empty or too-short encoded string");
    return 1;
  }

  // Step 1: DecodeForPrint
  const decoded = decodeForPrint(encoded);
  if (!decoded) {
    console.error("Error: EncodeForPrint decode failed");
    return 1;
  }

  // Step 2: Decompress
  let decompressed;
  try {
    decompressed = zlib.inflateSync(decoded);
  } catch (_) {
    try {
      decompressed = zlib.inflateRawSync(decoded);
    } catch (e2) {
      console.error("Error: deflate decompression failed:", e2.message);
      return 1;
    }
  }

  // Step 3: Convert to readable text, collapsing LibSerialize binary bytes
  const len = decompressed.length;
  const out = [];
  let runStart = -1;
  let binaryCount = 0;

  for (let i = 0; i < len; i++) {
    const b = decompressed[i];
    // Printable ASCII (space through ~) and common whitespace
    if ((b >= 0x20 && b <= 0x7e) || b === 0x0a || b === 0x0d) {
      if (runStart === -1) runStart = i;
    } else {
      if (runStart !== -1) {
        const text = decompressed.slice(runStart, i).toString("utf8");
        if (text.trim().length > 0) out.push(text);
        runStart = -1;
      }
      binaryCount++;
    }
  }
  if (runStart !== -1) {
    const text = decompressed.slice(runStart, len).toString("utf8");
    if (text.trim().length > 0) out.push(text);
  }

  const text = out.join(" ");
  console.log(text.substring(0, 12000));
  if (text.length > 12000) {
    console.log(`\n... (${text.length - 12000} more chars, ${binaryCount} binary bytes skipped)`);
  }
  return 0;
}

// ── CLI ──────────────────────────────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  let input;

  if (args.includes("--stdin") || args.includes("-")) {
    input = fs.readFileSync(0, "utf8").trim();
  } else if (args.includes("--file") || args.includes("-f")) {
    const idx = args.includes("--file") ? args.indexOf("--file") : args.indexOf("-f");
    const filePath = args[idx + 1];
    if (!filePath) { console.error("Error: --file requires a path"); return 1; }
    input = fs.readFileSync(filePath, "utf8").trim();
  } else {
    input = args.join(" ");
  }

  if (!input) {
    console.error("Usage: node scripts/decode-wa.js <WA:2!...string>");
    console.error("       node scripts/decode-wa.js --file export.txt");
    console.error("       echo 'WA:2!...' | node scripts/decode-wa.js --stdin");
    return 1;
  }

  return decodeWAString(input);
}

process.exit(main());
