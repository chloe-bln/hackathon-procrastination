# Cozy Goals

A cute, relaxing, local-first productivity app designed to fight procrastination.

- Flutter Linux desktop frontend
- Riverpod state management
- SQLite local persistence
- Python local logic engine via CLI, no server
- Pastel UI with goals, streaks, XP, rewards, avatar customization and simulated app blocking
- Focus timer per goal: the validate button appears halfway through the selected duration
- Developer Mode for testing rewards, levels and simulated date progression

## Run locally

```bash
cd cozy_goals
flutter pub get
flutter run -d linux
```

Python 3 must be available as `python3`, because Flutter calls `backend/cli.py` through `Process.start` and exchanges JSON through stdin/stdout.

## Main folders

```text
lib/
  presentation/    UI screens, widgets, Riverpod controller
  domain/          App models
  data/            SQLite, notifications, Python bridge
backend/           Python progression/streak/reward/reset logic
docs/              Architecture and setup documentation
```

## Core rules

A day is protected when the user completes at least 3 goals. The app increments the streak immediately when the third goal is completed, then avoids double-counting during the next daily validation.

Goal completion now requires a focus timer:

1. Add a goal and choose a focus duration.
2. Start the timer.
3. Halfway through the duration, the validate button appears.
4. The timer keeps running until the user validates.
5. From the third completed goal onward, every validated goal grants a reward.

## Developer Mode

Settings → Developer mode.

Password:

```text
zuoegfbozeiugbfzoiehgfahzefgo
```

Developer Mode can:

- manually add cosmetics and streak freeze rewards
- increase level
- add XP
- advance simulated time by 1 or 7 days
- reset simulated time

The time simulation uses a local `dayOffsetDays` value in SQLite. It does not modify the operating system clock.
