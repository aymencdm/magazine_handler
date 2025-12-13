from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CategoryViewSet, MaterialViewSet, StudentViewSet,
    BorrowTransactionViewSet, PDFRecordViewSet, GroupViewSet
)

router = DefaultRouter()
router.register(r'categories', CategoryViewSet)
router.register(r'materials', MaterialViewSet)
router.register(r'students', StudentViewSet)
router.register(r'groups', GroupViewSet)
router.register(r'transactions', BorrowTransactionViewSet)
router.register(r'pdfs', PDFRecordViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
