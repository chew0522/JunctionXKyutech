from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import chat_log
from agent import run_agent
from api_routes import router as api_router

app = FastAPI()
app.include_router(api_router)

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
    chat_log.append_message("user", req.message)
    result = run_agent(req.message, history=_history)
    _history[:] = result["history"]
    cards = result["cards"]
    choices = None if cards else result["choices"]
    chat_log.append_message("agent", result["reply"], choices=choices, cards=cards)
    return {"reply": result["reply"], "choices": choices, "cards": cards}


@app.get("/history")
def history():
    """Persisted display log for hydrating the chat UI on app launch — separate from
    _history above, which is the raw tool-calling context the agent needs to keep reasoning."""
    return {"messages": chat_log.get_recent_messages()}


@app.post("/reset")
def reset():
    _history.clear()
    return {"ok": True}
