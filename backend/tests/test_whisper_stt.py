import io
import wave
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.api.catalog import speech_service
from backend.app.ai.speech_service import (
    SpeechToTextService,
    LocalWhisperProvider,
    MockSpeechToTextProvider,
    STTUnavailableError,
)

client = TestClient(app)


def create_dummy_wav_bytes(duration_seconds: float = 1.0, sample_rate: int = 16000) -> bytes:
    buf = io.BytesIO()
    num_frames = int(duration_seconds * sample_rate)
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(b"\x00\x00" * num_frames)
    return buf.getvalue()


def test_local_whisper_provider_unavailable_when_unconfigured():
    """Verify LocalWhisperProvider raises STTUnavailableError when model path/weights are absent."""
    provider = LocalWhisperProvider(model_path="/nonexistent/model/path.bin")
    # In an environment without local whisper binaries installed
    if not provider.is_available():
        with pytest.raises(STTUnavailableError):
            provider.transcribe(b"RIFF\x24\x00\x00\x00WAVEfmt ", "test.wav")


def test_speech_to_text_service_returns_503_when_model_unavailable():
    """Verify /ai/transcribe returns 503 Service Unavailable with LOCAL_STT_MODEL_UNAVAILABLE error."""
    class UnavailableProvider:
        def is_available(self) -> bool:
            return False
        def transcribe(self, audio_bytes, filename):
            raise STTUnavailableError()

    orig_provider = speech_service.provider
    speech_service.provider = UnavailableProvider()
    try:
        wav_bytes = create_dummy_wav_bytes(1.0)
        files = {"file": ("recording.wav", wav_bytes, "audio/wav")}
        response = client.post("/ai/transcribe", files=files)
        assert response.status_code == 503
        data = response.json()
        assert "LOCAL_STT_MODEL_UNAVAILABLE" in data["detail"]
    finally:
        speech_service.provider = orig_provider


def test_mock_speech_to_text_provider_transcription():
    """Verify MockSpeechToTextProvider correctly decodes sample audio for unit tests."""
    mock_prov = MockSpeechToTextProvider(canned_transcript="Authentic Dokra Lamp", language="en")
    service = SpeechToTextService(provider=mock_prov)
    wav_bytes = create_dummy_wav_bytes(2.0)
    transcript, lang, conf, duration = service.transcribe_audio(wav_bytes, "dokra_lamp.wav")
    assert transcript == "Authentic Dokra Lamp"
    assert lang == "en"
    assert conf == 0.95
    assert duration == 2.0
