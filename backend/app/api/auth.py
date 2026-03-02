from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.user import UserCreate, UserLogin, UserOut, Token, CompanyCreate, CompanyJoin, CompanyOut
from app.services.auth_service import (
    create_user,
    login_user,
    get_user_by_username,
    create_company,
    get_company_by_id,
)
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.post("/register", response_model=UserOut)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    existing = get_user_by_username(db, user_data.username)
    if existing:
        raise HTTPException(status_code=400, detail="用户名已存在")
    user = create_user(db, user_data)
    return user


@router.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    token = login_user(db, user_data.username, user_data.password)
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="用户名或密码错误")
    return Token(access_token=token)


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/company", response_model=CompanyOut)
def create_new_company(
    data: CompanyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.company_id:
        raise HTTPException(status_code=400, detail="当前账号已加入企业，不能重复创建")

    try:
        company = create_company(db, data.name, data.industry)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    # 将当前用户关联到公司
    current_user.company_id = company.id
    current_user.company_super_admin = True
    db.commit()
    return company


@router.post("/company/join", response_model=CompanyOut)
def join_company(
    data: CompanyJoin,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.company_id:
        raise HTTPException(status_code=400, detail="当前账号已加入企业")

    company = get_company_by_id(db, data.company_id)
    if not company:
        raise HTTPException(status_code=404, detail="企业不存在，请检查企业 ID")

    current_user.company_id = company.id
    current_user.company_super_admin = False
    # 通过企业 ID 主动加入时，默认设置为查看者；企业管理员由超级管理员分配
    current_user.role = "viewer"
    db.commit()
    return company
