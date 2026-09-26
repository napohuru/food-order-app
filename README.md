# Food Order App (Firebase version)

This repository contains a Flutter food ordering app (MVP) that can run on iOS and Android.

This branch adds Firebase integration for orders and basic anonymous authentication.

Important: You must configure a Firebase project and add platform-specific configuration files (GoogleService-Info.plist for iOS and google-services.json for Android) before the app can write/read data from Firestore.

Quick start (after you configure Firebase):

1. Install Flutter and the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Configure your Firebase project for this Flutter app (recommended):

```bash
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID>
```

This will generate `firebase_options.dart` and update native settings automatically.

3. Ensure anonymous auth and Cloud Firestore are enabled in your Firebase console.

4. Get dependencies and run the app:

```bash
flutter pub get
flutter run
```

If you don't use `flutterfire configure`, make sure you add the platform files manually:
- iOS: add `GoogleService-Info.plist` to `ios/Runner/` and register it in Xcode
- Android: add `google-services.json` to `android/app/`

Firestore layout used:
- collection: orders
  - document: auto id
    - customerName
    - phone
    - address
    - total
    - status
    - createdAt (timestamp)
    - items: array of maps {id, name, price, quantity}


Security note: This sample uses anonymous auth for demo only. For production, use proper authentication and Firestore security rules.
