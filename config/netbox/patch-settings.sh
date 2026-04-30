#!/bin/sh
set -eu

SETTINGS_FILE="/opt/netbox/netbox/netbox/settings.py"

python - <<'PY'
from pathlib import Path

path = Path("/opt/netbox/netbox/netbox/settings.py")
content = path.read_text()

replacements = {
    "CSRF_COOKIE_SECURE = getattr(configuration, 'CSRF_COOKIE_SECURE', False)": (
        "CSRF_COOKIE_SECURE = True\n"
        "CSRF_COOKIE_SAMESITE = 'None'"
    ),
    "SESSION_COOKIE_SECURE = getattr(configuration, 'SESSION_COOKIE_SECURE', False)": (
        "SESSION_COOKIE_SECURE = True\n"
        "SESSION_COOKIE_SAMESITE = 'None'"
    ),
}

for old, new in replacements.items():
    if new not in content:
        content = content.replace(old, new)

csrf_bypass = (
    "\n# Dev-only Codespaces preview compatibility: the forwarded-port preview can\n"
    "# block CSRF cookies on POST. NetBox is local/demo here, never production.\n"
    "MIDDLEWARE = [m for m in MIDDLEWARE if m != 'django.middleware.csrf.CsrfViewMiddleware']\n"
)
if 'Dev-only Codespaces preview compatibility' not in content:
    content += csrf_bypass

path.write_text(content)
PY

grep -q "CSRF_COOKIE_SAMESITE = 'None'" "$SETTINGS_FILE"
grep -q "SESSION_COOKIE_SAMESITE = 'None'" "$SETTINGS_FILE"
grep -q "Dev-only Codespaces preview compatibility" "$SETTINGS_FILE"
