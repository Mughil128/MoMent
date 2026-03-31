# MoMent – AI Meeting Assistant

MoMent is a mobile-based AI-powered meeting assistant that records live meetings, converts speech to text in real time, generates structured Minutes of Meeting (MoM), and extracts actionable tasks automatically.

The system integrates speech recognition, natural language processing, and deep learning to automate meeting documentation and improve productivity.

---

## Features

* Real-time audio streaming from mobile device
* Speech-to-text using Whisper model
* Automatic Minutes of Meeting (MoM) generation using LLM
* Action item extraction using BERT-based pipeline
* Flutter mobile application for recording and viewing results
* Near real-time processing with incremental audio handling

---

## Project Structure

```
MoMent/
│
├── backend/                 # FastAPI backend
│   ├── api/                 # Routes and WebSockets
│   ├── application/         # Business logic (orchestrator)
│   ├── domain/              # Core logic and interfaces
│   ├── infrastructure/      # Whisper, LLM, file handling
│   └── nlp/                 # Action extraction models
│
├── moment_flutter_app/      # Flutter frontend app
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   └── services/        # API + WebSocket communication
│
└── recordings/              # Stored meeting data (generated)
```

---

## Requirements

### Backend

* Python 3.9+
* FastAPI
* Uvicorn
* Whisper
* Transformers (HuggingFace)
* PyTorch
* FFmpeg

### Frontend

* Flutter SDK
* Android Studio / VS Code
* Physical Android device (USB debugging enabled)

---

## Installation

---

### 1. Backend Setup

```
cd backend
pip install -r requirements.txt
```

Make sure FFmpeg is installed and accessible in your system.

---

### 2. Environment Variables

Create a `.env` file inside `backend/`:

```
OPENROUTER_API_KEY=your_api_key_here
```

---

## Running the Application

### Step 1: Start Backend Server

```
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

Backend will run at:

```
http://<ip-address>:8000
```

---

### Step 2: Connect Mobile Device

* Enable USB Debugging
* Connect phone via USB
* Ensure both laptop and phone are on the same WiFi network

---

### Step 3: Update Backend IP in Flutter

Go to:

```
moment_flutter_app/lib/services/meeting_service.dart
```

Change the IP address:

```dart
final String baseUrl = "http://<YOUR-IP>:8000";
```

Use your system’s local IP (for example, 192.168.x.x), not localhost.

---

### Step 4: Run Flutter App

```
cd moment_flutter_app
flutter pub get
flutter run
```

---

## How to Use

1. Open the app on your mobile device
2. Click Start to begin recording
3. Speak normally during the meeting
4. Click Stop to end the meeting
5. Wait a few seconds for processing
6. View:

   * Minutes of Meeting
   * Action Items

---

## System Workflow

1. Audio recorded from mobile device
2. Audio streamed via WebSocket to backend
3. AAC converted to PCM using FFmpeg
4. Whisper processes audio incrementally
5. Transcript generated and stored
6. LLM generates structured MoM
7. BERT pipeline extracts action items
8. Results returned to mobile app

---

## Tech Stack

### Backend

* FastAPI
* Whisper (Speech Recognition)
* OpenRouter LLM (Summarization)
* Transformers (BERT for NLP)
* WebSockets

### Frontend

* Flutter
* Dart
* HTTP + WebSocket

---

## Important Notes

* Both devices must be on the same network
* Do not use `localhost` in Flutter
* Ensure microphone permissions are granted
* Model files must be present in `/models` for action extraction
* Large meetings may take longer to process

---

## Testing

Basic test scripts are available in:

```
test/
```

---

## Future Improvements

* Speaker identification (diarization)
* Live summary updates during meeting
* Cloud deployment support
* Multilingual support
* Integration with task management tools