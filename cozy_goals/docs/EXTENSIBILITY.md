# Extensibility

## Add rewards

Edit `backend/rewards.py`:

```python
HAIR_REWARDS.append({"id": "hair_cloud_blue", "type": "hair", "label": "Cloud blue hair"})
```

Then update `AvatarPreview` in Flutter so the new ID maps to a visual layer.

## Add avatar layers

Current layers:

- background circle
- clothes
- face/base
- hair
- flower accessory

To add accessories:

1. Add `type: "accessory"` rewards.
2. Add `avatarAccessory` to `CozyAppState` and SQLite schema.
3. Add a third picker in `AvatarScreen`.
4. Add a `Positioned` layer in `AvatarPreview`.

## Expand goal logic

Ideas:

- difficulty levels: small / medium / deep work
- recurring goals
- anti-procrastination timers
- weekly review
- soft deadlines

Keep rule calculation in Python and persistence in Flutter.

## Improve notifications

The provided wrapper displays local notifications. For a production build, add scheduling rules or a lightweight in-app daily reminder check when the app opens/resumes.
