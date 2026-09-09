"""add artisan profile fields and updated_at timestamps

Revision ID: 0003_artisan_profile_fields
Revises: 0002_inquiries
Create Date: 2026-09-09 23:05:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0003_artisan_profile_fields'
down_revision: Union[str, None] = '0002_inquiries'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add columns to artisans table
    op.add_column('artisans', sa.Column('artisan_name', sa.String(length=255), nullable=True))
    op.add_column('artisans', sa.Column('craft_category', sa.String(length=100), nullable=True))
    op.add_column('artisans', sa.Column('state', sa.String(length=100), nullable=True))
    op.add_column('artisans', sa.Column('district', sa.String(length=100), nullable=True))
    op.add_column('artisans', sa.Column('preferred_language', sa.String(length=50), server_default='hi', nullable=False))
    op.add_column('artisans', sa.Column('artisan_type', sa.String(length=50), nullable=True))
    op.add_column('artisans', sa.Column('experience_years', sa.Integer(), nullable=True))
    op.add_column('artisans', sa.Column('description', sa.Text(), nullable=True))
    op.add_column('artisans', sa.Column('is_profile_complete', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('artisans', sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))

    # Add updated_at column to users table
    op.add_column('users', sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))


def downgrade() -> None:
    op.drop_column('users', 'updated_at')
    op.drop_column('artisans', 'updated_at')
    op.drop_column('artisans', 'is_profile_complete')
    op.drop_column('artisans', 'description')
    op.drop_column('artisans', 'experience_years')
    op.drop_column('artisans', 'artisan_type')
    op.drop_column('artisans', 'preferred_language')
    op.drop_column('artisans', 'district')
    op.drop_column('artisans', 'state')
    op.drop_column('artisans', 'craft_category')
    op.drop_column('artisans', 'artisan_name')
