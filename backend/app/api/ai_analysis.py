import json
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database import get_db
from app.models.alert import Budget
from app.models.user import User
from app.schemas.alert import AnomalyResult, BudgetSuggestion, ForecastResult
from app.services.ai_service import detect_anomalies, get_dashboard_ai_insights
from app.services.llm_service import (
    analyze_anomalies_with_llm,
    analyze_report_with_llm,
    chat_with_ai,
    generate_budget_advice_with_llm,
    get_llm_config,
    llm_forecast_financials,
    llm_suggest_budgets,
    prepare_chat_messages,
    stream_chat_with_ai,
    test_llm_connection,
    update_llm_config,
)

router = APIRouter()


def _ensure_company(current_user: User):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="请先创建或加入企业")


def _is_income_or_expense(category: str) -> bool:
    return bool(category) and (
        ("收入" in category)
        or ("支出" in category)
        or ("鏀跺叆" in category)
        or ("鏀嚭" in category)
    )


@router.post("/anomaly-detect", response_model=AnomalyResult)
def anomaly_detection(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    result = detect_anomalies(db, current_user.company_id)
    try:
        result["llm_analysis"] = analyze_anomalies_with_llm(result.get("anomalies", []))
    except Exception:
        result["llm_analysis"] = ""
    return result


@router.post("/forecast", response_model=ForecastResult)
def financial_forecast(
    months_ahead: int = 3,
    persist: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    try:
        # Pure LLM path: no rule-based forecasting.
        result = llm_forecast_financials(db, current_user.company_id, months_ahead)
        if persist and result.get("forecasts"):
            for item in result["forecasts"]:
                month_str = str(item.get("month", ""))
                if len(month_str) != 7 or "-" not in month_str:
                    continue
                year_i, month_i = month_str.split("-")
                try:
                    y = int(year_i)
                    m = int(month_i)
                    amount = float(item.get("predicted_amount", 0))
                except Exception:
                    continue
                category = str(item.get("category", "")).strip() or "其他"
                if not _is_income_or_expense(category):
                    continue
                existing = (
                    db.query(Budget)
                    .filter(
                        Budget.company_id == current_user.company_id,
                        Budget.year == y,
                        Budget.month == m,
                        Budget.category == category,
                    )
                    .first()
                )
                if existing:
                    existing.forecast_amount = amount
                else:
                    db.add(
                        Budget(
                            company_id=current_user.company_id,
                            year=y,
                            month=m,
                            category=category,
                            planned_amount=0,
                            forecast_amount=amount,
                        )
                    )
            db.commit()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM 预测失败: {str(e)}")


@router.post("/budget-suggest", response_model=BudgetSuggestion)
def budget_suggestion(
    year: int | None = None,
    month: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    today = date.today()
    if year is None:
        year = today.year
    if month is None:
        month = today.month

    try:
        # Pure LLM path: no rule-based budget suggestion.
        result = llm_suggest_budgets(db, current_user.company_id, year, month)
        for item in result.get("suggestions", []):
            category = str(item.get("category", "")).strip()
            if not category:
                continue
            try:
                suggested = float(item.get("suggested_amount", 0))
            except Exception:
                continue
            existing = (
                db.query(Budget)
                .filter(
                    Budget.company_id == current_user.company_id,
                    Budget.year == year,
                    Budget.month == month,
                    Budget.category == category,
                )
                .first()
            )
            if not existing:
                db.add(
                    Budget(
                        company_id=current_user.company_id,
                        year=year,
                        month=month,
                        category=category,
                        planned_amount=suggested,
                        forecast_amount=suggested,
                    )
                )
        db.commit()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM 预算建议失败: {str(e)}")

    # Optional narrative text for compatibility with existing UI fields.
    try:
        result["llm_advice"] = generate_budget_advice_with_llm(result.get("suggestions", []), year, month)
    except Exception:
        result["llm_advice"] = ""
    return result


@router.get("/dashboard-insights")
def dashboard_insights(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    return get_dashboard_ai_insights(db, current_user.company_id)


class ChatRequest(BaseModel):
    message: str
    history: list[dict] | None = None


class ChatResponse(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatResponse)
def ai_chat(
    req: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    try:
        reply = chat_with_ai(db, current_user.company_id, req.message, req.history)
        return ChatResponse(reply=reply)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 服务异常: {str(e)}")


@router.post("/chat/stream")
def ai_chat_stream(
    req: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    messages = prepare_chat_messages(db, current_user.company_id, req.message, req.history)

    def event_generator():
        try:
            for token in stream_chat_with_ai(messages):
                yield f"data: {json.dumps({'content': token}, ensure_ascii=False)}\n\n"
            yield "data: [DONE]\n\n"
        except ValueError as e:
            yield f"data: {json.dumps({'error': str(e)}, ensure_ascii=False)}\n\n"
        except Exception as e:
            yield f"data: {json.dumps({'error': f'AI 服务异常: {str(e)}'}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


class ReportAnalysisRequest(BaseModel):
    report_data: dict
    report_type: str


class ReportAnalysisResponse(BaseModel):
    analysis: str


@router.post("/analyze-report", response_model=ReportAnalysisResponse)
def analyze_report(
    req: ReportAnalysisRequest,
    current_user: User = Depends(get_current_user),
):
    _ensure_company(current_user)
    try:
        analysis = analyze_report_with_llm(req.report_data, req.report_type)
        return ReportAnalysisResponse(analysis=analysis)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 分析失败: {str(e)}")


class LLMConfigUpdate(BaseModel):
    api_key: str | None = None
    base_url: str | None = None
    model: str | None = None


@router.get("/config")
def read_llm_config(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="仅管理员可查看 AI 配置")
    cfg = get_llm_config()
    key = cfg["api_key"]
    if key and len(key) > 10:
        masked = key[:6] + "*" * (len(key) - 10) + key[-4:]
    else:
        masked = "未配置"
    return {
        "api_key_masked": masked,
        "base_url": cfg["base_url"],
        "model": cfg["model"],
        "has_key": bool(key and not key.startswith("sk-your")),
    }


@router.put("/config")
def save_llm_config(
    data: LLMConfigUpdate,
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="仅管理员可修改 AI 配置")
    update_llm_config(api_key=data.api_key, base_url=data.base_url, model=data.model)
    return {"message": "配置已更新", **get_llm_config()}


@router.post("/config/test")
def test_connection(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="仅管理员可测试 AI 连接")
    return test_llm_connection()
