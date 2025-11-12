import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

String _ensureScheme(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

/// Resilient image widget that handles:
/// - Invalid/empty URLs → shows placeholder asset
/// - Loading state → shows placeholder asset
/// - Network errors → shows placeholder asset
/// - URL validation → adds https:// if missing
class ResilientImage extends StatelessWidget {
  final String? imageUrl;
  final String placeholderAsset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ResilientImage({
    Key? key,
    required this.imageUrl,
    required this.placeholderAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeUrl = _ensureScheme(imageUrl);
    
    Widget imageWidget;
    
    if (safeUrl.isEmpty) {
      imageWidget = Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image,
            size: height ?? width ?? 48,
            color: Colors.grey,
          );
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: safeUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null ? (width! * 2).toInt() : null, 
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        maxWidthDiskCache: 500, 
        maxHeightDiskCache: 500,
        placeholder: (context, url) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              size: height ?? width ?? 48,
              color: Colors.grey,
            );
          },
        ),
        errorWidget: (context, url, error) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              size: height ?? width ?? 48,
              color: Colors.grey,
            );
          },
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
}

class ResilientCircleImage extends StatelessWidget {
  final String? imageUrl;
  final String placeholderAsset;
  final double size;

  const ResilientCircleImage({
    Key? key,
    required this.imageUrl,
    required this.placeholderAsset,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: ResilientImage(
          imageUrl: imageUrl,
          placeholderAsset: placeholderAsset,
          width: size,
          height: size,
          fit: BoxFit.contain, // Changed from cover to contain to prevent cropping
        ),
      ),
    );
  }
}
