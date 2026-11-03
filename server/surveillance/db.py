"""One small database interface over SQLite (local runs, tests) and Postgres
(Supabase in production). Queries are written once, with ? placeholders and
SQL both engines accept (IS NOT DISTINCT FROM, RETURNING)."""

import sqlite3
from contextlib import contextmanager

SQLITE_SCHEMA = """
CREATE TABLE IF NOT EXISTS reports (
  farmer TEXT NOT NULL,
  result_id TEXT NOT NULL,
  reported_at TEXT NOT NULL,
  received_at TEXT NOT NULL,
  source TEXT NOT NULL,
  confidence TEXT,
  unclear INTEGER NOT NULL,
  state_pcode TEXT NOT NULL,
  lga_pcode TEXT NOT NULL,
  card_id TEXT,
  score REAL,
  simulated INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (farmer, result_id)
);
CREATE INDEX IF NOT EXISTS reports_time ON reports (reported_at);
CREATE TABLE IF NOT EXISTS alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,
  lga_pcode TEXT NOT NULL,
  card_id TEXT,
  severity TEXT NOT NULL,
  farmers INTEGER NOT NULL,
  reports INTEGER NOT NULL,
  baseline_farmers INTEGER NOT NULL,
  neighbours TEXT NOT NULL,
  first_seen TEXT NOT NULL,
  last_seen TEXT NOT NULL,
  raised_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  review_note TEXT,
  reviewed_at TEXT,
  farmers_at_review INTEGER,
  reviewed_by TEXT
);
"""

# Tables live in their own "watch" schema with row-level security on and no
# policies. Supabase's public REST API only exposes the "public" schema and
# the publishable key would be blocked by RLS anyway: only this server,
# connecting as the database owner, can read or write farmers' reports.
POSTGRES_SCHEMA = """
CREATE SCHEMA IF NOT EXISTS {schema};
SET search_path TO {schema};
CREATE TABLE IF NOT EXISTS reports (
  farmer TEXT NOT NULL,
  result_id TEXT NOT NULL,
  reported_at TEXT NOT NULL,
  received_at TEXT NOT NULL,
  source TEXT NOT NULL,
  confidence TEXT,
  unclear INTEGER NOT NULL,
  state_pcode TEXT NOT NULL,
  lga_pcode TEXT NOT NULL,
  card_id TEXT,
  score DOUBLE PRECISION,
  simulated INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (farmer, result_id)
);
CREATE INDEX IF NOT EXISTS reports_time ON reports (reported_at);
CREATE TABLE IF NOT EXISTS alerts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  kind TEXT NOT NULL,
  lga_pcode TEXT NOT NULL,
  card_id TEXT,
  severity TEXT NOT NULL,
  farmers INTEGER NOT NULL,
  reports INTEGER NOT NULL,
  baseline_farmers INTEGER NOT NULL,
  neighbours TEXT NOT NULL,
  first_seen TEXT NOT NULL,
  last_seen TEXT NOT NULL,
  raised_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new',
  review_note TEXT,
  reviewed_at TEXT,
  farmers_at_review INTEGER,
  reviewed_by TEXT
);
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
"""


def is_postgres(target):
    return str(target).startswith(("postgres://", "postgresql://"))


class Database:
    """`target` is a SQLite file path or a postgres:// URL."""

    def __init__(self, target, schema="watch"):
        self.postgres = is_postgres(target)
        self.target, self.schema = target, schema
        self._depth = 0
        self._connect()

    def _connect(self):
        if self.postgres:
            import psycopg
            from psycopg.rows import dict_row

            self.conn = psycopg.connect(self.target, autocommit=True, row_factory=dict_row,
                                        connect_timeout=15)
            self.conn.execute(POSTGRES_SCHEMA.format(schema=self.schema))
        else:
            self.conn = sqlite3.connect(self.target, check_same_thread=False)
            self.conn.row_factory = sqlite3.Row
            self.conn.executescript(SQLITE_SCHEMA)
            try:  # databases made before officer sign-in existed
                self.conn.execute("ALTER TABLE alerts ADD COLUMN reviewed_by TEXT")
            except sqlite3.OperationalError:
                pass

    def _sql(self, sql):
        return sql.replace("?", "%s") if self.postgres else sql

    def execute(self, sql, params=()):
        try:
            return self.conn.execute(self._sql(sql), params)
        except Exception as e:
            # Supabase's pooler can drop idle connections (e.g. while Render's
            # free tier sleeps). Reconnect and retry once, but never inside a
            # transaction, where a retry could apply half a change.
            if not self.postgres or self._depth or not _is_disconnect(e):
                raise
            self._connect()
            return self.conn.execute(self._sql(sql), params)

    def executemany(self, sql, rows):
        if self.postgres:
            with self.conn.cursor() as cur:
                cur.executemany(self._sql(sql), rows)
        else:
            self.conn.executemany(sql, rows)

    @contextmanager
    def transaction(self):
        """All-or-nothing block. Nested uses join the outer transaction."""
        if self._depth:
            self._depth += 1
            try:
                yield
            finally:
                self._depth -= 1
            return
        if self.postgres and self.conn.closed:
            self._connect()
        self._depth = 1
        try:
            if self.postgres:
                with self.conn.transaction():
                    yield
            else:
                with self.conn:
                    yield
        finally:
            self._depth = 0

    def ping(self):
        return self.execute("SELECT 1 AS ok").fetchone()["ok"] == 1

    def close(self):
        self.conn.close()


def _is_disconnect(e):
    try:
        import psycopg
    except ImportError:
        return False
    return isinstance(e, (psycopg.OperationalError, psycopg.InterfaceError))
