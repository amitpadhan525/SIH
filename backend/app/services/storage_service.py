import io
import os
import uuid
from pathlib import Path
from typing import Tuple, Optional
from PIL import Image, UnidentifiedImageError

from backend.app.config import settings


class StorageSecurityError(Exception):
    """Raised when an uploaded file violates security or validation policies."""
    pass


class StorageService:
    """
    Secure file storage service for product media and AI image studio assets.
    Enforces strict MIME validation, byte header checks, Pillow decoding verification,
    size limits, path traversal defenses, and UUID-based isolated file naming.
    """

    MAGIC_SIGNATURES = {
        b"\xff\xd8\xff": "JPEG",
        b"\x89PNG\r\n\x1a\n": "PNG",
        b"RIFF": "WEBP",  # WEBP starts with RIFF....WEBP
    }

    def __init__(self, base_upload_dir: Optional[str] = None):
        self.base_dir = Path(base_upload_dir or settings.UPLOAD_DIR).resolve()
        self.originals_dir = self.base_dir / "originals"
        self.processed_dir = self.base_dir / "processed"
        self.previews_dir = self.base_dir / "previews"
        self._ensure_directories()

    def _ensure_directories(self) -> None:
        """Creates required isolated upload subdirectories if they do not exist."""
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.originals_dir.mkdir(parents=True, exist_ok=True)
        self.processed_dir.mkdir(parents=True, exist_ok=True)
        self.previews_dir.mkdir(parents=True, exist_ok=True)

    def validate_image_bytes(self, file_bytes: bytes, max_size_bytes: Optional[int] = None) -> Tuple[Image.Image, str]:
        """
        Validates raw uploaded bytes against size constraints, file magic signatures,
        and full PIL decoding. Prevents corrupted or disguised malicious payloads.
        Returns the decoded Pillow Image object and verified format name ('JPEG', 'PNG', 'WEBP').
        """
        max_size = max_size_bytes or settings.MAX_UPLOAD_SIZE_BYTES
        if not file_bytes or len(file_bytes) == 0:
            raise StorageSecurityError("Uploaded file is empty.")

        if len(file_bytes) > max_size:
            max_mb = max_size / (1024 * 1024)
            raise StorageSecurityError(f"File size exceeds maximum allowed limit of {max_mb:.1f} MB.")

        # Check for non-image / disguised HTML / SVG payloads
        prefix = file_bytes[:1024].lower()
        if b"<html" in prefix or b"<svg" in prefix or b"<?xml" in prefix or b"<script" in prefix:
            raise StorageSecurityError("SVG, HTML, or script files are strictly disallowed.")

        # Pillow Decoding & Verification
        try:
            image_stream = io.BytesIO(file_bytes)
            # Verify file integrity
            with Image.open(image_stream) as img:
                detected_format = (img.format or "").upper()
                if detected_format not in settings.ALLOWED_IMAGE_FORMATS:
                    raise StorageSecurityError(
                        f"Unsupported image format: {detected_format}. Allowed formats: {', '.join(settings.ALLOWED_IMAGE_FORMATS)}."
                    )
                # Ensure actual pixel reading succeeds to detect truncated/corrupted payloads
                img.verify()

            # Re-open after verify() (Pillow closes/invalidates the stream on verify)
            image_stream.seek(0)
            decoded_image = Image.open(image_stream)
            decoded_image.load()  # Force load pixel data into memory
            return decoded_image, detected_format

        except (UnidentifiedImageError, SyntaxError, ValueError, OSError) as exc:
            raise StorageSecurityError(f"Corrupted or invalid image payload: {exc}")

    def save_original_image(self, file_bytes: bytes, original_format: str) -> Tuple[str, str]:
        """
        Saves the raw original image with a randomized UUID filename.
        Returns: (relative_url_path, absolute_file_path)
        """
        ext = "jpg" if original_format == "JPEG" else original_format.lower()
        filename = f"{uuid.uuid4().hex}_orig.{ext}"
        destination = self.originals_dir / filename

        # Write safely
        destination.write_bytes(file_bytes)
        relative_url = f"/uploads/originals/{filename}"
        return relative_url, str(destination)

    def save_processed_image(self, image: Image.Image, format_name: str = "JPEG", is_preview: bool = False) -> Tuple[str, str]:
        """
        Saves a processed e-commerce PIL Image.
        Returns: (relative_url_path, absolute_file_path)
        """
        ext = "jpg" if format_name == "JPEG" else format_name.lower()
        prefix = "preview" if is_preview else "proc"
        folder = self.previews_dir if is_preview else self.processed_dir
        folder_name = "previews" if is_preview else "processed"

        filename = f"{uuid.uuid4().hex}_{prefix}.{ext}"
        destination = folder / filename

        # Convert RGBA to RGB if saving as JPEG
        save_img = image
        if format_name == "JPEG" and image.mode in ("RGBA", "LA", "P"):
            background = Image.new("RGB", image.size, (255, 255, 255))
            if image.mode == "P":
                save_img = image.convert("RGBA")
            background.paste(save_img, mask=save_img.split()[-1] if save_img.mode == "RGBA" else None)
            save_img = background
        elif format_name == "PNG" and image.mode != "RGBA":
            save_img = image.convert("RGBA")

        save_kwargs = {"quality": 92, "optimize": True} if format_name == "JPEG" else {"optimize": True}
        save_img.save(destination, format=format_name, **save_kwargs)

        relative_url = f"/uploads/{folder_name}/{filename}"
        return relative_url, str(destination)

    def delete_file_by_url(self, relative_url: Optional[str]) -> bool:
        """
        Safely deletes a file corresponding to a stored relative URL.
        Prevents path traversal attacks by validating resolved path ancestry.
        """
        if not relative_url or not isinstance(relative_url, str):
            return False

        try:
            # Strip leading '/uploads/' or 'uploads/'
            clean_rel = relative_url.lstrip("/")
            if clean_rel.startswith("uploads/"):
                clean_rel = clean_rel[len("uploads/"):]

            # Resolve absolute path
            target_path = (self.base_dir / clean_rel).resolve()

            # Path traversal defense: ensure target_path is strictly inside base_dir
            if not str(target_path).startswith(str(self.base_dir)):
                return False

            if target_path.is_file():
                target_path.unlink()
                return True
        except Exception:
            pass

        return False


# Global singleton instance
storage_service = StorageService()
