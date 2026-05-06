"""Reward generation for level-ups and threshold goal completions.

Reward IDs are stable. Flutter persists cosmetics in SQLite by ID.
"""
from __future__ import annotations

import random
from typing import Dict, Iterable, List, Optional

HAIR_REWARDS = [
    {"id": "hair_pink", "type": "hair", "label": "Pink"},
    {"id": "hair_lavender", "type": "hair", "label": "Lavender"},
    {"id": "hair_green", "type": "hair", "label": "Green"},
    {"id": "hair_mint", "type": "hair", "label": "Mint"},
    {"id": "hair_brown", "type": "hair", "label": "Brown"},
    {"id": "hair_blonde", "type": "hair", "label": "Blonde"},
    {"id": "hair_white", "type": "hair", "label": "White"},
    {"id": "hair_black", "type": "hair", "label": "Black"},
    {"id": "hair_bun_pink", "type": "hair", "label": "Pink bun"},
    {"id": "hair_bun_lavender", "type": "hair", "label": "Lavender bun"},
    {"id": "hair_bun_green", "type": "hair", "label": "Green bun"},
    {"id": "hair_bun_brown", "type": "hair", "label": "Brown bun"},
    {"id": "hair_bun_blonde", "type": "hair", "label": "Blonde bun"},
    {"id": "hair_bun_white", "type": "hair", "label": "White bun"},
    {"id": "hair_bun_black", "type": "hair", "label": "Black bun"},
]

CLOTHES_REWARDS = [
    {"id": "clothes_pink", "type": "clothes", "label": "Pink"},
    {"id": "clothes_green", "type": "clothes", "label": "Green"},
    {"id": "clothes_mint", "type": "clothes", "label": "Mint"},
    {"id": "clothes_brown", "type": "clothes", "label": "Brown"},
    {"id": "clothes_yellow", "type": "clothes", "label": "Yellow"},
    {"id": "clothes_white", "type": "clothes", "label": "White"},
    {"id": "clothes_black", "type": "clothes", "label": "Black"},
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
