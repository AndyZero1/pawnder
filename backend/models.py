import uuid
import enum
from sqlalchemy import Column, String, Boolean, DateTime, Enum, ForeignKey, Text, Float, Date
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

# ENUMS
class Role(str, enum.Enum):
    OWNER = "OWNER"
    VETERINARY = "VETERINARY"
    ADMIN = "ADMIN"

class LocationType(str, enum.Enum):
    PET_FRIENDLY = "PET_FRIENDLY"
    VET_CLINIC = "VET_CLINIC"
    HIDDEN_GEM = "HIDDEN_GEM"

class MessageStatus(str, enum.Enum):
    SENT = "SENT"
    DELIVERED = "DELIVERED"
    READ = "READ"

class ConsultationStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACTIVE = "ACTIVE"
    CLOSED = "CLOSED"

# MODELS
class User(Base):
    __tablename__ = "users" 

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    hash_pass = Column(String(255), nullable=False)
    rol = Column(Enum(Role), default=Role.OWNER)
    birth_date = Column(DateTime(timezone=True), nullable=True)
    is_premium = Column(Boolean, default=False)
    is_identity_verified = Column(Boolean, default=False)
    id_card_url = Column(String(255), nullable=True)
    photo_url = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    veterinary_profile = relationship("VeterinaryProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    pets = relationship("Pet", back_populates="owner", cascade="all, delete-orphan")
    events = relationship("Event", back_populates="organizer")
    missing_pet_posts = relationship("MissingPetPost", back_populates="user", cascade="all, delete-orphan")
    consultations_as_owner = relationship("Consultation", foreign_keys="[Consultation.owner_id]", back_populates="owner")
    consultations_as_vet = relationship("Consultation", foreign_keys="[Consultation.vet_id]", back_populates="vet")

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

class Pet(Base):
    __tablename__ = "pets"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    species = Column(String(50), nullable=False)
    breed = Column(String(100), nullable=True)
    age = Column(Float, nullable=True)
    weight = Column(Float, nullable=True)
    photo_url = Column(String(256), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", back_populates="pets")
    medical_records = relationship("MedicalRecord", back_populates="pet", cascade="all, delete-orphan")

class MedicalRecord(Base):
    __tablename__ = "medical_records"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    pet_id = Column(String(36), ForeignKey("pets.id", ondelete="CASCADE"), nullable=False)
    vet_name = Column(String(150), nullable=True)
    description = Column(Text, nullable=True)
    file_url = Column(String(255), nullable=True)
    vaccination_date = Column(DateTime(timezone=True), nullable=True)
    next_vaccination_date = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    pet = relationship("Pet", back_populates="medical_records")

class Location(Base):
    __tablename__ = "locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    type = Column(Enum(LocationType), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    phone_number = Column(String(30), nullable=True)

    hidden_gem = relationship("HiddenGem", back_populates="location", uselist=False, cascade="all, delete-orphan")
    missing_pet_posts = relationship("MissingPetPost", back_populates="location")
    events = relationship("Event", back_populates="location")

class HiddenGem(Base):
    __tablename__ = "hidden_gems"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    location_id = Column(String(36), ForeignKey("locations.id", ondelete="CASCADE"), unique=True, nullable=False)
    is_exclusive_premium = Column(Boolean, default=True)
    discount_rate = Column(Float, default=0.0)

    location = relationship("Location", back_populates="hidden_gem")

class MissingPetPost(Base):
    __tablename__ = "missing_pet_posts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    location_id = Column(String(36), ForeignKey("locations.id", ondelete="SET NULL"), nullable=True)
    description = Column(Text, nullable=False)
    missing_date = Column(DateTime(timezone=True), nullable=False)
    status = Column(String(50), default="MISSING")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="missing_pet_posts")
    location = relationship("Location", back_populates="missing_pet_posts")

class Event(Base):
    __tablename__ = "eveniments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    id_organizer = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    id_location = Column(String(36), ForeignKey("locations.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    date_hour = Column(DateTime(timezone=True), nullable=False)

    organizer = relationship("User", back_populates="events")
    location = relationship("Location", back_populates="events")

class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    vet_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    status = Column(Enum(ConsultationStatus), default=ConsultationStatus.PENDING)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", foreign_keys=[owner_id], back_populates="consultations_as_owner")
    vet = relationship("User", foreign_keys=[vet_id], back_populates="consultations_as_vet")
    messages = relationship("ConsultationMessage", back_populates="consultation", cascade="all, delete-orphan")

class ConsultationMessage(Base):
    __tablename__ = "consultation_messages"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    consultation_id = Column(String(36), ForeignKey("consultations.id", ondelete="CASCADE"), nullable=False)
    sender_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    status = Column(Enum(MessageStatus), default=MessageStatus.SENT)
    sent_at = Column(DateTime(timezone=True), server_default=func.now())

    consultation = relationship("Consultation", back_populates="messages")
    sender = relationship("User")