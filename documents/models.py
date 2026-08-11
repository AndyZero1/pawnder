from django.db import models
from django.contrib.auth import get_user_model
from datetime import date
from django.core.exceptions import ValidationError

User = get_user_model()

class UserDocument(models.Model):
    DOCUMENT_TYPES = (
        ('ID_CARD', 'Buletin (Verificare Vârstă)'),
        ('VET_LICENSE', 'Atestat Medic Veterinar'),
    )
    STATUS_CHOICES = (
        ('PENDING', 'În așteptare'),
        ('APPROVED', 'Aprobat'),
        ('REJECTED', 'Respins'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=20, choices=DOCUMENT_TYPES)
    
    # upload_to='documents/' va salva automat fișierul în folderul /media/documents/ 
    # (sau în AWS S3 dacă folosiți django-storages)
    file = models.FileField(upload_to='documents/%Y/%m/')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    rejection_reason = models.TextField(blank=True, null=True, help_text="Completat doar dacă este respins")
    
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.get_document_type_display()} - {self.user.email}"