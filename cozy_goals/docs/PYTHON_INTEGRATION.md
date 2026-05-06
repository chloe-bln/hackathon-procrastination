# Python Integration

## Why CLI instead of FFI?

`dart:ffi` calling CPython is possible but brittle for a desktop app because it requires shipping and linking the correct Python runtime. A CLI bridge is simpler, auditable and local-only.

## Command pattern

Flutter:

```dart
final result = await Process.run(
  'python3',
  ['backend/cli.py', 'progression'],
  stdin: jsonEncode({'current_xp': 0, 'current_level': 1, 'xp_gain': 25}),
);
final json = jsonDecode(result.stdout as String);
```

Shell equivalent:

```bash
echo '{"current_xp":0,"current_level":1,"xp_gain":25}' | python3 backend/cli.py progression
```

## Commands

### progression

Input:

```json
{
  "current_xp": 375,
  "current_level": 1,
  "xp_gain": 25
}
```

Output:

```json
{
  "xp": 400,
  "level": 2,
  "level_up": true,
  "rewards": [
    {"id": "hair_bob_rose", "type": "hair", "label": "Rose bob"}
  ],
  "next_level_threshold": 900
}
```

### secure_streak

Used when today's completed goal count reaches the daily minimum.

### daily_reset

Used on startup to validate past days.

## App blocking

The current app intentionally simulates blocking. This is the safer default for a demo/local-first app because real blocking can require elevated privileges, can interfere with user control, and is distribution-specific.

Possible Linux integrations:

1. **Process guard**: periodic local check with `pgrep` and a user-approved `pkill` list. Simple but blunt.
2. **Desktop launcher wrapper**: replace selected `.desktop` launch commands with a wrapper script that checks Cozy Goals state before opening the app.
3. **Network/domain blocking**: for web distractions, update `/etc/hosts` or firewall rules. This requires root and clear rollback logic.
4. **Flatpak sandbox policy**: possible for apps installed via Flatpak, but depends on packaging and permissions.

Recommended production path: use a launcher wrapper, never silently modify system files, and always provide a visible emergency unblock option.
