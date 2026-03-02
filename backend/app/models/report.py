from datetime import datetime, date

from sqlalchemy import Integer, String, Date, DateTime, ForeignKey, Enum, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    company_id: Mapped[int] = mapped_column(Integer, ForeignKey("companies.id"))
    report_type: Mapped[str] = mapped_column(
        Enum("profit_loss", "balance_sheet", "cash_flow", name="report_type")
    )
    title: Mapped[str | None] = mapped_column(String(200), nullable=True)
    period_start: Mapped[date] = mapped_column(Date)
    period_end: Mapped[date] = mapped_column(Date)
    data_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
