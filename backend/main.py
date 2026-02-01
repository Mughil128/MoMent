from dotenv import load_dotenv
load_dotenv()

import asyncio
from fastapi import FastAPI
from api.api import api_router, ws_router


from application.meeting_polling import poll_meetings
from _bootstrap.bootstrap import orchestrator_instance


app = FastAPI(
    title="AI Meeting Assistant API",
    description="for speech-to-text and MoM generation",
    version="1.0.0",
)

app.include_router(api_router)
app.include_router(ws_router)


@app.on_event("startup")
async def startup_event():
    from api.websockets import streaming
    
    # Make orchestrator available to websocket handler for final flush
    streaming.orchestrator_instance = orchestrator_instance
    
    asyncio.create_task(poll_meetings(orchestrator_instance))


@app.get("/")
def root():
    return {"message": "AI Meeting Assistant API is running"}
