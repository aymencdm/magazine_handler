from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CategoryViewSet, MaterialViewSet, StudentViewSet,
    BorrowTransactionViewSet, PDFRecordViewSet, GroupViewSet,
    export_database, import_database
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
    path('database/export/', export_database, name='export_database'),
    path('database/import/', import_database, name='import_database'),
]
