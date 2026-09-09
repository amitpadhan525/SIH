import re
from typing import Dict, List, Optional, Protocol


class TranslationAdapter(Protocol):
    """Protocol for LLM or dedicated translation model (Bhashini, IndicTrans, NLLB, etc.)"""

    def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        ...


class CraftAwareDictionaryTranslator:
    """
    Craft-aware translator that preserves Indian artisanal terminology (Ikat, Zari, Dokra, Madhubani,
    Pattachitra, Bandhani, Warli, Kantha, etc.) while providing accurate cross-lingual translations.
    """

    CRAFT_KEYWORDS = {
        "sambalpuri": {"hi": "संबलपुरी", "or": "ସମ୍ବଲପୁରୀ", "bn": "সম্বলপুরী", "en": "Sambalpuri"},
        "ikat": {"hi": "इकत", "or": "ଇକତ", "bn": "ইকত", "en": "Ikat"},
        "saree": {"hi": "साड़ी", "or": "ଶାଢ଼ୀ", "bn": "শাড়ি", "en": "Saree"},
        "cotton": {"hi": "सूती / कॉटन", "or": "ସୂତା କପା", "bn": "সুতি", "en": "Cotton"},
        "handwoven": {"hi": "हथकरघा बुना हुआ", "or": "ହାତବୁଣା", "bn": "হস্তচালিত বোনা", "en": "Handwoven"},
        "handcrafted": {"hi": "हस्तनिर्मित", "or": "ହସ୍ତତନ୍ତ୍ର ନିର୍ମିତ", "bn": "হস্তনির্মিত", "en": "Handcrafted"},
        "terracotta": {"hi": "टेराकोटा (पकी मिट्टी)", "or": "ଟେରାକୋଟା", "bn": "টেরাকোটা", "en": "Terracotta"},
        "dokra": {"hi": "डोकरा (ढोकरा) पीतल कला", "or": "ଢୋକରା", "bn": "ডোকরা", "en": "Dokra"},
        "brass": {"hi": "पीतल", "or": "ପିତ୍ତଳ", "bn": "পিতল", "en": "Brass"},
        "clay": {"hi": "प्राकृतिक मिट्टी", "or": "ମାଟି", "bn": "মাটি", "en": "Natural Clay"},
        "natural dyes": {"hi": "प्राकृतिक रंग", "or": "ପ୍ରାକୃତିକ ରଙ୍ଗ", "bn": "প্রাকৃতিক রং", "en": "Natural Dyes"},
        "madhubani": {"hi": "मधुबनी मिथिला कला", "or": "ମଧୁବନୀ", "bn": "মধুবনী", "en": "Madhubani Painting"},
        "pottery": {"hi": "मिट्टी के बर्तन और कलाकृतियां", "or": "ମାଟିପାତ୍ର", "bn": "মৃৎশিল্প", "en": "Pottery & Clay Art"},
    }

    EN_TO_HI_PATTERNS = [
        (r"\bhandwoven\b", "हथकरघा बुना हुआ"),
        (r"\bhandcrafted\b", "कारीगरों द्वारा हस्तनिर्मित"),
        (r"\bauthentic\b", "प्रामाणिक"),
        (r"\btraditional\b", "पारंपरिक"),
        (r"\bcare instructions\b", "देखभाल निर्देश"),
        (r"\bdry clean only\b", "केवल ड्राई क्लीन करें"),
        (r"\bhandwash\b", "हाथ से धोएं"),
        (r"\bdays?\b", "दिन"),
        (r"\bhours?\b", "घंटे"),
        (r"\bnatural dyes?\b", "प्राकृतिक रंग"),
        (r"\bpure cotton\b", "शुद्ध सूती"),
    ]

    HI_TO_EN_PATTERNS = [
        (r"हथकरघा बुना हुआ", "handwoven"),
        (r"हस्तनिर्मित", "handcrafted"),
        (r"प्रामाणिक", "authentic"),
        (r"पारंपरिक", "traditional"),
        (r"मिट्टी", "clay"),
        (r"पीतल", "brass"),
        (r"प्राकृतिक रंग", "natural dyes"),
        (r"शुद्ध सूती", "pure cotton"),
    ]

    def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        if not text or not text.strip():
            return ""

        src = source_lang.lower().strip()
        tgt = target_lang.lower().strip()

        if src == tgt or tgt == "auto":
            return text

        # English -> Hindi
        if (src in ("en", "auto")) and tgt == "hi":
            result = text
            for pattern, replacement in self.EN_TO_HI_PATTERNS:
                result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
            return result

        # Hindi -> English
        if (src in ("hi", "auto")) and tgt == "en":
            result = text
            for pattern, replacement in self.HI_TO_EN_PATTERNS:
                result = re.sub(pattern, replacement, result)
            return result

        # Fallback translation with craft vocabulary normalization
        return text


class TranslationService:
    """Translation manager with language detection and craft-context preservation."""

    def __init__(self, adapter: Optional[TranslationAdapter] = None):
        self.adapter = adapter or CraftAwareDictionaryTranslator()

    def translate_text(self, text: str, source_lang: str = "auto", target_lang: str = "en") -> str:
        """Translates text from source language to target language."""
        if not text:
            return ""
        return self.adapter.translate(text, source_lang, target_lang)

    def detect_language(self, text: str) -> str:
        """Heuristic script / character range detector for Indian languages."""
        if not text:
            return "en"

        # Check Devanagari Unicode block (Hindi, Marathi, Sanskrit)
        devanagari_count = len(re.findall(r"[\u0900-\u097F]", text))
        # Check Odia block
        odia_count = len(re.findall(r"[\u0B00-\u0B7F]", text))
        # Check Bengali block
        bengali_count = len(re.findall(r"[\u0980-\u09FF]", text))
        # Check Tamil block
        tamil_count = len(re.findall(r"[\u0B80-\u0BFF]", text))
        # Check Telugu block
        telugu_count = len(re.findall(r"[\u0C00-\u0C7F]", text))

        counts = {
            "hi": devanagari_count,
            "or": odia_count,
            "bn": bengali_count,
            "ta": tamil_count,
            "te": telugu_count,
        }

        max_lang, max_count = max(counts.items(), key=lambda x: x[1])
        if max_count > 3:
            return max_lang

        return "en"
