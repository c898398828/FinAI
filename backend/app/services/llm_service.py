import json
import logging
import time
from datetime import date
from typing import Generator

from openai import OpenAI
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.config import settings
from app.models.alert import Alert
from app.models.financial_data import FinancialRecord
from app.services.system_config_store import load_config, save_config

logger = logging.getLogger(__name__)

_runtime_config: dict[str, str] = {}
_LLM_CONFIG_KEYS = ["api_key", "base_url", "model"]
_config_loaded = False

SYSTEM_PROMPT = """你是 F-AI 财务助手，面向企业管理与财务人员。
请基于给定财务数据，给出清晰、可执行的中文分析。
要求：
1. 不输出 SQL 或开发代码。
2. 需要列表或对比时使用 Markdown 表格/项目符号。
3. 金额统一使用人民币格式（￥）并保留两位小数。
4. 结论简洁，建议可执行。
"""


def _load_runtime_config_from_store() -> None:
    global _config_loaded
    if _config_loaded:
        return
    persisted = load_config([f"llm.{key}" for key in _LLM_CONFIG_KEYS])
    for key in _LLM_CONFIG_KEYS:
        value = persisted.get(f"llm.{key}")
        if value is not None and value != "":
            _runtime_config[key] = value
    _config_loaded = True


def get_llm_config() -> dict:
    """获取当前生效的 LLM 配置（运行时 > .env）"""
    _load_runtime_config_from_store()
    return {
        "api_key": _runtime_config.get("api_key") or settings.LLM_API_KEY,
        "base_url": _runtime_config.get("base_url") or settings.LLM_BASE_URL,
        "model": _runtime_config.get("model") or settings.LLM_MODEL,
    }


def update_llm_config(api_key: str | None = None, base_url: str | None = None, model: str | None = None):
    """运行时更新 LLM 配置，并写入 SQLite 持久化"""
    _load_runtime_config_from_store()
    to_persist: dict[str, str] = {}
    if api_key is not None:
        _runtime_config["api_key"] = api_key
        to_persist["llm.api_key"] = api_key
    if base_url is not None:
        _runtime_config["base_url"] = base_url
        to_persist["llm.base_url"] = base_url
    if model is not None:
        _runtime_config["model"] = model
        to_persist["llm.model"] = model
    if to_persist:
        save_config(to_persist)


def _get_client() -> OpenAI:
    cfg = get_llm_config()
    if not cfg["api_key"] or cfg["api_key"].startswith("sk-your"):
        raise ValueError("请先在系统设置中配置有效的 LLM API Key")
    return OpenAI(api_key=cfg["api_key"], base_url=cfg["base_url"])


def test_llm_connection() -> dict:
    cfg = get_llm_config()
    if not cfg["api_key"] or cfg["api_key"].startswith("sk-your"):
        return {"success": False, "message": "请先配置有效的 API Key", "latency_ms": 0, "model": cfg["model"]}

    start = time.time()
    try:
        client = OpenAI(api_key=cfg["api_key"], base_url=cfg["base_url"])
        response = client.chat.completions.create(
            model=cfg["model"],
            messages=[{"role": "user", "content": "请仅回复：OK"}],
            max_tokens=10,
            timeout=15,
        )
        latency = int((time.time() - start) * 1000)
        reply = response.choices[0].message.content or ""
        return {"success": True, "message": f"连接成功，模型回复: {reply}", "latency_ms": latency, "model": cfg["model"]}
    except Exception as e:
        latency = int((time.time() - start) * 1000)
        return {"success": False, "message": f"连接失败: {str(e)}", "latency_ms": latency, "model": cfg["model"]}


def _get_financial_context(db: Session, company_id: int) -> str:
    records = (
        db.query(
            FinancialRecord.category,
            func.sum(FinancialRecord.amount).label("total"),
            func.count(FinancialRecord.id).label("cnt"),
        )
        .filter(FinancialRecord.company_id == company_id)
        .group_by(FinancialRecord.category)
        .all()
    )
    if not records:
        return "该企业暂无财务数据。"

    lines = ["【财务摘要】"]
    for r in records:
        lines.append(f"- {r.category}: {int(r.cnt)} 条，合计 ￥{float(r.total):,.2f}")

    recent = (
        db.query(FinancialRecord)
        .filter(FinancialRecord.company_id == company_id)
        .order_by(FinancialRecord.record_date.desc())
        .limit(20)
        .all()
    )
    if recent:
        lines.append("\n【最近交易（20 条）】")
        for r in recent:
            sub = f"/{r.sub_category}" if r.sub_category else ""
            lines.append(f"- {r.record_date} | {r.category}{sub} | ￥{float(r.amount):,.2f} | {r.description or ''}")

    unread_alerts = (
        db.query(Alert)
        .filter(Alert.company_id == company_id, Alert.is_read.is_(False))
        .order_by(Alert.created_at.desc())
        .limit(5)
        .all()
    )
    if unread_alerts:
        lines.append("\n【未读预警】")
        for a in unread_alerts:
            lines.append(f"- [{a.severity}] {a.message}")

    return "\n".join(lines)


def prepare_chat_messages(
    db: Session,
    company_id: int,
    user_message: str,
    history: list[dict] | None = None,
) -> list[dict]:
    context = _get_financial_context(db, company_id)
    messages = [{"role": "system", "content": SYSTEM_PROMPT + "\n\n" + context}]
    if history:
        for h in history[-10:]:
            role = h.get("role")
            content = h.get("content")
            if role in {"user", "assistant", "system"} and content:
                messages.append({"role": role, "content": str(content)})
    messages.append({"role": "user", "content": user_message})
    return messages


def chat_with_ai(
    db: Session,
    company_id: int,
    user_message: str,
    history: list[dict] | None = None,
) -> str:
    client = _get_client()
    cfg = get_llm_config()
    messages = prepare_chat_messages(db, company_id, user_message, history)

    try:
        response = client.chat.completions.create(
            model=cfg["model"],
            messages=messages,
            temperature=0.5,
            max_tokens=2000,
        )
        return response.choices[0].message.content or "抱歉，AI 暂时无法回答。"
    except Exception as e:
        logger.error("LLM API call failed: %s", e)
        raise


def stream_chat_with_ai(messages: list[dict]) -> Generator[str, None, None]:
    client = _get_client()
    cfg = get_llm_config()
    response = client.chat.completions.create(
        model=cfg["model"],
        messages=messages,
        temperature=0.5,
        max_tokens=2000,
        stream=True,
    )
    for chunk in response:
        if chunk.choices and chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content


def analyze_report_with_llm(report_data: dict, report_type: str) -> str:
    client = _get_client()
    cfg = get_llm_config()
    type_names = {
        "profit_loss": "利润表",
        "balance_sheet": "资产负债表",
        "cash_flow": "现金流量表",
    }

    clean_data = {k: v for k, v in report_data.items() if k != "AI分析"}
    prompt = f"""以下是{type_names.get(report_type, '财务报表')}数据：
{json.dumps(clean_data, ensure_ascii=False, indent=2)}

请输出：
1. 整体概况（2-3句）
2. 关键指标变化与原因
3. 风险提示
4. 下一步建议（3条以内）
"""

    try:
        response = client.chat.completions.create(
            model=cfg["model"],
            messages=[
                {"role": "system", "content": "你是专业财务分析师，用中文输出。"},
                {"role": "user", "content": prompt},
            ],
            temperature=0.4,
            max_tokens=1500,
        )
        return response.choices[0].message.content or ""
    except Exception as e:
        logger.error("LLM report analysis failed: %s", e)
        return ""


def analyze_anomalies_with_llm(anomalies: list[dict]) -> str:
    if not anomalies:
        return "未检测到异常，财务数据整体稳定。"

    client = _get_client()
    cfg = get_llm_config()
    prompt = f"""以下是异常检测结果：
{json.dumps(anomalies, ensure_ascii=False, indent=2)}

请按条目给出：
1. 可能原因
2. 风险等级建议
3. 对应处理动作
"""

    try:
        response = client.chat.completions.create(
            model=cfg["model"],
            messages=[
                {"role": "system", "content": "你是财务风控专家，用中文输出。"},
                {"role": "user", "content": prompt},
            ],
            temperature=0.4,
            max_tokens=1500,
        )
        return response.choices[0].message.content or ""
    except Exception as e:
        logger.error("LLM anomaly analysis failed: %s", e)
        return ""


def generate_budget_advice_with_llm(suggestions: list[dict], year: int, month: int) -> str:
    client = _get_client()
    cfg = get_llm_config()
    prompt = f"""以下是 {year}年{month}月 预算建议数据：
{json.dumps(suggestions, ensure_ascii=False, indent=2)}

请输出：
1. 总体预算策略
2. 成本优化重点
3. 收入提升建议
4. 执行计划（3步）
"""

    try:
        response = client.chat.completions.create(
            model=cfg["model"],
            messages=[
                {"role": "system", "content": "你是企业预算规划顾问，用中文输出。"},
                {"role": "user", "content": prompt},
            ],
            temperature=0.4,
            max_tokens=1500,
        )
        return response.choices[0].message.content or ""
    except Exception as e:
        logger.error("LLM budget advice failed: %s", e)
        return ""


def _extract_json(text: str) -> dict:
    payload = (text or "").strip()
    if payload.startswith("```"):
        payload = payload.strip("`")
        lines = payload.splitlines()
        if lines and lines[0].lower().strip() in {"json", "javascript"}:
            lines = lines[1:]
        payload = "\n".join(lines).strip()

    try:
        return json.loads(payload)
    except Exception:
        start = payload.find("{")
        end = payload.rfind("}")
        if start >= 0 and end > start:
            return json.loads(payload[start : end + 1])
        raise


def _add_month(month_str: str, offset: int) -> str:
    y, m = month_str.split("-")
    year = int(y)
    month = int(m)
    month += offset
    while month > 12:
        month -= 12
        year += 1
    while month <= 0:
        month += 12
        year -= 1
    return f"{year:04d}-{month:02d}"


def _build_monthly_history(db: Session, company_id: int, max_rows: int = 24) -> list[dict]:
    records = (
        db.query(FinancialRecord)
        .filter(FinancialRecord.company_id == company_id)
        .order_by(FinancialRecord.record_date.asc())
        .all()
    )
    monthly: dict[str, dict[str, float]] = {}
    for r in records:
        month = r.record_date.strftime("%Y-%m")
        monthly.setdefault(month, {})
        key = r.sub_category or r.category
        monthly[month][key] = monthly[month].get(key, 0.0) + float(r.amount)
    rows = [{"month": m, "items": v} for m, v in sorted(monthly.items())]
    return rows[-max_rows:]


def llm_forecast_financials(
    db: Session,
    company_id: int,
    months_ahead: int = 3,
) -> dict:
    history = _build_monthly_history(db, company_id)
    if not history:
        return {"forecasts": [], "summary": "暂无历史数据，无法生成预测。"}

    client = _get_client()
    cfg = get_llm_config()
    last_month = history[-1]["month"]
    target_months = [_add_month(last_month, i + 1) for i in range(max(months_ahead, 1))]

    prompt = f"""
基于以下月度历史数据，预测未来 {months_ahead} 个月。
历史数据：{json.dumps(history, ensure_ascii=False)}
目标月份：{json.dumps(target_months, ensure_ascii=False)}

仅返回 JSON：
{{
  "summary": "一句总结",
  "forecasts": [
    {{"month":"YYYY-MM","category":"收入|支出|其他","predicted_amount":123.45,"trend_pct":1.23}}
  ]
}}
要求：
1. 必须覆盖每个目标月份的“收入、支出”两类。
2. predicted_amount >= 0，trend_pct 保留两位小数。
3. 不能返回代码块。
"""

    response = client.chat.completions.create(
        model=cfg["model"],
        messages=[
            {"role": "system", "content": "你是财务预测模型，只输出 JSON。"},
            {"role": "user", "content": prompt},
        ],
        temperature=0.2,
        max_tokens=2000,
    )

    raw = response.choices[0].message.content or "{}"
    data = _extract_json(raw)
    forecasts = data.get("forecasts", []) if isinstance(data, dict) else []
    summary = data.get("summary", "预测完成") if isinstance(data, dict) else "预测完成"

    normalized = []
    if isinstance(forecasts, list):
        for item in forecasts:
            if not isinstance(item, dict):
                continue
            month = str(item.get("month", "")).strip()
            category = str(item.get("category", "")).strip() or "其他"
            try:
                predicted_amount = round(max(float(item.get("predicted_amount", 0)), 0), 2)
                trend_pct = round(float(item.get("trend_pct", 0)), 2)
            except Exception:
                continue
            if month:
                normalized.append(
                    {
                        "month": month,
                        "category": category,
                        "predicted_amount": predicted_amount,
                        "trend_pct": trend_pct,
                    }
                )

    return {"forecasts": normalized, "summary": summary}


def llm_suggest_budgets(
    db: Session,
    company_id: int,
    year: int,
    month: int,
) -> dict:
    history = _build_monthly_history(db, company_id)
    if not history:
        return {"suggestions": [], "summary": "暂无历史数据，无法生成预算建议。"}

    client = _get_client()
    cfg = get_llm_config()
    prompt = f"""
基于以下月度历史数据，为 {year}年{month}月 输出预算建议。
历史数据：{json.dumps(history, ensure_ascii=False)}

仅返回 JSON：
{{
  "summary": "一句总结",
  "suggestions": [
    {{"category":"类别","historical_avg":1000.0,"suggested_amount":1100.0,"month_count":6}}
  ]
}}
要求：
1. suggested_amount >= 0。
2. month_count 为正整数。
3. 覆盖核心收支类目。
4. 不能返回代码块。
"""

    response = client.chat.completions.create(
        model=cfg["model"],
        messages=[
            {"role": "system", "content": "你是预算规划模型，只输出 JSON。"},
            {"role": "user", "content": prompt},
        ],
        temperature=0.2,
        max_tokens=2000,
    )

    raw = response.choices[0].message.content or "{}"
    data = _extract_json(raw)
    suggestions = data.get("suggestions", []) if isinstance(data, dict) else []
    summary = data.get("summary", f"{year}年{month}月预算建议已生成") if isinstance(data, dict) else f"{year}年{month}月预算建议已生成"

    normalized = []
    if isinstance(suggestions, list):
        for item in suggestions:
            if not isinstance(item, dict):
                continue
            category = str(item.get("category", "")).strip()
            if not category:
                continue
            try:
                historical_avg = round(max(float(item.get("historical_avg", 0)), 0), 2)
                suggested_amount = round(max(float(item.get("suggested_amount", 0)), 0), 2)
                month_count = int(item.get("month_count", 0))
            except Exception:
                continue
            normalized.append(
                {
                    "category": category,
                    "historical_avg": historical_avg,
                    "suggested_amount": suggested_amount,
                    "month_count": max(month_count, 1),
                }
            )

    return {"suggestions": normalized, "summary": summary}
