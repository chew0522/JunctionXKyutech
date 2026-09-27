import os
from datetime import datetime

# Default: the real local time. For a repeatable demo, start the server with DEMO_CLOCK=fixed
# to freeze the clock at DEMO_START (Sat 26 Sep 2026, 14:50).
DEMO_START = datetime(2026, 9, 26, 14, 50)


def now() -> datetime:
    if os.environ.get("DEMO_CLOCK") == "fixed":
        return DEMO_START
    return datetime.now().replace(microsecond=0)
