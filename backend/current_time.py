from datetime import datetime

# Demo-only: hardcoded so nudges and the coffee planner can both be staged to fire
# reliably on cue. Swap for datetime.now() once you're ready to test against a real clock.
DEMO_NOW = datetime(2026, 9, 26, 14, 50)


def now() -> datetime:
    return DEMO_NOW
