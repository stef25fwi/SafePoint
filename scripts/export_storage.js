#!/usr/bin/env node
/**
 * SafePoint V1 → V2 Migration
 * Step 4a: Download all files from Firebase Storage to a local directory.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json \
 *   FIREBASE_STORAGE_BUCKET=safepoint-prod.appspot.com \
 *   node export_storage.js
 *
 * Output: ./storage_export/<path>  (mirrors the bucket structure)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { pipeline } = require('stream/promises');

const BUCKET_NAME = process.env.FIREBASE_STORAGE_BUCKET;
const OUTPUT_DIR = path.join(__dirname, 'storage_export');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  storageBucket: BUCKET_NAME,
});

const bucket = admin.storage().bucket();

async function downloadAll() {
  if (!BUCKET_NAME) {
    console.error('ERROR: FIREBASE_STORAGE_BUCKET env var required');
    process.exit(1);
  }
  if (!fs.existsSync(OUTPUT_DIR)) fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const [files] = await bucket.getFiles();
  console.log(`Found ${files.length} files to download`);

  let count = 0;
  for (const file of files) {
    const localPath = path.join(OUTPUT_DIR, file.name);
    fs.mkdirSync(path.dirname(localPath), { recursive: true });
    await pipeline(file.createReadStream(), fs.createWriteStream(localPath));
    count++;
    if (count % 50 === 0) console.log(`  ${count}/${files.length} downloaded`);
  }
  console.log(`\nDownload complete: ${count} files → ${OUTPUT_DIR}`);
}

downloadAll().catch((err) => {
  console.error(err);
  process.exit(1);
});
