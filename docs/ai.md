# AI & Machine Learning Architecture — SIH 2026 (#90)

## Overview
The AI layer for the Artisan Digital Business Platform is designed for **practical zero-cost deployment on modest hardware**, prioritizing authenticity, high speed, and explainability without hallucinating product attributes or requiring expensive cloud GPU services.

---

## 1. Stage 5: AI Image Enhancer & Studio

### 1.1 Architecture & Pipeline Flow
```text
Raw Photo Upload (JPEG/PNG/WEBP)
      │
      ▼
EXIF Orientation Normalization (`ImageOps.exif_transpose`)
      │
      ▼
Quality Enhancement (`ImageEnhancer`)
  ├── Gentle Auto-contrast (0.5% highlight/shadow cutoff)
  ├── Exposure / Brightness Boost (+4%)
  ├── Texture & Depth Contrast (+8%)
  ├── Natural Craft Vibrance (+6%)
  └── Unsharp Masking (radius=1.2, percent=115, threshold=3)
      │
      ▼
Background Isolation & Simplification (`BackgroundRemover`)
  ├── ModelBasedBackgroundRemover (Optional local U2Net/Rembg adapter)
  └── FallbackBackgroundRemover (Deterministic edge chroma thresholding & alpha smoothing)
      │
      ▼
E-Commerce Studio Standardization (`ECommerceFormatter`)
  ├── Standardized 1024x1024 Square Canvas
  ├── 84% Bounding Box Subject Scaling (No distortion or aspect cropping)
  ├── Exact Center Placement
  ├── Grounding Contact Shadow (Soft subtle ellipse at product base)
  └── Studio Theme Palette (Pure White #FFFFFF, Neutral Grey #F0F2F5, Warm Earth #FAF6F0)
      │
      ▼
Final Validation & Dual Storage
  ├── Original Archive (`uploads/originals/{uuid}_orig.jpg`)
  └── 1024x1024 E-commerce Studio Image (`uploads/processed/{uuid}_proc.jpg`)
```

### 1.2 Technical Realism & Fallback Transparency
- **Deterministic Heuristic vs. Deep Learning**:
  - The default pipeline runs on standard CPU hardware without external API credentials or heavy model downloads.
  - When the optional deep-learning segmentation model (`rembg`) is present, `ModelBasedBackgroundRemover` executes local inference.
  - When absent, `FallbackBackgroundRemover` safely analyzes border variance, extracts background chroma, and applies soft alpha edging. If the background is complex, it preserves the authentic photo boundaries rather than creating ragged/destructive artifacts.
- **Anti-Hallucination Guarantee**:
  - The image pipeline strictly enhances presentation lighting, contrast, and framing.
  - It **never** alters or hallucinates craft textures, patterns, shapes, colors, dimensions, or branding.

---

## 2. Stage 6: Multilingual AI Auto-Cataloger

### 2.1 Pipeline Flow
```text
Artisan Spoken Voice (Hindi / Odia / English / Regional)
      │
      ▼
Speech Transcription & Language Detection (`SpeechService`)
      │
      ▼
Fact Isolation & Entity Extraction (`CatalogGenerationService`)
  ├── Strict Verified Facts Extraction (Materials, Craft Technique, Colors, Days, Care)
  └── Anti-Hallucination Guardrails (Never invent dimensions, certifications, prices)
      │
      ▼
Multilingual Catalog Generator (`TranslationService`)
  ├── English E-Commerce Title & Heritage Storytelling
  ├── Hindi E-Commerce Title & Heritage Storytelling
  ├── Structured Highlight Bullets
  └── High-Intent SEO Keywords & Indian Craft Hashtags
      │
      ▼
Structured Preview & 1-Tap Form Auto-Fill
```

### 2.2 Anti-Hallucination Isolation Guarantee
- **Verified Facts Isolation**: Attributes explicitly spoken by the artisan (e.g., pure organic cotton, 18 days on pit loom, natural plant dyes) are tagged as `verified_facts` with 100% grounded integrity.
- **Strict Non-Fabrication**: Dimensions, certifications (e.g. GI tag), and prices are marked `None` if not mentioned in speech. The model will never guess or hallucinate these values.

---

## 3. Stage 7: Dynamic Pricing Assistant

### 3.1 Transparent Cost & Margin Engine
The dynamic pricing engine eliminates predatory middleman underpricing by computing true production cost and recommending 3 distinct, explainable retail tiers:

1. **Direct Production Cost ($C$)**:
   $$C = M_{cost} + (L_{hours} \times W_{living}) + O_{cost} + P_{transit}$$
   - $M_{cost}$: Raw materials (yarn, clay, brass, natural dyes).
   - $L_{hours}$: Dedicated handcrafting hours (or converted from spoken days: $D \times 6$ hrs/day).
   - $W_{living}$: Living wage base rate (₹90/hr benchmark).
   - $O_{cost}$: Overhead, kiln firing, loom depreciation.
   - $P_{transit}$: Eco-friendly packaging and transit buffer.

2. **Craft Complexity Multipliers ($\mu_{skill}$)**:
   - Simple ($1.00\times$)
   - Standard ($1.15\times$)
   - Intricate ($1.30\times$)
   - Masterpiece / GI Heritage ($1.50\times$)

3. **Explainable 3-Tier Price Matrix**:
   - 🟢 **Fair Base Price**: $C \times \mu_{skill} \times 1.25$ (Guarantees living wage + 25% safety margin).
   - 🌟 **Recommended E-Commerce Price**: $C \times \mu_{skill} \times 1.45$ (Optimal online sweet spot delivering 45% healthy net profit).
   - 👑 **Premium Heritage / Export Price**: $C \times \mu_{skill} \times 1.75$ (Exhibition, bespoke, and global export tier with 75% margin).


