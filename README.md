# MiniPlay Hub

MiniPlay Hub - Gen-Z hyper-casual multi-game platform built with Flutter.

## Overview

Miniplay Hub is a collection of fast, lightweight mini games in a single hub. The
app supports optional Google sign-in, cloud-backed progress, and ad-based
monetization.

## Key Features

- Multiple hyper-casual mini games in one app
- Optional Google sign-in
- Cloud sync via Firebase (Auth, Firestore, Storage)
- Ad monetization with Google AdMob
- Share flow for inviting friends

## Tech Stack

- Flutter / Dart
- Flame + Forge2D
- Firebase Auth, Firestore, Storage
- Riverpod
- Google Mobile Ads

## Getting Started

1. Install Flutter SDK (>= 3.10.0) and run `flutter doctor`.
2. Fetch packages: `flutter pub get`.
3. Run the app: `flutter run`.

### Firebase setup (optional)

If you enable Firebase:

- Add `google-services.json` for Android in `android/app/`.
- Add `GoogleService-Info.plist` for iOS in `ios/Runner/`.
- Run `flutterfire configure` if you use the FlutterFire CLI.

## Project Structure

- `lib/` application code
- `assets/` images, audio, animations
- `android/`, `ios/` platform projects

## Privacy Policy

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

Not specified.
