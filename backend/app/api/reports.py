from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database import get_db
from app.models.user import User
from app.schemas.report import ReportGenerate, ReportList, ReportOut
from app.services.report_export_service import build_report_excel
from app.services.report_service import generate_report, get_report_by_id, get_reports

router = APIRouter()


def _ensure_company(current_user: User):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="请先创建或加入企业")


@router.post("/generate", response_model=ReportOut)
def create_report(
    data: ReportGenerate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    return generate_report(db, current_user.company_id, data.report_type, data.period_start, data.period_end)


@router.get("/", response_model=ReportList)
def list_reports(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    items, total = get_reports(db, current_user.company_id, skip, limit)
    return ReportList(total=total, items=items)


@router.get("/{report_id}", response_model=ReportOut)
def get_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    report = get_report_by_id(db, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="报表不存在")
    if report.company_id != current_user.company_id:
        raise HTTPException(status_code=403, detail="无权限访问此报表")
    return report


@router.get("/{report_id}/export")
def export_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    report = get_report_by_id(db, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="报表不存在")
    if report.company_id != current_user.company_id:
        raise HTTPException(status_code=403, detail="无权限访问此报表")

    output = build_report_excel(report)
    filename = f"report_{report.id}_{report.report_type}_{report.period_start}_{report.period_end}.xlsx"
    return StreamingResponse(
        output,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
