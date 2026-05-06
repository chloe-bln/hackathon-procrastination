"""Reward generation for level-ups and threshold goal completions.

Reward IDs are stable. Flutter persists cosmetics in SQLite by ID.
"""
from __future__ import annotations

import random
from typing import Dict, Iterable, List, Optional

HAIR_REWARDS = [
    {"id": "hair_bob_rose", "type": "hair", "label": "Rose bob"},
    {"id": "hair_waves_lavender", "type": "hair", "label": "Lavender waves"},
    {"id": "hair_leaf_sage", "type": "hair", "label": "Sage leaf hair"},
]

CLOTHES_REWARDS = [
    {"id": "clothes_sweater_mint", "type": "clothes", "label": "Mint sweater"},
    {"id": "clothes_raincoat_blush", "type": "clothes", "label": "Blush raincoat"},
    {"id": "clothes_overalls_sage", "type": "clothes", "label": "Sage overalls"},
]

FREEZE_REWARD = {"id": "streak_freeze", "type": "freeze", "label": "Streak freeze"}

ALL_COSMETICS = [*HAIR_REWARDS, *CLOTHES_REWARDS]
ALL_REWARDS = [*ALL_COSMETICS, FREEZE_REWARD]


def rewards_for_level(level: int) -> List[Dict[str, str]]:
    rewards: List[Dict[str, str]] = []
    if level % 3 == 0:
        rewards.append(FREEZE_REWARD)
    if level % 2 == 0:
        rewards.append(HAIR_REWARDS[(level // 2 - 1) % len(HAIR_REWARDS)])
    else:
        rewards.append(CLOTHES_REWARDS[(level // 2 - 1) % len(CLOTHES_REWARDS)])
    return rewards


def all_rewards() -> List[Dict[str, str]]:
    return list(ALL_REWARDS)


def reward_for_goal_completion(
    *,
    completed_count: int,
    minimum_goals: int,
    unlocked_ids: Iterable[str],
) -> Optional[Dict[str, str]]:
    """Return one reward once the daily minimum has been reached."""
    if completed_count < minimum_goals:
        return None
    unlocked = set(unlocked_ids)
    locked_cosmetics = [reward for reward in ALL_COSMETICS if reward["id"] not in unlocked]
    if locked_cosmetics:
        return random.choice(locked_cosmetics)
    return dict(FREEZE_REWARD)
