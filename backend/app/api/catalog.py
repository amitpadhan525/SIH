import os
import re
from fastapi import APIRouter, File, HTTPException, UploadFile, status

from backend.app.config import settings
from backend.app.schemas.catalog import (
    CatalogGenerateRequest,
    CatalogGenerateResponse,
    TranscriptionResponse,
    TranslationRequest,
    TranslationResponse,
)
from backend.app.ai.speech_service import SpeechToTextService, STTUnavailableError
from backend.app.ai.translation_service import TranslationService
from backend.app.ai.catalog_generator import CatalogGenerationService

router = APIRouter(prefix="/ai/catalog", tags=["AI Cataloging & Multilingual"])
ai_router = APIRouter(prefix="/ai", tags=["Speech Recognition"])

speech_service = SpeechToTextService()
translation_service = TranslationService()
catalog_service = CatalogGenerationService(translation_service=translation_service)

ALLOWED_AUDIO_EXTENSIONS = {".wav", ".mp3", ".m4a", ".aac", ".webm", ".ogg", ".flac"}


def validate_audio_file(audio_bytes: bytes, filename: str) -> None:
    """
    Validates audio file size, extension, MIME/magic bytes, and rejects malformed/path-traversal uploads.
    """
    if not filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must have a valid filename.",
        )

    # Sanitize filename & check for path traversal
    if ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid filename: Path traversal characters are not permitted.",
        )

    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_AUDIO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported audio format '{ext}'. Allowed formats: {', '.join(sorted(ALLOWED_AUDIO_EXTENSIONS))}",
        )

    # Validate size
    if len(audio_bytes) > settings.MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE if hasattr(status, "HTTP_413_CONTENT_TOO_LARGE") else status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Audio file exceeds maximum allowed size of {settings.MAX_UPLOAD_SIZE_BYTES // (1024 * 1024)}MB.",
        )

    if len(audio_bytes) < 16:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty or too short to be valid.",
        )

    # Magic byte validation
    is_valid = False
    if ext == ".wav":
        is_valid = audio_bytes[:4] == b"RIFF" and b"WAVE" in audio_bytes[:16]
    elif ext == ".mp3":
        is_valid = audio_bytes[:3] == b"ID3" or (audio_bytes[0] == 0xFF and (audio_bytes[1] & 0xE0) == 0xE0)
    elif ext in [".m4a", ".aac"]:
        is_valid = (b"ftyp" in audio_bytes[:16]) or (audio_bytes[:2] in [b"\xff\xf1", b"\xff\xf9"])
    elif ext == ".ogg":
        is_valid = audio_bytes[:4] == b"OggS"
    elif ext == ".flac":
        is_valid = audio_bytes[:4] == b"fLaC"
    elif ext == ".webm":
        is_valid = audio_bytes[:4] == b"\x1a\x45\xdf\xa3"

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Uploaded file header does not match expected {ext} audio magic bytes.",
        )


async def _handle_transcription(file: UploadFile) -> TranscriptionResponse:
    audio_bytes = await file.read()
    validate_audio_file(audio_bytes, file.filename or "recording.wav")

    try:
        transcript, lang, confidence, duration = speech_service.transcribe_audio(
            audio_bytes=audio_bytes,
            filename=file.filename or "recording.wav",
        )
    except STTUnavailableError as stt_err:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"{stt_err.error_code}: {str(stt_err)}",
        )
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(ve),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Speech transcription failed: {str(e)}",
        )

    return TranscriptionResponse(
        transcript=transcript,
        detected_language=lang,
        confidence=confidence,
        duration_seconds=duration,
    )


@ai_router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Transcribe artisan voice input to text",
)
async def transcribe_audio_primary(file: UploadFile = File(...)):
    """Primary voice transcription endpoint with magic byte security validation."""
    return await _handle_transcription(file)


@router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Transcribe artisan voice input to text (backward compatibility)",
)
async def transcribe_audio_compat(file: UploadFile = File(...)):
    """Backward compatibility transcription endpoint."""
    return await _handle_transcription(file)


@router.post(
    "/generate",
    response_model=CatalogGenerateResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate structured multilingual catalog with verified facts",
)
def generate_catalog_content(request: CatalogGenerateRequest):
    """
    Takes artisan speech transcript, extracts verified facts (materials, craft technique,
    colors, days taken), and generates structured multilingual marketing copy.
    """
    if not request.text.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transcript text cannot be empty.",
        )

    try:
        response = catalog_service.generate_catalog(
            transcript=request.text,
            source_language=request.source_language,
            target_languages=request.target_languages,
            artisan_notes=request.artisan_notes,
        )
        return response
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Catalog generation failed: {str(e)}",
        )


@router.post(
    "/translate",
    response_model=TranslationResponse,
    status_code=status.HTTP_200_OK,
    summary="Translate text across Indian languages preserving craft terminology",
)
def translate_text(request: TranslationRequest):
    """
    Translates artisanal text while preserving authentic craft keywords.
    """
    try:
        translated = translation_service.translate_text(
            text=request.text,
            source_lang=request.source_language,
            target_lang=request.target_language,
        )
        return TranslationResponse(
            original_text=request.text,
            source_language=request.source_language,
            target_language=request.target_language,
            translated_text=translated,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Translation failed: {str(e)}",
        )
