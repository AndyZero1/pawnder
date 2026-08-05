import uuid
import enum
from sqlalchemy import Column, String, Boolean, DateTime, Enum, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Role(str, enum.Enum):
    OWNER = "OWNER"
    VETERINARY = "VETERINARY"
    ADMIN = "ADMIN"

class User(Base):
    __tablename__ = "users" 

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    hash_pass = Column(String(255), nullable=False)
    rol = Column(Enum(Role), default=Role.OWNER)
    is_premium = Column(Boolean, default=False)
    id_card_url = Column(String(255), nullable=True)
    photo_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    veterinary_profile = relationship("VeterinaryProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")

class VeterinaryProfile(Base):
    __tablename__ = "veterinary_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    cv_url = Column(String(255), nullable=True)
    recommendation_form_url = Column(String(255), nullable=True)
    cabinet_name = Column(String(150), nullable=True)
    is_checked = Column(Boolean, default=False)
    last_active_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="veterinary_profile")