"""Put the demo data back to its starting state: python demo_reset.py (or POST /reset-demo).
data/seed/ holds the clean copies of every file the app changes while you use it."""

import shutil
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


def reset_demo(data_dir: Path = DATA_DIR) -> list[str]:
    for name in RESET_FILES:
        shutil.copyfile(data_dir / "seed" / name, data_dir / name)
    return RESET_FILES


if __name__ == "__main__":
    print("Reset:", ", ".join(reset_demo()))
