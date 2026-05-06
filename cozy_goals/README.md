# Cozy Goals

A cute, relaxing, local-first productivity app designed to fight procrastination.

- Flutter Linux desktop frontend
- Riverpod state management
- SQLite local persistence
- Python local logic engine via CLI, no server
- Pastel UI with goals, streaks, XP, rewards, avatar customization and simulated app blocking

## Run locally

```bash
cd cozy_goals
flutter pub get
flutter run -d linux
```

Python 3 must be available as `python3`, because Flutter calls `backend/cli.py` through `Process.run`.

## Main folders

```text
lib/
  presentation/    UI screens, widgets, Riverpod controller
  domain/          App models
  data/            SQLite, notifications, Python bridge
backend/           Python progression/streak/reward/reset logic
docs/              Architecture and setup documentation
```

## Core rule

A day is protected when the user completes at least 3 goals. The app increments the streak immediately when the third goal is completed, then avoids double-counting during the next daily validation.
