# 🏺 Artisan Studio AI — SIH 2026 Problem Statement #90
> **PS Number**: SIH26090  
> **Theme**: AI-driven digital commerce platform for marginalized artisans & micro-entrepreneurs.  
> **Core Concept**: `PHOTO ➔ SPEAK ➔ AI PROCESSES ➔ REVIEW ➔ PUBLISH` (Zero digital literacy barrier).

---

## 🌟 Solution Architecture & Implemented Stages (1 – 12)

```
                       ┌────────────────────────────────────────────────────────┐
                       │                   ARTISAN MOBILE APP                   │
                       │           (Flutter 3.x / Dart / Android)               │
                       └──────────────────────────┬─────────────────────────────┘
                                                  │
                                 REST / JSON / Multipart HTTP (10s Timeout)
                                                  │
                       ┌──────────────────────────▼─────────────────────────────┐
                       │                FASTAPI BACKEND CORE                    │
                       │   (Python 3.14 / Pydantic v2 / SQLAlchemy 2.0 ORM)     │
                       └─────┬──────────────┬──────────────┬──────────────┬─────┘
                             │              │              │              │
       ┌─────────────────────┼──────────────┼──────────────┼──────────────┼─────────────────────┐
       │                     │              │              │              │                     │
┌──────▼──────┐       ┌──────▼──────┐ ┌─────▼─────┐ ┌──────▼──────┐ ┌─────▼─────┐       ┌──────▼──────┐
│  AI Image   │       │  AI Voice   │ │  Dynamic  │ │ Marketplace │ │  Offline  │       │  Web Admin  │
│   Studio    │       │ Cataloger   │ │  Pricing  │ │  & Inquiries│ │Sync Queue │       │  Dashboard  │
│ (1024x1024  │       │(Vernacular  │ │ (Living   │ │ (ONDC / GeM │ │(Idempotent│       │ (Analytics &│
│ Chroma/BG)  │       │ Fact Match) │ │  Wage/COGS│ │ Interoper.) │ │Batch Sync)│       │ Supervison) │
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

## 🚀 Key Feature Modules

| Module | Purpose & Artisan Impact | Endpoints / Screens |
| :--- | :--- | :--- |
| **1. Product Foundation** | High-precision catalog management with zero floating-point arithmetic errors. | `POST /products`, `GET /products`, `HomeScreen`, `ProductsScreen` |
| **2. AI Image Studio** | Converts raw phone photos into 1024x1024 studio-quality catalog shots with background removal & centering. | `POST /ai/images/enhance`, `ImageStudioScreen` |
| **3. Voice Cataloger** | Speech-to-text in Indian vernaculars, strict anti-hallucination fact isolation, bilingual Hindi/English copy. | `POST /ai/catalog/transcribe`, `POST /ai/catalog/generate`, `VoiceCatalogScreen` |
| **4. Dynamic Pricing Assistant** | Transparent cost calculation ($M + L + O + P$), living wage baseline (₹90/hr), and 3-tier price cards. | `POST /ai/pricing/calculate`, `PricingCalculatorScreen` |
| **5. Marketplace & B2B Leads** | Public discovery feed, RFQ wholesale lead inbox with status management (`Contacted`, `Accepted`, `Declined`). | `GET /marketplace/products`, `POST /products/{id}/inquiries`, `InquiriesScreen` |
| **6. ONDC & GeM Interoperability** | One-click protocol export compliant with Beckn / ONDC retail and GeM public procurement schemas. | `GET /marketplace/export/ondc/{id}`, `GET /marketplace/export/gem/{id}` |
| **7. Simple Auth & Profiles** | Mobile phone SMS OTP authentication with 1-tap SIH Evaluator quick login and verified artisan profile cards. | `POST /auth/otp/send`, `POST /auth/otp/verify`, `LoginScreen` |
| **8. Offline-First Sync** | Idempotent batch action queue with client UUID deduplication for low-connectivity craft clusters. | `POST /sync/batch`, `GET /sync/delta`, `SyncService` |
| **9. Web Admin Portal** | Responsive dashboard for cooperative supervisors and evaluators with live analytics and protocol modals. | `GET /admin/stats`, `GET /admin/portal` |

---

## 🧪 Automated Verification & Test Metrics

- **Backend Pytest Test Suite**: **70 / 70 tests passing (100%)**
- **Flutter Mobile Test Suite**: **32 / 32 tests passing (100%)**
- **Static Analysis**: `flutter analyze` ➔ **0 issues found**
- **Physical Device Deployment**: Installed on **moto g54 5G** (`ZD222H7659`) via `adb install -r`.

---

## 💻 Quick Start & Run Commands

### 1. Start Database & Backend
```bash
cd /home/amit/github/SIH
docker-compose up -d
source backend/.venv/bin/activate
PYTHONPATH=. uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```
- 📖 **Interactive Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- 📊 **Web Admin Portal**: [http://localhost:8000/admin/portal](http://localhost:8000/admin/portal)

### 2. Run Backend Tests
```bash
cd /home/amit/github/SIH
source backend/.venv/bin/activate
PYTHONPATH=. pytest backend/tests -v
```

### 3. Run or Build Mobile App (Android)
```bash
cd /home/amit/github/SIH/mobile
export PATH="/home/amit/development/flutter/bin:$PATH"

# Run tests
flutter test
flutter analyze

# Build & Run on connected Android device:
flutter run -d ZD222H7659 --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000

# Build APK:
flutter build apk --debug --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000
```