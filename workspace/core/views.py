from django.shortcuts import render
from django.utils import timezone
from datetime import timedelta
from notes.models import Note


def dashboard(request):
    total_notes = Note.objects.count()
    pinned_notes = Note.objects.filter(is_pinned=True).count()
    week_ago = timezone.now() - timedelta(days=7)
    week_notes = Note.objects.filter(updated_at__gte=week_ago).count()
    recent_notes = Note.objects.all()[:6]

    context = {
        "total_notes": total_notes,
        "pinned_notes": pinned_notes,
        "week_notes": week_notes,
        "recent_notes": recent_notes,
        "greeting": _greeting(),
    }
    return render(request, "core/dashboard.html", context)


def _greeting():
    hour = timezone.localtime().hour
    if hour < 12:
        return "Good morning"
    elif hour < 17:
        return "Good afternoon"
    return "Good evening"