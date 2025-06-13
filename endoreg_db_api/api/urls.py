from django.urls import path, include
from rest_framework.routers import DefaultRouter
from endoreg_db.views import (
    CenterViewSet, ExaminationViewSet, FindingViewSet, LocationClassificationViewSet,
    LocationChoiceViewSet, MorphologyClassificationViewSet, MorphologyChoiceViewSet,
    InterventionViewSet, PatientDataViewSet
)

router = DefaultRouter()
router.register(r'centers', CenterViewSet)
router.register(r'examinations', ExaminationViewSet)
router.register(r'findings', FindingViewSet)
router.register(r'location-classifications', LocationClassificationViewSet)
router.register(r'location-choices', LocationChoiceViewSet)
router.register(r'morphology-classifications', MorphologyClassificationViewSet)
router.register(r'morphology-choices', MorphologyChoiceViewSet)
router.register(r'interventions', InterventionViewSet)
router.register(r'patient-data', PatientDataViewSet)


