"""Put the demo data back to its starting state: python demo_reset.py (or POST /reset-demo).
Add --sample to start with the sample appointments instead.
data/seed/ holds the clean copies of every file the app changes while you use it."""

import json
import shutil
import sys
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

RESET_FILES = [
    "my_bookings.json",
    "chat_log.json",
    "attendance.json",
    "merit_log.json",
    "feedback.json",
    "form_submissions.json",
    "course_extras.json",
    "clinic_slots.json",
]


def reset_demo(data_dir: Path = DATA_DIR, empty_bookings: bool = True) -> list[str]:
    """By default the student starts with no appointments; empty_bookings=False keeps the sample ones."""
    for name in RESET_FILES:
        shutil.copyfile(data_dir / "seed" / name, data_dir / name)
    if empty_bookings:
        seeded = json.loads((data_dir / "seed" / "my_bookings.json").read_text())
        held = {b["resource_id"] for b in seeded if b["kind"] == "clinic" and b.get("resource_id")}
        slots_file = data_dir / "clinic_slots.json"
        slots = json.loads(slots_file.read_text())
        for slot in slots:
            if slot["id"] in held:
                slot["available"] = True
        slots_file.write_text(json.dumps(slots, indent=2))
        (data_dir / "my_bookings.json").write_text("[]")
    return RESET_FILES


if __name__ == "__main__":
    sample = "--sample" in sys.argv
    print("Reset:", ", ".join(reset_demo(empty_bookings=not sample)), "(with sample appointments)" if sample else "(no appointments)")
