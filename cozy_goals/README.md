# Cozy Goals

A cute, relaxing, local-first productivity app designed to fight procrastination.

- Flutter Linux desktop frontend
- Riverpod state management
- SQLite local persistence
- Python local logic engine via CLI, no server
- Pastel UI with goals, streaks, XP, rewards and avatar customization
- Real local blocking options: process guard for apps, `/etc/hosts` rules for websites
- Focus timer per goal with pause/resume and tracked focus time
- Developer Mode for testing rewards, levels, simulated date progression and full reset

## Run locally

```bash
cd cozy_goals
flutter pub get
flutter run -d linux
```

Python 3 must be available as `python3`, because Flutter calls `backend/cli.py` through `Process.start` and exchanges JSON through stdin/stdout.

For website blocking, Linux also needs `pkexec` available, usually via `policykit-1` / Polkit packages.

## Main folders

```text
lib/
  presentation/    UI screens, widgets, Riverpod controller
  domain/          App models
  data/            SQLite, notifications, Python bridge
backend/           Python progression/streak/reward/reset/blocking logic
docs/              Architecture and setup documentation
```

## Core rules

A day is protected when the user completes at least 3 goals. The app increments the streak immediately when the third goal is completed, then avoids double-counting during the next daily validation.

Goal completion requires a focus timer:

1. Add a goal and choose a focus duration.
2. Start the timer.
3. Pause/resume if needed.
4. Halfway through the duration, the validate button appears.
5. The timer keeps running until the user validates.
6. The active, unpaused time is stored on the goal.
7. From the third completed goal onward, every validated goal grants a reward.

End-of-day focus bonus:

```text
30 min tracked focus = 15 XP
```

The app calculates this as 1 XP per 2 minutes of tracked focus time, rounded down.

## Avatar

The avatar is still drawn in Flutter widgets, not loaded from image files. Hair and clothes are unlockable cosmetics. Skin color is now a free option available from the start.

## Blocking

Apps are blocked while Cozy Goals is running by a local process guard that checks every 5 seconds and closes matching processes with `pgrep` / `pkill`.

Websites are blocked by writing a Cozy Goals section in `/etc/hosts`, using `pkexec` to request administrator approval. This is local and reversible from the Blocking screen.

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
- reset the whole local app

The time simulation uses a local `dayOffsetDays` value in SQLite. It does not modify the operating system clock.
