import pandas as pd
from io import BytesIO


def parse_excel(file_content: bytes, filename: str) -> tuple[list[dict], list[str]]:
    """解析 Excel/CSV 文件，返回 (记录列表, 错误列表)"""
    errors = []
    records = []

    try:
        if filename.endswith(".csv"):
            df = pd.read_csv(BytesIO(file_content))
        else:
            df = pd.read_excel(BytesIO(file_content))
    except Exception as e:
        return [], [f"文件解析失败: {str(e)}"]

    required_columns = {"日期", "类别", "金额"}
    actual_columns = set(df.columns)

    # 支持英文列名映射
    column_map = {
        "date": "日期", "category": "类别", "amount": "金额",
        "sub_category": "子类别", "description": "描述",
    }
    df.rename(columns={k: v for k, v in column_map.items() if k in df.columns}, inplace=True)

    if not required_columns.issubset(set(df.columns)):
        missing = required_columns - set(df.columns)
        return [], [f"缺少必要列: {', '.join(missing)}。需要的列: 日期, 类别, 金额"]

    for idx, row in df.iterrows():
        try:
            record = {
                "record_date": pd.to_datetime(row["日期"]).date(),
                "category": str(row["类别"]).strip(),
                "amount": float(row["金额"]),
                "sub_category": str(row.get("子类别", "")) if pd.notna(row.get("子类别")) else None,
                "description": str(row.get("描述", "")) if pd.notna(row.get("描述")) else None,
                "source": "excel_import",
            }
            records.append(record)
        except Exception as e:
            errors.append(f"第 {idx + 2} 行解析失败: {str(e)}")

    return records, errors
