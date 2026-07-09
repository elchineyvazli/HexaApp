// lib/features/feed/services/upload_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uploadServiceProvider = Provider<UploadService>((ref) => UploadService());

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yükleme sırasında ilerlemeyi dışarıya bildirmek için Stream kullanıyoruz
  Stream<double> uploadVideo({
    required File videoFile,
    required String description,
    required Function(String) onUrlReady,
  }) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Kullanıcı girişi yapılmamış.");

    final String videoId = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('videos').child(user.uid).child('$videoId.mp4');
    
    final uploadTask = ref.putFile(videoFile);

    // İlerlemeyi canlı yayınla
    await for (final event in uploadTask.snapshotEvents) {
      yield event.bytesTransferred / event.totalBytes;
    }

    final downloadUrl = await ref.getDownloadURL();
    onUrlReady(downloadUrl);

    await _firestore.collection('videos').add({
      'videoUrl': downloadUrl,
      'description': description,
      'uploaderId': user.uid,
      'username': '@${user.email?.split('@')[0] ?? 'cyber_user'}',
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'viewsCount': 0,
      'sharesCount': 0,
      'commentsCount': 0,
    });
  }
}