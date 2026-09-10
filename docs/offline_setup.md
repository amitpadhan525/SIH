# 📴 Artisan AI — Complete Offline Setup & Local Deployment Guide

> **SIH Problem Statement 90**: AI-driven digital commerce & catalog management platform for grassroots artisans.  
> This guide enables evaluators and developers to run the **entire platform 100% offline** on local infrastructure without any external cloud dependencies.

---

## 🏗️ Offline Architecture Overview

The system is designed with an **Offline-First / Zero-Cloud Dependency** architecture:

```
┌────────────────────────────────────────────────────────┐
│               ARTISAN MOBILE APP (Flutter)             │
│   • Local SQLite / File Storage Queue                  │
│   • Offline Drafts & Pending Batch Sync Queue          │
│   • Zero-Latency Voice Recording & Image Capture       │
└──────────────────────────┬─────────────────────────────┘
                           │ USB Cable (ADB Reverse) OR Local LAN Wi-Fi
┌──────────────────────────▼─────────────────────────────┐
│             LOCAL FASTAPI BACKEND (0.0.0.0:8000)       │
│   • Local Heuristic & Multilingual Entity Extraction   │
│   • Living Wage Fair Price Calculator Engine           │
│   • Local Image Studio (Pillow / OpenCV Chroma Key)    │
│   • Local Whisper STT (Offline PyTorch Weights)        │
└──────────────────────────┬─────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────┐
│             LOCAL POSTGRESQL 16 DATABASE               │
│   • Runs in local Docker container or native service   │
└────────────────────────────────────────────────────────┘
```

---

## 📋 System Prerequisites

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| **Docker & Docker Compose** | 24.0+ | Runs local PostgreSQL database |
| **Python** | 3.12, 3.13, or 3.14 | Backend API engine & STT models |
| **Flutter SDK** | 3.x | Android mobile client build & tooling |
| **Android Device / Emulator** | Android 8.0+ (API 26+) | Physical phone with USB debugging enabled |
| **ADB (Android Debug Bridge)** | Platform-Tools 34+ | USB reverse tunneling to localhost |

---

## 🚀 Step-by-Step Offline Setup

### Step 1: Start the Local Database

Start the bundled PostgreSQL 16 container:

```bash
cd /home/amit/github/SIH

# Start the PostgreSQL service in the background
docker-compose up -d postgres
```

Verify the database container is healthy:
```bash
docker ps --filter "name=artisan_ai_postgres"
```

*(Optional alternative without Docker: run a native PostgreSQL service listening on `localhost:5432` with username `postgres`, password `postgres`, and database `artisan_ai`).*

---

### Step 2: Configure Backend Environment

Ensure your `.env` file exists in the project root:

```ini
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/artisan_ai
SECRET_KEY=sih-2026-artisan-super-secret-key-change-in-prod
AUTH_DEMO_MODE=true
UPLOAD_DIR=/home/amit/github/SIH/backend/uploads
WHISPER_MODEL_NAME=base
CORS_ORIGINS=*
```

---

### Step 3: Initialize Database Schema (Alembic)

Apply all database migrations up to `head`:

```bash
cd /home/amit/github/SIH/backend

# Activate virtual environment
source .venv/bin/activate

# Run migrations
alembic upgrade head
```

---

### Step 4: Configure Local Offline Whisper (Speech-to-Text)

To enable speech-to-text without cloud APIs:

1. Install offline Whisper into the virtual environment:
   ```bash
   pip install openai-whisper
   # OR for ultra-fast CPU inference:
   pip install faster-whisper
   ```

2. Download local weights (e.g. `base` or `tiny` model) to a local directory:
   ```bash
   python -c "import whisper; whisper.load_model('base')"
   ```

3. In `.env`, set:
   ```ini
   WHISPER_MODEL_PATH=base
   ```

*(Note: If Whisper weights are not downloaded, the backend gracefully falls back to deterministic multilingual entity extraction).*

---

### Step 5: Start the Backend FastAPI Server

Run the server bound to `0.0.0.0:8000` so it accepts connections from localhost and local network devices:

```bash
cd /home/amit/github/SIH

PYTHONPATH=. /home/amit/github/SIH/backend/.venv/bin/uvicorn backend.app.main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --reload
```

Verify backend health:
```bash
curl http://127.0.0.1:8000/health/db
# Expected output: {"database":"connected","detail":null}
```

---

### Step 6: Connect Your Android Phone via USB (ADB Reverse)

To allow your physical Android device to reach the local backend over USB cable without any external router or internet:

1. Connect your phone via USB and enable **USB Debugging**.
2. Verify ADB sees the device:
   ```bash
   adb devices
   ```
3. Establish a reverse proxy tunnel:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
   *(This forwards all HTTP requests from `http://127.0.0.1:8000` on your phone directly to your computer's local FastAPI backend).*

---

### Step 7: Build & Install the Mobile App

Install the release APK directly to the connected phone:

```bash
cd /home/amit/github/SIH/mobile

# Build the release binary
/home/amit/development/flutter/bin/flutter build apk --release

# Install onto the connected device
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Launch the app
adb shell am start -n com.example.mobile/.MainActivity
```

---

## 🔄 Testing the Offline-First Sync Queue

The mobile application is built with an **Offline Sync Queue** to support rural artisans in areas with intermittent or zero internet connectivity:

### 1. Simulating Offline Work
1. Disconnect the phone from Wi-Fi or turn on Airplane mode (or stop the backend server).
2. Open the app on the phone.
3. Tap **📸 Add New Product**, record product details via voice/input, and tap **Publish**.
4. The product is immediately saved to the local offline sync queue as a **Pending Draft**.

### 2. Automatic Reconnection & Synchronization
1. Reconnect the USB cable or restart the backend server.
2. The background `SyncService` detects backend connectivity and flushes the queued items to `POST /sync/batch`.
3. The product is synced to the central database and published to the marketplace with full idempotency.

---

## 🧪 Verification & Health Check Commands

| Test | Command | Expected Result |
| :--- | :--- | :--- |
| **Database Connection** | `curl -s http://127.0.0.1:8000/health/db` | `{"database":"connected"}` |
| **Backend Test Suite** | `PYTHONPATH=. pytest backend/tests -v` | **100+ tests passed** |
| **Mobile Test Suite** | `flutter test` | **58 tests passed** |
| **ADB Reverse Tunnel** | `adb reverse --list` | `UsbFfs tcp:8000 tcp:8000` |
| **Marketplace API** | `curl -s http://127.0.0.1:8000/marketplace/products` | JSON array of published crafts |

---

## 🛠️ Offline Troubleshooting

### 1. `adb reverse` Connection Drops
If the phone disconnects and reconnects, re-run:
```bash
adb reverse tcp:8000 tcp:8000
```

### 2. Physical Device on Local Wi-Fi (Without USB)
If you prefer running over local Wi-Fi without a USB cable:
1. Find your computer's local Wi-Fi IP address:
   ```bash
   ip addr show | grep -E "inet "
   # e.g., 10.221.235.31
   ```
2. Open the app $\rightarrow$ Go to `Profile` $\rightarrow$ `Settings` $\rightarrow$ `Advanced Server Settings`.
3. Enter `http://<YOUR_IP>:8000` and tap **Save**.
