# AN Life Tracker - Mobile App Build Guide

## ✅ COMPATIBILITY

### Android
- **Minimum**: Android 5.0 (API 21) - Released 2014
- **Target**: Android 14 (API 34)
- **✅ Supports Android 13**: YES
- **Runs on**: Android 5.0 through Android 14+

### iOS
- **Minimum**: iOS 12.0
- **Target**: iOS 17.0
- **✅ Supports iOS 18**: YES
- **Runs on**: iPhone 6s and newer, all iPads from 2015+

---

## 🛡️ SECURITY FEATURES (Prevents "Harmful App" Warnings)

### Android Security:
✅ **HTTPS Only** - All network traffic encrypted
✅ **Network Security Config** - Proper certificate validation
✅ **No Cleartext Traffic** - Blocks unencrypted connections
✅ **Secure Storage** - Flutter Secure Storage for sensitive data
✅ **Backup Protection** - Excludes sensitive files from backups
✅ **Proper Permissions** - Only necessary permissions requested
✅ **Official Package Name** - com.anlifetracker.app

### iOS Security:
✅ **App Transport Security** - Enforced HTTPS
✅ **Permission Descriptions** - Clear explanations for all permissions
✅ **Secure Storage** - Keychain integration
✅ **No suspicious permissions** - Standard productivity app permissions

---

## 📱 BUILD INSTRUCTIONS

### For Android (APK)

1. **Clean Build**:
```bash
flutter clean
flutter pub get
```

2. **Build Release APK**:
```bash
flutter build apk --release
```

3. **Find Your APK**:
Location: `build/app/outputs/flutter-apk/app-release.apk`

4. **Install on Android Device**:
- Transfer APK to phone
- Enable "Install from Unknown Sources" in Settings
- Open APK file to install

### For Android (App Bundle - Google Play)

```bash
flutter build appbundle --release
```
Location: `build/app/outputs/bundle/release/app-release.aab`

### For iOS (iPhone/iPad)

**Requirements**:
- Mac computer with Xcode 15+
- Apple Developer Account ($99/year)
- Physical iOS device or Simulator

1. **Open in Xcode**:
```bash
cd ios
open Runner.xcworkspace
```

2. **Configure Signing**:
- In Xcode, select "Runner" project
- Go to "Signing & Capabilities"
- Select your Team
- Change Bundle Identifier to unique name

3. **Build**:
```bash
flutter build ios --release
```

4. **Run on Device**:
- Connect iPhone via USB
- Trust computer on iPhone
- In Xcode: Product → Run

---

## 🔐 PERMISSIONS EXPLAINED (Why Not Harmful)

### Android Permissions:
| Permission | Why Needed | Safe? |
|------------|------------|-------|
| INTERNET | Sync data with cloud | ✅ Standard |
| POST_NOTIFICATIONS | Reminders & alerts | ✅ Standard |
| CAMERA | Profile photo | ✅ Standard |
| READ/WRITE_STORAGE | Save photos | ✅ Standard (Android <10) |
| SCHEDULE_EXACT_ALARM | Focus session timers | ✅ Standard |

### iOS Permissions:
| Permission | Why Needed |
|------------|------------|
| Camera | Take profile photos |
| Photo Library | Choose profile photos |
| Notifications | Study reminders |

**All permissions are standard for productivity apps. Nothing suspicious!**

---

## 🏪 PUBLISHING TO STORES

### Google Play Store (Android)

1. **Create Developer Account**: $25 one-time fee
2. **Generate Signing Key**:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

3. **Configure Signing** (android/key.properties):
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

4. **Build Signed Bundle**:
```bash
flutter build appbundle --release
```

5. **Upload to Play Console**:
- Create app listing
- Add screenshots (phone, tablet)
- Set content rating
- Upload AAB file
- Submit for review

**Review Time**: 1-3 days

### Apple App Store (iOS)

1. **Join Apple Developer Program**: $99/year
2. **Create App ID** in App Store Connect
3. **Configure in Xcode**:
   - Set Team & Bundle ID
   - Configure capabilities
4. **Archive**: Product → Archive in Xcode
5. **Upload**: Window → Organizer → Distribute
6. **Submit for Review** in App Store Connect

**Review Time**: 1-2 days

---

## ⚠️ GOOGLE PLAY PROTECT / iOS APP REVIEW TIPS

### To Avoid "Harmful App" Warnings:

#### Android:
✅ **Use Official Build** - Always build with `flutter build apk --release`
✅ **No Debug Keys** - Never distribute debug builds
✅ **Clear Permissions** - All permissions have clear justifications
✅ **Privacy Policy** - Required if collecting user data
✅ **Target Latest SDK** - We target SDK 34 (Android 14)
✅ **Secure Network** - HTTPS only, no cleartext traffic

#### iOS:
✅ **Valid Signing** - Proper provisioning profile
✅ **Permission Descriptions** - Already added in Info.plist
✅ **No Private APIs** - Only public Flutter/iOS APIs used
✅ **Privacy Manifest** - Declare data usage
✅ **No Crashes** - Test thoroughly before submission

---

## 🧪 TESTING BEFORE RELEASE

### Android Testing:
```bash
# Install on device
flutter install --release

# Test on different Android versions
# Use Android Virtual Device Manager in Android Studio
```

### iOS Testing:
```bash
# Install on physical device
flutter run --release

# Test on Simulator
open -a Simulator
flutter run
```

### Test Checklist:
- [ ] Login/Logout works
- [ ] All permissions requested with explanations
- [ ] Camera/Photos work
- [ ] Notifications arrive
- [ ] App doesn't crash
- [ ] Offline mode works
- [ ] Data syncs properly

---

## 📊 APP STATISTICS

- **App Size (Android)**: ~30-50 MB
- **App Size (iOS)**: ~40-60 MB
- **Min RAM**: 2 GB
- **Storage**: 100 MB recommended
- **Internet**: Required for sync (works offline)

---

## 🚀 DISTRIBUTION OPTIONS

### 1. **Direct APK** (Android Only)
- Build APK and share via link/email
- Users must enable "Unknown Sources"
- ⚠️ May show Play Protect warning (expected for sideloaded apps)
- ✅ Free, instant distribution

### 2. **Google Play Store** (Recommended)
- No "Unknown Sources" needed
- Automatic updates
- Trusted by users
- No Play Protect warnings
- $25 one-time fee

### 3. **Apple App Store** (iOS Required)
- Only way to distribute iOS apps
- Automatic updates
- Trusted by users
- $99/year

### 4. **Enterprise Distribution**
- For companies only
- Internal app distribution
- No store approval needed

---

## ❓ COMMON ISSUES

### "App Not Installed" (Android)
**Fix**: Uninstall old version first, then install new one

### "Untrusted Developer" (iOS)
**Fix**: Settings → General → VPN & Device Management → Trust Developer

### "Harmful App" Warning (Android)
**Fix**: This is normal for sideloaded APKs. Reasons:
1. App not from Play Store
2. Debug signature instead of release
3. First install (no reputation yet)

**Solution**: Upload to Play Store OR tell users to ignore warning (our app is safe!)

### Play Protect Blocks Installation
**Fix**: Tap "More Details" → "Install Anyway"
This only happens for sideloaded APKs, not Play Store versions.

---

## 📝 REQUIREMENTS SUMMARY

### To Build:
- Flutter SDK 3.0+
- Android Studio (for Android)
- Xcode 15+ & Mac (for iOS)
- Valid development certificates

### To Publish Play Store:
- Google Play Developer Account ($25)
- Privacy Policy URL
- App screenshots & icon
- Signed release build

### To Publish App Store:
- Apple Developer Account ($99/year)
- Mac with Xcode
- App Store Connect access
- iOS device for testing

---

## ✅ YOUR APP IS SAFE!

Your app is **NOT harmful**. It uses:
- Standard Flutter framework
- Official packages only
- Proper security configs
- HTTPS encryption
- Secure storage
- Normal permissions

The app is as safe as any other productivity app on the stores!

---

## 🎯 QUICK START (5 Minutes to APK)

```bash
# 1. Clean everything
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build release APK
flutter build apk --release

# 4. Find APK at:
# build/app/outputs/flutter-apk/app-release.apk

# 5. Transfer to phone and install!
```

**Done!** Your app is ready to use on Android 5.0 - Android 14+ (including Android 13) 🎉
