from datetime import datetime, timezone
import uuid
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db, SessionLocal
import models
from websocket_manager import manager
from services.ai_service import generate_ai_veterinary_advice

router = APIRouter(
    prefix="/api/consultations",
    tags=["Consultation & Websockets"]
)

class SendMessageRequest(BaseModel):
    owner_id: str
    message: str
    pet_id: Optional[str] = None

class VetReplyRequest(BaseModel):
    vet_id: str
    consultation_id: str
    message: str


def searchRecentActiveVet(db: Session) -> Optional[models.User]:
    online_vet_ids = list(manager.active_connections.keys())
    if online_vet_ids:
        available_online_vets = db.query(models.User).join(models.VeterinaryProfile).filter(
            models.User.id.in_(online_vet_ids),
            models.User.rol == models.Role.VETERINARY,
            models.VeterinaryProfile.is_checked == True,
            ~models.User.consultations_as_vet.any(models.Consultation.status == models.ConsultationStatus.ACTIVE)
        ).order_by(models.VeterinaryProfile.last_active_at.desc()).first()

        if available_online_vets:
            return available_online_vets

    return (
        db.query(models.User)
        .join(models.VeterinaryProfile)
        .filter(
            models.User.rol == models.Role.VETERINARY,
            models.VeterinaryProfile.is_checked == True,
            ~models.User.consultations_as_vet.any(models.Consultation.status == models.ConsultationStatus.ACTIVE)
        )
        .order_by(models.VeterinaryProfile.last_active_at.desc())
        .first()
    )


@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(user_id, websocket)
    db = SessionLocal()
    try:
        vet_profile = db.query(models.VeterinaryProfile).filter(models.VeterinaryProfile.user_id == user_id).first()
        if vet_profile:
            vet_profile.last_active_at = datetime.now(timezone.utc)
            db.commit()

        while True:
            await websocket.receive_text()
            if vet_profile:
                vet_profile.last_active_at = datetime.now(timezone.utc)
                db.commit()
    except WebSocketDisconnect:
        manager.disconnect(user_id)
    finally:
        db.close()


@router.get("/active/{user_id}")
def get_active_consultation(user_id: str, db: Session = Depends(get_db)):
    consultation = db.query(models.Consultation).filter(
        (models.Consultation.owner_id == user_id) | (models.Consultation.vet_id == user_id),
        models.Consultation.status == models.ConsultationStatus.ACTIVE
    ).first()

    if not consultation:
        return None

    messages = db.query(models.ConsultationMessage).filter(
        models.ConsultationMessage.consultation_id == consultation.id
    ).order_by(models.ConsultationMessage.sent_at.asc()).all()

    other_id = consultation.vet_id if consultation.owner_id == user_id else consultation.owner_id
    other_user = db.query(models.User).filter(models.User.id == other_id).first() if other_id else None

    return {
        "consultation_id": consultation.id,
        "other_party": other_user.username if other_user else "Unknown",
        "messages": [
            {
                "id": m.id,
                "sender_id": m.sender_id,
                "content": m.content,
                "sent_at": m.sent_at.isoformat()
            } for m in messages
        ]
    }


@router.post("/send", status_code=status.HTTP_201_CREATED)
async def send_consultation_message(payload: SendMessageRequest, db: Session = Depends(get_db)):
    owner = db.query(models.User).filter(models.User.id == payload.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="User not found")

    if not owner.is_premium:
        raise HTTPException(status_code=403, detail="Direct veterinary consultations are exclusive to Premium users.")

    consultation = db.query(models.Consultation).filter(
        models.Consultation.owner_id == owner.id,
        models.Consultation.status == models.ConsultationStatus.ACTIVE
    ).first()

    assigned_vet = None
    if consultation:
        assigned_vet = db.query(models.User).filter(models.User.id == consultation.vet_id).first()
    else:
        assigned_vet = searchRecentActiveVet(db)
        if not assigned_vet:
            ai_response_text = generate_ai_veterinary_advice(payload.message)
            return {
                "status": "FALLBACK_TRIGGERED",
                "fallback_type": "AI",
                "ai_response": ai_response_text
            }

        consultation = models.Consultation(
            id=str(uuid.uuid4()),
            owner_id=owner.id,
            vet_id=assigned_vet.id,
            status=models.ConsultationStatus.ACTIVE
        )
        db.add(consultation)
        db.commit()
        db.refresh(consultation)

    new_message = models.ConsultationMessage(
        id=str(uuid.uuid4()),
        consultation_id=consultation.id,
        sender_id=owner.id,
        content=payload.message,
        status=models.MessageStatus.SENT
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    message_payload = {
        "event": "NEW_CONSULTATION_MESSAGE",
        "consultation_id": consultation.id,
        "message_id": new_message.id,
        "sender_username": owner.username,
        "content": payload.message,
        "sent_at": new_message.sent_at.isoformat()
    }

    delivered_live = await manager.send_personal_message(message_payload, assigned_vet.id)
    if delivered_live:
        new_message.status = models.MessageStatus.DELIVERED
        db.commit()

    return {
        "consultation_id": consultation.id,
        "message_id": new_message.id,
        "status": "DELIVERED" if delivered_live else "QUEUED",
        "assigned_vet_id": assigned_vet.id,
        "delivered_live": delivered_live
    }


@router.post("/reply", status_code=status.HTTP_201_CREATED)
async def vet_reply_message(payload: VetReplyRequest, db: Session = Depends(get_db)):
    vet = db.query(models.User).filter(models.User.id == payload.vet_id).first()
    if not vet or vet.rol != models.Role.VETERINARY:
        raise HTTPException(status_code=403, detail="Only veterinarians can reply.")

    consultation = db.query(models.Consultation).filter(
        models.Consultation.id == payload.consultation_id,
        models.Consultation.vet_id == payload.vet_id,
        models.Consultation.status == models.ConsultationStatus.ACTIVE
    ).first()

    if not consultation:
        raise HTTPException(status_code=404, detail="Active consultation not found.")

    new_message = models.ConsultationMessage(
        id=str(uuid.uuid4()),
        consultation_id=consultation.id,
        sender_id=vet.id,
        content=payload.message,
        status=models.MessageStatus.SENT
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    message_payload = {
        "event": "NEW_CONSULTATION_MESSAGE",
        "consultation_id": consultation.id,
        "message_id": new_message.id,
        "sender_username": f"Dr. {vet.username}",
        "content": payload.message,
        "sent_at": new_message.sent_at.isoformat()
    }

    delivered_live = await manager.send_personal_message(message_payload, consultation.owner_id)
    if delivered_live:
        new_message.status = models.MessageStatus.DELIVERED
        db.commit()

    return {
        "consultation_id": consultation.id,
        "message_id": new_message.id,
        "status": "DELIVERED" if delivered_live else "QUEUED"
    }


@router.post("/{consultation_id}/end")
async def end_consultation(consultation_id: str, db: Session = Depends(get_db)):
    consultation = db.query(models.Consultation).filter(models.Consultation.id == consultation_id).first()
    if not consultation:
        raise HTTPException(status_code=404, detail="Consultation not found")

    consultation.status = models.ConsultationStatus.CLOSED
    db.commit()

    payload = {"event": "CONSULTATION_ENDED", "consultation_id": consultation_id}
    await manager.send_personal_message(payload, consultation.owner_id)
    if consultation.vet_id:
        await manager.send_personal_message(payload, consultation.vet_id)

    return {"message": "Consultation closed"}