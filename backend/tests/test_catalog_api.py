import io
import wave
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.api.catalog import speech_service
from backend.app.ai.speech_service import MockSpeechToTextProvider

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_mock_speech_provider():
    original_provider = speech_service.provider
    speech_service.provider = MockSpeechToTextProvider()
    yield
    speech_service.provider = original_provider


def create_dummy_wav_bytes(duration_seconds: float = 1.0, sample_rate: int = 16000) -> bytes:
    """Generates a minimal valid PCM WAV byte stream for testing audio uploads."""
    buf = io.BytesIO()
    num_frames = int(duration_seconds * sample_rate)
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        # Write silence frames (16-bit zeros)
        wf.writeframes(b"\x00\x00" * num_frames)
    return buf.getvalue()


def test_speech_transcription_sambalpuri_sample():
    """Test audio transcription endpoint with a craft audio sample."""
    wav_bytes = create_dummy_wav_bytes(duration_seconds=2.5)
    files = {"file": ("sambalpuri_craft_audio.wav", wav_bytes, "audio/wav")}

    response = client.post("/ai/catalog/transcribe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert "transcript" in data
    assert "Sambalpuri" in data["transcript"]
    assert data["detected_language"] == "en"
    assert data["confidence"] > 0.8
    assert data["duration_seconds"] == 2.5


def test_speech_transcription_terracotta_hindi_sample():
    """Test audio transcription endpoint with Hindi terracotta audio."""
    wav_bytes = create_dummy_wav_bytes(duration_seconds=3.0)
    files = {"file": ("terracotta_pottery_audio.wav", wav_bytes, "audio/wav")}

    response = client.post("/ai/catalog/transcribe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert "टेराकोटा" in data["transcript"] or "मिट्टी" in data["transcript"]
    assert data["detected_language"] == "hi"


def test_speech_transcription_empty_file():
    """Test audio transcription endpoint with invalid/empty audio."""
    files = {"file": ("empty.wav", b"", "audio/wav")}
    response = client.post("/ai/catalog/transcribe", files=files)
    assert response.status_code == 400


def test_catalog_generate_sambalpuri_saree():
    """Test structured catalog generation with Sambalpuri Ikat Saree artisan input."""
    payload = {
        "text": (
            "This is a handwoven Sambalpuri double ikat cotton saree in maroon and black. "
            "It is hand-crafted with traditional shankha and chakra border motifs using natural dyes. "
            "It took our family 18 days on a pit loom. Dry clean or gentle cold water handwash only."
        ),
        "source_language": "en",
        "target_languages": ["en", "hi"],
    }

    response = client.post("/ai/catalog/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    # Verify anti-hallucination facts isolation
    facts = data["verified_facts"]
    assert "Sambalpuri" in (facts["craft_technique"] or "")
    assert "Organic Cotton" in facts["materials"]
    assert "Maroon" in facts["colors"]
    assert "Black" in facts["colors"]
    assert facts["time_taken_days"] == 18
    assert len(facts["care_instructions"]) > 0
    # Strict anti-hallucination: dimensions was not stated in speech -> must be None
    assert facts["dimensions"] is None

    # Verify localized content
    assert "en" in data["content"]
    assert "hi" in data["content"]
    assert "Sambalpuri" in data["content"]["en"]["title"]
    assert len(data["content"]["en"]["key_features"]) >= 2
    assert "हस्तनिर्मित" in data["content"]["hi"]["title"] or "संबलपुरी" in data["content"]["hi"]["title"]

    # Verify tags & guarantee
    assert len(data["suggested_tags"]) >= 2
    assert data["anti_hallucination_passed"] is True
    assert data["confidence_score"] >= 0.90


def test_catalog_generate_with_spoken_dimensions():
    """Test fact extraction when artisan explicitly states physical dimensions."""
    payload = {
        "text": (
            "Authentic Bastar Dokra brass idol measuring 15x8x4 inches. "
            "Handcrafted using solid brass in lost-wax casting. Took 7 days to craft."
        ),
        "source_language": "en",
        "target_languages": ["en"],
    }

    response = client.post("/ai/catalog/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    facts = data["verified_facts"]
    assert facts["dimensions"] == "15x8x4 inches"
    assert "Solid Brass" in facts["materials"]
    assert facts["time_taken_days"] == 7


def test_catalog_generate_empty_text():
    """Test catalog generation rejects empty text."""
    response = client.post("/ai/catalog/generate", json={"text": "   "})
    assert response.status_code in (400, 422)


def test_multilingual_translation():
    """Test translation endpoint preserving artisan terminology."""
    payload = {
        "text": "Authentic handwoven Sambalpuri cotton saree with natural dyes.",
        "source_language": "en",
        "target_language": "hi",
    }

    response = client.post("/ai/catalog/translate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "हथकरघा बुना हुआ" in data["translated_text"] or "संबलपुरी" in data["translated_text"]
    assert data["target_language"] == "hi"
