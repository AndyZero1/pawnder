from django.contrib import admin
from django.utils.html import format_html
from .models import UserDocument

@admin.register(UserDocument)
class UserDocumentAdmin(admin.ModelAdmin):
    list_display = ('user', 'document_type', 'status', 'uploaded_at', 'document_preview')
    
    # filtre
    list_filter = ('status', 'document_type', 'uploaded_at')
    
    # campuri de cautare
    search_fields = ('user__email', 'user__first_name', 'user__last_name')
    
    # butoane de approve/reject
    actions = ['approve_documents', 'reject_documents']

    # 1. AFIȘAREA POZEI ÎN PANOUL ADMIN
    def document_preview(self, obj):
        if obj.file:

            if obj.file.name.lower().endswith(('.png', '.jpg', '.jpeg')):
                return format_html('<a href="{}" target="_blank"><img src="{}" style="height: 50px; border-radius: 5px;"/></a>', obj.file.url, obj.file.url)

            return format_html('<a href="{}" target="_blank">Vezi PDF</a>', obj.file.url)
        return "Niciun fișier"
    
    document_preview.short_description = "Previzualizare Document"

    # 2. BUTON DE APROBARE
    @admin.action(description="Marchează documentele selectate ca APROBATE")
    def approve_documents(self, request, queryset):
        
        queryset.update(status='APPROVED')
        
        for doc in queryset:
            user = doc.user
            if doc.document_type == 'ID_CARD':
                user.is_verified = True # contul de pet owner
            elif doc.document_type == 'VET_LICENSE':
                user.is_vet_verified = True # statutul de medic pe forum
            user.save()
            
        self.message_user(request, "Documentele au fost aprobate, iar utilizatorii activați.")

    # 3. BUTON DE RESPINGERE
    @admin.action(description="Marchează documentele selectate ca RESPINSE")
    def reject_documents(self, request, queryset):
        queryset.update(status='REJECTED')

        self.message_user(request, "Documentele au fost respinse.")