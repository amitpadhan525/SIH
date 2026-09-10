# 🏺 Artisan AI — SIH 2026 Production Hardened Architecture
> **PS Number**: SIH26090  
> **Theme**: AI-driven digital commerce and catalog management platform for grassroots artisans.  
> **Core Workflow**: `PHOTO ➔ SPEAK ➔ PROCESS ➔ REVIEW/EDIT ➔ PUBLISH`

---

## 🌟 System Architecture

```
                       ┌────────────────────────────────────────────────────────┐
                       │                   ARTISAN MOBILE APP                   │
                       │           (Flutter 3.x / Dart / Android)               │
                       │   • flutter_secure_storage session persistence         │
                       │   • record package for real microphone recording       │
                       │   • Offline JSON Sync queue with restart persistence   │
                       └──────────────────────────┬─────────────────────────────┘
                                                  │
                                 REST / JSON / Multipart HTTP (10s Timeout)
                                                  │
                       ┌──────────────────────────▼─────────────────────────────┐
                       │                FASTAPI BACKEND CORE                    │
                       │   (Python 3.14 / Pydantic v2 / SQLAlchemy 2.0 ORM)     │
                       │   • Server-side IDOR ownership checks                  │
                       │   • Role-based Admin authorization (`role == admin`)   │
                       │   • Magic-byte & MIME audio/image upload security      │
                       │   • Strict Production SECRET_KEY validation            │
                       └─────┬──────────────┬──────────────┬──────────────┬─────┘
                             │              │              │              │
       ┌─────────────────────┼──────────────┼──────────────┼──────────────┼─────────────────────┐
       │                     │              │              │              │                     │
┌──────▼──────┐       ┌──────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐ ┌─────▼─────┐       ┌──────▼──────┐
│  AI Image   │       │ SpeechToText│ │ Cost-Plus │ │ Marketplace │ │  Offline  │       │  Web Admin  │
│   Studio    │       │   Service   │ │  Pricing  │ │  & Inquiries│ │Sync Queue │       │  Dashboard  │
│ (1024x1024  │       │(LocalWhisper│ │ Benchmark │ │  (ONDC/GeM  │ │(Persisted │       │ (Role-Auth  │
│ Chroma/BG)  │       │ Provider)   │ │ Assistant)│ │ JSON Export)│ │Batch Sync)│       │ Inquiries)  │
└──────┬──────┘       └──────┬──────┘ └─────┬─────┘ └──────┬──────┘ └─────┬─────┘       └──────┬──────┘
       │                     │              │              │              │                    │
       └─────────────────────┴──────────────┼──────────────┴──────────────┴────────────────────┘
                                            │
                               ┌────────────▼────────────┐
                               │   PostgreSQL 16 Engine  │
                               │  (Alembic Migrations)   │
                               └─────────────────────────┘
```

---

## 📋 Feature Classification & Verification Status

| Module | Classification | Status Details |
| :--- | :--- | :--- |
| **Authentication & Session Persistence** | `WORKING` | Mobile phone OTP auth with `flutter_secure_storage` persistence across app restarts. Unauthenticated access yields 401. |
| **Admin Inquiries & Authorization** | `WORKING` | Server-side role enforcement on `GET /admin/inquiries` (`401` if unauthenticated, `403` if non-admin, `200` for admin). Admin portal sends Bearer token. |
| **IDOR Resource Protection** | `WORKING` | Strict artisan ownership checks on `PUT /products/{id}`, `DELETE /products/{id}`, and `GET /artisans/{id}/inquiries`. |
| **Audio Upload & Validation** | `WORKING` | 10 MB limit, randomized filenames, temporary file cleanup, magic byte header verification for WAV, MP3, M4A, AAC, WEBM, OGG, FLAC. |
| **Local Whisper STT** | `WORKING` | `SpeechToTextService` abstraction with `LocalWhisperProvider`. Returns explicit `503 LOCAL_STT_MODEL_UNAVAILABLE` when unconfigured. No fake STT fallback. |
| **Voice Recording (Flutter)** | `WORKING` | Real microphone capture with `record` package, permission handling, recording timer, cancellation, and audio upload to `/ai/transcribe`. |
| **Offline Sync Queue** | `WORKING` | Persistent JSON queue surviving app kill/restarts. Idempotent batch sync to `/sync/batch`. |
| **Cost-Plus Pricing Calculator** | `WORKING / HEURISTIC` | Deterministic cost breakdown ($M + L + O + P$) + regional benchmark reference. *Not an ML model*. |
| **Multilingual Catalog Generator** | `WORKING / HEURISTIC` | Rule-based entity extraction and template generation based strictly on verified inputs to prevent hallucination. |
| **ONDC / GeM Export** | `WORKING / HEURISTIC` | Generates compliant ONDC Beckn and GeM JSON payloads for export. *Not a live ONDC network connection*. |
| **Image Studio** | `WORKING` | Transparent background removal and 1024x1024 centering with magic byte upload validation. |
| **Camera & Gallery Shortcut** | `WORKING` | Direct camera capture / gallery picker shortcuts feeding into Image Studio pipeline. |

---

## 🧪 Automated Test Results

- **Backend Pytest Suite**: **100 / 100 tests passing (100%)**
- **Flutter Mobile Suite**: **51 / 51 tests passing (100%)**
- **Flutter Analyzer**: **0 issues found**

---

## 🔒 Security Configuration

### Production Secret Key
In `production` mode (`ENVIRONMENT=production`), the application validates `SECRET_KEY` and refuses to start if it is missing, default, or fewer than 32 characters.

### Demo OTP Security
- When `AUTH_DEMO_MODE=true` (development/evaluation): Demo OTP `123456` is enabled and returned for evaluator convenience.
- When `AUTH_DEMO_MODE=false` (production): OTP is cryptographically generated, time-limited, single-use, attempt-limited, constant-time compared, and **never returned in API responses or logs**.

### CORS Configuration
Configurable via `CORS_ORIGINS` environment variable (comma-separated list of allowed origins).

---

## 🎙️ Local Whisper Setup

To enable local speech-to-text recognition with Whisper:

1. Install local Whisper / faster-whisper in the Python environment:
   ```bash
   pip install openai-whisper
   # OR
   pip install faster-whisper
   ```
2. Set the model path or model size in `.env`:
   ```env
   WHISPER_MODEL_PATH=base
   # OR path to local model weights:
   # WHISPER_MODEL_PATH=/path/to/whisper/model
   ```
3. If Whisper is not installed or the model is not found, `/ai/transcribe` safely returns:
   ```json
   {
     "success": false,
     "error": "LOCAL_STT_MODEL_UNAVAILABLE",
     "message": "Local Speech-to-Text (Whisper) is not configured or available."
   }
   ```
   The mobile app displays a clear notification to the user.

---

## 📴 100% Offline Setup & Local Deployment

Artisan AI can run completely offline with zero external cloud dependencies.

👉 **Full Step-by-Step Guide**: See [`docs/offline_setup.md`](docs/offline_setup.md)

### Quick Offline Start (3 Commands):

```bash
# 1. Start Local Postgres Database
docker-compose up -d postgres

# 2. Run Local Backend Server
PYTHONPATH=. backend/.venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000

# 3. Tunnel to Android Phone over USB (Zero internet needed)
adb reverse tcp:8000 tcp:8000
```

---

## 💻 Developer & Evaluation Commands

### 1. Run All Backend Tests
```bash
PYTHONPATH=. backend/.venv/bin/pytest backend/tests -v
```

### 2. Run All Flutter Tests & Analyzer
```bash
cd mobile
/home/amit/development/flutter/bin/flutter test
/home/amit/development/flutter/bin/flutter analyze
```

### 3. Build & Install Release APK
```bash
cd mobile
/home/amit/development/flutter/bin/flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```