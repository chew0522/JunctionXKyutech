import json
from datetime import datetime, timedelta
from pathlib import Path

import current_time

LOG_FILE = Path(__file__).resolve().parent.parent / "data" / "chat_log.json"
RETENTION_DAYS = 7


def append_message(role: str, text: str, choices: list[str] | None = None) -> None:
    """role is 'user' or 'agent'. Called once per turn from each side of /chat. choices
    is only ever set for an 'agent' message — see agent.py's offer_choices tool — so a
    reloaded history still shows the same tappable options as when it was first sent."""
    log = _load_all()
    entry = {"role": role, "text": text, "time": current_time.now().isoformat()}
    if choices:
        entry["choices"] = choices
    log.append(entry)
    LOG_FILE.write_text(json.dumps(log, indent=2))


def get_recent_messages() -> list[dict]:
    """Returns messages from the last RETENTION_DAYS, oldest first. Also prunes the
    on-disk log so it doesn't grow unbounded with entries nobody will ever see again."""
    log = _load_all()
    cutoff = current_time.now() - timedelta(days=RETENTION_DAYS)
    recent = [m for m in log if _parse_time(m) >= cutoff]

    if len(recent) != len(log):
        LOG_FILE.write_text(json.dumps(recent, indent=2))

    return recent


def _load_all() -> list[dict]:
    if not LOG_FILE.exists():
        return []
    return json.loads(LOG_FILE.read_text())


def _parse_time(message: dict) -> datetime:
    return datetime.fromisoformat(message["time"])
