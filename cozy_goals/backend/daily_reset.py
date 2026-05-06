"""Daily reset entry point.

The actual midnight trigger is Flutter app startup/resume. This avoids a daemon,
keeps the app offline and preserves local-first behavior.
"""
from __future__ import annotations

from typing import Any, Dict

from streak import validate_day


def run(payload: Dict[str, Any]) -> Dict[str, Any]:
    return validate_day(
        date=str(payload["date"]),
        completed_count=int(payload.get("completed_count", 0)),
        minimum_goals=int(payload.get("minimum_goals", 3)),
        current_streak=int(payload.get("current_streak", 0)),
        longest_streak=int(payload.get("longest_streak", 0)),
        freeze_count=int(payload.get("freeze_count", 0)),
        last_streak_awarded_date=payload.get("last_streak_awarded_date"),
    )
