from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.database import get_db
from app.models.alert import Alert, Budget
from app.models.company import Company
from app.models.financial_data import FinancialRecord
from app.models.report import Report
from app.models.user import User
from app.schemas.user import CompanyMemberInvite, CompanyMemberRoleUpdate, CompanySuperAdminTransfer, UserOut, UserUpdate
from app.services.auth_service import get_user_by_id, get_users

router = APIRouter()


def _is_enterprise_manager(user: User) -> bool:
    return bool(user.company_super_admin or user.role == "admin")


@router.get("/", response_model=list[UserOut])
def list_users(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="仅管理员可查看用户列表")
    return get_users(db, skip, limit)


@router.put("/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "admin" and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="无权限修改此用户")

    user = get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    if data.email is not None:
        user.email = data.email
    if data.role is not None and current_user.role == "admin":
        user.role = data.role
    if data.company_id is not None:
        user.company_id = data.company_id
    if data.company_super_admin is not None and current_user.role == "admin":
        user.company_super_admin = data.company_super_admin
    if data.is_active is not None and current_user.role == "admin":
        user.is_active = data.is_active

    db.commit()
    db.refresh(user)
    return user


@router.get("/company/members", response_model=list[UserOut])
def list_company_members(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")

    members = (
        db.query(User)
        .filter(User.company_id == current_user.company_id)
        .order_by(User.created_at.asc())
        .all()
    )
    return members


@router.post("/company/members/invite", response_model=UserOut)
def invite_company_member(
    data: CompanyMemberInvite,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")
    if not _is_enterprise_manager(current_user):
        raise HTTPException(status_code=403, detail="仅超级管理员或企业管理员可邀请成员")
    if data.role == "admin" and not current_user.company_super_admin:
        raise HTTPException(status_code=403, detail="仅超级管理员可设置企业管理员")

    if not data.username and not data.email:
        raise HTTPException(status_code=400, detail="请提供用户名或邮箱")

    if data.username and data.email:
        target = db.query(User).filter(User.username == data.username, User.email == data.email).first()
    else:
        filters = []
        if data.username:
            filters.append(User.username == data.username)
        if data.email:
            filters.append(User.email == data.email)
        target = db.query(User).filter(or_(*filters)).first()

    if not target:
        raise HTTPException(status_code=404, detail="被邀请用户不存在")

    if target.company_id == current_user.company_id:
        raise HTTPException(status_code=400, detail="该用户已在当前企业")
    if target.company_id and target.company_id != current_user.company_id:
        raise HTTPException(status_code=400, detail="该用户已加入其他企业")

    target.company_id = current_user.company_id
    target.company_super_admin = False
    target.role = data.role

    db.commit()
    db.refresh(target)
    return target


@router.put("/company/members/{user_id}/role", response_model=UserOut)
def set_company_member_role(
    user_id: int,
    data: CompanyMemberRoleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")
    if not _is_enterprise_manager(current_user):
        raise HTTPException(status_code=403, detail="仅超级管理员或企业管理员可分配成员权限")

    target = db.query(User).filter(User.id == user_id).first()
    if not target or target.company_id != current_user.company_id:
        raise HTTPException(status_code=404, detail="成员不存在")
    if target.company_super_admin:
        raise HTTPException(status_code=400, detail="不能修改超级管理员权限")
    if data.role == "admin" and not current_user.company_super_admin:
        raise HTTPException(status_code=403, detail="仅超级管理员可设置企业管理员")

    target.role = data.role
    db.commit()
    db.refresh(target)
    return target


@router.delete("/company/members/{user_id}", response_model=UserOut)
def remove_company_member(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")

    target = db.query(User).filter(User.id == user_id).first()
    if not target or target.company_id != current_user.company_id:
        raise HTTPException(status_code=404, detail="成员不存在")

    # 超级管理员不能被移除，只支持转移或解散企业
    if target.company_super_admin:
        raise HTTPException(status_code=400, detail="超级管理员仅支持转移或解散企业")

    is_self = current_user.id == user_id
    is_super_admin = bool(current_user.company_super_admin)
    is_admin = current_user.role == "admin"

    if is_self:
        # 自己可退出企业（超级管理员除外）
        if current_user.company_super_admin:
            raise HTTPException(status_code=400, detail="超级管理员仅支持转移或解散企业")
    else:
        if is_super_admin:
            # 超级管理员可移除除超级管理员外的成员
            pass
        elif is_admin:
            # 管理员不能移除超级管理员
            pass
        else:
            # 普通成员不支持移除他人
            raise HTTPException(status_code=403, detail="仅超级管理员或管理员可移除其他成员")

    target.company_id = None
    target.company_super_admin = False
    db.commit()
    db.refresh(target)
    return target


@router.post("/company/super-admin/transfer", response_model=UserOut)
def transfer_company_super_admin(
    data: CompanySuperAdminTransfer,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")
    if not current_user.company_super_admin:
        raise HTTPException(status_code=403, detail="仅企业超级管理员可执行转移")
    if data.target_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="不能转移给自己")

    target = (
        db.query(User)
        .filter(User.id == data.target_user_id, User.company_id == current_user.company_id)
        .first()
    )
    if not target:
        raise HTTPException(status_code=404, detail="目标成员不存在")

    current_user.company_super_admin = False
    target.company_super_admin = True
    db.commit()
    db.refresh(target)
    return target


@router.delete("/company", response_model=dict)
def dissolve_company(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.company_id:
        raise HTTPException(status_code=400, detail="当前用户未加入企业")
    if not current_user.company_super_admin:
        raise HTTPException(status_code=403, detail="仅企业超级管理员可解散企业")

    company_id = current_user.company_id
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="企业不存在")

    db.query(Alert).filter(Alert.company_id == company_id).delete(synchronize_session=False)
    db.query(Budget).filter(Budget.company_id == company_id).delete(synchronize_session=False)
    db.query(Report).filter(Report.company_id == company_id).delete(synchronize_session=False)
    db.query(FinancialRecord).filter(FinancialRecord.company_id == company_id).delete(synchronize_session=False)

    db.query(User).filter(User.company_id == company_id).update(
        {
            User.company_id: None,
            User.company_super_admin: False,
        },
        synchronize_session=False,
    )
    db.delete(company)
    db.commit()
    return {"message": "企业已解散"}
