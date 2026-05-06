#!/usr/bin/env python3
"""CLI bridge used by Flutter."""
from __future__ import annotations

import json
import sys
from typing import Any, Dict

from daily_reset import run as daily_reset_run
from progression import apply_xp
from rewards import all_rewards, reward_for_goal_completion
from streak import secure_streak


def read_payload() -> Dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("CLI payload must be a JSON object")
    return data


def main() -> int:
    if len(sys.argv) < 2:
        print(json.dumps({"error": "missing command"}), file=sys.stderr)
        return 2

    command = sys.argv[1]
    payload = read_payload()

    if command == "progression":
        result = apply_xp(
            current_xp=int(payload.get("current_xp", 0)),
            current_level=int(payload.get("current_level", 1)),
            xp_gain=int(payload.get("xp_gain", 25)),
        )
    elif command == "goal_reward":
        result = {
            "reward": reward_for_goal_completion(
                completed_count=int(payload.get("completed_count", 0)),
                minimum_goals=int(payload.get("minimum_goals", 3)),
                unlocked_ids=payload.get("unlocked_ids", []),
            )
        }
    elif command == "all_rewards":
        result = {"rewards": all_rewards()}
    elif command == "secure_streak":
        result = secure_streak(
            date=str(payload["date"]),
            completed_count=int(payload.get("completed_count", 0)),
            minimum_goals=int(payload.get("minimum_goals", 3)),
            current_streak=int(payload.get("current_streak", 0)),
            longest_streak=int(payload.get("longest_streak", 0)),
            last_streak_awarded_date=payload.get("last_streak_awarded_date"),
        )
    elif command == "daily_reset":
        result = daily_reset_run(payload)
    else:
        print(json.dumps({"error": f"unknown command: {command}"}), file=sys.stderr)
        return 2

    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(json.dumps({"error": str(exc)}), file=sys.stderr)
        raise SystemExit(1)
