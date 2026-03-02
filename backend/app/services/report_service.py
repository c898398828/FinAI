from datetime import date

import numpy as np
from sqlalchemy.orm import Session

from app.models.financial_data import FinancialRecord
from app.models.report import Report


REPORT_TYPE_NAMES = {
    "profit_loss": "利润表",
    "balance_sheet": "资产负债表",
    "cash_flow": "现金流量表",
}


def generate_report(
    db: Session,
    company_id: int,
    report_type: str,
    period_start: date,
    period_end: date,
) -> Report:
    records = (
        db.query(FinancialRecord)
        .filter(
            FinancialRecord.company_id == company_id,
            FinancialRecord.record_date >= period_start,
            FinancialRecord.record_date <= period_end,
        )
        .all()
    )

    if report_type == "profit_loss":
        data = _build_profit_loss(records)
    elif report_type == "balance_sheet":
        data = _build_balance_sheet(records)
    elif report_type == "cash_flow":
        data = _build_cash_flow(records)
    else:
        data = {}

    # AI 增强：加入趋势分析和智能摘要
    ai_analysis = _generate_ai_analysis(records, report_type, period_start, period_end)
    data["AI分析"] = ai_analysis

    title = f"{REPORT_TYPE_NAMES.get(report_type, report_type)} ({period_start} ~ {period_end})"

    report = Report(
        company_id=company_id,
        report_type=report_type,
        title=title,
        period_start=period_start,
        period_end=period_end,
        data_json=data,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report


def get_reports(db: Session, company_id: int, skip: int = 0, limit: int = 20) -> tuple[list[Report], int]:
    query = db.query(Report).filter(Report.company_id == company_id)
    total = query.count()
    items = query.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()
    return items, total


def get_report_by_id(db: Session, report_id: int) -> Report | None:
    return db.query(Report).filter(Report.id == report_id).first()


def _build_profit_loss(records: list[FinancialRecord]) -> dict:
    income_items: dict[str, float] = {}
    expense_items: dict[str, float] = {}

    for r in records:
        sub = r.sub_category or "其他"
        if r.category == "收入":
            income_items[sub] = income_items.get(sub, 0) + float(r.amount)
        elif r.category == "支出":
            expense_items[sub] = expense_items.get(sub, 0) + float(r.amount)

    total_income = sum(income_items.values())
    total_expense = sum(expense_items.values())

    return {
        "收入明细": income_items,
        "支出明细": expense_items,
        "收入合计": total_income,
        "支出合计": total_expense,
        "净利润": total_income - total_expense,
    }


def _build_balance_sheet(records: list[FinancialRecord]) -> dict:
    asset_items: dict[str, float] = {}
    liability_items: dict[str, float] = {}

    for r in records:
        sub = r.sub_category or "其他"
        if r.category == "资产":
            asset_items[sub] = asset_items.get(sub, 0) + float(r.amount)
        elif r.category == "负债":
            liability_items[sub] = liability_items.get(sub, 0) + float(r.amount)

    total_assets = sum(asset_items.values())
    total_liabilities = sum(liability_items.values())

    return {
        "资产明细": asset_items,
        "负债明细": liability_items,
        "资产合计": total_assets,
        "负债合计": total_liabilities,
        "所有者权益": total_assets - total_liabilities,
    }


def _build_cash_flow(records: list[FinancialRecord]) -> dict:
    inflow: dict[str, float] = {}
    outflow: dict[str, float] = {}

    for r in records:
        sub = r.sub_category or "其他"
        if r.category == "收入":
            inflow[sub] = inflow.get(sub, 0) + float(r.amount)
        elif r.category == "支出":
            outflow[sub] = outflow.get(sub, 0) + float(r.amount)

    total_inflow = sum(inflow.values())
    total_outflow = sum(outflow.values())

    return {
        "现金流入": inflow,
        "现金流出": outflow,
        "流入合计": total_inflow,
        "流出合计": total_outflow,
        "净现金流": total_inflow - total_outflow,
    }


def _generate_ai_analysis(
    records: list[FinancialRecord],
    report_type: str,
    period_start: date,
    period_end: date,
) -> dict:
    """为报表生成 AI 分析：趋势分析 + 异常标注 + 智能摘要"""
    if not records:
        return {"摘要": "暂无数据，无法生成分析", "趋势": [], "异常项": []}

    # 按月汇总
    monthly: dict[str, dict[str, float]] = {}
    for r in records:
        key = r.record_date.strftime("%Y-%m")
        if key not in monthly:
            monthly[key] = {"收入": 0, "支出": 0, "资产": 0, "负债": 0}
        if r.category in monthly[key]:
            monthly[key][r.category] += float(r.amount)

    months_sorted = sorted(monthly.keys())
    trends = []
    anomaly_items = []
    summary_parts = []

    # 根据报表类型选择分析维度
    if report_type == "profit_loss":
        analyze_cats = ["收入", "支出"]
    elif report_type == "balance_sheet":
        analyze_cats = ["资产", "负债"]
    else:
        analyze_cats = ["收入", "支出"]

    for cat in analyze_cats:
        values = [monthly[m].get(cat, 0) for m in months_sorted]
        if len(values) < 2:
            continue

        # 趋势分析
        first_val = values[0] if values[0] != 0 else 1
        change_pct = round((values[-1] - values[0]) / abs(first_val) * 100, 1)
        avg_val = round(float(np.mean(values)), 2)
        direction = "增长" if change_pct > 0 else "下降"

        trends.append({
            "类别": cat,
            "期初": round(values[0], 2),
            "期末": round(values[-1], 2),
            "变化": f"{'+' if change_pct > 0 else ''}{change_pct}%",
            "月均": avg_val,
        })

        # 异常检测（Z-score）
        if len(values) >= 3:
            arr = np.array(values)
            mean = np.mean(arr)
            std = np.std(arr)
            if std > 0:
                for i, (m, v) in enumerate(zip(months_sorted, values)):
                    z = (v - mean) / std
                    if abs(z) > 2:
                        anomaly_items.append({
                            "月份": m,
                            "类别": cat,
                            "金额": round(v, 2),
                            "偏离程度": f"{'偏高' if z > 0 else '偏低'} {abs(z):.1f} 个标准差",
                        })

        # 摘要生成
        if abs(change_pct) > 20:
            summary_parts.append(f"{cat}在报表期间{direction} {abs(change_pct)}%，变化幅度较大")
        elif abs(change_pct) > 5:
            summary_parts.append(f"{cat}小幅{direction} {abs(change_pct)}%")
        else:
            summary_parts.append(f"{cat}基本持平")

    # 特定报表类型补充
    if report_type == "profit_loss":
        income_vals = [monthly[m].get("收入", 0) for m in months_sorted]
        expense_vals = [monthly[m].get("支出", 0) for m in months_sorted]
        total_income = sum(income_vals)
        total_expense = sum(expense_vals)
        if total_income > 0:
            margin = round((total_income - total_expense) / total_income * 100, 1)
            summary_parts.append(f"期间利润率为 {margin}%")
    elif report_type == "balance_sheet":
        asset_vals = [monthly[m].get("资产", 0) for m in months_sorted]
        liability_vals = [monthly[m].get("负债", 0) for m in months_sorted]
        total_a = sum(asset_vals)
        total_l = sum(liability_vals)
        if total_a > 0:
            ratio = round(total_l / total_a * 100, 1)
            summary_parts.append(f"资产负债率为 {ratio}%")

    if anomaly_items:
        summary_parts.append(f"共发现 {len(anomaly_items)} 处异常波动")

    summary = "；".join(summary_parts) + "。" if summary_parts else "数据量较少，分析结果仅供参考。"

    return {
        "摘要": summary,
        "趋势": trends,
        "异常项": anomaly_items,
    }
