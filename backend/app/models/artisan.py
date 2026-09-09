from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Boolean, String, Integer, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from backend.app.db.base import Base

if TYPE_CHECKING:
    from backend.app.models.user import User
    from backend.app.models.product import Product

class Artisan(Base):
    __tablename__ = "artisans"

    id: Mapped[int] = mapped_column(primary_key=True, index=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False
    )
    craft_type: Mapped[str] = mapped_column(String(100), nullable=False, default="Traditional Handicrafts")
    artisan_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    craft_category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    state: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    district: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    preferred_language: Mapped[str] = mapped_column(String(50), nullable=False, default="hi")
    artisan_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    experience_years: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_profile_complete: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="artisan")
    products: Mapped[List["Product"]] = relationship(
        "Product",
        back_populates="artisan",
        cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Artisan(id={self.id}, user_id={self.user_id}, craft_category='{self.craft_category}', complete={self.is_profile_complete})>"
