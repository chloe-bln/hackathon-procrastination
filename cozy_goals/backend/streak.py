"""Streak validation rules."""
from __future__ import annotations

from typing import Any, Dict, Optional


def secure_streak(
    *,
    date: str,
    completed_count: int,
    minimum_goals: int,
    current_streak: int,
    longest_streak: int,
    last_streak_awarded_date: Optional[str],
) -> Dict[str, Any]:
    if completed_count < minimum_goals:
        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "last_streak_awarded_date": last_streak_awarded_date,
            "message": None,
        }

    if last_streak_awarded_date == date:
        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "last_streak_awarded_date": last_streak_awarded_date,
            "message": "Daily streak already protected 🌿",
        }

    new_streak = current_streak + 1
    return {
        "current_streak": new_streak,
        "longest_streak": max(longest_streak, new_streak),
        "last_streak_awarded_date": date,
        "message": "Streak protected. The day is safe 🔥",
    }


def validate_day(
    *,
    date: str,
    completed_count: int,
    minimum_goals: int,
    current_streak: int,
    longest_streak: int,
    freeze_count: int,
    last_streak_awarded_date: Optional[str],
) -> Dict[str, Any]:
    """Validate a past day during app startup.

    If the day was already awarded in-app when the user reached 3 goals, do not
    increment twice. If the day failed, consume a freeze before resetting.
    """
    if completed_count >= minimum_goals:
        secured = secure_streak(
            date=date,
            completed_count=completed_count,
            minimum_goals=minimum_goals,
            current_streak=current_streak,
            longest_streak=longest_streak,
            last_streak_awarded_date=last_streak_awarded_date,
        )
        return {
            **secured,
            "freeze_count": freeze_count,
            "used_freeze": False,
            "reset": False,
        }

    if last_streak_awarded_date == date:
        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "freeze_count": freeze_count,
            "last_streak_awarded_date": last_streak_awarded_date,
            "used_freeze": False,
            "reset": False,
            "message": "Day was already protected.",
        }

    if freeze_count > 0:
        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "freeze_count": freeze_count - 1,
            "last_streak_awarded_date": last_streak_awarded_date,
            "used_freeze": True,
            "reset": False,
            "message": "A streak freeze protected the day ❄️",
        }

    return {
        "current_streak": 0,
        "longest_streak": longest_streak,
        "freeze_count": 0,
        "last_streak_awarded_date": last_streak_awarded_date,
        "used_freeze": False,
        "reset": True,
        "message": "Streak reset. Restart gently today.",
    }
