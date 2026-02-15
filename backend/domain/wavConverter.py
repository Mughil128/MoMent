import wave

def pcm_to_wav(pcm_path, wav_path):
    with open(pcm_path, 'rb') as pcmfile:
        pcm_data = pcmfile.read()

    with wave.open(wav_path, 'wb') as wavfile:
        wavfile.setnchannels(1)       # mono
        wavfile.setsampwidth(2)       # 16-bit = 2 bytes
        wavfile.setframerate(16000)   # match Flutter
        wavfile.writeframes(pcm_data)
