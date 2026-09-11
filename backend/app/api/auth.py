import hmac
import logging
import re
import secrets
import time
from dataclasses import dataclass
from typing import Dict, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.config import settings
from backend.app.core.security import (
    create_access_token,
    decode_access_token,
    get_current_artisan,
    get_current_user,
    hash_password,
    verify_password,
)
from backend.app.db.session import get_db
from backend.app.models.artisan import Artisan
from backend.app.models.user import User
from backend.app.schemas.artisan import ArtisanProfileUpdateRequest, ArtisanRead
from backend.app.schemas.auth import (
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication & Security"])


@dataclass
class OtpEntry:
    code: str
    created_at: float
    expires_at: float
    attempts: int = 0


# Server-side ephemeral OTP storage (phone -> OtpEntry)
_OTP_STORE: Dict[str, OtpEntry] = {}


def normalize_phone(phone: str) -> str:
    """Sanitizes and normalizes phone number input, validating sufficient digits."""
    if not phone:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Phone number cannot be empty.",
        )
    cleaned = re.sub(r"[\s\-\(\)]", "", phone.strip())
    digits_only = re.sub(r"\D", "", cleaned)
    if len(digits_only) < 10 or len(digits_only) > 15:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid phone number. Must contain 10 to 15 digits.",
        )
    return cleaned


def _build_token_response(
    user: User,
    token: str,
    artisan: Optional[Artisan] = None,
) -> TokenResponse:
    """Constructs standard TokenResponse with profile metadata and completion status."""
    art = artisan or user.artisan
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        artisan_id=art.id if art else None,
        name=user.name,
        role=user.role,
        phone=user.phone,
        is_profile_complete=bool(art.is_profile_complete) if art else False,
        craft_category=art.craft_category if art else None,
        state=art.state if art else None,
        district=art.district if art else None,
        preferred_language=art.preferred_language if art else user.language,
        artisan_name=art.artisan_name if art else None,
        artisan_type=art.artisan_type if art else None,
        experience_years=art.experience_years if art else None,
        description=art.description if art else None,
    )


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new artisan or buyer account",
)
def register(request: UserRegisterRequest, db: Session = Depends(get_db)):
    phone = normalize_phone(request.phone)
    # Check phone uniqueness
    existing = db.execute(select(User).where(User.phone == phone)).scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"User with phone number '{phone}' already exists",
        )

    user = User(
        name=request.name.strip(),
        phone=phone,
        role=request.role.strip().lower(),
        language=request.language.strip().lower() if request.language else "hi",
        location=request.location.strip() if request.location else None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    artisan = None
    if user.role == "artisan":
        artisan = Artisan(
            user_id=user.id,
            craft_type=request.craft_type.strip() if request.craft_type else "Traditional Handicrafts",
            craft_category=request.craft_type.strip() if request.craft_type else "Handicraft",
            preferred_language=user.language,
            is_profile_complete=False,
        )
        db.add(artisan)
        db.commit()
        db.refresh(artisan)

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "name": user.name,
        "phone": user.phone,
        "artisan_id": artisan.id if artisan else None,
    })

    return _build_token_response(user, token, artisan)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login with phone number and password",
)
def login(request: UserLoginRequest, db: Session = Depends(get_db)):
    phone = normalize_phone(request.phone)
    user = db.execute(select(User).where(User.phone == phone)).scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or credentials",
        )

    artisan_id = user.artisan.id if user.artisan else None

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "name": user.name,
        "phone": user.phone,
        "artisan_id": artisan_id,
    })

    return _build_token_response(user, token, user.artisan)


@router.post(
    "/otp/send",
    response_model=OtpSendResponse,
    status_code=status.HTTP_200_OK,
    summary="Send/Simulate cryptographically secure 6-digit OTP to phone number",
)
def send_otp(request: OtpSendRequest):
    phone = normalize_phone(request.phone)

    # Invalidate any previously active OTP for this phone number
    if phone in _OTP_STORE:
        del _OTP_STORE[phone]

    # Generate cryptographically secure random 6-digit OTP code (100000 - 999999)
    otp_code = f"{secrets.randbelow(900000) + 100000:06d}"
    now = time.time()
    expiry = now + getattr(settings, "OTP_EXPIRY_SECONDS", 300)

    _OTP_STORE[phone] = OtpEntry(
        code=otp_code,
        created_at=now,
        expires_at=expiry,
        attempts=0,
    )

    if getattr(settings, "AUTH_DEMO_MODE", True):
        logger.info(f"[AUTH DEMO] Generated OTP for {phone}: {otp_code} (Expires in {settings.OTP_EXPIRY_SECONDS}s)")
    else:
        logger.info(f"Generated OTP for {phone} (Expires in {settings.OTP_EXPIRY_SECONDS}s)")

    if getattr(settings, "AUTH_DEMO_MODE", True):
        return OtpSendResponse(
            phone=phone,
            message=f"OTP successfully sent to {phone}. (Demo code: {otp_code})",
            demo_otp=otp_code,
        )

    return OtpSendResponse(
        phone=phone,
        message=f"OTP successfully sent to {phone}.",
        demo_otp=None,
    )


@router.post(
    "/otp/verify",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and return authenticated JWT session with profile completion state",
)
def verify_otp(request: OtpVerifyRequest, db: Session = Depends(get_db)):
    phone = normalize_phone(request.phone)
    otp_code = request.otp.strip()

    entry = _OTP_STORE.get(phone)
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No active OTP found. Please request a new OTP.",
        )

    # Expiration check
    if time.time() > entry.expires_at:
        del _OTP_STORE[phone]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP has expired. Please request a new code.",
        )

    # Attempt rate limit check
    entry.attempts += 1
    max_attempts = getattr(settings, "MAX_OTP_VERIFY_ATTEMPTS", 5)
    if entry.attempts > max_attempts:
        del _OTP_STORE[phone]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum verification attempts exceeded. OTP invalidated.",
        )

    # Constant-time comparison to prevent timing attacks
    if not hmac.compare_digest(entry.code, otp_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP code. Please check and try again.",
        )

    # Invalidate OTP immediately upon successful verification (single-use guarantee)
    del _OTP_STORE[phone]

    # Source of truth: Look up existing user by phone
    user = db.execute(select(User).where(User.phone == phone)).scalar_one_or_none()
    if not user:
        # First-time login: auto-provision user and artisan profile with is_profile_complete=False
        user = User(
            name=f"Artisan {phone[-4:] if len(phone) >= 4 else phone}",
            phone=phone,
            role="artisan",
            language="hi",
            location=None,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        artisan = Artisan(
            user_id=user.id,
            craft_type="Traditional Handicrafts",
            preferred_language="hi",
            is_profile_complete=False,
        )
        db.add(artisan)
        db.commit()
        db.refresh(artisan)
    else:
        # Repeat login: reuse existing user and ensure artisan profile exists
        if not user.artisan and user.role == "artisan":
            artisan = Artisan(
                user_id=user.id,
                craft_type="Traditional Handicrafts",
                preferred_language="hi",
                is_profile_complete=False,
            )
            db.add(artisan)
            db.commit()
            db.refresh(artisan)

    artisan_id = user.artisan.id if user.artisan else None

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "name": user.name,
        "phone": user.phone,
        "artisan_id": artisan_id,
    })

    return _build_token_response(user, token, user.artisan)


@router.get(
    "/me",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user profile and completion status from JWT Bearer header",
)
def get_me(
    current_user: User = Depends(get_current_user),
    authorization: Optional[str] = Header(None),
):
    token = authorization.split(" ", 1)[1].strip() if authorization and " " in authorization else ""
    return _build_token_response(current_user, token, current_user.artisan)


@router.put(
    "/me/profile",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete or update the authenticated artisan's profile",
)
def update_profile(
    request: ArtisanProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    current_artisan: Artisan = Depends(get_current_artisan),
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
):
    """Saves mandatory and optional artisan onboarding profile data directly to PostgreSQL."""
    full_name = request.full_name.strip()
    if not full_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Full name cannot be empty.",
        )

    craft_cat = request.craft_category.strip()
    if not craft_cat:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Craft category cannot be empty.",
        )

    state_val = request.state.strip() if request.state and request.state.strip() else current_artisan.state
    district_val = request.district.strip() if request.district and request.district.strip() else current_artisan.district

    pref_lang = request.preferred_language.strip() if request.preferred_language else "hi"

    # Update User model
    current_user.name = full_name
    current_user.language = pref_lang.lower()
    if district_val and state_val:
        current_user.location = f"{district_val}, {state_val}"
    elif state_val:
        current_user.location = state_val
    elif district_val:
        current_user.location = district_val
    db.add(current_user)

    # Update Artisan model
    current_artisan.craft_category = craft_cat
    current_artisan.craft_type = craft_cat  # Keep craft_type synced for backward compatibility
    current_artisan.state = state_val
    current_artisan.district = district_val
    current_artisan.preferred_language = pref_lang
    if request.artisan_name is not None:
        current_artisan.artisan_name = request.artisan_name.strip() if request.artisan_name.strip() else None
    if request.artisan_type is not None:
        current_artisan.artisan_type = request.artisan_type.strip() if request.artisan_type.strip() else None
    if request.experience_years is not None:
        current_artisan.experience_years = request.experience_years
    if request.description is not None:
        current_artisan.description = request.description.strip() if request.description.strip() else None
    current_artisan.is_profile_complete = True
    db.add(current_artisan)

    db.commit()
    db.refresh(current_user)
    db.refresh(current_artisan)

    token = authorization.split(" ", 1)[1].strip() if authorization and " " in authorization else ""
    return _build_token_response(current_user, token, current_artisan)
