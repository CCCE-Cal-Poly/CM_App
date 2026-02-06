import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:ccce_application/services/error_logger.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$folder/$timestamp\_$fileName';
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ErrorLogger.logError('ImageService', 'Error uploading image', error: e);
      return null;
    }
  }

  static Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,  // Reasonable max width
        maxHeight: 1024, // Reasonable max height
        imageQuality: 85, // Good quality but smaller file size
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      ErrorLogger.logError('ImageService', 'Error picking image', error: e);
    }
    return null;
  }

  static Future<String?> updateEntityImage({
    required String? oldImageUrl,
    required String entityId,
    required String folder,
    bool fromCamera = false,
  }) async {
    final File? imageFile = await pickImage(fromCamera: fromCamera);
    if (imageFile == null) return null;

    final String? newImageUrl = await uploadImage(imageFile, folder);
    if (newImageUrl == null) return null;

    if (oldImageUrl != null) {
      try {
        final ref = _storage.refFromURL(oldImageUrl);
        await ref.delete();
      } catch (e) {
        ErrorLogger.logError('ImageService', 'Error deleting old image', error: e);
      }
    }

    return newImageUrl;
  }
}