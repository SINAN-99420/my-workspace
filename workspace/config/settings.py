import os
import dj_database_url
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# ── 🔐 SECURITY SETTINGS (Production Ready) ──
SECRET_KEY = os.environ.get("SECRET_KEY", "django-insecure-local-dev-only-change-me")

# ലോക്കലിൽ DEBUG True ആയിരിക്കും, റെൻഡറിൽ False ആക്കാൻ ഇത് സഹായിക്കും
DEBUG = os.environ.get("DEBUG", "True") == "True"

# എല്ലാ ഹോസ്റ്റുകളെയും അനുവദിക്കാൻ (Render-ന് വേണ്ടി)
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "*").split(",")


# ── 📦 APPLICATIONS ──
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
    "api_tester",
    # add future apps here: "calendar", "todos", ...
]

# ── 🛡️ MIDDLEWARE (WhiteNoise added for Static Files) ──
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # <-- പുതിയത്: CSS/JS ലോഡ് ആകാൻ
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


# ── 🗄️ DATABASE (PostgreSQL for Production, SQLite for Local) ──
# ലോക്കലിൽ SQLite ഉം, ലൈവിൽ DATABASE_URL ഉണ്ടെങ്കിൽ PostgreSQL ഉം ഓട്ടോമാറ്റിക് ആയി തിരഞ്ഞെടുക്കും
DATABASES = {
    "default": dj_database_url.config(
        default="sqlite:///" + str(BASE_DIR / "db.sqlite3"),
        conn_max_age=600,
        conn_health_checks=True,
    )
}

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kolkata"
USE_I18N = True
USE_TZ = True


# ── 🎨 STATIC FILES (CSS, JavaScript, Images) ──
STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]

# WhiteNoise ഉപയോഗിച്ച് ലൈവിൽ സ്റ്റാറ്റിക് ഫയലുകൾ ശേഖരിക്കാനും കംപ്രസ് ചെയ്യാനും
STATIC_ROOT = BASE_DIR / "staticfiles" 
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"