# Firebase privacy website

Project/site: `frame-octopus`. Public site: https://frame-octopus.web.app

The site contains static HTML and CSS only. It has no Firebase JavaScript SDK, analytics, forms, cookies added by the site, or media uploads. Firebase Hosting's technical request processing is disclosed in the policy. Its public directory is **hosting/public**; app source, APKs, Firebase client configuration and local credentials are not deployed.

## Published pages

- English (default): https://frame-octopus.web.app/privacy
- Korean: https://frame-octopus.web.app/ko/privacy
- Japanese: https://frame-octopus.web.app/ja/privacy
- `/` also serves the English policy. Firebase `cleanUrls` handles `.html` URLs.

## Update and deploy

Edit the three language versions in `tool/build_privacy_site.py`, then run:

```powershell
python tool/build_privacy_site.py
firebase deploy --only hosting --project frame-octopus
```

The generator also updates the English source at `docs/PRIVACY.md`. Styling is in `hosting/public/style.css`. `firebase.json` sets a restrictive Content Security Policy, nosniff, no-referrer and a five-minute cache lifetime. Do not deploy unrelated project files into the public directory.

## Android project connection

- Package: `ink.frameoctopus.frame_octopus`
- Firebase app: `1:18444933139:android:03c4c58207011ebdd207e6`
- Flutter configuration: `lib/firebase_options.dart`
- Android configuration: `android/app/google-services.json`
- Android startup initializes Firebase Core. The app manifest disables default automatic data collection. Analytics, Crashlytics, Authentication, Firestore and Storage plugins were not added.
- Windows does not initialize Firebase; the shared Flutter dependency's Windows compilation was checked.

These generated client configuration files contain public app identifiers/configuration, not a service-account credential or signing key. No admin credential, login token or signing material belongs in this repository or Hosting directory.

The mobile Advanced panel opens the policy in the selected app language. Firebase SDK setup follows the [official Flutter setup](https://firebase.google.com/docs/flutter/setup); Hosting processing disclosures follow [Firebase privacy information](https://firebase.google.com/support/privacy).

## Evidence

Published on 2026-11-22. Three language routes returned HTTP 200 with CSP headers, and language navigation was verified in Chrome. See `docs/firebase/hosting-verification.json` and `docs/firebase/privacy-hosted-ko.jpg`. Earlier Microsoft Store draft/Gist settings were not changed by this deployment.
