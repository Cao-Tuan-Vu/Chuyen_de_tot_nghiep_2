# Week 1 - Firebase setup

## Current project

- Project ID: `news-app-6ef88`
- Realtime Database URL: `https://news-app-6ef88-default-rtdb.asia-southeast1.firebasedatabase.app`
- Region: `asia-southeast1`
- Plan: Spark

## Setup checklist

1. Firebase Authentication
   - Enable Email/Password sign-in.
2. Realtime Database
   - Import `database.rules.json` from project root.
3. Flutter app registration
   - Add Android/iOS app in Firebase console.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
4. FlutterFire
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`.
5. Analytics + Crashlytics
   - Enable both in Firebase console.

## Notes

- Khong commit service account JSON vao git.
- Dung env variable cho backend secret va Firebase admin credentials.

