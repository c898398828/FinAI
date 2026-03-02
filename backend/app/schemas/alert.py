from datetime import datetime
from pydantic import BaseModel


class AlertOut(BaseModel):
    id: int
    company_id: int
    alert_type: str
    severity: str
    message: str
    is_read: bool
    data_json: dict | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class AlertList(BaseModel):
    total: int
    items: list[AlertOut]


class BudgetCreate(BaseModel):
    year: int
    month: int
    category: str
    planned_amount: float


class BudgetOut(BaseModel):
    id: int
    company_id: int
    year: int
    month: int
    category: str
    planned_amount: float
    actual_amount: float
    forecast_amount: float
    created_at: datetime

    model_config = {"from_attributes": True}


class BudgetList(BaseModel):
    total: int
    items: list[BudgetOut]


class AnomalyResult(BaseModel):
    anomalies: list[dict]
    summary: str


class ForecastResult(BaseModel):
    forecasts: list[dict]
    summary: str


class BudgetSuggestion(BaseModel):
    suggestions: list[dict]
    summary: str
