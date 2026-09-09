# Security & Media Upload Protections — SIH 2026 (#90)

## 1. File Upload Defense-in-Depth

The media storage and processing layer implements rigorous OWASP file upload defense controls:

### 1.1 Strict File Size Enforcement
- File uploads are hard-capped at **10 MB** (`MAX_UPLOAD_SIZE_BYTES = 10485760`).
- Oversized requests are immediately rejected before full buffer processing to prevent Denial-of-Service (DoS) and memory exhaustion.

### 1.2 MIME & Magic Signature Verification
- Client-supplied `Content-Type` and filename extensions are **never trusted blindly**.
- Byte-level headers are inspected for valid binary signatures:
  - JPEG: `\xff\xd8\xff`
  - PNG: `\x89PNG\r\n\x1a\n`
  - WEBP: `RIFF....WEBP`
- Payloads containing SVG (`<svg>`), XML (`<?xml>`), HTML (`<html>`), or JavaScript (`<script>`) are rejected immediately.

### 1.3 Pillow Pixel Decoding Validation
- All uploaded bytes undergo dual-pass verification (`Image.open().verify()` followed by full `Image.open().load()`).
- Decompression bombs and corrupted/truncated images are detected and safely rejected.

### 1.4 Path Traversal Defense & Isolation
- User-supplied filenames are **never** used to determine disk destination paths.
- Files are saved using crypto-safe UUID4 strings: `{uuid4().hex}_orig.{ext}` and `{uuid4().hex}_proc.jpg`.
- Target paths are resolved and validated to ensure they remain strictly within the isolated `uploads/` boundary.

### 1.5 Isolated Static File Serving
- Static media routes are strictly scoped to the `uploads/` directory.
- No source code, config files, `.env`, SQLite DB files, or system directories are accessible via HTTP.
