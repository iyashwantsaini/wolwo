# Releasing wolwo

This is a step-by-step recipe for cutting a signed Android release.
The CI workflow at [`.github/workflows/release.yml`](../.github/workflows/release.yml)
does everything below for you on every tag push — these notes are mostly for
**setting up the signing secrets once** and for cutting **local** builds.

---

## 1. One-time: generate a release keystore

Do this **once** and keep the resulting `.jks` file safe — losing it means
you can never publish an upgrade-compatible APK ever again.

```bash
keytool -genkey -v \
  -keystore wolwo-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias wolwo
```

Pick a strong store password, key password, and alias. Write them down
(password manager, not a sticky note).

---

## 2. One-time: load the keystore into GitHub secrets

Encode the keystore as base64 so it can ride inside a GitHub secret:

```bash
# macOS / Linux
base64 -i wolwo-release.jks | pbcopy
# or
base64 -w0 wolwo-release.jks > wolwo-release.b64

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("wolwo-release.jks")) | Set-Clipboard
```

Then in **Settings → Secrets and variables → Actions → New repository secret**
on GitHub, add:

| Secret name                  | Value                                                         |
| ---------------------------- | ------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`    | The base64 string from above                                  |
| `ANDROID_KEYSTORE_PASSWORD`  | Store password you set in `keytool`                           |
| `ANDROID_KEY_ALIAS`          | Key alias (e.g. `wolwo`)                                      |
| `ANDROID_KEY_PASSWORD`       | Key password (often same as store password)                   |
| `WALLHAVEN_KEY` _(optional)_ | Wallhaven API key. Empty = anonymous (rate-limited, SFW only) |
| `PIXABAY_KEY` _(optional)_   | Pixabay API key. Empty = Pixabay source disabled at runtime   |
| `NASA_KEY` _(optional)_      | NASA api.nasa.gov key. Defaults to `DEMO_KEY`                 |
| `REDDIT_USER_AGENT`          | Custom UA string, e.g. `wolwo:v2.1 (by /u/your_handle)`       |

---

## 3. Local: produce a signed APK on your own machine

If you want to build a release APK locally (for testing on a real device,
or because you don't want to wait on CI), drop the keystore and a
`key.properties` file next to it:

```text
android/
├── app/
│   └── wolwo-release.jks         ← your keystore
└── key.properties                ← passwords (NEVER commit)
```

`android/key.properties` (gitignored already):

```properties
storeFile=app/wolwo-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=wolwo
keyPassword=YOUR_KEY_PASSWORD
```

Build:

```bash
flutter pub get
flutter build apk --release --split-per-abi \
  --dart-define-from-file=.env.dart-define
```

Output APKs land in `build/app/outputs/flutter-apk/`. The
`app-arm64-v8a-release.apk` is the one you want for any modern phone.

---

## 4. Cut a release

Pick the next semver bump, tag, push:

```bash
# 1. bump version in pubspec.yaml (the "+N" build number must increase too)
#    e.g.   version: 2.1.0+5
git commit -am "chore: release v2.1.0"
git tag v2.1.0
git push origin main --tags
```

The `release.yml` workflow will:

1. Pull dependencies, decode the keystore secret.
2. Build a **per-ABI split** APK set (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
3. Build a **universal** APK as a fallback for sideloaders.
4. Generate release notes from your commit history.
5. Create / update the GitHub Release with all four APKs attached.

You can also kick the workflow manually from the **Actions** tab; it will
use whatever version is in `pubspec.yaml`.

---

## 5. Post-release sanity check

- Download the `arm64-v8a` APK from the release page.
- Install on a real device — it should upgrade in place over the previous
  release (no "package conflicts" / signature-mismatch dialog).
- Open the about page (Settings → About) and confirm the version string
  matches the tag.

If the upgrade dialog complains about signature mismatch, the keystore
in CI doesn't match the one used for the previous release — restore the
correct keystore from your password vault and try again.
