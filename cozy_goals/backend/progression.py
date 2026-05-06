"""XP and level progression logic for Cozy Goals.

This module is intentionally pure: it receives dictionaries and returns dictionaries.
Flutter owns persistence; Python owns rules.
"""
from __future__ import annotations

from typing import Any, Dict, List

from rewards import rewards_for_level


def threshold_for_level(level: int) -> int:
    """Cumulative XP needed to be at the given level.

    Level 1 starts at 0 conceptually, but we keep level^2 * 100 as the base used
    by the Flutter XP bar for a simple predictable curve.
    """
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
