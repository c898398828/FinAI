from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.alert import AlertOut, AlertList, BudgetCreate, BudgetOut, BudgetList
from app.services.ai_service import get_alerts, mark_alert_read, get_budgets
from app.api.deps import get_current_user
from app.models.user import User
from app.models.alert import Budget

router = APIRouter()


@router.get("/", response_model=AlertList)
def list_alerts(
    is_read: bool | None = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="请先创建或加入企业")
    items, total = get_alerts(db, current_user.company_id, is_read, skip, limit)
    return AlertList(total=total, items=items)


@router.put("/{alert_id}/read", response_model=AlertOut)
def read_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    alert = mark_alert_read(db, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="预警不存在")
    return alert


@router.get("/budgets", response_model=BudgetList)
def list_budgets(
    year: int | None = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="请先创建或加入企业")
    items, total = get_budgets(db, current_user.company_id, year, skip, limit)
    return BudgetList(total=total, items=items)


@router.post("/budgets", response_model=BudgetOut)
def create_budget(
    data: BudgetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="请先创建或加入企业")
    budget = Budget(
        company_id=current_user.company_id,
        year=data.year,
        month=data.month,
        category=data.category,
        planned_amount=data.planned_amount,
    )
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget
