const API_BASE = "/dev/api";
const PENDING_KEY = "pendingActionV1";

function savePendingAction(action) {
  try {
    const payload = { ...action, ts: Date.now() };
    localStorage.setItem(PENDING_KEY, JSON.stringify(payload));
  } catch {}
}

function loadPendingAction(maxAgeMs = 5 * 60 * 1000) {
  try {
    const raw = localStorage.getItem(PENDING_KEY);
    if (!raw) return null;
    const obj = JSON.parse(raw);
    if (!obj?.ts || Date.now() - obj.ts > maxAgeMs) return null;
    return obj;
  } catch {
    return null;
  }
}

function clearPendingAction() {
  try { localStorage.removeItem(PENDING_KEY); } catch {}
}

function handleAuthRedirect(res, bodyText) {
  if (res.status !== 401) return false;
  const hdr = res.headers.get("X-Auth-Redirect");
  if (hdr) {
    window.location.assign(hdr);
    return true;
  }
  try {
    const json = bodyText ? JSON.parse(bodyText) : null;
    if (json?.login) {
      window.location.assign(json.login);
      return true;
    }
  } catch {}
  return false;
}

async function checkHealth() {
  const healthEl = document.getElementById("health");
  try {
    const res = await fetch(`${API_BASE}/health`, { credentials: "include" });
    if (res.ok) {
      const data = await res.json();
      healthEl.textContent = `✅ API Status: ${data.status}`;
      healthEl.classList.add("text-green-600");
    } else {
      const txt = await res.text();
      if (handleAuthRedirect(res, txt)) return; // will navigate
      throw new Error("API not healthy");
    }
  } catch {
    healthEl.textContent = "❌ API Unreachable";
    healthEl.classList.add("text-red-600");
  }
}

async function loadItems() {
  const list = document.getElementById("itemsList");
  list.innerHTML = "<p class='text-gray-400 text-center'>Loading...</p>";
  try {
    const res = await fetch(`${API_BASE}/items`, { credentials: "include" });
    if (!res.ok) {
      const txt = await res.text();
      if (handleAuthRedirect(res, txt)) return; // will navigate
      throw new Error("Failed to load items");
    }
    const items = await res.json();
    if (items.length === 0) {
      list.innerHTML = "<p class='text-gray-400 text-center'>No items yet.</p>";
      return;
    }
    list.innerHTML = items
      .map(
        (item) => `
        <li class="p-3 bg-gray-50 border rounded-lg hover:bg-gray-100 transition">
          ${item.name}
        </li>`
      )
      .join("");
  } catch {
    list.innerHTML = "<p class='text-red-500 text-center'>Failed to load items</p>";
  }
}

document.getElementById("itemForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  const input = document.getElementById("itemName");
  const addBtn = document.getElementById("addBtn");
  const label = addBtn.querySelector(".btn-label");
  const name = input.value.trim();
  if (!name) return;

  try {
    addBtn.disabled = true; label.textContent = "Adding...";
    // Persist intent so we can resume after auth
    savePendingAction({ url: `${API_BASE}/items`, method: "POST", body: { name } });
    const res = await fetch(`${API_BASE}/items`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ name }),
    });

    if (res.ok) {
      input.value = "";
      clearPendingAction();
      await loadItems();
    } else {
      const txt = await res.text();
      if (handleAuthRedirect(res, txt)) return; // will navigate
      alert("Failed to add item");
    }
  } catch {
    alert("Server unreachable");
  }
    addBtn.disabled = false; label.textContent = "Add";
});

async function resumePendingAction() {
  const pending = loadPendingAction();
  if (!pending) return;
  try {
    const { url, method, body } = pending;
    // Try disabling button while we resume (if present)
    const addBtn = document.getElementById("addBtn");
    const label = addBtn?.querySelector(".btn-label");
    if (addBtn && label) { addBtn.disabled = true; label.textContent = "Resuming..."; }
    const res = await fetch(url, {
      method: method || "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.ok) {
      clearPendingAction();
      await loadItems();
    } else {
      const txt = await res.text();
      if (handleAuthRedirect(res, txt)) return; // triggers nav
      // Keep pending for manual retry
    }
  } catch {
    // Keep pending; maybe network issue
  } finally {
    const addBtn = document.getElementById("addBtn");
    const label = addBtn?.querySelector(".btn-label");
    if (addBtn && label) { addBtn.disabled = false; label.textContent = "Add"; }
  }
}

async function init() {
  await checkHealth();
  await resumePendingAction();
  await loadItems();
}

init();
