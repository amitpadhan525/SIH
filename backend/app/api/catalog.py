from fastapi import APIRouter, File, HTTPException, UploadFile, status

from backend.app.schemas.catalog import (
    CatalogGenerateRequest,
    CatalogGenerateResponse,
    TranscriptionResponse,
    TranslationRequest,
    TranslationResponse,
)
from backend.app.ai.speech_service import SpeechService
from backend.app.ai.translation_service import TranslationService
from backend.app.ai.catalog_generator import CatalogGenerationService

router = APIRouter(prefix="/ai/catalog", tags=["AI Cataloging & Multilingual"])

speech_service = SpeechService()
translation_service = TranslationService()
catalog_service = CatalogGenerationService(translation_service=translation_service)


@router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    status_code=status.HTTP_200_OK,
    summary="Transcribe artisan voice input to text",
)
async def transcribe_audio(file: UploadFile = File(...)):
    """
    Accepts voice recording audio (WAV, MP3, M4A, WEBM, OGG),
    transcribes regional speech, and detects source language.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file must have a valid filename.",
        )

    audio_bytes = await file.read()
    if not audio_bytes or len(audio_bytes) < 16:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty or corrupted.",
        )

    try:
        transcript, lang, confidence, duration = speech_service.transcribe_audio(
            audio_bytes=audio_bytes,
            filename=file.filename,
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
