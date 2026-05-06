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

### time_xp

Calculates the end-of-day focus-time XP bonus.

Input:

```json
{"focus_seconds": 1800}
```

Output:

```json
{"focus_seconds": 1800, "focus_minutes": 30, "xp_gain": 15}
```

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

Used on startup or simulated time jump to validate past days.

### all_rewards

Returns the reward catalog. The current Developer Mode uses a mirrored Dart catalog for simple synchronous UI rendering.

### enforce_apps

Receives locked app entries and closes matching Linux processes.

The implementation uses:

```bash
pgrep -f <target>
pkill -f <target>
```

This works while Cozy Goals is running. It is intentionally blunt: the user should enter process patterns carefully, for example `firefox`, `steam`, `discord`.

### apply_site_blocks

Receives locked website entries and writes a marked section in `/etc/hosts`.

If the Python process is not root, it launches:

```bash
pkexec python3 backend/cli.py apply_site_blocks_root <payload.json>
```

Linux will request administrator approval. The written section is clearly delimited:

```text
# COZY_GOALS_BLOCK_START
0.0.0.0 youtube.com
::1 youtube.com
# COZY_GOALS_BLOCK_END
```

### clear_site_blocks

Removes only the Cozy Goals marked section from `/etc/hosts`.

## Blocking limits

- App blocking works only while Cozy Goals is running.
- Website blocking requires administrator approval.
- Browser DNS-over-HTTPS can bypass `/etc/hosts`; disable it in the browser if needed.
- The app does not modify firewall rules.
