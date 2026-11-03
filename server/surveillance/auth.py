"""Officer sign-in, checked against Supabase Auth.

The dashboard signs officers in with Supabase directly and sends the access
token with each request. Here we ask Supabase who the token belongs to, and
cache the answer briefly so the dashboard's refreshes don't each cost a
round trip. Accounts are invite-only (public sign-up is off in Supabase).
"""

import hashlib
import json
import threading
import time
import urllib.error
import urllib.request

from . import config

CACHE_SECONDS = 60
_cache = {}
_lock = threading.Lock()


class AuthError(Exception):
    pass


def officer_for(header):
    """Return the officer's email for an `Authorization: Bearer …` header,
    or raise AuthError."""
    if not header or not header.startswith("Bearer "):
        raise AuthError("sign in required")
    token = header[len("Bearer "):].strip()
    key = hashlib.sha256(token.encode()).hexdigest()
    now = time.monotonic()
    with _lock:
        hit = _cache.get(key)
        if hit and hit[1] > now:
            return hit[0]
    email = _ask_supabase(token)
    with _lock:
        if len(_cache) > 1000:
            _cache.clear()
        _cache[key] = (email, now + CACHE_SECONDS)
    return email


def _ask_supabase(token):
    req = urllib.request.Request(
        f"{config.SUPABASE_URL}/auth/v1/user",
        headers={"apikey": config.SUPABASE_ANON_KEY, "Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            user = json.load(r)
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            raise AuthError("session expired, sign in again") from e
        raise
    if not user.get("email"):
        raise AuthError("not an officer account")
    return user["email"]
