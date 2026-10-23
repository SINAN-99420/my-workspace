from django.urls import path
from . import views

urlpatterns = [
    path("", views.api_tester_view, name="api_tester"),
    path("test/", views.test_api, name="test_api"),
]