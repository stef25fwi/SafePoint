#!/usr/bin/env node
/**
 * SafePoint V1 → V2 Migration
 * Step 5a: Export Firebase Auth users to JSON.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json \
 *   node export_firebase_auth.js
 *
 * Output: ./export/firebase_users.json  (array of user records)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const OUTPUT_FILE = path.join(__dirname, 'export', 'firebase_users.json');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

async function exportUsers() {
  const users = [];
  let nextPageToken;

  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of result.users) {
      users.push({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        disabled: user.disabled,
        emailVerified: user.emailVerified,
        creationTime: user.metadata.creationTime,
        lastSignInTime: user.metadata.lastSignInTime,
        // Role and shelterId must be fetched from Firestore /users collection
      });
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(users, null, 2));
  console.log(`Exported ${users.length} users → ${OUTPUT_FILE}`);
}

exportUsers().catch((err) => {
  console.error(err);
  process.exit(1);
});
