from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from .models import UserDocument
from .serializers import DocumentUploadSerializer

class DocumentUploadView(generics.CreateAPIView):
    queryset = UserDocument.objects.all()
    serializer_class = DocumentUploadSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser] #permite upload de poze

    def perform_create(self, serializer):
        # document salvat si 'legat' de user-ul respectiv
        serializer.save(user=self.request.user)