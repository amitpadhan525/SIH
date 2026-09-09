import io
import wave
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.api.catalog import speech_service
from backend.app.ai.speech_service import MockSpeechToTextProvider
from backend.app.config import settings

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_mock_speech():
    orig = speech_service.provider
    speech_service.provider = MockSpeechToTextProvider()
    yield
    speech_service.provider = orig


def create_dummy_wav_bytes(duration_seconds: float = 1.0) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(16000)
        wf.writeframes(b"\x00\x00" * int(duration_seconds * 16000))
    return buf.getvalue()


def test_reject_audio_oversized():
    """Verify audio upload larger than MAX_UPLOAD_SIZE_BYTES is rejected with 413 or 400."""
    # Create an oversized payload exceeding 10MB
    oversized = b"RIFF" + b"\x00" * 4 + b"WAVEfmt " + b"\x00" * (10 * 1024 * 1024 + 1024)
    files = {"file": ("giant_audio.wav", oversized, "audio/wav")}
    response = client.post("/ai/transcribe", files=files)
    assert response.status_code in [400, 413]


def test_reject_invalid_audio_extension():
    """Verify unsupported file extensions (.exe, .py, .txt) are rejected with 400."""
    files = {"file": ("malicious.exe", b"MZ\x90\x00\x03\x00\x00\x00", "application/octet-stream")}
    response = client.post("/ai/transcribe", files=files)
    assert response.status_code == 400
    assert "Unsupported audio format" in response.json()["detail"]


def test_reject_path_traversal_audio_filename():
    """Verify directory traversal in audio upload filename is rejected with 400."""
    wav_bytes = create_dummy_wav_bytes(1.0)
    files = {"file": ("../../etc/passwd.wav", wav_bytes, "audio/wav")}
    response = client.post("/ai/transcribe", files=files)
    assert response.status_code == 400
    assert "Path traversal" in response.json()["detail"]


def test_reject_invalid_magic_bytes_for_wav():
    """Verify fake file pretending to be .wav with invalid magic header is rejected."""
    fake_wav = b"THIS_IS_NOT_A_WAV_HEADER_1234567890"
    files = {"file": ("spoofed.wav", fake_wav, "audio/wav")}
    response = client.post("/ai/transcribe", files=files)
    assert response.status_code == 400
    assert "magic bytes" in response.json()["detail"]


def test_valid_audio_upload_transcription():
    """Verify clean WAV audio upload passes magic byte validation and transcribes."""
    wav_bytes = create_dummy_wav_bytes(1.5)
    files = {"file": ("valid_craft.wav", wav_bytes, "audio/wav")}
    response = client.post("/ai/transcribe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert "transcript" in data
    assert data["duration_seconds"] == 1.5
