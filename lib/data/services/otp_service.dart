import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  final _db = FirebaseFirestore.instance;

  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> verifyOtp(String email, String inputOtp) async {
    final doc = await _db.collection('otp_codes').doc(email).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'];
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) return false;

    return storedOtp == inputOtp;
  }

  Future<void> clearOtp(String email) async {
    await _db.collection('otp_codes').doc(email).delete();
  }
}