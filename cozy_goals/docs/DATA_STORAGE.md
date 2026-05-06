# Data Storage

## Database

The app uses SQLite through `sqflite_common_ffi` for Linux desktop.

Default path:

```text
<application documents directory>/cozy_goals/cozy_goals.sqlite
```

## Tables

### profile

```text
id INTEGER PRIMARY KEY CHECK(id = 1)
username TEXT
birthDate TEXT ISO-8601
```

### app_state

```text
id INTEGER PRIMARY KEY CHECK(id = 1)
currentStreak INTEGER
longestStreak INTEGER
xp INTEGER
level INTEGER
freezeCount INTEGER
lastValidatedDate TEXT yyyy-MM-dd
lastStreakAwardedDate TEXT yyyy-MM-dd nullable
avatarHair TEXT
avatarClothes TEXT
avatarSkin TEXT
avatarSkin defaults to skin_peach
 dayOffsetDays INTEGER DEFAULT 0
```

`dayOffsetDays` is used only by Developer Mode. It simulates time locally without touching the Linux system clock.

### goals

```text
id TEXT PRIMARY KEY
title TEXT
description TEXT nullable
goalDate TEXT yyyy-MM-dd
durationMinutes INTEGER DEFAULT 25
focusSeconds INTEGER DEFAULT 0
isCompleted INTEGER 0/1
completedAt TEXT ISO-8601 nullable
```

`focusSeconds` stores active timer time only. Paused time is not counted.

A goal is completed only after the focus timer has been launched and the user validates it. The validate button appears halfway through `durationMinutes`.

### daily_time_bonus

```text
day TEXT PRIMARY KEY
xpAwarded INTEGER
awardedAt TEXT ISO-8601
```

This prevents the end-of-day time bonus from being paid twice.

Rule:

```text
30 min focus = 15 XP
1 XP every 2 minutes, rounded down
```

### inventory

```text
id TEXT PRIMARY KEY
type TEXT hair|clothes|freeze
label TEXT
isUnlocked INTEGER 0/1
```

Cosmetics are stored in `inventory`. Streak freeze items are consumables and are stored as `freezeCount` in `app_state`.

Skin colors are not stored in inventory because they are all available from the start. The selected skin is stored in `app_state.avatarSkin`.

### blocked_apps

```text
id TEXT PRIMARY KEY
name TEXT
command TEXT legacy compatibility alias
type/kind TEXT app|site
target TEXT process pattern or domain
unlockedUntil TEXT ISO-8601 nullable
```

The Dart model uses `kind` and `target`. The `command` column is kept to migrate older save files.

## Migration

Database version 4 includes:

- `goals.durationMinutes`
- `goals.focusSeconds`
- `app_state.dayOffsetDays`
- `app_state.avatarSkin`
- `blocked_apps.kind`
- `blocked_apps.target`
- `daily_time_bonus`

Older save files are migrated automatically with default values.

## Full reset

Developer Mode → Full app reset deletes the local SQLite file and sends a request to clear the Cozy Goals section in `/etc/hosts`.

## JSON save-file equivalent

A JSON export shape is provided in `docs/example_save.json`. The live implementation uses SQLite because it scales better as goals, rewards and blocking rules grow.
