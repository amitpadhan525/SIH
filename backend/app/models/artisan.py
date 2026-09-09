from datetime import datetime
from typing import TYPE_CHECKING, List
from sqlalchemy import String, Integer, ForeignKey, DateTime, func
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
    craft_type: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
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
        return f"<Artisan(id={self.id}, user_id={self.user_id}, craft_type='{self.craft_type}')>"
