import 'dart:async';

import 'package:flutter/material.dart';

class ImageHelper {
  static const String _assetBasePath = 'assets/icons';

  static String getDefaultImageAsset(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'club':
        return '$_assetBasePath/default_club.png';
      case 'company':
        return '$_assetBasePath/default_company.png';
      case 'faculty':
        return '$_assetBasePath/default_faculty.png';
      default:
        return '$_assetBasePath/default_company.png'; // Default fallback
    }
  }

  static Widget buildNetworkImage(String? imageUrl, String entityType, {double? width, double? height, BoxFit? fit}) {
    final String defaultImage = getDefaultImageAsset(entityType);
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        defaultImage,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          defaultImage,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static Future<Size> getImageDimensions(String imageUrl) async {
    final ImageProvider provider = NetworkImage(imageUrl);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    
    return await _calculateImageDimension(stream);
  }

  static Future<Size> _calculateImageDimension(ImageStream stream) {
    Completer<Size> completer = Completer<Size>();
    
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        final Size size = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        completer.complete(size);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception);
      },
    );
    
    stream.addListener(listener);
    return completer.future;
  }
}