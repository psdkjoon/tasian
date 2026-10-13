# Tasian

A Catppuccin-themed calendar for Android, written in Flutter. The only third-party Dart package is pcal.

## Features

- Gregorian, Jalali, Deylami and Japanese calendars, with today shown in all four
- Month view for every calendar and a converter between them
- Choose a main calendar and the order of the others, used everywhere including the notification
- Events with or without a time, with optional reminder notifications
- Optional always-on, silent notification with today's date
- English, Persian, Russian and Japanese
- Light (Latte) and dark (Mocha) themes with a launcher icon that follows the theme

## Build

```
flutter pub get
flutter build apk --release --split-per-abi
```

For a signed Android release create `android/key.properties` with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`.

CI builds signed APKs with `./scripts/strip.sh` and checks them with `./scripts/verify-apk.sh`.
