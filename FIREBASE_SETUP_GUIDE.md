# SafePoint — Firebase Complete Setup Guide

Complete configuration guide for Firebase V1 backend with Google Sign-In, Firestore, Storage, and Messaging.

---

## Prerequisites

- Firebase account at https://console.firebase.google.com/
- Google Cloud Console access
- Flutter SDK 3.2+
- Android SDK / Xcode for mobile
- `flutterfire_cli` installed (`flutter pub global activate flutterfire_cli`)

---

## 1️⃣ Create Firebase Project

### In Firebase Console:

1. Go to https://console.firebase.google.com/
2. Click **"Create a project"**
3. Name: **safepoint**
4. Accept terms → **Continue**
5. Disable Google Analytics (optional)
6. **Create project** — wait 1-2 minutes

### Configure Location

- Settings → Project settings → Cloud location
- Select **europe-west1** (or closest to Guadeloupe)

---

## 2️⃣ Enable Authentication

### Email/Password Auth

1. **Authentication** tab
2. **Sign-in method** → **Email/Password**
3. Enable both: ✅ Email/Password, ✅ Email link
4. **Save**

### Google Sign-In

1. **Sign-in method** → **Google**
2. Enable ✅
3. Select **Support email** (your email)
4. **Save**

---

## 3️⃣ Configure OAuth 2.0 (Google Sign-In)

### For Web

1. **Project settings** → **Service accounts**
2. **Manage OAuth consent screen**
3. **External** → **Create**
4. **App name:** SafePoint
5. **User support email:** your-email@example.com
6. **Add scopes:** `email`, `profile`, `openid`
7. **Save & Continue** → **Back to dashboard**

### Add OAuth Client

1. **Credentials** tab
2. **Create Credentials** → **OAuth 2.0 Client IDs**
3. **Web application**
4. **Name:** SafePoint Web
5. **Authorized JavaScript origins:**
   ```
   http://localhost:5000
   http://localhost:3000
   https://yourdomain.com
   ```
6. **Authorized redirect URIs:**
   ```
   http://localhost:5000/
   http://localhost:3000/
   https://yourdomain.com/
   http://localhost:5000/__/auth/handler
   ```
7. **Create** → Copy **Client ID**
8. Update `lib/core/firebase_options.dart`:
   ```dart
   await GoogleSignIn(
     clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com', // Paste here
     ...
   )
   ```

### For Android

1. **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**
2. **Android**
3. **Name:** SafePoint Android
4. **Package name:** `com.safepoint.app`
5. **SHA-1 fingerprint:** (see below)
6. **Create**

**Get SHA-1 fingerprint:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### For iOS

1. **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**
2. **iOS**
3. **Name:** SafePoint iOS
4. **Bundle ID:** `com.safepoint.app`
5. **Create**

---

## 4️⃣ Configure Firestore

1. **Firestore Database** tab
2. **Create database**
3. **Location:** europe-west1
4. **Security rules:** **Start in production mode** (rules in `firestore.rules`)
5. **Create**

### Collections to Create

```
/organizations/{orgId}
/users/{userId}
/refuges/{refugeId}
/persons/{personId}
/checkins/{checkinId}
/transfers/{transferId}
/alerts/{alertId}
/families/{familyId}
/needs/{needId}
/crisis_events/{eventId}
/audit_logs/{logId}
/files/{fileId}
```

Deploy security rules:

```bash
firebase deploy --only firestore:rules
```

---

## 5️⃣ Configure Cloud Storage

1. **Storage** tab
2. **Get started** → **Next**
3. **Location:** europe-west1
4. **Done**

### Storage Paths Structure

```
/organizations/{organizationId}
  /persons/{personId}
  /refuges/{refugeId}
  /alerts/{alertId}
  /reports/{reportId}
```

---

## 6️⃣ Enable Cloud Messaging (Push Notifications)

1. **Cloud Messaging** tab
2. **Enable Cloud Messaging API** on Google Cloud Console
3. Copy **Server key** and **Sender ID**

---

## 7️⃣ Configure Firebase in Flutter

### Update `firebase_options.dart`

1. Get config from **Project settings** → **Your apps** → **Config**
2. Copy credentials to `lib/core/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'safepoint-xxxxx.firebaseapp.com',
  storageBucket: 'safepoint-xxxxx.appspot.com',
);
```

### Initialize Firebase

Run (in project root):

```bash
flutterfire configure --project=safepoint
```

This automatically updates:
- `android/build.gradle`
- `ios/Podfile`
- `web/index.html`
- `macos/Podfile` (if applicable)

---

## 8️⃣ Deploy Firestore Security Rules

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login:
   ```bash
   firebase login
   ```

3. Initialize project:
   ```bash
   firebase init
   ```

4. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## 9️⃣ Create Demo Users

### Create First Agent via Firebase Console

1. **Authentication** → **Users**
2. **Add user**
3. Email: `agent@safepoint.app`
4. Password: `SecurePassword123!`
5. Create

### Create Firestore Profile

1. **Firestore** → **users** collection
2. **Add document** → Document ID: `{uid-from-auth}`

```json
{
  "organizationId": "org_guadeloupe",
  "email": "agent@safepoint.app",
  "firstName": "Agent",
  "lastName": "Test",
  "role": "AGENT",
  "refugeId": "shelter_1",
  "isActive": true,
  "createdAt": "2026-06-29T00:00:00Z",
  "createdBy": "system",
  "updatedBy": "system"
}
```

---

## 🔟 Test the Setup

### Run App

```bash
flutter pub get
flutter run
```

### Test Email/Password Auth

1. Login with `agent@safepoint.app` / `SecurePassword123!`
2. Should see dashboard

### Test Google Sign-In

1. Click **"Se connecter avec Google"**
2. Select Google account
3. Should auto-create user in Firestore

### Test Firestore Writes

1. Create a person in app
2. Check Firestore → persons collection
3. Should see new document

### Test File Upload

1. Upload document in app
2. Check Storage → organizations/org_guadeloupe/...
3. File should appear

---

## 📊 Monitoring

### View Metrics

- **Analytics** dashboard
- **Usage** → See requests, reads, writes
- **Quota** → See limits

### Set Alerts

1. **Settings** → **Notifications** → **Quotas**
2. Enable alerts for:
   - Firestore read operations
   - Firestore write operations
   - Cloud Storage operations

---

## 🔒 Security Best Practices

✅ **Enable:**
- App Check (prevent abuse)
- Strong password policy
- MFA for admins
- Firestore security rules (in `firestore.rules`)

❌ **Disable:**
- Public Firestore access
- Anonymous auth (for production)
- Unsigned tokens

---

## 🚀 Next: Prepare for V2 Migration

Once V1 is stable:

1. Run migration export scripts:
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json \
   node scripts/export_firestore.js
   ```

2. Transform data:
   ```bash
   python scripts/transform_firestore_to_sql.py
   ```

3. Prepare PostgreSQL/Cloud Temple infrastructure
4. Deploy NestJS backend + Keycloak
5. Flip `Environment.useApiBackend = true` in Flutter

---

## 📝 Environment Variables

Create `.env` file for local development:

```env
FIREBASE_PROJECT_ID=safepoint-xxxxx
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxx
FIREBASE_STORAGE_BUCKET=safepoint-xxxxx.appspot.com
FCM_SERVER_KEY=xxxxx
```

Load in `lib/main.dart`:

```dart
const apiKey = String.fromEnvironment('FIREBASE_PROJECT_ID');
```

---

## ✅ Checklist

- [ ] Firebase project created
- [ ] Web app added and configured
- [ ] Authentication enabled (Email/Password + Google)
- [ ] Firestore database created
- [ ] Cloud Storage enabled
- [ ] Cloud Messaging enabled
- [ ] OAuth 2.0 credentials set up (Web, Android, iOS)
- [ ] `firebase_options.dart` updated with real credentials
- [ ] `flutterfire configure` run
- [ ] Firestore security rules deployed
- [ ] Demo user created
- [ ] App tested (login, file upload, Firestore writes)
- [ ] Monitoring and alerts configured

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Google Sign-In fails** | Check OAuth client ID in `firebase_options.dart` |
| **Firestore denied** | Deploy security rules: `firebase deploy --only firestore:rules` |
| **File upload fails** | Check Storage location in `firebase_options.dart` |
| **"Project not found"** | Verify `projectId` in config matches Firebase console |
| **Auth not persisting** | Ensure `flutter_secure_storage` saves tokens locally |

---

## 📚 References

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
