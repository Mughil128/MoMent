from domain.ports.stt_port import STTPort
from domain.ports.file_handling_port import FileHandlingPort
import os
from domain.ports.llm_port import LLMPort
from domain import prompt_builder
class MomentsOrchestrator:
    def __init__(self, stt: STTPort, file_handler: FileHandlingPort,llm:LLMPort):
        self.stt = stt
        self.file_handler = file_handler
        self.BASE_DIR = "recordings"
        self.llm=llm

    def process_meeting_workflow(self, meeting_id: str, force_remaining: bool = False):
        # 1. Call STT to process the meeting audio
        if force_remaining and hasattr(self.stt, 'process_remaining'):
            transcript_chunk = self.stt.process_remaining(meeting_id)
        else:
            transcript_chunk = self.stt.process_meeting(meeting_id)
        print(f"[Orchestrator] STT returned: {transcript_chunk!r}")
        
        # 2. If we got a transcript, store it
        if transcript_chunk:
            transcript_path = f"recordings/{meeting_id}/transcript.txt"
            print(f"[Orchestrator] Writing to: {transcript_path}")
            self.file_handler.append_text_line(transcript_path, transcript_chunk)
            print(f"[Orchestrator] Wrote transcript chunk")
            
    def meeting_end_workflow(self,meeting_id):
        transcript_path = os.path.join(self.BASE_DIR, meeting_id, "transcript.txt")
        if not os.path.exists(transcript_path):
            raise FileNotFoundError(f"Transcript not found for meeting {meeting_id}")
        
        with open(transcript_path, "r", encoding="utf-8") as f:
            transcript = f.read()
        
        try:
            prompt = prompt_builder.build_prompt(transcript)
            mom = self.llm.prompt(prompt)
            return mom
        except Exception as e:
            print(f"[Orchestrator] LLM failed: {e}, returning raw transcript")
            # Return transcript with basic formatting if LLM fails
            return f"TRANSCRIPT\n{'='*50}\n\n{transcript}\n\n(Note: AI summary unavailable - showing raw transcript)"