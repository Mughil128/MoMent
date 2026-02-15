from fastapi import WebSocket, APIRouter
from starlette.websockets import WebSocketDisconnect
import os
import numpy as np
import subprocess
import imageio_ffmpeg
from shared_state import meeting_states

router = APIRouter()

# Import will be set by dependency injection in main.py, but for now we'll access the singleton
orchestrator_instance = None
BASE_DIR = "recordings"


def convert_aac_to_pcm(aac_path: str, pcm_path: str) -> None:
    """Convert an AAC file to 16kHz mono 16-bit PCM using ffmpeg."""
    if not os.path.exists(aac_path):
        print(f"[WebSocket] AAC file not found for conversion: {aac_path}")
        return

    try:
        ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
        
        # Use ffmpeg to convert AAC to raw PCM
        # -i: input file
        # -ar 16000: 16kHz sample rate
        # -ac 1: mono
        # -f s16le: 16-bit signed little-endian PCM
        # -: output to stdout
        cmd = [
            ffmpeg_exe,
            '-i', aac_path,
            '-ar', '16000',
            '-ac', '1',
            '-f', 's16le',
            '-'
        ]
        
        result = subprocess.run(cmd, capture_output=True, check=True)
        
        # Write PCM data to file
        with open(pcm_path, 'wb') as f:
            f.write(result.stdout)
        
        samples = len(result.stdout) // 2  # 2 bytes per 16-bit sample
        print(f"[WebSocket] Converted AAC to PCM: {aac_path} -> {pcm_path} ({samples} samples)")
    except subprocess.CalledProcessError as e:
        print(f"[WebSocket] FFmpeg failed to convert AAC to PCM: {e.stderr.decode()}")
    except Exception as e:
        print(f"[WebSocket] Failed to convert AAC to PCM: {e}")


@router.websocket("/audio")
async def receive_audio(websocket: WebSocket, meeting_id: str):
    await websocket.accept()

    meeting_dir = os.path.join(BASE_DIR, meeting_id)
    os.makedirs(meeting_dir, exist_ok=True)

    aac_path = os.path.join(meeting_dir, "audio.aac")
    pcm_path = os.path.join(meeting_dir, "audio.pcm")

    meeting_states.setdefault(meeting_id, {"last_processed_bytes": 0})
    
    total_bytes = 0
    with open(aac_path, "ab") as f:
        try:
            while True:
                chunk = await websocket.receive_bytes()
                f.write(chunk)
                total_bytes += len(chunk)
                if total_bytes % 10000 < len(chunk):  # Log every ~10KB
                    print(f"[WebSocket] {meeting_id}: received {total_bytes} bytes")
        except WebSocketDisconnect:
            # Normal client disconnect (code 1000) – Starlette will close the socket.
            pass
        finally:
            # Convert the received AAC to PCM and then process remaining audio
            print(f"[WebSocket] Connection closed for {meeting_id}, total received: {total_bytes} bytes")
            
            if total_bytes == 0 or not os.path.exists(aac_path) or os.path.getsize(aac_path) == 0:
                print(f"[WebSocket] No audio data received for {meeting_id}, skipping conversion")
            else:
                print(f"[WebSocket] Converting {os.path.getsize(aac_path)} bytes of AAC...")
                convert_aac_to_pcm(aac_path, pcm_path)
                
            if orchestrator_instance:
                orchestrator_instance.process_meeting_workflow(meeting_id, force_remaining=True)
            # Remove meeting from state so polling stops
            if meeting_id in meeting_states:
                del meeting_states[meeting_id]
