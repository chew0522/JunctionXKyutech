import json
import uuid
from pathlib import Path

import current_time

DATA = Path(__file__).resolve().parent.parent.parent / "data"


def get_registration() -> dict:
    reg = json.loads((DATA / "registration.json").read_text())
    reg["total_credits"] = sum(c["credits"] for c in reg["registered"])
    return reg


def get_finance() -> dict:
    fin = json.loads((DATA / "finance.json").read_text())
    total = sum(f["amount"] for f in fin["fees"])
    paid = sum(p["amount"] for p in fin["payments"])
    fin.update({"total_fees": total, "paid": paid, "outstanding": total - paid})
    return fin


def get_forms() -> list[dict]:
    return json.loads((DATA / "forms.json").read_text())


def get_form_submissions() -> list[dict]:
    return list(reversed(json.loads((DATA / "form_submissions.json").read_text())))


def submit_form(form_id: str, values: dict) -> dict | None:
    form = next((f for f in get_forms() if f["id"] == form_id), None)
    if form is None:
        return None
    file = DATA / "form_submissions.json"
    log = json.loads(file.read_text())
    entry = {
        "id": str(uuid.uuid4())[:8],
        "form_id": form_id,
        "title": form["title"],
        "values": values,
        "status": "Pending review",
        "submitted_at": current_time.now().isoformat(),
    }
    log.append(entry)
    file.write_text(json.dumps(log, indent=2))
    return entry
