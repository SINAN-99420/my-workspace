#!/usr/bin/env bash
set -e

PROJECT="workspace"
mkdir -p "$PROJECT"
cd "$PROJECT"

# ---------- virtualenv ----------
py -m venv .venv
source .venv/Scripts/activate
pip install --quiet "Django>=5.0,<5.1"

# ---------- django project ----------
django-admin startproject config .
python manage.py startapp core
python manage.py startapp notes

mkdir -p core/templates/core
mkdir -p notes/templates/notes
mkdir -p static/css

# ============================================================
# config/settings.py
# ============================================================
cat > config/settings.py <<'EOF'
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = "django-insecure-local-dev-only-change-me"
DEBUG = True
ALLOWED_HOSTS = ["127.0.0.1", "localhost"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # local apps
    "core",
    "notes",
    # add future apps here: "calendar", "todos", ...
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [BASE_DIR / "core" / "templates"],
    "APP_DIRS": True,
    "OPTIONS": {
        "context_processors": [
            "django.template.context_processors.request",
            "django.contrib.auth.context_processors.auth",
            "django.contrib.messages.context_processors.messages",
        ],
    },
}]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kolkata"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
EOF

# ============================================================
# config/urls.py
# ============================================================
cat > config/urls.py <<'EOF'
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("core.urls")),
    path("notes/", include("notes.urls")),
    # future: path("calendar/", include("calendar.urls")),
]
EOF

# ============================================================
# core app
# ============================================================
cat > core/apps.py <<'EOF'
from django.apps import AppConfig

class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "core"
EOF

cat > core/views.py <<'EOF'
from django.shortcuts import render
from notes.models import Note

def dashboard(request):
    context = {
        "recent_notes": Note.objects.all()[:5],
    }
    return render(request, "core/dashboard.html", context)
EOF

cat > core/urls.py <<'EOF'
from django.urls import path
from . import views

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
]
EOF

cat > core/templates/core/base.html <<'EOF'
{% load static %}
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{% block title %}Workspace{% endblock %}</title>
  <link rel="stylesheet" href="{% static 'css/app.css' %}" />
  <script src="https://unpkg.com/htmx.org@1.9.12"></script>
  <script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body>
  <div class="layout">
    <aside class="sidebar">
      <div class="brand">🧠 Workspace</div>
      <nav>
        <a href="/" class="{% if request.path == '/' %}active{% endif %}">🏠 Dashboard</a>
        <a href="/notes/" class="{% if '/notes' in request.path %}active{% endif %}">📝 Notes</a>
        <!-- future features: add nav links here -->
      </nav>
      <button class="theme-toggle" onclick="toggleTheme()">🌓 Theme</button>
    </aside>
    <main class="content">
      {% block content %}{% endblock %}
    </main>
  </div>
  <script>
    function toggleTheme() {
      const html = document.documentElement;
      const next = html.dataset.theme === 'light' ? 'dark' : 'light';
      html.dataset.theme = next;
      localStorage.setItem('theme', next);
    }
    document.documentElement.dataset.theme = localStorage.getItem('theme') || 'light';
  </script>
</body>
</html>
EOF

cat > core/templates/core/dashboard.html <<'EOF'
{% extends "core/base.html" %}
{% block title %}Dashboard · Workspace{% endblock %}
{% block content %}
  <h1>Dashboard</h1>
  <p class="muted">Your local workspace. Pick a tool from the sidebar.</p>

  <section class="card">
    <h2>📝 Recent notes</h2>
    {% if recent_notes %}
      <ul class="plain">
        {% for note in recent_notes %}
          <li>
            <a href="/notes/">{{ note.title|default:"Untitled" }}</a>
            <small class="muted"> — {{ note.updated_at|date:"M d, H:i" }}</small>
          </li>
        {% endfor %}
      </ul>
    {% else %}
      <p class="muted">No notes yet. <a href="/notes/">Create your first note →</a></p>
    {% endif %}
  </section>

  <!-- Future widgets go here -->
{% endblock %}
EOF

# ============================================================
# notes app
# ============================================================
cat > notes/apps.py <<'EOF'
from django.apps import AppConfig

class NotesConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "notes"
EOF

cat > notes/models.py <<'EOF'
from django.db import models

class Note(models.Model):
    title = models.CharField(max_length=200, blank=True)
    content = models.TextField(blank=True)
    is_pinned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-is_pinned", "-updated_at"]

    def __str__(self):
        return self.title or f"Note {self.pk}"
EOF

cat > notes/views.py <<'EOF'
from django.http import HttpResponse
from django.shortcuts import render, get_object_or_404
from .models import Note

def note_list(request):
    notes = Note.objects.all()
    selected = notes.first() if notes else None
    return render(request, "notes/list.html", {"notes": notes, "selected": selected})

def note_detail(request, pk):
    note = get_object_or_404(Note, pk=pk)
    return render(request, "notes/_editor.html", {"note": note})

def note_create(request):
    note = Note.objects.create(title="Untitled")
    return render(request, "notes/_editor.html", {"note": note})

def note_update(request, pk):
    note = get_object_or_404(Note, pk=pk)
    note.title = request.POST.get("title", "")
    note.content = request.POST.get("content", "")
    note.save()
    # swap the list + editor so both reflect the new state
    notes = Note.objects.all()
    return render(request, "notes/_notes_panel.html", {"notes": notes, "selected": note})

def note_delete(request, pk):
    note = get_object_or_404(Note, pk=pk)
    note.delete()
    notes = Note.objects.all()
    selected = notes.first() if notes else None
    return render(request, "notes/_notes_panel.html", {"notes": notes, "selected": selected})
EOF

cat > notes/urls.py <<'EOF'
from django.urls import path
from . import views

urlpatterns = [
    path("", views.note_list, name="note_list"),
    path("create/", views.note_create, name="note_create"),
    path("<int:pk>/", views.note_detail, name="note_detail"),
    path("<int:pk>/update/", views.note_update, name="note_update"),
    path("<int:pk>/delete/", views.note_delete, name="note_delete"),
]
EOF

cat > notes/templates/notes/list.html <<'EOF'
{% extends "core/base.html" %}
{% block title %}Notes · Workspace{% endblock %}
{% block content %}
<div id="notes-panel" class="notes-app">
  {% include "notes/_notes_panel.html" %}
</div>
{% endblock %}
EOF

cat > notes/templates/notes/_notes_panel.html <<'EOF'
<aside class="notes-list">
  <button class="btn-primary"
          hx-post="/notes/create/"
          hx-target="#notes-panel"
          hx-swap="innerHTML">+ New note</button>
  <ul class="plain">
    {% for note in notes %}
      <li id="note-{{ note.pk }}" class="{% if note.is_pinned %}pinned{% endif %} {% if selected and selected.pk == note.pk %}active{% endif %}">
        <a hx-get="/notes/{{ note.pk }}/"
           hx-target="#editor"
           hx-swap="innerHTML">
          {{ note.title|default:"Untitled" }}
        </a>
        <small class="muted">{{ note.updated_at|date:"M d, H:i" }}</small>
        <button class="btn-ghost"
                hx-post="/notes/{{ note.pk }}/delete/"
                hx-target="#notes-panel"
                hx-swap="innerHTML"
                hx-confirm="Delete this note?">✕</button>
      </li>
    {% empty %}
      <li class="muted">No notes yet.</li>
    {% endfor %}
  </ul>
</aside>

<section id="editor" class="notes-editor">
  {% if selected %}
    {% include "notes/_editor.html" with note=selected %}
  {% else %}
    <p class="muted">Select a note or create a new one.</p>
  {% endif %}
</section>
EOF

cat > notes/templates/notes/_editor.html <<'EOF'
<form hx-post="/notes/{{ note.pk }}/update/"
      hx-trigger="input changed delay:800ms, change"
      hx-target="#notes-panel"
      hx-swap="innerHTML"
      class="editor-form">
  <input name="title" value="{{ note.title }}" placeholder="Title" autocomplete="off" />
  <textarea name="content" placeholder="Start typing...">{{ note.content }}</textarea>
  <div class="status"><span class="muted">Auto-saves while you type</span></div>
</form>
EOF

# ============================================================
# static/css/app.css
# ============================================================
cat > static/css/app.css <<'EOF'
:root {
  --bg: #ffffff;
  --surface: #f7f7f8;
  --text-0: #1a1a1a;
  --text-1: #6b7280;
  --border: #e5e7eb;
  --accent: #4f46e5;
  --accent-fg: #ffffff;
  --radius: 8px;
}
[data-theme="dark"] {
  --bg: #111114;
  --surface: #1b1b20;
  --text-0: #f4f4f5;
  --text-1: #a1a1aa;
  --border: #2a2a31;
  --accent: #6366f1;
  --accent-fg: #ffffff;
}
* { box-sizing: border-box; }
body {
  margin: 0; background: var(--bg); color: var(--text-0);
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  font-size: 15px;
}
a { color: var(--accent); text-decoration: none; }
.muted { color: var(--text-1); }
.plain { list-style: none; padding: 0; margin: 0; }

.layout { display: flex; min-height: 100vh; }
.sidebar {
  width: 230px; flex: 0 0 230px;
  border-right: 1px solid var(--border);
  background: var(--surface);
  padding: 16px; display: flex; flex-direction: column; gap: 16px;
}
.brand { font-weight: 700; font-size: 18px; }
.sidebar nav { display: flex; flex-direction: column; gap: 4px; }
.sidebar nav a {
  display: block; padding: 8px 10px; border-radius: var(--radius);
  color: var(--text-0);
}
.sidebar nav a:hover { background: var(--border); }
.sidebar nav a.active { background: var(--accent); color: var(--accent-fg); }
.theme-toggle {
  margin-top: auto; padding: 8px; border: 1px solid var(--border);
  border-radius: var(--radius); background: transparent; color: var(--text-0);
  cursor: pointer;
}

.content { flex: 1; padding: 24px; max-width: 100%; overflow-x: hidden; }

.card {
  border: 1px solid var(--border); border-radius: var(--radius);
  padding: 16px; margin-top: 16px; background: var(--surface);
}
.card h2 { margin-top: 0; font-size: 16px; }

button { cursor: pointer; font: inherit; }
.btn-primary {
  padding: 8px 12px; border: none; border-radius: var(--radius);
  background: var(--accent); color: var(--accent-fg);
}
.btn-ghost {
  padding: 2px 6px; border: 1px solid var(--border); border-radius: var(--radius);
  background: transparent; color: var(--text-1);
}

/* Notes */
.notes-app { display: flex; gap: 16px; align-items: flex-start; }
.notes-list {
  width: 300px; flex: 0 0 300px;
  border: 1px solid var(--border); border-radius: var(--radius);
  padding: 12px; background: var(--surface);
}
.notes-list ul { margin-top: 12px; }
.notes-list li {
  display: grid; grid-template-columns: 1fr auto auto; gap: 8px;
  align-items: center; padding: 8px; border-radius: var(--radius);
  border-bottom: 1px solid var(--border);
}
.notes-list li.pinned { font-weight: 600; }
.notes-list li.active { background: var(--border); }
.notes-list li a { color: var(--text-0); }

.notes-editor {
  flex: 1; min-width: 0; border: 1px solid var(--border);
  border-radius: var(--radius); padding: 16px; background: var(--surface);
}
.editor-form { display: flex; flex-direction: column; gap: 12px; }
.editor-form input, .editor-form textarea {
  width: 100%; padding: 10px; border: 1px solid var(--border);
  border-radius: var(--radius); background: var(--bg); color: var(--text-0);
  font: inherit;
}
.editor-form textarea { min-height: 60vh; resize: vertical; }
.status { font-size: 12px; }

@media (max-width: 768px) {
  .layout { flex-direction: column; }
  .sidebar { width: 100%; flex: none; flex-direction: row; flex-wrap: wrap; align-items: center; }
  .sidebar nav { flex-direction: row; flex-wrap: wrap; }
  .theme-toggle { margin-top: 0; }
  .notes-app { flex-direction: column; }
  .notes-list { width: 100%; flex: none; }
  .editor-form textarea { min-height: 40vh; }
}
EOF

# ============================================================
# migrations + init
# ============================================================
python manage.py makemigrations notes
python manage.py migrate

echo ""
echo "✅ Setup complete."
echo ""
echo "Next:"
echo "  cd $PROJECT"
echo "  source .venv/Scripts/activate"
echo "  python manage.py runserver"
echo ""
echo "Open http://127.0.0.1:8000/"