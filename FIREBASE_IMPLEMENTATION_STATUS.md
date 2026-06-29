# SafePoint — Firebase Implementation Status Report

**Date:** 2026-06-29  
**Branch:** `main` (synced with PR #4)  
**Status:** ✅ Main up-to-date | ⚠️ Firebase Google Auth incomplete

---

## ✅ Verification Results

### Branch Status
- ✅ **main** is up-to-date with remote (`origin/main`)
- ✅ PR #4 merged V1 migration-ready architecture (105 files, 18,407 insertions)
- ✅ All repository/service layer files present
- ✅ Firestore rules configured (`firestore.rules`)
- ✅ Migration scripts included (`scripts/` folder)

---

## ⚠️ Firebase Implementation Gaps

### Critical Missing Features

| Feature | Status | Impact | Fix Required |
|---------|--------|--------|--------------|
| **Google Sign-In** | ❌ Missing | Cannot auth via Google account | Add `google_sign_in` package + implement `signInWithGoogle()` |
| **Firebase Storage** | ❌ Missing | Cannot upload/download files | Add `firebase_storage` package + implement FileRepository |
| **Cloud Messaging** | ❌ Missing | No push notifications | Add `firebase_messaging` package |
| **Custom Claims** | ⏳ Partial | Role verification incomplete | Need server-side validation in Cloud Functions |
| **App Check** | ⏳ Missing | No request validation | Require Firebase App Check configuration |

### Partially Implemented

| Component | Status | Details |
|-----------|--------|---------|
| **Firebase Config** | ⚠️ Placeholder | `firebase_options.dart` has `YOUR_*` placeholders (expected - user must fill) |
| **Email/Password Auth** | ✅ Done | `signInWithEmail()` + `signInWithAgentCode()` working |
| **Firestore CRUD** | ✅ Done | 10 repository implementations with full serialization |
| **Audit Logging** | ✅ Done | All sensitive actions logged to audit_logs collection |
| **Offline Mode** | ✅ Done | Demo mode without Firebase works |

---

## 🔧 Required Fixes

### 1. Add Missing Packages to `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  intl: ^0.19.0
  uuid: ^4.4.0
  shared_preferences: ^2.3.2
  url_launcher: ^6.3.0
  # Firebase — COMPLETE SUITE
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.1.2           # ⬅️ ADD THIS
  firebase_messaging: ^14.9.2         # ⬅️ ADD THIS
  google_sign_in: ^6.2.1              # ⬅️ ADD THIS
  flutter_secure_storage: ^9.2.2      # ⬅️ ADD THIS (for secure token storage)
```

### 2. Implement Google Sign-In in `firebase_auth_repository.dart`

Add method:
```dart
Future<UserModel?> signInWithGoogle() async {
  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(cred);
    return _fetchProfile(userCred.user!.uid);
  } catch (e) {
    debugPrint('[GoogleSignIn] Error: $e');
    return null;
  }
}
```

### 3. Create `firebase_file_repository.dart`

New file: `lib/infrastructure/firebase/firebase_file_repository.dart`
- Implement file upload/download via Firebase Storage
- Support organized paths: `/organizations/{orgId}/persons/{personId}/...`
- Return signed URLs (expiry: 24h)

### 4. Implement `FileService`

New file: `lib/domain/services/file_service.dart`
- Wrap FileRepository
- Handle upload progress
- Audit log file operations

### 5. Configure Google OAuth in Firebase Console

**Web:**
- Enable Google Sign-In provider
- Add OAuth consent screen
- Add authorized origins (localhost:5000, deployment URL)

**Android:**
- SHA-1 fingerprint from `keytool -list -v -keystore ~/.android/debug.keystore`

**iOS:**
- Bundle ID: `com.safepoint.app`
- Enable Google Sign-In in Capabilities

### 6. Update `lib/pages/login_page.dart`

Add Google Sign-In button:
```dart
ElevatedButton.icon(
  onPressed: _signInWithGoogle,
  icon: const Icon(Icons.login_outlined),
  label: const Text('Se connecter avec Google'),
),
```

---

## 📋 Checklist to Complete Firebase Implementation

- [ ] Add `firebase_storage` to pubspec.yaml
- [ ] Add `firebase_messaging` to pubspec.yaml
- [ ] Add `google_sign_in` to pubspec.yaml
- [ ] Add `flutter_secure_storage` to pubspec.yaml
- [ ] Implement `signInWithGoogle()` in FirebaseAuthRepository
- [ ] Create `FileRepository` abstract interface
- [ ] Implement `FirebaseFileRepository`
- [ ] Create `FileService`
- [ ] Update `ServiceLocator` to inject FileService
- [ ] Add Google Sign-In button to LoginPage
- [ ] Configure Firebase Console (Google provider)
- [ ] Configure Google OAuth web/Android/iOS
- [ ] Test Google Sign-In flow end-to-end
- [ ] Implement Firebase Cloud Messaging (push notifications)
- [ ] Add App Check validation
- [ ] Document credentials setup in README

---

## 🚀 Next Steps

1. **Update pubspec.yaml** with missing packages
2. **Run `flutter pub get`**
3. **Implement Google Sign-In** (priority: high)
4. **Configure Firebase Console** with OAuth credentials
5. **Test login flow** in emulator/device
6. **Implement FileService** (priority: medium)
7. **Add push notifications** (priority: medium)

---

## 📝 Notes

- **Demo mode works offline** — no Firebase needed for mockups
- **Email auth works** — but Google auth is needed for production
- **Firestore rules are strict** — only authenticated users with proper org can access data
- **All code is architecture-ready for V2 API migration** — just flip `Environment.useApiBackend = true`
