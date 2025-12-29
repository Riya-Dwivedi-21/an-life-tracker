# 🚀 Quick Start: Google Auth Setup

## Step 1: Google Cloud Console Setup (5 minutes)

1. **Create OAuth Credentials** at https://console.cloud.google.com/apis/credentials

2. **Create 3 OAuth Client IDs:**

   ### Android Client
   - Type: Android
   - Package: `com.example.an_life_tracker`
   - SHA-1: Get via `cd android && ./gradlew signingReport`

   ### iOS Client  
   - Type: iOS
   - Bundle ID: `com.example.anLifeTracker`

   ### Web Client (MOST IMPORTANT!)
   - Type: Web
   - Redirect URI: `https://bqiqwvcwoclgntofggtc.supabase.co/auth/v1/callback`

3. **Save these values:**
   - Web Client ID: `______________.apps.googleusercontent.com`
   - Web Client Secret: `______________`
   - iOS Client ID: `______________.apps.googleusercontent.com`

---

## Step 2: Supabase Dashboard (2 minutes)

1. Go to **Authentication** > **Providers** > **Google**
2. Enable Google provider
3. Paste **Web Client ID** and **Web Client Secret**
4. Save

---

## Step 3: Update Flutter Code (1 minute)

### File: `lib/core/services/google_signin_service.dart`

Replace line 14 with:
```dart
serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
```

**⚠️ Use WEB Client ID, not Android or iOS Client ID!**

---

## Step 4: iOS Configuration (3 minutes)

### File: `ios/Runner/Info.plist`

Add before `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- If iOS Client ID is: 123-abc.apps.googleusercontent.com -->
            <!-- Then use: com.googleusercontent.apps.123-abc -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_REVERSED</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
```

**How to reverse iOS Client ID:**
- Original: `123456-abc.apps.googleusercontent.com`
- Reversed: `com.googleusercontent.apps.123456-abc`

---

## Step 5: Android Configuration (AUTOMATIC! ✅)

Android setup is automatic - just make sure:
1. SHA-1 is added to Google Cloud Console
2. Package name in `android/app/build.gradle.kts` matches Google Cloud Console

---

## Step 6: Test!

```bash
flutter pub get
flutter run
```

Tap "Continue with Google" button and sign in!

---

## 🔍 Quick Debug Checklist

**If Google Sign-In doesn't work:**

### Android Issues:
- [ ] SHA-1 fingerprint added to Google Cloud Console?
- [ ] Package name matches exactly?
- [ ] Waited 5-10 minutes after adding SHA-1?
- [ ] Clear app data and reinstall

### iOS Issues:
- [ ] Bundle ID matches Google Cloud Console?
- [ ] Reversed Client ID correct in Info.plist?
- [ ] GIDClientID matches iOS Client ID?

### Both Platforms:
- [ ] Web Client ID added to `google_signin_service.dart`?
- [ ] Google provider enabled in Supabase?
- [ ] Correct Web Client ID/Secret in Supabase?

---

## 📋 Values You Need

Fill this out as you go:

```
Android Package Name: com.example.an_life_tracker
iOS Bundle ID: com.example.anLifeTracker

Android SHA-1: ___________________________________

Web Client ID: ___________________________________
Web Client Secret: ________________________________

iOS Client ID: ____________________________________
iOS Client ID (Reversed): _________________________
```

---

## 🎯 That's It!

Your app now has Google Sign-In! 🎉

For detailed troubleshooting, see `GOOGLE_AUTH_SETUP.md`
