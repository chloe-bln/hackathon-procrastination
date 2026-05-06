"""XP and level progression logic for Cozy Goals.

This module is intentionally pure: it receives dictionaries and returns dictionaries.
Flutter owns persistence; Python owns rules.
"""
from __future__ import annotations

from typing import Any, Dict, List

from rewards import rewards_for_level


def threshold_for_level(level: int) -> int:
    """Cumulative XP needed to be at the given level."""
    if level <= 1:
        return 0
    return level * level * 100


def level_from_xp(xp: int) -> int:
    level = 1
    while xp >= threshold_for_level(level + 1):
        level += 1
    return level


def apply_xp(current_xp: int, current_level: int, xp_gain: int) -> Dict[str, Any]:
    new_xp = max(0, current_xp + xp_gain)
    new_level = max(current_level, level_from_xp(new_xp))
    level_up = new_level > current_level

    rewards: List[Dict[str, str]] = []
    if level_up:
        for level in range(current_level + 1, new_level + 1):
            rewards.extend(rewards_for_level(level))

    return {
        "xp": new_xp,
        "level": new_level,
        "level_up": level_up,
        "rewards": rewards,
        "next_level_threshold": threshold_for_level(new_level + 1),
    }


def time_xp_for_seconds(focus_seconds: int) -> Dict[str, int]:
    """Return the end-of-day time bonus.

    Rule: 30 minutes of actual unpaused focus time = 15 XP.
    That is 1 XP every 2 minutes, rounded down to keep the system predictable.
    """
    safe_seconds = max(0, int(focus_seconds))
    return {
        "focus_seconds": safe_seconds,
        "focus_minutes": safe_seconds // 60,
        "xp_gain": safe_seconds // 120,
    }
