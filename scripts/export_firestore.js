#!/usr/bin/env node
/**
 * SafePoint V1 → V2 Migration
 * Step 1: Export all Firestore collections to JSON files.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node export_firestore.js
 *
 * Output: ./export/<collection>.json  (one document per line, NDJSON)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const COLLECTIONS = [
  'users',
  'organizations',
  'refuges',
  'persons',
  'checkins',
  'transfers',
  'alerts',
  'families',
  'needs',
  'crisis_events',
  'audit_logs',
];

const OUTPUT_DIR = path.join(__dirname, 'export');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function exportCollection(name) {
  console.log(`Exporting ${name}...`);
  const snap = await db.collection(name).get();
  const outPath = path.join(OUTPUT_DIR, `${name}.json`);
  const stream = fs.createWriteStream(outPath);
  for (const doc of snap.docs) {
    const data = doc.data();
    // Convert Firestore Timestamps to ISO strings for portability
    const serialized = JSON.stringify(convertTimestamps(data));
    stream.write(serialized + '\n');
  }
  stream.end();
  console.log(`  → ${snap.size} documents → ${outPath}`);
}

function convertTimestamps(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj && typeof obj.toDate === 'function') {
    return obj.toDate().toISOString();
  }
  if (Array.isArray(obj)) return obj.map(convertTimestamps);
  if (typeof obj === 'object') {
    return Object.fromEntries(
      Object.entries(obj).map(([k, v]) => [k, convertTimestamps(v)])
    );
  }
  return obj;
}

async function main() {
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  for (const col of COLLECTIONS) {
    await exportCollection(col);
  }
  console.log('\nExport complete.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
