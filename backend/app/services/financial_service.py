from collections import defaultdict
from datetime import date

from sqlalchemy.orm import Session

from app.models.financial_data import FinancialRecord
from app.schemas.financial import (
    FinancialCashflow,
    FinancialRecordCreate,
    FinancialSummary,
    FinancialTrend,
)


def create_record(db: Session, company_id: int, user_id: int, data: FinancialRecordCreate) -> FinancialRecord:
    record = FinancialRecord(
        company_id=company_id,
        record_date=data.record_date,
        category=data.category,
        sub_category=data.sub_category,
        amount=data.amount,
        description=data.description,
        source=data.source,
        created_by=user_id,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def bulk_create_records(db: Session, company_id: int, user_id: int, records_data: list[dict]) -> int:
    records: list[FinancialRecord] = []
    for data in records_data:
        record = FinancialRecord(
            company_id=company_id,
            created_by=user_id,
            **data,
        )
        records.append(record)
    db.add_all(records)
    db.commit()
    return len(records)


def get_records(
    db: Session,
    company_id: int,
    category: str | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[FinancialRecord], int]:
    query = db.query(FinancialRecord).filter(FinancialRecord.company_id == company_id)

    if category:
        query = query.filter(FinancialRecord.category == category)
    if start_date:
        query = query.filter(FinancialRecord.record_date >= start_date)
    if end_date:
        query = query.filter(FinancialRecord.record_date <= end_date)

    total = query.count()
    items = query.order_by(FinancialRecord.record_date.desc()).offset(skip).limit(limit).all()
    return items, total


def _is_income(category: str) -> bool:
    # Support both normal Chinese and legacy mojibake values in old data.
    return ("收入" in category) or ("鏀跺叆" in category)


def _is_expense(category: str) -> bool:
    return ("支出" in category) or ("鏀嚭" in category)


def _is_asset(category: str) -> bool:
    return ("资产" in category) or ("璧勪骇" in category)


def _is_liability(category: str) -> bool:
    return ("负债" in category) or ("璐熷€" in category)


def get_summary(
    db: Session,
    company_id: int,
    start_date: date | None = None,
    end_date: date | None = None,
) -> FinancialSummary:
    query = db.query(FinancialRecord).filter(FinancialRecord.company_id == company_id)

    if start_date:
        query = query.filter(FinancialRecord.record_date >= start_date)
    if end_date:
        query = query.filter(FinancialRecord.record_date <= end_date)

    records = query.all()

    total_income = sum(float(r.amount) for r in records if _is_income(r.category))
    total_expense = sum(float(r.amount) for r in records if _is_expense(r.category))
    total_assets = sum(float(r.amount) for r in records if _is_asset(r.category))
    total_liabilities = sum(float(r.amount) for r in records if _is_liability(r.category))

    breakdown: dict[str, float] = {}
    for r in records:
        key = f"{r.category}-{r.sub_category or '其他'}"
        breakdown[key] = breakdown.get(key, 0.0) + float(r.amount)

    return FinancialSummary(
        total_income=round(total_income, 2),
        total_expense=round(total_expense, 2),
        net_profit=round(total_income - total_expense, 2),
        total_assets=round(total_assets, 2),
        total_liabilities=round(total_liabilities, 2),
        category_breakdown=breakdown,
    )


def _bucket_key(record_date: date, period: str) -> str:
    if period == "quarter":
        quarter = (record_date.month - 1) // 3 + 1
        return f"{record_date.year}-Q{quarter}"
    return record_date.strftime("%Y-%m")


def get_trend(
    db: Session,
    company_id: int,
    start_date: date | None = None,
    end_date: date | None = None,
    period: str = "month",
) -> FinancialTrend:
    query = db.query(FinancialRecord).filter(FinancialRecord.company_id == company_id)
    if start_date:
        query = query.filter(FinancialRecord.record_date >= start_date)
    if end_date:
        query = query.filter(FinancialRecord.record_date <= end_date)

    records = query.order_by(FinancialRecord.record_date.asc()).all()

    income_map: dict[str, float] = defaultdict(float)
    expense_map: dict[str, float] = defaultdict(float)
    periods: list[str] = []

    for r in records:
        key = _bucket_key(r.record_date, period)
        if key not in periods:
            periods.append(key)
        if _is_income(r.category):
            income_map[key] += float(r.amount)
        elif _is_expense(r.category):
            expense_map[key] += float(r.amount)

    return FinancialTrend(
        periods=periods,
        income=[round(income_map.get(k, 0.0), 2) for k in periods],
        expense=[round(expense_map.get(k, 0.0), 2) for k in periods],
    )


def get_cashflow(
    db: Session,
    company_id: int,
    start_date: date | None = None,
    end_date: date | None = None,
    period: str = "month",
) -> FinancialCashflow:
    trend = get_trend(
        db=db,
        company_id=company_id,
        start_date=start_date,
        end_date=end_date,
        period=period,
    )
    inflow = trend.income
    outflow = trend.expense
    net = [round(i - o, 2) for i, o in zip(inflow, outflow)]
    return FinancialCashflow(periods=trend.periods, inflow=inflow, outflow=outflow, net=net)
