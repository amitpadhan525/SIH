# SIH Problem Statement #90: Project Memory & Progress Log

This document serves as the persistent state memory across development sessions for the SIH Problem Statement #90 project: **AI-Powered Digital Business Platform for Artisans and Micro-Entrepreneurs**.

---

## 📌 Completed Stages Summary

### ✅ Stage 1: Architecture & Repository Initialization
- Established multi-tier mono-repo: `backend/`, `mobile/`, `infrastructure/`, `docs/`, `ml/`, `web/`.
- Git repository initialized and configured with `.gitignore`.

### ✅ Stage 2: Database Foundation Layer
- **Stack**: Python 3.14 / 3.12, FastAPI, PostgreSQL 16 (with SQLite local dev fallback), SQLAlchemy 2.0 (mapped columns), Alembic, psycopg v3, Pydantic v2.
- **Relational Schema**:
  1. `users` (id, name, phone [unique], role, language, location, created_at)
  2. `artisans` (id, user_id [FK->users.id, unique], craft_type, created_at)
  3. `products` (id, artisan_id [FK->artisans.id], name, category, description, material, price [Numeric(12, 2)], status, created_at, updated_at)
  4. `product_images` (id, product_id [FK->products.id], original_url, processed_url, created_at)
- **Cascade Behavior**:
  - `User` → `Artisan`: 1-to-1 (`cascade="all, delete-orphan"`, `ON DELETE CASCADE`)
  - `Artisan` → `Products`: 1-to-many (`cascade="all, delete-orphan"`, `ON DELETE CASCADE`)
  - `Product` → `ProductImages`: 1-to-many (`cascade="all, delete-orphan"`, `ON DELETE CASCADE`)
- **Alembic Migrations**: Initial migration `backend/alembic/versions/0001_initial_database_foundation.py`.

### ✅ Stage 3: Product REST API
- **Router**: `backend/app/api/products.py` registered at `/products` with OpenAPI tag `Products`.
- **Endpoints**:
  - `POST /products`: 201 Created (Validates `artisan_id` existence, defaults status to `draft`, validates non-empty strings and non-negative Decimal prices).
  - `GET /products`: 200 OK (Pagination via `?page=1&page_size=20`, filtering via `?category=...&status=...&artisan_id=...`).
  - `GET /products/{id}`: 200 OK / 404 Not Found.
  - `PUT /products/{id}`: 200 OK (Updates editable fields; strictly forbids modifying `artisan_id` ownership).
  - `DELETE /products/{id}`: 204 No Content (Cascades to linked images).
- **Health Checks**: `GET /` and `GET /health/db`.

### ✅ Stage 4: Flutter Mobile App Foundation
- **Location**: `mobile/`
- **Stack**: Flutter 3.x, Dart, `http`, `intl`, `flutter_lints`.
- **Architecture**:
  - `core/constants/api_constants.dart`: Configurable API base URL defaulting to `http://10.0.2.2:8000` (Android emulator loopback) + image URL resolution.
  - `core/network/api_client.dart`: Centralized HTTP client with timeouts (10s), multipart file streaming, and user-friendly error translation.
  - `core/theme/app_theme.dart`: Accessible, warm terracotta palette (`#C85A32`, `#FAF8F5`) with large touch targets.
  - `core/utils/currency_formatter.dart`: Indian Rupee formatting (`₹650.00`) preserving exact decimal string precision (no IEEE-754 binary floating-point errors).
  - `models/product.dart`: Matches backend `ProductRead`/`ProductCreate`/`ProductUpdate` schemas.
  - `services/product_service.dart`: HTTP REST client for CRUD operations, multipart uploads, and DB health status.
  - **Screens**:
    1. `HomeScreen`: Welcome greeting, live backend connection indicator, total product count, quick actions.
    2. `ProductsScreen`: Product catalog, status filter chips (`All`, `Draft`, `Published`, `Archived`), pull-to-refresh, empty & error states.
    3. `AddProductScreen`: Form with live validation for name, category, price, material, description + Studio photo trigger.
    4. `ProductDetailScreen`: Product details view, studio photo gallery, in-place edit mode, delete confirmation modal.
  - **Tests**: `product_model_test.dart`, `product_service_test.dart`, `widget_test.dart`.

### ✅ Stage 5: AI Image Enhancer & Studio
- **Backend Infrastructure**:
  - `backend/app/services/storage_service.py`: Secure upload pipeline, 10MB limits, MIME/magic byte checks, Pillow pixel verification, path traversal defense, UUID naming, isolated storage under `uploads/`.
  - `backend/app/ai/image_processor.py`: Modular `ImageProcessor` with `BackgroundRemover` (model adapter + deterministic chroma thresholding fallback), `ImageEnhancer` (auto-contrast, unsharp mask, exposure/saturation tune), and `ECommerceFormatter` (1024x1024 square canvas, 84% bounding box centering, subtle grounding shadow, and studio theme palettes).
  - `backend/app/api/images.py`: Endpoints for `POST /products/{id}/images`, `GET /products/{id}/images`, `DELETE /products/{id}/images/{image_id}`, and `POST /ai/images/enhance` (standalone preview).
  - Static media mount at `/uploads` in `main.py`.
- **Mobile Studio Client**:
  - `ImageStudioScreen`: Artisan-friendly Photo Studio with live processing animation, interactive **BEFORE | AFTER** toggle, studio background palette switcher (`Pure White`, `Neutral Grey`, `Warm Studio`), and demo sample craft photos.
  - Integration with `ProductDetailScreen` (photo gallery + delete actions) and `AddProductScreen`.
  - `mobile/lib/models/product_image.dart` and multipart methods in `product_service.dart`.
### ✅ Stage 6: Multilingual AI Auto-Cataloger
- **Backend AI Engine & Services**:
  - `backend/app/ai/speech_service.py`: `SpeechService` with pluggable `SpeechRecognizerAdapter` and `FallbackAudioTranscriber` (audio duration reading, craft speech corpus detection).
  - `backend/app/ai/translation_service.py`: `TranslationService` with Indian language detection (Devanagari, Odia, Bengali, Tamil, Telugu) and craft keyword preservation (Ikat, Zari, Dokra, Madhubani, Terracotta, Saree, Handloom).
  - `backend/app/ai/catalog_generator.py`: `CatalogGenerationService` with strict anti-hallucination fact isolation (materials, technique, colors, time taken in days, care instructions, stated dimensions). Generates localized marketing copy (titles, hooks, heritage story, highlights, SEO keywords, hashtags).
  - `backend/app/schemas/catalog.py`: `TranscriptionResponse`, `CatalogGenerateRequest`, `VerifiedFacts`, `LocalizedContent`, `CatalogGenerateResponse`, `TranslationRequest`, `TranslationResponse`.
  - `backend/app/api/catalog.py`: Endpoints `POST /ai/catalog/transcribe`, `POST /ai/catalog/generate`, `POST /ai/catalog/translate`.
- **Mobile Voice Cataloging Client**:
  - `mobile/lib/screens/voice_catalog/voice_catalog_screen.dart`: Interactive screen with animated microphone listening state, quick craft voice demo chips, editable spoken transcript, anti-hallucination **Verified Facts Card**, multilingual language tabs (English / हिन्दी), and "Apply to Product" 1-tap form fill.
  - Integration with `mobile/lib/screens/add_product/add_product_screen.dart` via prominent "Speak to Auto-Fill Details 🎙️" launcher.
  - `mobile/lib/services/product_service.dart`: Added `transcribeAudio`, `generateCatalogContent`, and `translateText`.
### ✅ Stage 7: Dynamic Pricing Assistant
- **Backend AI Engine & APIs**:
  - `backend/app/schemas/pricing.py`: `CostBreakdownInput`, `PricingCalculateRequest`, `PriceTier`, `PricingCalculateResponse`.
  - `backend/app/ai/pricing_engine.py`: `DynamicPricingEngine` with direct production cost calculations ($C = M + L + O + P$), living wage baseline (₹90/hr), craft complexity factors (1.0x to 1.5x), and transparent 3-tier price recommendations (Fair Base: +25% margin, Recommended Market: +45% margin, Premium Heritage / Export: +75% margin).
  - `backend/app/api/pricing.py`: Endpoints `POST /ai/pricing/calculate` and `GET /ai/pricing/benchmarks`.
- **Mobile Pricing Client**:
  - `mobile/lib/screens/pricing_calculator/pricing_calculator_screen.dart`: Interactive calculator with material cost input, working hours/days chips, living wage rate adjustments, craft intricacy chips, market benchmark banner, and 3-Tier Price Cards with live profit breakdown.
  - Integration with `mobile/lib/screens/add_product/add_product_screen.dart` via "💡 AI Calculate" helper button next to the Price field.
  - `mobile/lib/services/product_service.dart`: Added `calculatePricing` and `getPricingBenchmarks`.
### ✅ Stage 8: Marketplace + B2B Buyer Layer
- **Backend Models & APIs**:
  - `backend/app/models/inquiry.py`: `Inquiry` model (`id`, `product_id`, `buyer_name`, `buyer_email`, `buyer_phone`, `buyer_type`, `quantity`, `target_price`, `message`, `status`, `created_at`, `updated_at`).
  - Migration: `0002_add_inquiries_table.py` applied to database.
  - `backend/app/api/inquiries.py`: Endpoints `POST /products/{id}/inquiries` (buyer leads submission), `GET /artisans/{id}/inquiries` (artisan inbox), and `PUT /inquiries/{id}/status` (lifecycle update).
  - `backend/app/api/marketplace.py`: Endpoints `GET /marketplace/products` (public discovery feed with search, category, and price filters), `GET /marketplace/export/ondc/{id}` (ONDC retail protocol JSON export), and `GET /marketplace/export/gem/{id}` (Government e-Marketplace procurement schema).
- **Mobile B2B Leads Client**:
  - `mobile/lib/screens/inquiries/inquiries_screen.dart`: Artisan Inquiries Inbox with filter chips (`All`, `Pending`, `Contacted`, `Accepted`, `Declined`), quantity, target price, and status transition buttons.
  - Integration with `mobile/lib/screens/home/home_screen.dart` via **"Buyer Leads & Inquiries"** action button.
  - `mobile/lib/services/product_service.dart`: Added `getArtisanInquiries`, `updateInquiryStatus`, `getOndcExport`, and `getGemExport`.
- **Documentation**: `docs/api.md`, `README.md`.

---

## 🧪 Test Verification Status

- **Backend Pytest Suite**: **59 / 59 tests passing** (100% pass rate):
  - `test_marketplace_api.py`: 6 tests (inquiry submit, 404 handler, artisan inbox, status updates, public discovery feed, ONDC export, GeM export).
  - `test_pricing_api.py`: 4 tests.
  - `test_catalog_api.py`: 7 tests.
  - `test_database.py`: 6 tests.
  - `test_health.py`: 3 tests.
  - `test_images_api.py`: 14 tests.
  - `test_migrations.py`: 1 test.
  - `test_products_api.py`: 18 tests.

- **Flutter Mobile Suite**: **26 / 26 tests passing** (100% pass rate, `flutter analyze` 0 issues):
  - `inquiries_test.dart`: 3 tests (UI rendering, status update, empty state).
  - `pricing_calculator_test.dart`: 2 tests.
  - `voice_catalog_test.dart`: 3 tests.
  - `image_studio_test.dart`: 5 tests.
  - `product_model_test.dart`: 4 tests.
  - `product_service_test.dart`: 6 tests.
  - `widget_test.dart`: 3 tests.

- **Android Device & APK Status**:
  - Debug APK built and installed on connected physical device: **moto g54 5G** (`ZD222H7659`).
  - Binary location: `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

---

## 💻 Commands Reference

### Run Backend
```bash
cd /home/amit/github/SIH
source backend/.venv/bin/activate
PYTHONPATH=. uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```
Interactive Swagger UI: 👉 `http://localhost:8000/docs`

### Run Backend Tests
```bash
cd /home/amit/github/SIH
source backend/.venv/bin/activate
PYTHONPATH=. pytest backend/tests -v
```

### Run Flutter Mobile App
```bash
cd /home/amit/github/SIH/mobile
export PATH="/home/amit/development/flutter/bin:$PATH"
flutter run -d ZD222H7659 --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000

# Run Flutter tests:
flutter test
flutter analyze
```

---

### ✅ Stage 9: Artisan Profiles, Role-Based Access & Simple Auth
- **Backend Security & Auth APIs**:
  - `backend/app/core/security.py`: Password hashing with PBKDF2/SHA256, JWT token encoding and decoding with expiration checking.
  - `backend/app/schemas/auth.py`: `UserRegisterRequest`, `UserLoginRequest`, `SendOtpRequest`, `VerifyOtpRequest`, `TokenResponse`, `UserProfileResponse`.
  - `backend/app/api/auth.py`: Endpoints `POST /auth/register`, `POST /auth/login`, `POST /auth/otp/send`, `POST /auth/otp/verify`, and `GET /auth/me`.
- **Mobile Auth Client**:
  - `mobile/lib/screens/auth/login_screen.dart`: Phone OTP login + Password mode + 1-tap "SIH Evaluator Quick Access" demo button + Artisan Profile Card.
  - Linked to `HomeScreen` top AppBar profile action icon.
  - `mobile/lib/services/product_service.dart`: Added `register`, `login`, `sendOtp`, `verifyOtp`, and `getMe`.
  - `mobile/test/auth_test.dart`: Unit tests for mobile auth operations.

### ✅ Stage 10: Offline-First Resilience & Sync Queue
- **Backend Sync APIs**:
  - `backend/app/schemas/sync.py`: `SyncBatchRequest`, `SyncBatchResponse`, `SyncActionItem`, `SyncActionResponse`, `SyncDeltaResponse`.
  - `backend/app/api/sync.py`: `POST /sync/batch` with strict client UUID idempotency (caches processed actions to prevent duplicate writes on reconnect) and `GET /sync/delta` for low-bandwidth incremental sync.
- **Mobile Sync Queue**:
  - `mobile/lib/services/sync_service.dart`: Queue manager for offline product creation, update, and inquiry status changes.
  - `mobile/lib/services/product_service.dart`: `syncBatch` and `getSyncDelta`.
  - `HomeScreen`: Visual status banner ("Connected & Cloud-Synced" / "Offline Mode") and one-tap manual sync button with pending count badge.
  - `mobile/test/sync_test.dart`: Unit tests for offline queuing and batch flushing.

### ✅ Stage 11: Web Admin & Buyer Discovery Portal
- **Interactive Single-Page Application**:
  - `backend/app/static/admin/index.html`: Responsive Web Admin dashboard featuring:
    - Live metric counters (Total Artisans, Cataloged Crafts, Total Catalog Value in INR, Buyer Inquiries, ONDC/GeM export readiness).
    - Craft category distribution and living-wage economic impact bar charts.
    - Product catalog explorer with live ONDC JSON viewer and GeM procurement payload modals.
    - Wholesale inquiry management table with inline status transitions (`Contacted`, `Accepted`, `Declined`).
    - Public discovery feed grid for buyers.
- **Backend Admin APIs**:
  - `backend/app/api/admin.py`: `GET /admin/stats` (aggregate metrics) and `GET /admin/portal` (serves the dashboard HTML).
  - `backend/tests/test_admin_api.py`: Unit tests for stats endpoint and portal HTML delivery.

### ✅ Stage 12: Final Integration, Polish & SIH Demo Readiness
- **Complete End-to-End Artisan Journey**:
  1. 📸 **Image Studio**: Captures photo, removes background, enhances lighting, standardizes to 1024x1024 square with Before/After preview.
  2. 🎙️ **Voice Auto-Cataloger**: Speech-to-text in Indian vernaculars/dialects, anti-hallucination fact isolation, bilingual Hindi/English copy generation.
  3. 💡 **Dynamic Pricing Assistant**: Direct cost + living wage + craft intricacy with 3-tier price cards.
  4. 🌐 **Marketplace & B2B Leads**: Public discovery feed, RFQ wholesale lead inbox with status lifecycle management.
  5. 📦 **Government & Retail Interoperability**: Instant ONDC Protocol JSON and GeM public procurement schema exports.
  6. 🔑 **Simple Auth & Artisan Profiles**: SMS OTP authentication and SIH Evaluator one-tap login.
  7. 📡 **Offline-First Resilience**: Automatic queueing of offline drafts and idempotent batch sync.
  8. 🖥️ **Web Admin Portal**: Rich real-time dashboard for supervisors, cooperative leaders, and evaluators.

---

## 🧪 Test Verification Status

- **Backend Pytest Suite**: **70 / 70 tests passing** (100% pass rate):
  - `test_products_api.py`: 18 tests
  - `test_images_api.py`: 13 tests
  - `test_catalog_api.py`: 7 tests
  - `test_pricing_api.py`: 4 tests
  - `test_marketplace_api.py`: 6 tests
  - `test_auth_api.py`: 6 tests
  - `test_sync_api.py`: 3 tests
  - `test_admin_api.py`: 2 tests
  - `test_database.py`: 6 tests
  - `test_health.py`: 3 tests
  - `test_migrations.py`: 2 tests

- **Flutter Mobile Suite**: **32 / 32 tests passing** (100% pass rate, `flutter analyze` 0 issues):
  - `product_model_test.dart`: 4 tests
  - `product_service_test.dart`: 5 tests
  - `image_studio_test.dart`: 4 tests
  - `voice_catalog_test.dart`: 4 tests
  - `pricing_calculator_test.dart`: 4 tests
  - `inquiries_test.dart`: 4 tests
  - `auth_test.dart`: 3 tests
  - `sync_test.dart`: 3 tests
  - `widget_test.dart`: 5 tests

- **Android Device & APK Status**:
  - Debug APK built and installed on connected physical device: **moto g54 5G** (`ZD222H7659`).
  - Binary location: `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

---

## 💻 Commands Reference

### Run Backend
```bash
cd /home/amit/github/SIH
source backend/.venv/bin/activate
PYTHONPATH=. uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```
- Interactive Swagger UI: 👉 `http://localhost:8000/docs`
- Web Admin Portal: 👉 `http://localhost:8000/admin/portal`

### Run Backend Tests
```bash
cd /home/amit/github/SIH
source backend/.venv/bin/activate
PYTHONPATH=. pytest backend/tests -v
```

### Run Flutter Mobile App
```bash
cd /home/amit/github/SIH/mobile
export PATH="/home/amit/development/flutter/bin:$PATH"
flutter run -d ZD222H7659 --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000

# Run Flutter tests & analyzer:
flutter test
flutter analyze
```
