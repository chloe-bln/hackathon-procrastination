# Architecture

## Goal

Cozy Goals is local-first: the user owns the data, there is no account system, no remote backend and no server process.

## Layers

```text
presentation/
  screens/        Flutter pages
  widgets/        reusable UI components
  providers/      Riverpod controller and state
  theme/          pastel design system

domain/
  models/         pure Dart data models

data/
  local/          SQLite persistence
  python/         CLI bridge to Python
  notifications/ local notifications wrapper

backend/
  progression.py  XP and level progression
  streak.py       streak validation and freeze logic
  rewards.py      cosmetic and item unlocks
  daily_reset.py  past-day validation
  cli.py          JSON stdin/stdout bridge
```

## Flutter ↔ Python interaction

Flutter owns UI and persistence. Python owns deterministic game rules.

1. Flutter reads current local state from SQLite.
2. Flutter calls `python3 backend/cli.py <command>` with JSON through stdin.
3. Python returns JSON through stdout.
4. Flutter persists the returned state changes.

This avoids a local HTTP server, open ports, background daemons and network dependencies.

## Daily reset

There is no permanent daemon. On app startup, the Riverpod controller checks whether `lastValidatedDate` is older than today. It validates each missing day using Python. This is robust enough for an offline desktop app and avoids platform-specific midnight services.

## Streak behavior

- Completing 3 goals today immediately protects the streak.
- If the user opens the app the next day, the previous day is validated but not double-counted.
- If a past day failed and the user owns a streak freeze, one freeze is consumed.
- If no freeze is available, the streak resets to zero.
