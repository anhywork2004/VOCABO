// ── Utility helpers ───────────────────────────────────────────────────────────

// Toast notification
export function showToast(message, type = "info", duration = 3000) {
  let container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    container.className = "toast-container";
    document.body.appendChild(container);
  }
  const toast = document.createElement("div");
  const icons = { success: "✅", error: "❌", info: "ℹ️", warning: "⚠️" };
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span>${icons[type] || "ℹ️"}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.animation = "slideIn .3s ease reverse";
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

// Loading overlay
export function showLoading() {
  let el = document.getElementById("loading-overlay");
  if (!el) {
    el = document.createElement("div");
    el.id = "loading-overlay";
    el.className = "loading-overlay";
    el.innerHTML = '<div class="spinner"></div>';
    document.body.appendChild(el);
  }
  el.classList.remove("hidden");
}

export function hideLoading() {
  const el = document.getElementById("loading-overlay");
  if (el) el.classList.add("hidden");
}

// Format date
export function formatDate(ts) {
  if (!ts) return "";
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  return d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" });
}

export function formatDateTime(ts) {
  if (!ts) return "";
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  return d.toLocaleString("vi-VN", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit"
  });
}

// Shuffle array
export function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// Debounce
export function debounce(fn, delay = 300) {
  let t;
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), delay); };
}

// Confirm dialog
export function confirm(title, message) {
  return new Promise((resolve) => {
    const overlay = document.createElement("div");
    overlay.className = "modal-overlay";
    overlay.innerHTML = `
      <div class="modal" style="max-width:380px">
        <div class="modal-title">${title}</div>
        <p style="color:var(--text-muted);font-size:14px">${message}</p>
        <div class="modal-actions">
          <button class="btn btn-outline" id="confirm-cancel">Hủy</button>
          <button class="btn btn-primary" id="confirm-ok">Xác nhận</button>
        </div>
      </div>`;
    document.body.appendChild(overlay);
    overlay.querySelector("#confirm-ok").onclick = () => { overlay.remove(); resolve(true); };
    overlay.querySelector("#confirm-cancel").onclick = () => { overlay.remove(); resolve(false); };
  });
}

// Render navbar user info
export function renderNavUser(user, userData) {
  const el = document.getElementById("nav-user");
  if (!el) return;
  const name   = userData?.displayName || user.displayName || user.email || "User";
  const photo  = userData?.photoURL || user.photoURL || "";
  const initials = name.charAt(0).toUpperCase();
  el.innerHTML = `
    <div class="nav-avatar">
      ${photo ? `<img src="${photo}" alt="">` : initials}
    </div>
    <span style="font-size:14px;font-weight:600">${name.split(" ").pop()}</span>
  `;
}

// Level badge color
export const LEVEL_COLORS = {
  A1: "#3b82f6", A2: "#10b981", B1: "#f59e0b",
  B2: "#8b5cf6", C1: "#ef4444", C2: "#14b8a6"
};

export function levelBadge(level) {
  const color = LEVEL_COLORS[level] || "#6b7280";
  return `<span class="badge" style="background:${color}20;color:${color}">${level}</span>`;
}
