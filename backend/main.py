from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from agent import run_agent
from nudges import check_nudges

app = FastAPI()

# Wide open for the hackathon demo — tighten if this ever leaves your laptop.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory conversation history, single session — fine for a live demo, not for real users.
_history: list[dict] = []


class ChatRequest(BaseModel):
    message: str


@app.post("/chat")
def chat(req: ChatRequest):
    result = run_agent(req.message, history=_history)
    _history[:] = result["history"]
    return {"reply": result["reply"]}


@app.get("/nudges")
def nudges():
    return {"nudges": check_nudges()}


@app.post("/reset")
def reset():
    _history.clear()
    return {"ok": True}
