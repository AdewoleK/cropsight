// Officer sign-in with Supabase Auth, over its plain REST API (no SDK to
// load). Accounts are invite-only: an invite or password-reset email links
// back here with a one-time session in the URL, and the officer sets a
// password. The session is kept in this browser and refreshed before it
// expires.
const Auth = (() => {
  const KEY = "cropsight.session";
  let cfg = { auth: false };
  let session = null;
  let onReady = () => {};

  const el = (id) => document.getElementById(id);
  const now = () => Math.floor(Date.now() / 1000);

  function load() {
    try { return JSON.parse(localStorage.getItem(KEY)); } catch { return null; }
  }
  function save(s) {
    session = s;
    try { s ? localStorage.setItem(KEY, JSON.stringify(s)) : localStorage.removeItem(KEY); } catch {}
  }
  function fromToken(t) {
    return { access_token: t.access_token, refresh_token: t.refresh_token,
             expires_at: t.expires_at || now() + Number(t.expires_in || 3600),
             email: t.user?.email || session?.email || "" };
  }

  async function gotrue(path, { method = "POST", body, token } = {}) {
    const r = await fetch(`${cfg.supabase_url}/auth/v1/${path}`, {
      method,
      headers: { apikey: cfg.supabase_anon_key, "Content-Type": "application/json",
                 ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(data.msg || data.error_description || data.message || `error ${r.status}`);
    return data;
  }

  async function refresh() {
    if (!session?.refresh_token) throw new Error("no session");
    save(fromToken(await gotrue("token?grant_type=refresh_token",
                                { body: { refresh_token: session.refresh_token } })));
  }

  // ---------------------------------------------------------------- screens

  function show(which, message = "", isError = false) {
    el("auth-screen").hidden = false;
    el("app").hidden = true;
    for (const f of ["signin-form", "forgot-form", "setpw-form"]) el(f).hidden = f !== which;
    const m = el("auth-message");
    m.textContent = message;
    m.className = `auth-message${isError ? " error" : ""}`;
    m.hidden = !message;
    el(which).querySelector("input")?.focus();
  }

  function enter() {
    el("auth-screen").hidden = true;
    el("app").hidden = false;
    el("officer").hidden = !cfg.auth;
    el("officer-email").textContent = session?.email || "";
    onReady();
  }

  async function busy(form, task) {
    const button = form.querySelector("button[type=submit]");
    button.disabled = true;
    try { await task(); } finally { button.disabled = false; }
  }

  function wire() {
    el("signin-form").addEventListener("submit", (e) => {
      e.preventDefault();
      busy(e.target, async () => {
        try {
          save(fromToken(await gotrue("token?grant_type=password", { body: {
            email: el("signin-email").value.trim(), password: el("signin-password").value } })));
          el("signin-password").value = "";
          enter();
        } catch (err) {
          show("signin-form", `Couldn't sign in: ${err.message}`, true);
        }
      });
    });
    el("forgot-form").addEventListener("submit", (e) => {
      e.preventDefault();
      busy(e.target, async () => {
        const email = el("forgot-email").value.trim();
        try {
          await gotrue(`recover?redirect_to=${encodeURIComponent(location.origin + "/")}`,
                       { body: { email } });
        } catch (err) {
          return show("forgot-form", `Couldn't send the email: ${err.message}`, true);
        }
        show("signin-form", `If ${email} has an officer account, a link to set a new password is on its way.`);
      });
    });
    el("setpw-form").addEventListener("submit", (e) => {
      e.preventDefault();
      busy(e.target, async () => {
        const pw = el("setpw-password").value;
        if (pw.length < 10) return show("setpw-form", "Use at least 10 characters.", true);
        if (pw !== el("setpw-confirm").value) return show("setpw-form", "The two passwords don't match.", true);
        try {
          await gotrue("user", { method: "PUT", body: { password: pw }, token: session.access_token });
          el("setpw-password").value = el("setpw-confirm").value = "";
          enter();
        } catch (err) {
          show("setpw-form", `Couldn't set the password: ${err.message}`, true);
        }
      });
    });
    el("show-forgot").addEventListener("click", () => show("forgot-form"));
    el("show-signin").addEventListener("click", () => show("signin-form"));
    el("sign-out").addEventListener("click", async () => {
      try { await gotrue("logout", { token: session?.access_token }); } catch {}
      save(null);
      location.reload();
    });
  }

  // ------------------------------------------------------------------ public

  async function start(ready) {
    onReady = ready;
    wire();
    try {
      cfg = await fetch("/api/config").then((r) => r.json());
    } catch {
      return show("signin-form", "Can't reach the server. Check your connection and reload.", true);
    }
    if (!cfg.auth) return enter();

    // Invite and password-reset links land here with a session in the URL.
    const hash = new URLSearchParams(location.hash.slice(1));
    if (hash.get("access_token") || hash.get("error_description")) {
      history.replaceState(null, "", location.pathname);
    }
    if (hash.get("error_description")) {
      return show("signin-form", `${hash.get("error_description")}. Ask for a new link, or use "Forgot password".`, true);
    }
    if (hash.get("access_token")) {
      save(fromToken(Object.fromEntries(hash)));
      try { session.email = (await gotrue("user", { method: "GET", token: session.access_token })).email; save(session); } catch {}
      if (["invite", "recovery", "signup"].includes(hash.get("type"))) {
        el("setpw-email").textContent = session.email;
        return show("setpw-form");
      }
      return enter();
    }

    session = load();
    if (!session) return show("signin-form");
    try {
      if (session.expires_at - now() < 120) await refresh();
      enter();
    } catch {
      save(null);
      show("signin-form", "Your session ended. Please sign in again.");
    }
  }

  /** Headers for our own API. Refreshes the session first if it's nearly over. */
  async function headers() {
    if (!cfg.auth) return {};
    if (session && session.expires_at - now() < 120) {
      try { await refresh(); } catch { signedOut(); throw new Error("signed out"); }
    }
    return session ? { Authorization: `Bearer ${session.access_token}` } : {};
  }

  function signedOut() {
    save(null);
    show("signin-form", "Your session ended. Please sign in again.");
  }

  return { start, headers, signedOut, active: () => !cfg.auth || !!session };
})();
