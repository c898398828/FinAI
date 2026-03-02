from datetime import datetime, date

from sqlalchemy import Integer, String, Date, DateTime, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class FinancialRecord(Base):
    __tablename__ = "financial_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    company_id: Mapped[int] = mapped_column(Integer, ForeignKey("companies.id"))
    record_date: Mapped[date] = mapped_column(Date)
    category: Mapped[str] = mapped_column(String(50))
    sub_category: Mapped[str | None] = mapped_column(String(50), nullable=True)
    amount: Mapped[float] = mapped_column(Numeric(15, 2))
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
    source: Mapped[str | None] = mapped_column(String(50), nullable=True, default="manual")
    created_by: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
