import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Base directory for the backend application
BASE_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR = BASE_DIR.parent

class Settings(BaseSettings):
    APP_NAME: str = "Artisan AI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # PostgreSQL Connection URL
    # Example: postgresql+psycopg://postgres:postgres@localhost:5432/artisan_ai
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/artisan_ai"

    # Docker PostgreSQL credentials
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "artisan_ai"
    POSTGRES_PORT: int = 5432

    # Storage & Image Processing Configuration
    UPLOAD_DIR: str = str(BASE_DIR / "uploads")
    MAX_UPLOAD_SIZE_BYTES: int = 10 * 1024 * 1024  # 10 MB limit
    PROCESSED_IMAGE_SIZE: int = 1024  # Standard 1024x1024 square canvas
    ALLOWED_IMAGE_FORMATS: list[str] = ["JPEG", "PNG", "WEBP"]

    model_config = SettingsConfigDict(
        env_file=(
            str(ROOT_DIR / ".env"),
            str(BASE_DIR / ".env"),
            ".env"
        ),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
