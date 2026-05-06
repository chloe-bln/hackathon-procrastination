"""Linux blocking utilities for Cozy Goals.

Apps are blocked by killing matching processes while Cozy Goals is running.
Sites are blocked by maintaining a clearly marked section in /etc/hosts; this
requires root privileges and is applied through pkexec when available.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, Iterable, List

HOSTS_PATH = Path("/etc/hosts")
START_MARKER = "# COZY_GOALS_BLOCK_START"
END_MARKER = "# COZY_GOALS_BLOCK_END"


def _is_unlocked(entry: Dict[str, Any]) -> bool:
    value = entry.get("unlocked_until")
    # Flutter filters by date for UX; Python receives only locked entries in
    # normal operation. Keep this hook for future expansion.
    return bool(value and entry.get("unlocked") is True)


def _safe_process_pattern(value: str) -> str:
    # Keep app blocking intentionally conservative. The user can enter a process
    # name like firefox, discord, steam. We reject shell metacharacters.
    value = value.strip()
    if not value or re.search(r"[;&|`$<>]", value):
        raise ValueError(f"Unsafe app target: {value!r}")
    return value


def enforce_apps(entries: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    killed: List[Dict[str, Any]] = []
    skipped: List[str] = []

    for entry in entries:
        if entry.get("kind") != "app" or _is_unlocked(entry):
            continue
        target = _safe_process_pattern(str(entry.get("target", "")))
        if not target:
            skipped.append(str(entry.get("name", "unknown")))
            continue

        probe = subprocess.run(["pgrep", "-f", target], text=True, capture_output=True)
        pids = [line.strip() for line in probe.stdout.splitlines() if line.strip() and line.strip() != str(os.getpid())]
        if not pids:
            continue

        subprocess.run(["pkill", "-f", target], text=True, capture_output=True)
        killed.append({"name": entry.get("name", target), "target": target, "count": len(pids)})

    return {"killed": killed, "skipped": skipped, "killed_count": sum(item["count"] for item in killed)}


def _normalize_domain(domain: str) -> List[str]:
    value = domain.strip().lower()
    value = re.sub(r"^https?://", "", value)
    value = value.split("/", 1)[0].split(":", 1)[0]
    value = value.strip(".")
    if not value or not re.match(r"^[a-z0-9.-]+\.[a-z]{2,}$", value):
        raise ValueError(f"Invalid domain: {domain!r}")
    domains = [value]
    if not value.startswith("www."):
        domains.append(f"www.{value}")
    return sorted(set(domains))


def _render_hosts_block(domains: Iterable[str]) -> str:
    normalized: List[str] = []
    for domain in domains:
        normalized.extend(_normalize_domain(domain))
    normalized = sorted(set(normalized))
    if not normalized:
        return f"{START_MARKER}\n{END_MARKER}\n"

    lines = [START_MARKER]
    for domain in normalized:
        lines.append(f"0.0.0.0 {domain}")
        lines.append(f"::1 {domain}")
    lines.append(END_MARKER)
    return "\n".join(lines) + "\n"


def _replace_hosts_block(text: str, block: str) -> str:
    pattern = re.compile(rf"\n?{re.escape(START_MARKER)}.*?{re.escape(END_MARKER)}\n?", re.S)
    cleaned = pattern.sub("\n", text).rstrip() + "\n"
    if block.strip() == f"{START_MARKER}\n{END_MARKER}":
        return cleaned
    return cleaned + "\n" + block


def _write_hosts_block_as_root(domains: List[str]) -> Dict[str, Any]:
    original = HOSTS_PATH.read_text(encoding="utf-8")
    block = _render_hosts_block(domains)
    updated = _replace_hosts_block(original, block)
    backup = HOSTS_PATH.with_name("hosts.cozy-goals.bak")
    if not backup.exists():
        backup.write_text(original, encoding="utf-8")
    HOSTS_PATH.write_text(updated, encoding="utf-8")
    return {"ok": True, "blocked_domains": domains, "hosts_path": str(HOSTS_PATH)}


def _run_privileged(command: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".json") as handle:
        json.dump(payload, handle)
        payload_path = handle.name
    try:
        script = Path(__file__).with_name("cli.py")
        try:
            proc = subprocess.run(
                ["pkexec", sys.executable, str(script), command, payload_path],
                text=True,
                capture_output=True,
                timeout=120,
            )
        except FileNotFoundError:
            return {"ok": False, "error": "pkexec is not installed. Install Polkit/policykit-1 or run the command as root."}
        if proc.returncode != 0:
            return {"ok": False, "error": proc.stderr.strip() or proc.stdout.strip() or "pkexec failed"}
        return json.loads(proc.stdout.strip() or "{}")
    finally:
        try:
            os.unlink(payload_path)
        except OSError:
            pass


def apply_site_blocks(entries: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    domains = [str(entry.get("target", "")) for entry in entries if entry.get("kind") == "site" and not _is_unlocked(entry)]
    domains = sorted({domain for domain in domains if domain.strip()})
    if os.geteuid() == 0:
        return _write_hosts_block_as_root(domains)
    return _run_privileged("apply_site_blocks_root", {"domains": domains})


def apply_site_blocks_root(payload_path: str) -> Dict[str, Any]:
    payload = json.loads(Path(payload_path).read_text(encoding="utf-8"))
    return _write_hosts_block_as_root(list(payload.get("domains", [])))


def clear_site_blocks() -> Dict[str, Any]:
    if os.geteuid() == 0:
        return _write_hosts_block_as_root([])
    return _run_privileged("clear_site_blocks_root", {"domains": []})


def clear_site_blocks_root(payload_path: str) -> Dict[str, Any]:
    return _write_hosts_block_as_root([])
