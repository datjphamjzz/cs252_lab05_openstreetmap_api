# Firebase Setup Instructions

Your Flutter app now has Firebase Authentication integrated! Follow these steps to complete the setup:

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter your project name
4. Follow the setup wizard

## 2. Enable Email/Password Authentication

1. In your Firebase project, go to **Authentication**
2. Click on **Get Started**
3. Go to **Sign-in method** tab
4. Click on **Email/Password**
5. Enable it and click **Save**

## 3. Configure Firebase for Your Flutter App

You need to configure Firebase for each platform you want to support.

### Option A: Using FlutterFire CLI (Recommended)

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Login to Firebase:
   ```bash
   firebase login
   ```

4. Configure your Flutter app:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Select the platforms you want to support (Android, iOS, Web, etc.)

This will automatically create `firebase_options.dart` with your configuration.

5. Update `main.dart` to use the generated options:
   ```dart
   import 'firebase_options.dart';
   
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### Option B: Manual Configuration

#### For Android:
1. In Firebase Console, add an Android app
2. Enter your package name (found in `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in `android/app/`
5. Add to `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```
6. Add to `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

#### For iOS:
1. In Firebase Console, add an iOS app
2. Enter your bundle ID (found in `ios/Runner.xcodeproj/project.pbxproj`)
3. Download `GoogleService-Info.plist`
4. Add it to `ios/Runner/` using Xcode

#### For Web:
1. In Firebase Console, add a Web app
2. Copy the Firebase configuration
3. Add it to `web/index.html` before the closing `</body>` tag

## 4. Test Your App

1. Run your app:
   ```bash
   flutter run
   ```

2. Try to sign up with a new email and password
3. Check Firebase Console > Authentication > Users to see registered users

## Features Implemented

- **Sign Up**: Create new accounts with email/password
- **Sign In**: Login with existing credentials
- **Sign Out**: Logout functionality with a button in the map screen
- **Authentication State**: Automatically shows login screen when logged out
- **Error Handling**: User-friendly error messages for common auth issues
- **Form Validation**: Email and password validation

## Security Notes

- Passwords must be at least 6 characters
- Email validation is performed
- Authentication state is managed automatically
- User sessions persist across app restarts

## Troubleshooting

If you encounter issues:
1. Make sure Firebase project is created
2. Verify Email/Password authentication is enabled
3. Check that configuration files are properly placed
4. Run `flutter clean` and `flutter pub get`
5. Check Firebase Console for any error messages
