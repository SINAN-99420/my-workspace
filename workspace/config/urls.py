from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("core.urls")),
    path("notes/", include("notes.urls")),
    # future: path("calendar/", include("calendar.urls")),
]
