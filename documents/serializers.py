from rest_framework import serializers
from .models import UserDocument
from datetime import date

class DocumentUploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDocument
        fields = ['id', 'document_type', 'file', 'status']
        read_only_fields = ['id', 'status'] # user-ul nu poate modifica

    def validate_file(self, value):
        # marime de maxim 5MB
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("Fișierul este prea mare (Max 5MB).")
            
        # extensia
        if not value.name.lower().endswith(('.png', '.jpg', '.jpeg', '.pdf')):
            raise serializers.ValidationError("Acceptăm doar JPG, PNG sau PDF.")
            
        return value

    def validate(self, data):
        user = self.context['request'].user
        
        if data.get('document_type') == 'ID_CARD':
            # getattr() = pentru a extrage data nasterii
            # else dob va fi none -> nu se intampla nimic
            dob = getattr(user, 'date_of_birth', None)
            
            if not dob:
                pass
                # raise serializers.ValidationError("Trebuie să completezi data nașterii în profil înainte de a încărca buletinul.")
            else:
                today = date.today()
                age = today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))
                
                if age < 18:
                    raise serializers.ValidationError("Trebuie sa ai peste 18 ani pentru a folosi aplicatia.")
                
        return data