import io
import os
import re
import tempfile
import time
import uuid
import wave
from typing import Optional, Protocol, Tuple

from backend.app.config import settings


class STTUnavailableError(Exception):
    """Raised when the local Speech-to-Text provider/model is not available or configured."""
    def __init__(self, message: str = "Local Speech-to-Text model is not configured or unavailable."):
        super().__init__(message)
        self.error_code = "LOCAL_STT_MODEL_UNAVAILABLE"


class SpeechToTextProvider(Protocol):
    """Protocol for speech-to-text providers (Local Whisper, etc.)."""

    def is_available(self) -> bool:
        """Returns True if the underlying model is loaded or accessible."""
        ...

    def transcribe(self, audio_bytes: bytes, filename: str) -> Tuple[str, str, Optional[float], float]:
        """
        Transcribes audio data.
        Returns: (transcript, detected_language, confidence_or_none, duration_seconds)
        """
        ...


class LocalWhisperProvider:
    """
    Local CPU/GPU Whisper Speech-to-Text provider.
    Uses locally configured Whisper/faster-whisper model weights without cloud or paid APIs.
    """

    def __init__(self, model_path: Optional[str] = None, model_name: Optional[str] = None):
        self.model_path = model_path or getattr(settings, "WHISPER_MODEL_PATH", None)
        self.model_name = model_name or getattr(settings, "WHISPER_MODEL_NAME", "base")
        self._model = None
        self._load_attempted = False

    def _try_load_model(self):
        if self._load_attempted:
            return self._model
        self._load_attempted = True

        # First attempt: faster-whisper
        try:
            from faster_whisper import WhisperModel
            target = self.model_path if self.model_path and os.path.exists(self.model_path) else self.model_name
            self._model = ("faster_whisper", WhisperModel(target, device="cpu", compute_type="int8"))
            return self._model
        except Exception:
            pass

        # Second attempt: standard local openai-whisper
        try:
            import whisper
            target = self.model_path if self.model_path and os.path.exists(self.model_path) else self.model_name
            self._model = ("whisper", whisper.load_model(target, device="cpu"))
            return self._model
        except Exception:
            pass

        self._model = None
        return None

    def is_available(self) -> bool:
        return self._try_load_model() is not None

    def transcribe(self, audio_bytes: bytes, filename: str) -> Tuple[str, str, Optional[float], float]:
        engine = self._try_load_model()
        if not engine:
            raise STTUnavailableError("LOCAL_STT_MODEL_UNAVAILABLE")

        engine_type, model = engine
        ext = os.path.splitext(filename)[1].lower() or ".wav"
        temp_path = None
        try:
            with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
                tmp.write(audio_bytes)
                temp_path = tmp.name

            if engine_type == "faster_whisper":
                segments, info = model.transcribe(temp_path, beam_size=5)
                transcript = " ".join([seg.text.strip() for seg in segments]).strip()
                detected_lang = info.language if info.language else "en"
                duration = round(info.duration, 2) if info.duration else 0.0
                confidence = round(info.language_probability, 2) if hasattr(info, "language_probability") else None
                return transcript, detected_lang, confidence, duration

            elif engine_type == "whisper":
                result = model.transcribe(temp_path)
                transcript = result.get("text", "").strip()
                detected_lang = result.get("language", "en")
                return transcript, detected_lang, None, 0.0

        finally:
            if temp_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except Exception:
                    pass

        raise STTUnavailableError("LOCAL_STT_MODEL_UNAVAILABLE")


class MockSpeechToTextProvider:
    """
    Mock STT provider strictly for unit tests and local test fixtures.
    Must never be used as a fake fallback in real production requests.
    """

    def __init__(self, canned_transcript: str = "Handwoven Sambalpuri cotton saree", language: str = "en"):
        self.canned_transcript = canned_transcript
        self.language = language

    def is_available(self) -> bool:
        return True

    def transcribe(self, audio_bytes: bytes, filename: str) -> Tuple[str, str, Optional[float], float]:
        duration = 0.0
        try:
            with wave.open(io.BytesIO(audio_bytes), "rb") as wf:
                frames = wf.getnframes()
                rate = wf.getframerate()
                if rate > 0:
                    duration = round(frames / float(rate), 2)
        except Exception:
            duration = max(1.0, round(len(audio_bytes) / 32000.0, 1))

        fname_lower = filename.lower()
        if "terracotta" in fname_lower:
            return (
                "यह मिट्टी का बना हुआ पारंपरिक टेराकोटा पानी का मटका और शोपीस है।",
                "hi",
                0.96,
                duration,
            )
        elif "sambalpuri" in fname_lower:
            return (
                "This is a handwoven Sambalpuri double ikat cotton saree in maroon and black.",
                "en",
                0.96,
                duration,
            )

        return self.canned_transcript, self.language, 0.95, duration



class SpeechToTextService:
    """
    Main Speech-to-Text orchestrator.
    Validates audio streams and delegates strictly to the configured local provider.
    No fake transcription fallbacks.
    """

    def __init__(self, provider: Optional[SpeechToTextProvider] = None):
        self.provider = provider or LocalWhisperProvider()

    def transcribe_audio(self, audio_bytes: bytes, filename: str) -> Tuple[str, str, Optional[float], float]:
        """
        Validates audio bytes and transcribes via local provider.
        Raises ValueError on corrupted audio or STTUnavailableError if local Whisper is not available.
        """
        if not audio_bytes or len(audio_bytes) < 16:
            raise ValueError("Audio file is empty or corrupted.")

        if not self.provider.is_available():
            raise STTUnavailableError(
                "Local Whisper model is not configured or unavailable on this server. "
                "Please configure WHISPER_MODEL_PATH or install local speech model."
            )

        return self.provider.transcribe(audio_bytes, filename)


# Maintain backward compatibility alias for legacy imports
SpeechService = SpeechToTextService
