from infrastructure.whisper import WhisperSTT
from infrastructure.file_handler import LocalFileHandler
from application.moments_orchestrator import MomentsOrchestrator
from infrastructure.open_router_llm import OpenRouterLLM


stt_adapter = WhisperSTT()
file_handler = LocalFileHandler()
llm=OpenRouterLLM()
orchestrator = MomentsOrchestrator(stt_adapter, file_handler,llm)
# Make orchestrator available to websocket handler for final flush
orchestrator_instance = orchestrator