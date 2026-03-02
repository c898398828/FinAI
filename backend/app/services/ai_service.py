from datetime import date, datetime

import numpy as np
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.financial_data import FinancialRecord
from app.models.alert import Alert, Budget


def detect_anomalies(db: Session, company_id: int) -> dict:
    """基于 Z-score 方法检测财务异常（支持全部分类，自动去重）"""
    records = (
        db.query(FinancialRecord)
        .filter(FinancialRecord.company_id == company_id)
        .order_by(FinancialRecord.record_date)
        .all()
    )

    if len(records) < 5:
        return {"anomalies": [], "summary": "数据不足，需要至少5条记录才能进行异常检测"}

    # 按月汇总所有分类（收入、支出、资产、负债）
    all_categories = ("收入", "支出", "资产", "负债")
    monthly: dict[str, dict[str, float]] = {}
    for r in records:
        key = r.record_date.strftime("%Y-%m")
        if key not in monthly:
            monthly[key] = {c: 0 for c in all_categories}
        if r.category in all_categories:
            monthly[key][r.category] += float(r.amount)

    # 查询已有告警的 message，用于去重
    existing_messages = set(
        msg for (msg,) in db.query(Alert.message)
        .filter(Alert.company_id == company_id)
        .all()
    )

    anomalies = []
    new_alerts = 0

    for category in all_categories:
        values = [m.get(category, 0) for m in monthly.values()]
        if len(values) < 3:
            continue

        arr = np.array(values)
        mean = np.mean(arr)
        std = np.std(arr)

        if std == 0:
            continue

        months = list(monthly.keys())
        for i, (month, val) in enumerate(zip(months, values)):
            z_score = (val - mean) / std
            if abs(z_score) > 2:
                severity = "high" if abs(z_score) > 3 else "medium"
                direction = "偏高" if z_score > 0 else "偏低"
                msg = f"{month} {category} ¥{val:,.2f} 明显{direction}（均值 ¥{mean:,.2f}）"
                anomaly = {
                    "month": month,
                    "category": category,
                    "amount": val,
                    "mean": round(mean, 2),
                    "z_score": round(z_score, 2),
                    "severity": severity,
                    "message": msg,
                }
                anomalies.append(anomaly)

                # 去重：已有相同 message 的告警则跳过
                if msg not in existing_messages:
                    alert = Alert(
                        company_id=company_id,
                        alert_type=f"{category}异常",
                        severity=severity,
                        message=msg,
                        data_json=anomaly,
                    )
                    db.add(alert)
                    existing_messages.add(msg)
                    new_alerts += 1

    db.commit()

    if anomalies:
        summary = f"检测到 {len(anomalies)} 条异常，新增 {new_alerts} 条预警"
    else:
        summary = "未检测到明显异常，财务数据正常"
    return {"anomalies": anomalies, "summary": summary}


def forecast_financials(db: Session, company_id: int, months_ahead: int = 3, persist: bool = False) -> dict:
    """基于移动平均进行财务预测，支持持久化到 Budget 表"""
    records = (
        db.query(FinancialRecord)
        .filter(FinancialRecord.company_id == company_id)
        .order_by(FinancialRecord.record_date)
        .all()
    )

    if len(records) < 3:
        return {"forecasts": [], "summary": "数据不足，需要至少3条记录才能进行预测"}

    # 按月汇总
    all_categories = ("收入", "支出", "资产", "负债")
    monthly: dict[str, dict[str, float]] = {}
    for r in records:
        key = r.record_date.strftime("%Y-%m")
        if key not in monthly:
            monthly[key] = {c: 0 for c in all_categories}
        if r.category in all_categories:
            monthly[key][r.category] += float(r.amount)

    months = sorted(monthly.keys())
    forecasts = []

    for category in all_categories:
        values = [monthly[m].get(category, 0) for m in months]
        if len(values) < 3:
            continue

        # 使用3个月移动平均
        window = min(3, len(values))
        recent = values[-window:]
        avg = np.mean(recent)

        # 计算趋势（简单线性）
        if len(values) >= 2:
            trend = (values[-1] - values[-2]) / max(abs(values[-2]), 1) * 100
        else:
            trend = 0

        last_month = months[-1]
        year, month = int(last_month[:4]), int(last_month[5:7])

        for i in range(1, months_ahead + 1):
            month += 1
            if month > 12:
                month = 1
                year += 1
            forecast_month = f"{year}-{month:02d}"
            predicted = round(avg * (1 + trend / 100 * 0.5), 2)

            forecasts.append({
                "month": forecast_month,
                "category": category,
                "predicted_amount": predicted,
                "trend_pct": round(trend, 2),
            })

            # 持久化预测结果到 Budget
            if persist and category in ("收入", "支出"):
                existing = (
                    db.query(Budget)
                    .filter(Budget.company_id == company_id, Budget.year == year, Budget.month == month, Budget.category == category)
                    .first()
                )
                if existing:
                    existing.forecast_amount = predicted
                else:
                    budget = Budget(
                        company_id=company_id,
                        year=year,
                        month=month,
                        category=category,
                        planned_amount=0,
                        forecast_amount=predicted,
                    )
                    db.add(budget)

    if persist:
        db.commit()

    if forecasts:
        categories_found = list(set(f["category"] for f in forecasts))
        summary = f"基于历史数据，已生成未来 {months_ahead} 个月的财务预测（{', '.join(categories_found)}）"
    else:
        summary = "历史数据月份跨度不足，每个类别至少需要3个月的记录才能生成预测"
    return {"forecasts": forecasts, "summary": summary}


def suggest_budgets(db: Session, company_id: int, year: int, month: int) -> dict:
    """基于历史数据生成预算建议"""
    records = (
        db.query(FinancialRecord)
        .filter(FinancialRecord.company_id == company_id)
        .all()
    )

    if not records:
        return {"suggestions": [], "summary": "无历史数据，无法生成预算建议"}

    # 按类别统计历史月平均
    category_totals: dict[str, list[float]] = {}
    monthly_data: dict[str, dict[str, float]] = {}

    for r in records:
        m = r.record_date.strftime("%Y-%m")
        cat = r.sub_category or r.category
        if m not in monthly_data:
            monthly_data[m] = {}
        monthly_data[m][cat] = monthly_data[m].get(cat, 0) + float(r.amount)

    for m, cats in monthly_data.items():
        for cat, amount in cats.items():
            if cat not in category_totals:
                category_totals[cat] = []
            category_totals[cat].append(amount)

    suggestions = []
    for cat, amounts in category_totals.items():
        avg = np.mean(amounts)
        suggested = round(avg * 1.05, 2)  # 在均值基础上增加5%缓冲
        suggestions.append({
            "category": cat,
            "historical_avg": round(avg, 2),
            "suggested_amount": suggested,
            "month_count": len(amounts),
        })

        # 保存预算记录
        existing = (
            db.query(Budget)
            .filter(Budget.company_id == company_id, Budget.year == year, Budget.month == month, Budget.category == cat)
            .first()
        )
        if not existing:
            budget = Budget(
                company_id=company_id,
                year=year,
                month=month,
                category=cat,
                planned_amount=suggested,
                forecast_amount=suggested,
            )
            db.add(budget)

    db.commit()

    summary = f"已为 {year}年{month}月 生成 {len(suggestions)} 个类别的预算建议"
    return {"suggestions": suggestions, "summary": summary}


def get_dashboard_ai_insights(db: Session, company_id: int) -> dict:
    """为仪表盘生成 AI 洞察摘要"""
    # 未读告警数
    unread_count = (
        db.query(func.count(Alert.id))
        .filter(Alert.company_id == company_id, Alert.is_read == False)
        .scalar() or 0
    )

    # 最近告警
    recent_alerts = (
        db.query(Alert)
        .filter(Alert.company_id == company_id)
        .order_by(Alert.created_at.desc())
        .limit(5)
        .all()
    )

    # 快速预测（不持久化）
    forecast = forecast_financials(db, company_id, months_ahead=1, persist=False)

    # 生成洞察文字
    insights = []

    if unread_count > 0:
        high_count = sum(1 for a in recent_alerts if a.severity == "high" and not a.is_read)
        if high_count > 0:
            insights.append(f"有 {high_count} 条高危预警待处理，请立即关注")
        else:
            insights.append(f"有 {unread_count} 条未读预警，建议及时查看")

    # 分析预测趋势
    for f in forecast.get("forecasts", []):
        cat = f["category"]
        trend = f["trend_pct"]
        if cat == "收入" and trend < -10:
            insights.append(f"预测下月收入将下降 {abs(trend):.1f}%，建议关注收入来源")
        elif cat == "支出" and trend > 15:
            insights.append(f"预测下月支出将增长 {trend:.1f}%，建议控制成本")
        elif cat == "收入" and trend > 10:
            insights.append(f"预测下月收入将增长 {trend:.1f}%，趋势良好")

    if not insights:
        insights.append("财务状况平稳，暂无异常")

    return {
        "unread_alert_count": unread_count,
        "recent_alerts": [
            {
                "id": a.id,
                "severity": a.severity,
                "message": a.message,
                "alert_type": a.alert_type,
                "created_at": a.created_at.isoformat() if a.created_at else "",
            }
            for a in recent_alerts[:3]
        ],
        "forecast_next_month": forecast.get("forecasts", [])[:4],
        "insights": insights,
    }


def get_alerts(db: Session, company_id: int, is_read: bool | None = None, skip: int = 0, limit: int = 50) -> tuple[list[Alert], int]:
    query = db.query(Alert).filter(Alert.company_id == company_id)
    if is_read is not None:
        query = query.filter(Alert.is_read == is_read)
    total = query.count()
    items = query.order_by(Alert.created_at.desc()).offset(skip).limit(limit).all()
    return items, total


def mark_alert_read(db: Session, alert_id: int) -> Alert | None:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if alert:
        alert.is_read = True
        db.commit()
        db.refresh(alert)
    return alert


def get_budgets(db: Session, company_id: int, year: int | None = None, skip: int = 0, limit: int = 50) -> tuple[list[Budget], int]:
    query = db.query(Budget).filter(Budget.company_id == company_id)
    if year:
        query = query.filter(Budget.year == year)
    total = query.count()
    items = query.order_by(Budget.year.desc(), Budget.month.desc()).offset(skip).limit(limit).all()
    return items, total
