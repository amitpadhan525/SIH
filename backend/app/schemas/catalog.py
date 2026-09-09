from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class TranscriptionResponse(BaseModel):
    transcript: str = Field(..., description="Transcribed text from speech")
    detected_language: str = Field(..., description="Detected language code (e.g., 'hi', 'or', 'bn', 'en')")
    confidence: Optional[float] = Field(default=None, ge=0.0, le=1.0, description="Confidence score")
    duration_seconds: float = Field(default=0.0, ge=0.0, description="Audio duration in seconds")


class CatalogGenerateRequest(BaseModel):
    text: str = Field(..., min_length=3, description="Artisan speech transcript or description")
    source_language: str = Field(default="auto", description="Source language code or 'auto'")
    target_languages: List[str] = Field(default=["en", "hi"], description="Target translation languages")
    artisan_notes: Optional[str] = Field(default=None, description="Optional extra artisan input or context")


class VerifiedFacts(BaseModel):
    product_name: Optional[str] = Field(None, description="Exact product name identified from artisan speech")
    category: Optional[str] = Field(None, description="E-commerce category (Handicrafts, Textiles, Pottery, etc.)")
    craft_technique: Optional[str] = Field(None, description="Identified craft technique (e.g. Sambalpuri Ikat, Terracotta, Dokra)")
    materials: List[str] = Field(default_factory=list, description="Artisan-stated materials (e.g., Organic Cotton, Clay, Brass)")
    colors: List[str] = Field(default_factory=list, description="Stated colors or shades")
    dimensions: Optional[str] = Field(None, description="Stated dimensions if spoken, else null (never hallucinated)")
    time_taken_days: Optional[int] = Field(None, description="Artisan time taken to craft in days if spoken")
    care_instructions: List[str] = Field(default_factory=list, description="Artisan care instructions")
    origin_region: Optional[str] = Field(None, description="Artisan region/state if spoken")


class LocalizedContent(BaseModel):
    title: str = Field(..., description="Compelling, clean e-commerce title")
    short_description: str = Field(..., description="1-2 sentence hook for catalog listing")
    story_description: str = Field(..., description="Heritage & craft story highlighting handcrafted authenticity")
    key_features: List[str] = Field(default_factory=list, description="Key bullet points for product page")


class CatalogGenerateResponse(BaseModel):
    verified_facts: VerifiedFacts = Field(..., description="Strictly extracted facts without hallucination")
    content: Dict[str, LocalizedContent] = Field(..., description="Localized titles and stories keyed by language code ('en', 'hi', etc.)")
    suggested_tags: List[str] = Field(default_factory=list, description="Hashtags / searchable tags")
    seo_keywords: List[str] = Field(default_factory=list, description="High-intent e-commerce search keywords")
    confidence_score: float = Field(default=0.92, ge=0.0, le=1.0, description="Fact extraction confidence")
    anti_hallucination_passed: bool = Field(default=True, description="Strict guarantee that unmentioned facts were not invented")


class TranslationRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to translate")
    source_language: str = Field(default="auto", description="Source language code or 'auto'")
    target_language: str = Field(..., description="Target language code (e.g. 'en', 'hi', 'or', 'bn', 'ta', 'te')")


class TranslationResponse(BaseModel):
    original_text: str
    source_language: str
    target_language: str
    translated_text: str
