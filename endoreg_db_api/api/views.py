from rest_framework import viewsets
from endoreg_db_production.endoreg_db.models import Intervention

from endoreg_db_production.endoreg_db.serializers import InterventionSerializer

class InterventionViewSet(viewsets.ModelViewSet):
    queryset = Intervention.objects.all()
    serializer_class = InterventionSerializer
    
class CenterViewSet(viewsets.ModelViewSet):
    queryset = Center.objects.all()
    serializer_class = CenterSerializer

class ExaminationViewSet(viewsets.ModelViewSet):
    queryset = Examination.objects.all()
    serializer_class = ExaminationSerializer
    
class FindingViewSet(viewsets.ModelViewSet):
    queryset = Finding.objects.all()
    serializer_class = FindingSerializer
    
class LocationClassificationViewSet(viewsets.ModelViewSet):
    queryset = LocationClassification.objects.all()
    serializer_class = LocationClassificationSerializer
    
class LocationChoiceViewSet(viewsets.ModelViewSet):
    queryset = LocationChoice.objects.all()
    serializer_class = LocationChoiceSerializer

class MorphologyClassificationViewSet(viewsets.ModelViewSet):
    queryset = MorphologyClassification.objects.all()
    serializer_class = MorphologyClassificationSerializer

class MorphologyChoiceViewSet(viewsets.ModelViewSet):
    queryset = MorphologyChoice.objects.all()
    serializer_class = MorphologyChoiceSerializer

class InterventionViewSet(viewsets.ModelViewSet):
    queryset = Intervention.objects.all()
    serializer_class = InterventionSerializer
    
class PatientDataViewSet(viewsets.ModelViewSet):
    queryset = PatientData.objects.all()
    serializer_class = PatientDataSerializer