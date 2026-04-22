import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {

  Future<String> uploadAvatar(File file, String uid) async {

    final ref = FirebaseStorage.instance
        .ref()
        .child("avatars/$uid.jpg");

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }
}