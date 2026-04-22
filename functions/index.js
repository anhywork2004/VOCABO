// functions/index.js
// Deploy: firebase deploy --only functions
//
// Required packages:
//   npm install firebase-admin firebase-functions nodemailer

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

// ── Configure email transporter ─────────────────────────────────────────────
// Recommended: use Gmail App Password or any SMTP provider (SendGrid, Mailgun…)
// Set secrets: firebase functions:secrets:set GMAIL_USER GMAIL_PASS
const getTransporter = () =>
  nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.GMAIL_USER,  // your@gmail.com
      pass: process.env.GMAIL_PASS,  // Gmail App Password (16 chars)
    },
  });

// ── Helper: generate 6-digit OTP ───────────────────────────────────────────
const generateOtp = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

// ── Sanitize email for Firestore document ID ────────────────────────────────
const emailToKey = (email) => email.toLowerCase().replace(/\./g, "_");

// ────────────────────────────────────────────────────────────────────────────
// 1. sendOtp
//    - Generates OTP, stores in Firestore, sends email
//    - Called from ForgotPasswordScreen & OTP resend
// ────────────────────────────────────────────────────────────────────────────
exports.sendOtp = functions.https.onCall(async (data, context) => {
  const email = (data.email || "").trim().toLowerCase();

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid email address");
  }

  // Check if email exists in Firebase Auth
  try {
    await admin.auth().getUserByEmail(email);
  } catch {
    // Do not reveal whether email exists for security
    // But still "pretend" success so attackers can't enumerate accounts
    return { success: true };
  }

  const otp = generateOtp();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // Store OTP in Firestore
  await db.collection("otp_verifications").doc(emailToKey(email)).set({
    code: otp,
    email: email,
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    attempts: 0,
    verified: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send email
  const transporter = getTransporter();
  await transporter.sendMail({
    from: `"Your App" <${process.env.GMAIL_USER}>`,
    to: email,
    subject: "Your Password Reset OTP",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto;
                  background: #f9f9fb; border-radius: 16px; overflow: hidden;">
        <div style="background: linear-gradient(135deg, #5B7BFE, #7B61FF);
                    padding: 32px; text-align: center;">
          <h2 style="color: white; margin: 0; font-size: 24px;">Password Reset</h2>
        </div>
        <div style="padding: 32px; background: white;">
          <p style="color: #333; font-size: 15px;">
            You requested a password reset. Use the code below:
          </p>
          <div style="background: #f0f4ff; border-radius: 12px;
                      padding: 24px; text-align: center; margin: 24px 0;">
            <span style="font-size: 40px; font-weight: 900;
                         letter-spacing: 10px; color: #5B7BFE;">
              ${otp}
            </span>
          </div>
          <p style="color: #888; font-size: 13px;">
            This code expires in <strong>10 minutes</strong>.
            If you didn't request this, ignore this email.
          </p>
        </div>
      </div>
    `,
  });

  return { success: true };
});

// ────────────────────────────────────────────────────────────────────────────
// 2. resetPasswordWithOtp
//    - Verifies OTP is marked verified in Firestore
//    - Changes password using Firebase Admin SDK
//    - Cleans up OTP document
// ────────────────────────────────────────────────────────────────────────────
exports.resetPasswordWithOtp = functions.https.onCall(async (data, context) => {
  const email = (data.email || "").trim().toLowerCase();
  const newPassword = data.newPassword || "";

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required");
  }
  if (!newPassword || newPassword.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters"
    );
  }

  // Check OTP document
  const docRef = db.collection("otp_verifications").doc(emailToKey(email));
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "OTP not found. Please request a new one."
    );
  }

  const otpData = doc.data();

  // Must be verified (client marked it verified after correct OTP entry)
  if (!otpData.verified) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "OTP has not been verified."
    );
  }

  // Check expiry (10 min from creation, not from verification)
  const expiresAt = otpData.expiresAt.toDate();
  if (new Date() > expiresAt) {
    await docRef.delete();
    throw new functions.https.HttpsError(
      "deadline-exceeded",
      "OTP has expired. Please request a new one."
    );
  }

  // Get Firebase Auth user
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }

  // ✅ Update password via Admin SDK
  await admin.auth().updateUser(userRecord.uid, { password: newPassword });

  // Clean up OTP document
  await docRef.delete();

  return { success: true };
});