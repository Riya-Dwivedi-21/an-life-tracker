# Google Sign-In Setup Guide for iOS & Android

## Overview
This guide will help you set up Google authentication for your AN Life Tracker app on both iOS and Android platforms.

---

## 📋 Prerequisites

### 1. Create a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your **Project ID**

### 2. Enable Google Sign-In API
1. In Google Cloud Console, go to **APIs & Services** > **Library**
2. Search for "Google Sign-In" or "Google+ API"
3. Click **Enable**

---

## 🌐 Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Choose **External** (or Internal if you have a Google Workspace)
3. Fill in:
   - **App name**: AN Life Tracker
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Click **Save and Continue**
5. Add scopes: `email` and `profile` (already selected by default)
6. Save and continue through the remaining steps

---

## 🔑 Create OAuth 2.0 Credentials

### For Android

1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Select **Android**
4. Fill in:
   - **Name**: Android Client (or any name you prefer)
   - **Package name**: `com.example.an_life_tracker` (match your app's package name)
   - **SHA-1 certificate fingerprint**: See below how to get this

#### Get SHA-1 Fingerprint:

**For Debug Build:**
```bash
# On Windows (PowerShell):
cd android
./gradlew signingReport

# Or use keytool directly:
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**For Release Build:**
```bash
keytool -list -v -keystore path/to/your/release/keystore.jks -alias your-alias-name
```

Copy the **SHA-1** hash and paste it in Google Cloud Console.

5. Click **Create**
6. Copy the **Client ID** (you'll need this later)

### For iOS

1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Select **iOS**
4. Fill in:
   - **Name**: iOS Client
   - **Bundle ID**: `com.example.anLifeTracker` (match your iOS bundle ID in Xcode)
5. Click **Create**
6. Copy the **iOS Client ID** and **iOS URL scheme** (you'll need these)

### For Web (Required for Supabase)

1. Create another credential
2. Select **Web application**
3. Fill in:
   - **Name**: Web Client
   - **Authorized redirect URIs**: 
     - `https://bqiqwvcwoclgntofggtc.supabase.co/auth/v1/callback`
4. Click **Create**
5. Copy the **Web Client ID** - THIS IS IMPORTANT for Supabase!

---

## 📱 Android Configuration

### 1. Update `android/app/build.gradle.kts`

Add at the top (if not already present):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

Ensure your `applicationId` matches the package name used in Google Cloud:
```kotlin
android {
    defaultConfig {
        applicationId = "com.example.an_life_tracker"
        // ... other config
    }
}
```

### 2. No additional files needed
The `google_sign_in` package handles everything automatically for Android!

---

## 🍎 iOS Configuration

### 1. Update `ios/Runner/Info.plist`

Add the following before the closing `</dict>` tag:

```xml
<!-- Google Sign-In iOS URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_REVERSED</string>
        </array>
    </dict>
</array>

<!-- Google Sign-In Configuration -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

**How to get REVERSED_CLIENT_ID:**
If your iOS Client ID is: `123456789-abc.apps.googleusercontent.com`
Then REVERSED_CLIENT_ID is: `com.googleusercontent.apps.123456789-abc`

### 2. Update Bundle Identifier in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** project
3. Go to **Signing & Capabilities**
4. Ensure **Bundle Identifier** matches what you set in Google Cloud Console
   - Example: `com.example.anLifeTracker`

---

## ☁️ Supabase Configuration

### 1. Enable Google Provider in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** > **Providers**
3. Find **Google** and click **Enable**
4. Fill in:
   - **Client ID**: Your **Web Client ID** from Google Cloud Console
   - **Client Secret**: Your **Web Client Secret** from Google Cloud Console
5. Click **Save**

### 2. Add Redirect URL

The redirect URL should already be configured as:
```
https://bqiqwvcwoclgntofggtc.supabase.co/auth/v1/callback
```

Make sure this matches the authorized redirect URI in Google Cloud Console.

---

## 🔧 Update Your Flutter Code

### 1. Update `lib/core/services/google_signin_service.dart`

Uncomment and add your Web Client ID:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
  ],
  // Add your Web Client ID here (IMPORTANT!)
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

**Note:** Use the **Web Client ID**, NOT the Android or iOS Client ID!

---

## 🧪 Testing

### Install Dependencies
```bash
flutter pub get
```

### Test on Android
```bash
flutter run -d android
```

1. Click "Continue with Google"
2. Select your Google account
3. Grant permissions
4. You should be signed in!

### Test on iOS
```bash
flutter run -d ios
```

1. Click "Continue with Google"
2. Select your Google account
3. Grant permissions
4. You should be signed in!

---

## ⚠️ Common Issues & Solutions

### Issue 1: "PlatformException(sign_in_failed)"
**Solution:** 
- Double-check SHA-1 fingerprint in Google Cloud Console
- Make sure package name matches exactly
- For Android: Run `./gradlew signingReport` to verify SHA-1

### Issue 2: iOS - "Error 400: redirect_uri_mismatch"
**Solution:**
- Check Bundle ID in Xcode matches Google Cloud Console
- Verify iOS URL scheme in Info.plist is correct (reversed client ID)
- Ensure `GIDClientID` in Info.plist matches your iOS Client ID

### Issue 3: "Developer Error" on Android
**Solution:**
- Make sure you added SHA-1 fingerprint to Google Cloud Console
- Wait 5-10 minutes after adding SHA-1 (Google needs to propagate changes)
- Try clearing app data and reinstalling

### Issue 4: Google Sign-In works but Supabase auth fails
**Solution:**
- Verify Web Client ID is added to `google_signin_service.dart`
- Check Supabase Dashboard has Google provider enabled
- Ensure Web Client ID/Secret are correct in Supabase

### Issue 5: "API key not valid" error
**Solution:**
- Go to Google Cloud Console > APIs & Services > Credentials
- Restrict API key only if needed, or remove restrictions for testing
- Enable required APIs (Google Sign-In API)

---

## 📝 Quick Checklist

- [ ] Created Google Cloud Project
- [ ] Enabled Google Sign-In API
- [ ] Configured OAuth consent screen
- [ ] Created Android OAuth Client (with SHA-1)
- [ ] Created iOS OAuth Client (with Bundle ID)
- [ ] Created Web OAuth Client (for Supabase)
- [ ] Added Web Client ID to Supabase Dashboard
- [ ] Updated `google_signin_service.dart` with Web Client ID
- [ ] Added iOS URL scheme to Info.plist
- [ ] Added GIDClientID to Info.plist
- [ ] Verified Android package name matches
- [ ] Verified iOS Bundle ID matches
- [ ] Ran `flutter pub get`
- [ ] Tested on Android device/emulator
- [ ] Tested on iOS device/simulator

---

## 🎉 You're Done!

Your app now supports Google Sign-In on both iOS and Android! Users can sign in with just one tap using their Google account.

## 📞 Need Help?

If you encounter any issues:
1. Check the error message carefully
2. Verify all Client IDs and secrets are correct
3. Make sure SHA-1 fingerprints match (for Android)
4. Wait a few minutes after making changes in Google Cloud Console
5. Try clearing app data and reinstalling

---

## 🔐 Security Best Practices

1. **Never commit** `google-services.json` or `GoogleService-Info.plist` to public repositories
2. Use **environment variables** for sensitive keys in production
3. Enable **App Check** in Firebase for additional security
4. Regularly rotate your OAuth client secrets
5. Monitor authentication logs in Supabase Dashboard

