import random

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.models.user import User
from app.models.company import Company
from app.schemas.user import UserCreate
from app.utils.security import hash_password, verify_password, create_access_token


def create_user(db: Session, user_data: UserCreate) -> User:
    hashed_pw = hash_password(user_data.password)
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_pw,
        role=user_data.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, username: str, password: str) -> User | None:
    user = db.query(User).filter(User.username == username).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user


def login_user(db: Session, username: str, password: str) -> str | None:
    user = authenticate_user(db, username, password)
    if not user:
        return None
    token = create_access_token({"sub": str(user.id)})
    return token


def get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_username(db: Session, username: str) -> User | None:
    return db.query(User).filter(User.username == username).first()


def get_users(db: Session, skip: int = 0, limit: int = 50) -> list[User]:
    return db.query(User).offset(skip).limit(limit).all()


def _generate_company_id(db: Session) -> int:
    """Generate a unique random 9-digit company ID."""
    for _ in range(20):
        company_id = random.randint(100_000_000, 999_999_999)
        exists = db.query(Company.id).filter(Company.id == company_id).first()
        if not exists:
            return company_id
    raise ValueError("无法生成可用的企业 ID，请稍后重试")


def create_company(db: Session, name: str, industry: str | None = None) -> Company:
    for _ in range(3):
        company = Company(id=_generate_company_id(db), name=name, industry=industry)
        db.add(company)
        try:
            db.commit()
            db.refresh(company)
            return company
        except IntegrityError:
            db.rollback()
    raise ValueError("企业创建失败，请稍后重试")


def get_company_by_id(db: Session, company_id: int) -> Company | None:
    return db.query(Company).filter(Company.id == company_id).first()
