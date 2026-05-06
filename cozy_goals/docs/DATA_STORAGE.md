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
```

### goals

```text
id TEXT PRIMARY KEY
title TEXT
description TEXT nullable
goalDate TEXT yyyy-MM-dd
isCompleted INTEGER 0/1
completedAt TEXT ISO-8601 nullable
```

### inventory

```text
id TEXT PRIMARY KEY
type TEXT hair|clothes|freeze
label TEXT
isUnlocked INTEGER 0/1
```

### blocked_apps

```text
id TEXT PRIMARY KEY
name TEXT
command TEXT
unlockedUntil TEXT ISO-8601 nullable
```

## JSON save-file equivalent

A JSON export shape is provided in `docs/example_save.json`. The live implementation uses SQLite because it scales better as goals, rewards and blocking rules grow.
