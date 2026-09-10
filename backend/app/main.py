from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from fastapi.staticfiles import StaticFiles
from backend.app.config import settings
from backend.app.db.session import get_db, engine, SessionLocal
from backend.app.models import Base, User, Artisan
from backend.app.schemas.health import HealthResponse, DBHealthResponse
from backend.app.api.products import router as products_router
from backend.app.api.images import router as images_router
from backend.app.api.catalog import router as catalog_router, ai_router
from backend.app.api.pricing import router as pricing_router
from backend.app.api.inquiries import router as inquiries_router
from backend.app.api.marketplace import router as marketplace_router
from backend.app.api.auth import router as auth_router
from backend.app.api.sync import router as sync_router
from backend.app.api.admin import router as admin_router
from backend.app.services.storage_service import storage_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure storage directories exist
    storage_service._ensure_directories()

    # Auto-create tables if needed in development
    Base.metadata.create_all(bind=engine)

    # Ensure default artisan user exists for auth/demo access
    try:
        from backend.app.db.seed_demo_data import ensure_default_artisan
        with SessionLocal() as db:
            ensure_default_artisan(db)
    except Exception:
        pass

    yield


app = FastAPI(
    title=settings.APP_NAME,
    description="AI-powered digital business platform for artisans and micro-entrepreneurs",
    version="0.1.0",
    debug=settings.DEBUG,
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static Files Mount for Processed Media (only exposes configured UPLOAD_DIR)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Include Routers
app.include_router(products_router, prefix="/products", tags=["Products"])
app.include_router(images_router)
app.include_router(catalog_router)
app.include_router(ai_router)
app.include_router(pricing_router)
app.include_router(inquiries_router)
app.include_router(marketplace_router)
app.include_router(auth_router)
app.include_router(sync_router)
app.include_router(admin_router)


@app.get("/", response_model=HealthResponse, tags=["Health"])
def root() -> HealthResponse:
    """
    Root status check endpoint.
    """
    return HealthResponse(
        status="ok",
        service=settings.APP_NAME,
    )


@app.get("/health", response_model=HealthResponse, tags=["Health"])
def health_check() -> HealthResponse:
    """
    General application liveness health check endpoint.
    """
    return HealthResponse(
        status="healthy",
        service=settings.APP_NAME,
    )


@app.get("/health/db", response_model=DBHealthResponse, tags=["Health"])
def database_health_check(db: Session = Depends(get_db)) -> DBHealthResponse:
    """
    Verifies that FastAPI can connect to and query database.
    """
    try:
        db.execute(text("SELECT 1"))
        return DBHealthResponse(database="connected")
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database connection error: {exc}",
        )
