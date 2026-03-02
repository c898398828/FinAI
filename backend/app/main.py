from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, users, financial, reports, alerts, ai_analysis
from app.database import engine, Base

Base.metadata.create_all(bind=engine)

app = FastAPI(title="F-AI 财务助理", version="1.0.0", description="AI 财务助理平台 API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["认证"])
app.include_router(users.router, prefix="/api/users", tags=["用户管理"])
app.include_router(financial.router, prefix="/api/financial", tags=["财务数据"])
app.include_router(reports.router, prefix="/api/reports", tags=["财务报表"])
app.include_router(alerts.router, prefix="/api/alerts", tags=["预警"])
app.include_router(ai_analysis.router, prefix="/api/ai", tags=["AI 分析"])


@app.get("/")
def root():
    return {"message": "F-AI 财务助理 API 服务运行中"}
