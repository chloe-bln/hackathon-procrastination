# Python Integration

## Why CLI instead of FFI?

`dart:ffi` calling CPython is possible but brittle for a desktop app because it requires shipping and linking the correct Python runtime. A CLI bridge is simpler, auditable and local-only.

## Command pattern

Flutter uses `Process.start()` rather than `Process.run()` because the app writes a JSON payload to the Python process through `stdin`.

```dart
final process = await Process.start('python3', ['backend/cli.py', 'progression']);
process.stdin.write(jsonEncode({'current_xp': 0, 'current_level': 1, 'xp_gain': 25}));
await process.stdin.close();

final stdoutText = await utf8.decoder.bind(process.stdout).join();
final result = jsonDecode(stdoutText) as Map<String, dynamic>;
```

Shell equivalent:

```bash
echo '{"current_xp":0,"current_level":1,"xp_gain":25}' | python3 backend/cli.py progression
```

## Commands

### progression

Applies XP, calculates level progression and returns level-up rewards.

### goal_reward

Called after a goal is completed. Once the daily minimum is reached, each validated goal grants one reward.

Input:

```json
{
  "completed_count": 3,
  "minimum_goals": 3,
  "unlocked_ids": ["hair_bun_mint", "clothes_cardigan_lavender"]
}
```

Output:

```json
{
  "reward": {"id": "hair_leaf_sage", "type": "hair", "label": "Sage leaf hair"}
}
```

If all cosmetics are already unlocked, the command returns a consumable `streak_freeze`.

### secure_streak

Used when today's completed goal count reaches the daily minimum.

### daily_reset

Used on startup to validate past days.

### all_rewards

Returns the reward catalog. The current Developer Mode uses a mirrored Dart catalog for simple synchronous UI rendering.

## App blocking

The current app intentionally simulates blocking. This is the safer default for a demo/local-first app because real blocking can require elevated privileges, can interfere with user control, and is distribution-specific.

Possible Linux integrations:

1. **Process guard**: periodic local check with `pgrep` and a user-approved `pkill` list. Simple but blunt.
2. **Desktop launcher wrapper**: replace selected `.desktop` launch commands with a wrapper script that checks Cozy Goals state before opening the app.
3. **Network/domain blocking**: for web distractions, update `/etc/hosts` or firewall rules. This requires root and clear rollback logic.
4. **Flatpak sandbox policy**: possible for apps installed via Flatpak, but depends on packaging and permissions.

Recommended production path: use a launcher wrapper, never silently modify system files, and always provide a visible emergency unblock option.
