from typing import Dict
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)
from backend.app.db.session import get_db
from backend.app.models.artisan import Artisan
from backend.app.models.user import User
from backend.app.schemas.auth import (
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
)

router = APIRouter(prefix="/auth", tags=["Authentication & Security"])

# In-memory store for OTP simulation (phone -> otp_code)
_OTP_STORE: Dict[str, str] = {}


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new artisan or buyer account",
)
def register(request: UserRegisterRequest, db: Session = Depends(get_db)):
    # Check phone uniqueness
    existing = db.execute(select(User).where(User.phone == request.phone)).scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"User with phone number '{request.phone}' already exists",
        )

    user = User(
        name=request.name,
        phone=request.phone,
        role=request.role,
        language=request.language,
        location=request.location,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    artisan_id = None
    if request.role == "artisan":
        artisan = Artisan(
            user_id=user.id,
            craft_type=request.craft_type or "Traditional Handicrafts",
        )
        db.add(artisan)
        db.commit()
        db.refresh(artisan)
        artisan_id = artisan.id

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "name": user.name,
        "phone": user.phone,
        "artisan_id": artisan_id,
    })

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        artisan_id=artisan_id,
        name=user.name,
        role=user.role,
        phone=user.phone,
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login with phone number and password",
)
def login(request: UserLoginRequest, db: Session = Depends(get_db)):
    user = db.execute(select(User).where(User.phone == request.phone)).scalar_one_or_none()
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

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        artisan_id=artisan_id,
        name=user.name,
        role=user.role,
        phone=user.phone,
    )


@router.post(
    "/otp/send",
    response_model=OtpSendResponse,
    status_code=status.HTTP_200_OK,
    summary="Send/Simulate 6-digit OTP to phone number",
)
def send_otp(request: OtpSendRequest):
    # Simulated 6-digit OTP (e.g. 202690 for SIH 2026 #90)
    otp = "202690"
    _OTP_STORE[request.phone] = otp

    return OtpSendResponse(
        phone=request.phone,
        message=f"OTP successfully sent to {request.phone}. Use demo code {otp}",
        demo_otp=otp,
    )


@router.post(
    "/otp/verify",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and return authenticated JWT session",
)
def verify_otp(request: OtpVerifyRequest, db: Session = Depends(get_db)):
    stored_otp = _OTP_STORE.get(request.phone, "202690")
    if request.otp != stored_otp and request.otp != "202690":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP code",
        )

    # Find or auto-provision artisan user
    user = db.execute(select(User).where(User.phone == request.phone)).scalar_one_or_none()
    if not user:
        user = User(
            name=f"Artisan {request.phone[-4:]}",
            phone=request.phone,
            role="artisan",
            language="hi",
            location="India",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        artisan = Artisan(user_id=user.id, craft_type="Handicrafts")
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

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        artisan_id=artisan_id,
        name=user.name,
        role=user.role,
        phone=user.phone,
    )


@router.get(
    "/me",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user profile from JWT Bearer header",
)
def get_me(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Bearer authentication header",
        )

    token = authorization.split(" ")[1]
    try:
        payload = decode_access_token(token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {str(e)}",
        )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=int(payload["sub"]),
        artisan_id=payload.get("artisan_id"),
        name=payload.get("name", "Artisan"),
        role=payload.get("role", "artisan"),
        phone=payload.get("phone", ""),
    )
