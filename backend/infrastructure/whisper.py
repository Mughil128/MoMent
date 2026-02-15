import whisper
import numpy as np
import soundfile as sf
import os
from domain.ports.stt_port import STTPort, AudioInput
from shared_state import meeting_states

SAMPLE_RATE = 16000
BYTES_PER_SECOND = SAMPLE_RATE * 2
BATCH_SECONDS = 5  # Process every 5 seconds of audio

class WhisperSTT(STTPort):
    def __init__(self, model_name="base"):
        self.model = whisper.load_model(model_name)

    def transcribe(self, audio_input: AudioInput) -> str:
        if not os.path.exists(audio_input.audio_path):
            raise FileNotFoundError(f"Audio file not found: {audio_input.audio_path}")
        result = self.model.transcribe(audio_input.audio_path)
        return result['text']

    def process_meeting(self, meeting_id):
        state = meeting_states.get(meeting_id)
        if not state:
            return

        meeting_dir = os.path.join("recordings", meeting_id)
        pcm_path = os.path.join(meeting_dir, "audio.pcm")
        wav_path = os.path.join(meeting_dir, "chunk.wav")

        if not os.path.exists(pcm_path):
            return

        last_bytes = state["last_processed_bytes"]
        file_size = os.path.getsize(pcm_path)
        new_bytes = file_size - last_bytes
        print(f"[WhisperSTT] Meeting {meeting_id}: {new_bytes} new bytes (need {BATCH_SECONDS * BYTES_PER_SECOND})")

        if new_bytes < BATCH_SECONDS * BYTES_PER_SECOND:
            return

        with open(pcm_path, "rb") as f:
            f.seek(last_bytes)
            pcm_data = f.read()

        audio = np.frombuffer(pcm_data, dtype=np.int16)
        audio = audio.astype(np.float32) / 32768.0

        # Pass audio array directly to Whisper (bypasses ffmpeg requirement)
        print(f"[WhisperSTT] Transcribing {len(audio)} samples...")
        result = self.model.transcribe(audio, fp16=False)
        text = result['text'].strip()
        print(f"[WhisperSTT] Transcription result: {text!r}")

        state["last_processed_bytes"] += len(pcm_data)
        
        return text if text else None

    def process_remaining(self, meeting_id):
        """Process any remaining audio when meeting ends, ignoring batch size."""
        state = meeting_states.get(meeting_id)
        if not state:
            return

        meeting_dir = os.path.join("recordings", meeting_id)
        pcm_path = os.path.join(meeting_dir, "audio.pcm")

        if not os.path.exists(pcm_path):
            return

        last_bytes = state["last_processed_bytes"]
        file_size = os.path.getsize(pcm_path)
        new_bytes = file_size - last_bytes

        if new_bytes == 0:
            return
        
        # Need at least 0.5 seconds for meaningful transcription
        min_samples = int(SAMPLE_RATE * 0.5)
        min_bytes = min_samples * 2
        
        if new_bytes < min_bytes:
            print(f"[WhisperSTT] Warning: Only {new_bytes} bytes ({new_bytes/BYTES_PER_SECOND:.2f}s) - may be too short for transcription")

        print(f"[WhisperSTT] Final flush for {meeting_id}: {new_bytes} bytes ({new_bytes/BYTES_PER_SECOND:.2f}s)")

        with open(pcm_path, "rb") as f:
            f.seek(last_bytes)
            pcm_data = f.read()

        audio = np.frombuffer(pcm_data, dtype=np.int16)
        audio = audio.astype(np.float32) / 32768.0
        
        # Check audio statistics
        audio_max = np.max(np.abs(audio))
        audio_mean = np.mean(np.abs(audio))
        print(f"[WhisperSTT] Audio stats - max: {audio_max:.4f}, mean: {audio_mean:.4f}")
        
        if audio_max < 0.01:
            print(f"[WhisperSTT] Warning: Audio is very quiet (max={audio_max:.4f}), might be silence")

        print(f"[WhisperSTT] Transcribing final {len(audio)} samples...")
        result = self.model.transcribe(audio, fp16=False)
        text = result['text'].strip()
        print(f"[WhisperSTT] Final transcription: {text!r}")

        state["last_processed_bytes"] += len(pcm_data)
        
        return text if text else None

model = WhisperSTT()
