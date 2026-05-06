"""Reward generation for level-ups.

Reward IDs are stable. Flutter persists cosmetics in SQLite by ID.
"""
from __future__ import annotations

from typing import Dict, List

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


def rewards_for_level(level: int) -> List[Dict[str, str]]:
    rewards: List[Dict[str, str]] = []

    # Every third level gives a consumable freeze.
    if level % 3 == 0:
        rewards.append(FREEZE_REWARD)

    # Alternate cosmetic families in a deterministic way.
    if level % 2 == 0:
        rewards.append(HAIR_REWARDS[(level // 2 - 1) % len(HAIR_REWARDS)])
    else:
        rewards.append(CLOTHES_REWARDS[(level // 2 - 1) % len(CLOTHES_REWARDS)])

    return rewards
