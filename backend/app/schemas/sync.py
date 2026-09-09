from datetime import datetime
from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, Field, ConfigDict


class SyncActionItem(BaseModel):
    client_action_id: str = Field(..., description="Unique client-generated UUID for idempotency")
    action_type: Literal["create_product", "update_product", "delete_product", "update_inquiry_status"]
    payload: Dict[str, Any]
    client_timestamp: Optional[datetime] = None


class SyncBatchRequest(BaseModel):
    artisan_id: int
    actions: List[SyncActionItem] = Field(default_factory=list)


class SyncActionResponse(BaseModel):
    client_action_id: str
    status: Literal["applied", "already_processed", "failed", "conflict"]
    server_id: Optional[int] = None
    message: str
    data: Optional[Dict[str, Any]] = None


class SyncBatchResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    success: bool
    total_actions: int
    applied_count: int
    already_processed_count: int
    failed_count: int
    results: List[SyncActionResponse]
    server_time: datetime = Field(default_factory=datetime.utcnow)


class SyncDeltaResponse(BaseModel):
    server_time: datetime
    products: List[Dict[str, Any]]
    inquiries: List[Dict[str, Any]]
