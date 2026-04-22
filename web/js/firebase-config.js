// ── Firebase Config — dùng chung với app Flutter ──────────────────────────────
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { getAuth }       from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import { getFirestore }  from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import { getStorage }    from "https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js";

const firebaseConfig = {
  apiKey:            "AIzaSyAs8SThYkByqnEnNhPzWv9rpDbRK6CKkTo",
  authDomain:        "vocabofinalapp.firebaseapp.com",
  projectId:         "vocabofinalapp",
  storageBucket:     "vocabofinalapp.firebasestorage.app",
  messagingSenderId: "1060637668034",
  appId:             "1:1060637668034:web:e02e11427a579b9ede015b",
  measurementId:     "G-12XE10LPLT"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db   = getFirestore(app);
export const storage = getStorage(app);
export default app;
