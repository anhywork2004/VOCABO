// ── Auth helpers ──────────────────────────────────────────────────────────────
import { auth, db } from "./firebase-config.js";
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  sendPasswordResetEmail,
  updateProfile
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import {
  doc, setDoc, getDoc, serverTimestamp
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

const googleProvider = new GoogleAuthProvider();

// ── Kiểm tra auth state, redirect nếu cần ─────────────────────────────────────
export function requireAuth(redirectTo = "index.html") {
  return new Promise((resolve) => {
    onAuthStateChanged(auth, (user) => {
      if (!user) {
        window.location.href = redirectTo;
      } else {
        resolve(user);
      }
    });
  });
}

export function redirectIfLoggedIn(redirectTo = "dashboard.html") {
  onAuthStateChanged(auth, (user) => {
    if (user) window.location.href = redirectTo;
  });
}

// ── Đăng nhập Email ────────────────────────────────────────────────────────────
export async function loginWithEmail(email, password) {
  const cred = await signInWithEmailAndPassword(auth, email, password);
  return cred.user;
}

// ── Đăng ký Email ──────────────────────────────────────────────────────────────
export async function registerWithEmail(email, password, displayName) {
  const cred = await createUserWithEmailAndPassword(auth, email, password);
  await updateProfile(cred.user, { displayName });
  // Tạo user doc trong Firestore (giống app Flutter)
  await setDoc(doc(db, "users", cred.user.uid), {
    uid:          cred.user.uid,
    displayName,
    email,
    level:        "A1",
    dailyGoal:    10,
    wordsLearned: 0,
    streak:       0,
    progress:     0.0,
    lastTestScore: 0,
    totalTests:   0,
    darkMode:     false,
    notification: true,
    createdAt:    serverTimestamp(),
  }, { merge: true });
  return cred.user;
}

// ── Đăng nhập Google ───────────────────────────────────────────────────────────
export async function loginWithGoogle() {
  const cred = await signInWithPopup(auth, googleProvider);
  // Tạo/merge user doc nếu chưa có
  const ref  = doc(db, "users", cred.user.uid);
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    await setDoc(ref, {
      uid:          cred.user.uid,
      displayName:  cred.user.displayName || "",
      email:        cred.user.email || "",
      photoURL:     cred.user.photoURL || "",
      level:        "A1",
      dailyGoal:    10,
      wordsLearned: 0,
      streak:       0,
      progress:     0.0,
      lastTestScore: 0,
      totalTests:   0,
      darkMode:     false,
      notification: true,
      createdAt:    serverTimestamp(),
    });
  }
  return cred.user;
}

// ── Đăng xuất ──────────────────────────────────────────────────────────────────
export async function logout() {
  await signOut(auth);
  window.location.href = "index.html";
}

// ── Quên mật khẩu ─────────────────────────────────────────────────────────────
export async function resetPassword(email) {
  await sendPasswordResetEmail(auth, email);
}

// ── Lấy user hiện tại ─────────────────────────────────────────────────────────
export function getCurrentUser() {
  return auth.currentUser;
}

// ── Lấy user data từ Firestore ────────────────────────────────────────────────
export async function getUserData(uid) {
  const snap = await getDoc(doc(db, "users", uid));
  return snap.exists() ? snap.data() : null;
}
