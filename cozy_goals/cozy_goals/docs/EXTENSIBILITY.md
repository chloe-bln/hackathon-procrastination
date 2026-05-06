# Extensibility

## Add rewards

Edit `backend/rewards.py`:

```python
HAIR_REWARDS.append({"id": "hair_cloud_blue", "type": "hair", "label": "Cloud blue hair"})
```

Then update `AvatarPreview` in Flutter so the new ID maps to a visual layer.

## Add skin colors

Skin colors are free, not rewards. Add them in two places:

1. `AvatarScreen.skinOptions`
2. `AvatarPreview` skin color switch

If the default changes, also update `CozyAppState.avatarSkin` and the SQLite default.

## Add avatar layers

Current layers:

- background circle
- clothes
- face/base with selectable skin color
- hair
- flower accessory

To add accessories:

1. Add `type: "accessory"` rewards.
2. Add `avatarAccessory` to `CozyAppState` and SQLite schema.
3. Add a picker in `AvatarScreen`.
4. Add a `Positioned` layer in `AvatarPreview`.

## Expand goal logic

Ideas:

- difficulty levels: small / medium / deep work
- recurring goals
- anti-procrastination timers
- weekly review
- soft deadlines
- time-based achievements

Keep rule calculation in Python and persistence in Flutter.

## Extend blocking

Current app blocking is process-based and active only while the app runs.

Better future options:

1. `.desktop` launcher wrappers for selected apps.
2. A user-installed systemd user service to run the process guard continuously.
3. Browser extension integration for per-site timed unlocking.
4. Firewall/DNS-level blocking with explicit admin setup.

Avoid silent OS modifications. Always preserve an emergency unblock path.

## Improve notifications

The provided wrapper displays local notifications. For a production build, add scheduling rules or a lightweight in-app daily reminder check when the app opens/resumes.
