# REST API Specification — SIH 2026 (#90)

Base URL: `http://localhost:8000` (or `http://10.0.2.2:8000` on Android emulator)
Interactive Swagger Docs: `http://localhost:8000/docs`

---

## Products API (`/products`)

### `GET /products`
- **Description**: Returns paginated list of products.
- **Query Params**: `page` (default: 1), `page_size` (default: 20), `category`, `status`, `artisan_id`.
- **Response**: `200 OK` -> `List[ProductRead]`

### `POST /products`
- **Description**: Creates a new artisan product.
- **Body**: `ProductCreate` (`artisan_id`, `name`, `category`, `price`, `description`, `material`, `status`).
- **Response**: `201 Created` -> `ProductRead`

### `GET /products/{id}`
- **Description**: Retrieves single product details.
- **Response**: `200 OK` / `404 Not Found`

### `PUT /products/{id}`
- **Description**: Updates product attributes (ownership `artisan_id` is immutable).
- **Body**: `ProductUpdate`
- **Response**: `200 OK` / `404 Not Found`

### `DELETE /products/{id}`
- **Description**: Deletes product and cascades deletion to linked `ProductImage` records.
- **Response**: `204 No Content` / `404 Not Found`

---

## Product Images API (`/products/{product_id}/images`)

### `POST /products/{product_id}/images`
- **Description**: Securely uploads and enhances a product photograph.
- **Form Data**:
  - `file`: Multipart binary file (JPEG, PNG, WEBP, max 10MB).
  - `background_mode`: Query param (`white` [default], `grey`, `warm`).
- **Response**: `201 Created`
  ```json
  {
    "id": 1,
    "product_id": 101,
    "original_url": "/uploads/originals/a1b2c3d4_orig.jpg",
    "processed_url": "/uploads/processed/a1b2c3d4_proc.jpg",
    "created_at": "2026-09-09T18:00:00Z"
  }
  ```
- **Error Codes**:
  - `400 Bad Request`: Corrupted, invalid format, or SVG/HTML payload.
  - `404 Not Found`: Product ID does not exist.
  - `413 Payload Too Large`: Upload exceeds 10MB.

### `GET /products/{product_id}/images`
- **Description**: Lists all photos associated with a product.
- **Response**: `200 OK` -> `List[ProductImageRead]`

### `DELETE /products/{product_id}/images/{image_id}`
- **Description**: Deletes the database record and removes original and processed files from storage.
- **Response**: `204 No Content` / `404 Not Found`

---

## Standalone AI Studio Preview (`/ai/images/enhance`)

### `POST /ai/images/enhance`
- **Description**: Processes a photograph and returns instant 1024x1024 studio preview without saving to the product database.
- **Form Data**: `file` (Multipart image), `background_mode` (`white`, `grey`, `warm`).
- **Response**: `200 OK`
  ```json
  {
    "original_url": "/uploads/previews/uuid_orig.jpg",
    "processed_url": "/uploads/previews/uuid_proc.jpg",
    "width": 1024,
    "height": 1024,
    "background_mode": "white",
    "pipeline_stages": [
      "exif_transpose",
      "autocontrast",
      "lighting_tune",
      "unsharp_mask",
      "background_isolation",
      "ecommerce_1024_square_canvas"
    ]
  }
  ```

---

## AI Auto-Cataloger & Multilingual API (`/ai/catalog`)

### `POST /ai/catalog/transcribe`
- **Description**: Accepts audio recordings (WAV, MP3, M4A, WEBM, OGG) and transcribes artisan speech.
- **Form Data**: `file` (Multipart audio file).
- **Response**: `200 OK` -> `TranscriptionResponse` (`transcript`, `detected_language`, `confidence`, `duration_seconds`).

### `POST /ai/catalog/generate`
- **Description**: Extracts verified facts (strict anti-hallucination) and generates structured multilingual marketing copy.
- **Body**: `CatalogGenerateRequest` (`text`, `source_language`, `target_languages`, `artisan_notes`).
- **Response**: `200 OK` -> `CatalogGenerateResponse` (`verified_facts`, `content`, `suggested_tags`, `seo_keywords`, `confidence_score`, `anti_hallucination_passed`).

### `POST /ai/catalog/translate`
- **Description**: Translates artisan craft text while preserving authentic cultural and technique terms (e.g. *Ikat*, *Dokra*, *Madhubani*).
- **Body**: `TranslationRequest` (`text`, `source_language`, `target_language`).
- **Response**: `200 OK` -> `TranslationResponse` (`original_text`, `source_language`, `target_language`, `translated_text`).

---

## AI Dynamic Pricing Assistant API (`/ai/pricing`)

### `POST /ai/pricing/calculate`
- **Description**: Computes fair production cost and generates 3-tier retail prices with explainable margins.
- **Body**: `PricingCalculateRequest` (`category`, `cost_breakdown`, `craft_complexity`, `market_channel`, `artisan_stated_days`).
- **Response**: `200 OK` -> `PricingCalculateResponse` (`total_cost`, `material_cost`, `labor_cost`, `suggested_price`, `tiers`, `pricing_explanation`, `category_benchmark_range`).

### `GET /ai/pricing/benchmarks`
- **Description**: Returns category reference price ranges and default living wage standards.
- **Response**: `200 OK` (`categories`, `default_hourly_living_wage`, `complexity_multipliers`).


