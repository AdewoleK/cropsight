"""Settings from the environment, with server/.env filling any gaps when run
locally. On Render the same names are set as environment variables."""

import os
from pathlib import Path

SERVER = Path(__file__).resolve().parent.parent


def _load_env_file(path=SERVER / ".env"):
    if not path.is_file():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            os.environ.setdefault(key.strip(), value.strip().strip("'\""))


_load_env_file()


def database_target():
    """Supabase Postgres when DATABASE_URL is set, else a local SQLite file
    (DB, default server/watch.db)."""
    return os.environ.get("DATABASE_URL") or os.environ.get("DB", str(SERVER / "watch.db"))


SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "")

# Officer sign-in is required whenever Supabase is configured. Without it
# (local development, tests) the dashboard is open, as before.
AUTH_REQUIRED = bool(SUPABASE_URL and SUPABASE_ANON_KEY)
