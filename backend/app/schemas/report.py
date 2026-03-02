from datetime import date, datetime
from pydantic import BaseModel


class ReportGenerate(BaseModel):
    report_type: str
    period_start: date
    period_end: date


class ReportOut(BaseModel):
    id: int
    company_id: int
    report_type: str
    title: str | None = None
    period_start: date
    period_end: date
    data_json: dict | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportList(BaseModel):
    total: int
    items: list[ReportOut]
