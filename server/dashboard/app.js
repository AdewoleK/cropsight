const $ = (id) => document.getElementById(id);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const api = (path, opts) => fetch(path, opts).then((r) => {
  if (!r.ok) throw new Error(`${path}: ${r.status}`);
  return r.json();
});

const KIND = {
  new_in_area: "New in area",
  surge: "Surge",
  unidentified: "Unidentified",
};
const PROVENANCE = {
  phone: { label: "Phone", cls: "phone" },
  simulated: { label: "Simulated", cls: "sim" },
  mixed: { label: "Phone + simulated", cls: "sim" },
};
const LEVEL = { alert: "Alert", watch: "Watch", reports: "Reports", none: "No reports" };

const state = { selected: null, mapLayer: {}, alerts: [], seenReports: new Set(), first: true };

// ------------------------------------------------------------------ map

const W = 1000;
let project;

function buildProjection(features) {
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  for (const f of features) for (const poly of f.geometry.coordinates) for (const [x, y] of poly[0]) {
    minX = Math.min(minX, x); maxX = Math.max(maxX, x);
    minY = Math.min(minY, y); maxY = Math.max(maxY, y);
  }
  // Equirectangular with longitude shrunk by cos(mid-latitude): fine at
  // Nigeria's scale and needs no map library.
  const kx = Math.cos(((minY + maxY) / 2) * Math.PI / 180);
  const scale = W / ((maxX - minX) * kx);
  const H = (maxY - minY) * scale;
  project = ([x, y]) => [((x - minX) * kx * scale).toFixed(1), ((maxY - y) * scale).toFixed(1)];
  return H;
}

const pathOf = (geometry) => geometry.coordinates
  .map((poly) => poly.map((ring) => "M" + ring.map(project).join("L") + "Z").join(""))
  .join("");

async function drawMap() {
  const [states, lgas] = await Promise.all([api("/api/geo/states"), api("/api/geo/lgas")]);
  const H = buildProjection(states.features);
  const svg = $("map");
  svg.setAttribute("viewBox", `0 0 ${W} ${Math.ceil(H)}`);
  svg.innerHTML =
    `<g id="lgas">${lgas.features.map((f) =>
      `<path class="lga none" data-pcode="${f.properties.pcode}" data-name="${esc(f.properties.name)}" d="${pathOf(f.geometry)}"/>`
    ).join("")}</g>` +
    `<g>${states.features.map((f) => `<path class="state" d="${pathOf(f.geometry)}"/>`).join("")}</g>` +
    `<g id="rings"></g>`;

  const tip = $("tip");
  svg.addEventListener("mousemove", (e) => {
    const el = e.target.closest(".lga");
    if (!el) { tip.hidden = true; return; }
    const info = state.mapLayer[el.dataset.pcode];
    const box = svg.parentElement.getBoundingClientRect();
    tip.innerHTML = `<b>${esc(el.dataset.name)}</b>${info ? ` · ${esc(info.state)}<br>${LEVEL[info.level]} · ${info.farmers} farmer(s)` : ""}`;
    tip.style.left = `${e.clientX - box.left + 12}px`;
    tip.style.top = `${e.clientY - box.top + 12}px`;
    tip.hidden = false;
  });
  svg.addEventListener("mouseleave", () => { tip.hidden = true; });
  svg.addEventListener("click", (e) => {
    const el = e.target.closest(".lga");
    if (el) selectLga(el.dataset.pcode, el.dataset.name);
  });
}

function paintMap() {
  for (const el of document.querySelectorAll("#map .lga")) {
    const level = state.mapLayer[el.dataset.pcode]?.level || "none";
    el.setAttribute("class", `lga ${level}${el.dataset.pcode === state.selected ? " selected" : ""}`);
  }
  // Pulse a ring on every LGA with an open alert.
  $("rings").innerHTML = state.alerts.filter((a) => a.status !== "dismissed").map((a) => {
    const [x, y] = project([a.lon, a.lat]);
    return `<circle class="ring" cx="${x}" cy="${y}" r="16"/>`;
  }).join("");
}

function selectLga(pcode, name) {
  state.selected = pcode;
  paintMap();
  const info = state.mapLayer[pcode];
  const alerts = state.alerts.filter((a) => a.lga_pcode === pcode);
  $("lga-detail").innerHTML = info
    ? `<b>${esc(info.name)}, ${esc(info.state)}</b> — ${LEVEL[info.level]}. ` +
      `${info.reports} report(s) from ${info.farmers} farmer(s) in 14 days` +
      (info.top_problem ? `; most reported: <b>${esc(info.top_problem)}</b>.` : ".") +
      (alerts.length ? ` ${alerts.length} alert(s) — see the list.` : "")
    : `<b>${esc(name)}</b> — no reports in the last 14 days.`;
}

// ------------------------------------------------------------------ panels

function renderKpis(o) {
  const k = (n, label, hot) => `<div class="kpi${hot ? " hot" : ""}"><b>${n}</b><span>${label}</span></div>`;
  $("kpis").innerHTML =
    k(o.open_alerts, "open alerts", o.open_alerts > 0) +
    k(o.reports, `reports (${o.days} days)`) +
    k(o.farmers, "farmers reporting") +
    k(o.lgas, `LGAs in ${o.states} states`) +
    k(o.real_reports, "from real phones");
  $("sim-banner").hidden = !o.includes_simulated;
}

function alertCard(a) {
  const reviewed = a.status !== "new";
  const neighbours = a.neighbours.length
    ? `<div class="chips">Also reported next door: ${a.neighbours.map((n) => `${esc(n.name)} (${n.farmers})`).join(", ")}</div>`
    : "";
  const note = a.review_note ? `<div class="review-note">Officer's note: ${esc(a.review_note)}</div>` : "";
  const actions = a.status === "new"
    ? `<div class="actions">
         <button class="primary" data-review="confirmed" data-id="${a.id}">Confirm</button>
         <button data-review="dismissed" data-id="${a.id}">Dismiss</button>
       </div>
       <form class="review-form" data-id="${a.id}" hidden>
         <label>Note for the record</label>
         <textarea rows="2" required></textarea>
         <div class="actions"><button class="primary" type="submit">Save</button>
           <button type="button" data-cancel>Cancel</button></div>
       </form>`
    : "";
  return `<article class="alert-card ${a.severity}${reviewed ? " reviewed" : ""}" data-lga="${a.lga_pcode}" data-name="${esc(a.lga)}">
    <div class="tags">
      <span class="tag kind ${a.kind}">${KIND[a.kind]}</span>
      ${a.neighbours.length ? `<span class="tag kind">Spreading</span>` : ""}
      <span class="tag">${a.severity} priority</span>
      ${a.status !== "new" ? `<span class="tag ${a.status}">${a.status}</span>` : ""}
      <span class="tag ${PROVENANCE[a.provenance].cls}">${PROVENANCE[a.provenance].label}</span>
    </div>
    <h3>${a.kind === "unidentified" ? "Unidentified problem" : esc(a.problem)}</h3>
    <div class="where">${esc(a.lga)}, ${esc(a.state)} · first seen ${new Date(a.first_seen + "Z").toLocaleDateString()}</div>
    <p>${esc(a.explanation)}</p>
    ${neighbours}${note}${actions}
  </article>`;
}

function renderAlerts() {
  const showAll = $("show-all").checked;
  const list = state.alerts.filter((a) => showAll || a.status !== "dismissed");
  $("alerts").innerHTML = list.length
    ? list.map(alertCard).join("")
    : `<div class="empty">No alerts. Every LGA is within its usual level.</div>`;
}

function renderPrevalence(o) {
  $("prevalence").innerHTML = `<tr><th>State</th><th>Reports</th><th>Most reported</th></tr>` +
    o.prevalence.slice(0, 12).map((s) => `<tr><td>${esc(s.state)}</td><td>${s.reports}</td>
      <td class="muted">${s.top.map((t) => `${esc(t.problem)} (${t.reports})`).join("<br>")}</td></tr>`).join("");
}

function renderRecent(rows) {
  $("recent").innerHTML = `<tr><th>When</th><th>Where</th><th>Problem</th><th>From</th></tr>` +
    rows.map((r) => {
      const key = r.received_at + r.lga + r.problem;
      const fresh = !state.first && !state.seenReports.has(key);
      state.seenReports.add(key);
      const how = r.source === "lite" ? "farmer's pick" : `photo, ${r.confidence || "?"} confidence`;
      return `<tr class="${fresh ? "fresh" : ""}"><td class="muted">${new Date(r.reported_at + "Z").toLocaleString([], { dateStyle: "medium", timeStyle: "short" })}</td>
        <td>${esc(r.lga)}<div class="muted">${esc(r.state)}</div></td>
        <td>${esc(r.problem)}<div class="muted">${how}</div></td>
        <td><span class="tag ${r.simulated ? "sim" : "phone"}">${r.simulated ? "Simulated" : "Phone"}</span></td></tr>`;
    }).join("");
}

function renderRules(r) {
  $("rules").innerHTML = `<ol>
    <li>A report counts only if the farmer chose the match themselves, or the photo AI rated its own answer medium or high. Low-confidence results are kept but never raise an alert alone.</li>
    <li>Everything counts <b>farmers</b>, not scans: one farmer scanning ten times is one farmer.</li>
    <li><b>New in area</b>: ${r.min_farmers}+ farmers in one LGA report a problem in ${r.window_days} days that had no reports there in the ${r.baseline_days} days before.</li>
    <li><b>Surge</b>: ${r.min_farmers}+ farmers report a problem known in the LGA, at ${r.surge_ratio}× or more its usual rate.</li>
    <li><b>Unidentified</b>: ${r.min_farmers}+ farmers in one LGA get no clear match — possibly something the field guide doesn't cover.</li>
    <li><b>Spreading</b>: the same problem is also reported by ${r.neighbour_farmers}+ farmers in a neighbouring LGA.</li>
    <li><b>Watch</b> (map only): ${r.watch_farmers} farmers — not yet an alert.</li>
    <li>Problems that don't spread (nutrient deficiencies, drought, herbicide injury) are counted but never alert. An officer confirms or dismisses every alert before any action.</li>
    <li>One alert per LGA and problem. A dismissed alert returns only if more farmers report it; an alert closes itself after ${r.window_days} days with no new reports.</li>
  </ol>`;
}

// ------------------------------------------------------------------ loop

async function refresh() {
  if (reviewing) return;
  try {
    const [overview, alerts, mapLayer, recent] = await Promise.all([
      api("/api/overview?days=30"), api("/api/alerts?status=all"), api("/api/map"),
      api("/api/reports/recent?limit=12"),
    ]);
    // Redraw the alert list only when it changed, so a refresh can't swap a
    // button out from under an officer's click.
    // (updated_at ticks on every detection run, so it's left out.)
    const key = (list) => JSON.stringify(list.map(({ updated_at, ...a }) => a));
    const alertsChanged = key(alerts) !== key(state.alerts);
    state.alerts = alerts;
    state.mapLayer = mapLayer;
    renderKpis(overview);
    if (alertsChanged) renderAlerts();
    renderPrevalence(overview);
    renderRecent(recent);
    if (state.first) renderRules(overview.rules);
    paintMap();
    if (state.selected) {
      const el = document.querySelector(`#map .lga[data-pcode="${state.selected}"]`);
      selectLga(state.selected, el?.dataset.name);
    }
    state.first = false;
    $("updated").textContent = `Updated ${new Date().toLocaleTimeString()} · refreshes every 10 s`;
  } catch (e) {
    $("updated").textContent = `Can't reach the server (${e.message})`;
  }
}

const PLACEHOLDER = {
  confirmed: "e.g. Extension officer visited Ikara, confirmed Tuta absoluta on 3 farms",
  dismissed: "e.g. Field visit found early blight, not Tuta absoluta",
};

// While an officer is typing a note, hold the 10-second refresh so the form
// isn't redrawn under them.
let reviewing = false;

$("alerts").addEventListener("click", (e) => {
  const btn = e.target.closest("button[data-review]");
  if (btn) {
    e.stopPropagation();
    const form = btn.closest(".alert-card").querySelector(".review-form");
    form.dataset.status = btn.dataset.review;
    form.querySelector("label").textContent = btn.dataset.review === "confirmed"
      ? "Confirm — what did you find?" : "Dismiss — why?";
    form.querySelector("textarea").placeholder = PLACEHOLDER[btn.dataset.review];
    form.hidden = false;
    form.querySelector("textarea").focus();
    reviewing = true;
    return;
  }
  if (e.target.closest("[data-cancel]")) {
    e.target.closest(".review-form").hidden = true;
    reviewing = false;
    return;
  }
  if (e.target.closest(".review-form")) return;
  const card = e.target.closest(".alert-card");
  if (card) selectLga(card.dataset.lga, card.dataset.name);
});

$("alerts").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = e.target;
  try {
    await api(`/api/alerts/${form.dataset.id}/review`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: form.dataset.status, note: form.querySelector("textarea").value }),
    });
  } catch (err) {
    form.querySelector("label").textContent = `Couldn't save (${err.message}). Try again.`;
    return; // keep the note and the form; refresh stays paused
  }
  reviewing = false;
  refresh();
});
$("show-all").addEventListener("change", renderAlerts);

drawMap().then(refresh);
setInterval(refresh, 10000);
