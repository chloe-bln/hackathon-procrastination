# Setup Guide — Linux

## 1. Install system dependencies

Typical Ubuntu/Debian packages:

```bash
sudo apt update
sudo apt install -y curl git unzip xz-utils zip clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev python3 python3-pip sqlite3
```

## 2. Install Flutter

Use the official Flutter Linux installation path, then check the desktop target:

```bash
flutter doctor
flutter config --enable-linux-desktop
flutter devices
```

## 3. Install project dependencies

```bash
cd cozy_goals
flutter pub get
```

## 4. Run

```bash
flutter run -d linux
```

## 5. Python check

```bash
python3 backend/cli.py progression <<'JSON'
{"current_xp":0,"current_level":1,"xp_gain":25}
JSON
```

Expected output resembles:

```json
{"xp":25,"level":1,"level_up":false,"rewards":[],"next_level_threshold":400}
```

## 6. Packaging note

During development, Flutter runs from the project root, so `backend/cli.py` is found automatically.

For a release bundle, copy the `backend/` folder next to the executable or adapt `PythonEngine._resolveCliPath()` to your packaging layout.
