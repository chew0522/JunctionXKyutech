import os
import time as _time
from datetime import datetime, timedelta

# Demo-only start time; the clock then runs forward in real time from when the server started
# (so nothing looks frozen). POST /reset-demo re-anchors it. Set DEMO_CLOCK=fixed to freeze it.
DEMO_START = datetime(2026, 9, 26, 14, 50)
_anchor = _time.time()


def reset_anchor() -> None:
    global _anchor
    _anchor = _time.time()


def now() -> datetime:
    if os.environ.get("DEMO_CLOCK") == "fixed":
        return DEMO_START
    return (DEMO_START + timedelta(seconds=_time.time() - _anchor)).replace(microsecond=0)
