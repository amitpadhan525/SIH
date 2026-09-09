"""add inquiries table

Revision ID: 0002_inquiries
Revises: 0001_initial
Create Date: 2026-09-09 20:15:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '0002_inquiries'
down_revision: Union[str, None] = '0001_initial'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'inquiries',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('buyer_name', sa.String(length=255), nullable=False),
        sa.Column('buyer_email', sa.String(length=255), nullable=False),
        sa.Column('buyer_phone', sa.String(length=50), nullable=False),
        sa.Column('buyer_type', sa.String(length=50), server_default='wholesale_b2b', nullable=False),
        sa.Column('quantity', sa.Integer(), server_default='1', nullable=False),
        sa.Column('target_price', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=50), server_default='pending', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_inquiries_id'), 'inquiries', ['id'], unique=False)
    op.create_index(op.f('ix_inquiries_product_id'), 'inquiries', ['product_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_inquiries_product_id'), table_name='inquiries')
    op.drop_index(op.f('ix_inquiries_id'), table_name='inquiries')
    op.drop_table('inquiries')
