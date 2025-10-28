import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../utils/image_helper.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _basePath = 'images';

  /// Upload an image to Firebase Storage and return its URL
  Future<String?> uploadImage(String entityType, String entityId, File imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String storagePath = '$_basePath/$entityType/$entityId/$fileName';
      
      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Update an existing image in Firebase Storage
  Future<String?> updateImage(String entityType, String entityId, String oldImageUrl, File newImageFile) async {
    try {
      // Delete the old image if it exists
      if (oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }
      
      // Upload the new image
      return await uploadImage(entityType, entityId, newImageFile);
    } catch (e) {
      print('Error updating image: $e');
      return null;
    }
  }

  /// Delete an image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;
      
      final Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Get the URL of a default image for a given entity type
  String getDefaultImageUrl(String entityType) {
    return ImageHelper.getDefaultImageAsset(entityType);
  }

  /// Clean up old/unused images from storage for an entity
  Future<void> cleanupEntityImages(String entityType, String entityId, String currentImageUrl) async {
    try {
      final String entityPath = '$_basePath/$entityType/$entityId';
      final Reference entityRef = _storage.ref().child(entityPath);
      final ListResult result = await entityRef.listAll();
      
      for (var item in result.items) {
        final String itemUrl = await item.getDownloadURL();
        if (itemUrl != currentImageUrl) {
          await item.delete();
        }
      }
    } catch (e) {
      print('Error cleaning up images: $e');
    }
  }

  /// Validate image URL and return default if invalid
  Future<String> validateImageUrl(String entityType, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return getDefaultImageUrl(entityType);
    }

    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      return getDefaultImageUrl(entityType);
    }
  }
}