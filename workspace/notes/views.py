from django.shortcuts import render, get_object_or_404
from .models import Note


def _selected_or_first(selected=None):
    notes = Note.objects.all()
    if selected is None:
        selected = notes.first() if notes else None
    return notes, selected


def note_list(request):
    notes, selected = _selected_or_first()
    return render(request, "notes/list.html", {"notes": notes, "selected": selected})

def note_detail(request, pk):
    note = get_object_or_404(Note, pk=pk)
    return render(request, "notes/_editor.html", {"note": note})


def note_create(request):
    note = Note.objects.create(title="Untitled")
    notes, selected = _selected_or_first(note)
    return render(request, "notes/_panel.html", {"notes": notes, "selected": selected})


def note_update(request, pk):
    note = get_object_or_404(Note, pk=pk)
    note.title = request.POST.get("title", "")
    note.content = request.POST.get("content", "")
    note.save()
    # Only the sidebar is swapped — keeps the editor's focus while typing.
    notes, selected = _selected_or_first(note)
    return render(request, "notes/_list.html", {"notes": notes, "selected": selected})


def note_delete(request, pk):
    note = get_object_or_404(Note, pk=pk)
    note.delete()
    notes, selected = _selected_or_first()
    return render(request, "notes/_panel.html", {"notes": notes, "selected": selected})