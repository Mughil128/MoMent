from fastapi import APIRouter, HTTPException
import os
from _bootstrap.bootstrap import orchestrator_instance

router = APIRouter()

@router.get("/transcript/{meeting_id}")
def end_meeting(meeting_id: str):
    moments=orchestrator_instance.meeting_end_workflow(meeting_id)
    print("test"+moments)
    return {"moments":moments}
        
    
