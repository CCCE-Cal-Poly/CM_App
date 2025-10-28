import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

class ImageHelper {
  static const String defaultClubLogo = 'assets/icons/default_club.png';
  static const String defaultCompanyLogo = 'assets/icons/default_company.png';
  static const String defaultEventLogo = 'assets/icons/default_event.png';

  static Future<bool> isValidImageUrl(String? url) async {
    if (url == null || url.isEmpty) return false;
    
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type'];
      return contentType != null && contentType.startsWith('image/');
    } catch (e) {
      return false;
    }
  }

  static String getDefaultImage(EntityType type) {
    switch (type) {
      case EntityType.club:
        return defaultClubLogo;
      case EntityType.company:
        return defaultCompanyLogo;
      case EntityType.event:
        return defaultEventLogo;
    }
  }

  static Widget buildNetworkImage({
    required String? imageUrl,
    required double width,
    required double height,
    required EntityType type,
    BoxFit fit = BoxFit.cover,
    bool isCircular = true,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildDefaultImage(type, width, height, isCircular);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          image: DecorationImage(
            image: imageProvider,
            fit: fit,
          ),
        ),
      ),
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => _buildDefaultImage(type, width, height, isCircular),
    );
  }

  static Widget _buildDefaultImage(EntityType type, double width, double height, bool isCircular) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        color: Colors.grey[200],
      ),
      child: Center(
        child: Image.asset(
          getDefaultImage(type),
          width: width * 0.6,
          height: height * 0.6,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

enum EntityType {
  club,
  company,
  event,
}