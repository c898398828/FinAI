from datetime import date, datetime
from pydantic import BaseModel


class FinancialRecordCreate(BaseModel):
    record_date: date
    category: str
    sub_category: str | None = None
    amount: float
    description: str | None = None
    source: str | None = "manual"


class FinancialRecordOut(BaseModel):
    id: int
    company_id: int
    record_date: date
    category: str
    sub_category: str | None = None
    amount: float
    description: str | None = None
    source: str | None = None
    created_by: int | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class FinancialRecordList(BaseModel):
    total: int
    items: list[FinancialRecordOut]


class FinancialSummary(BaseModel):
    total_income: float = 0
    total_expense: float = 0
    net_profit: float = 0
    total_assets: float = 0
    total_liabilities: float = 0
    category_breakdown: dict = {}


class FinancialTrend(BaseModel):
    periods: list[str] = []
    income: list[float] = []
    expense: list[float] = []


class FinancialCashflow(BaseModel):
    periods: list[str] = []
    inflow: list[float] = []
    outflow: list[float] = []
    net: list[float] = []


class UploadResult(BaseModel):
    success: bool
    records_imported: int
    errors: list[str] = []
