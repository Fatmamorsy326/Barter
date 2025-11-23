// ============================================
// FILE: lib/services/image_upload_service.dart
// ============================================

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // Get your free API key from: https://api.imgbb.com/
  // Sign up and get your API key for free (no credit card needed)
  static const String _apiKey = 'd1ec08eddf3d5305ab50482666381e50';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Upload single image to ImgBB
  static Future<String> uploadImage(File imageFile) async {
    try {
      print('Starting ImgBB upload...');

      // Read image as bytes and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('Image converted to base64, uploading...');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add API key and image
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final imageUrl = jsonResponse['data']['url'] as String;
        print('Upload successful: $imageUrl');
        return imageUrl;
      } else {
        print('Upload failed: ${response.body}');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      rethrow;
    }
  }

  /// Upload multiple images
  static Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      print('Uploading image ${i + 1}/${images.length}...');
      try {
        final url = await uploadImage(images[i]);
        urls.add(url);
      } catch (e) {
        print('Failed to upload image $i: $e');
        // Continue with other images
      }
    }

    return urls;
  }
}

// ============================================
// Alternative: Cloudinary Service
// FILE: lib/services/cloudinary_service.dart
// ============================================

class CloudinaryService {
  // Get free account at: https://cloudinary.com/
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';

  static Future<String> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      try {
        final url = await uploadImage(image);
        urls.add(url);
      } catch (e) {
        print('Failed to upload image: $e');
      }
    }
    return urls;
  }
}

// ============================================
// Alternative: Base64 in Firestore (NOT RECOMMENDED for large images)
// Only use for very small images or thumbnails
// ============================================

class Base64ImageService {
  static Future<String> imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Future<List<String>> imagesToBase64(List<File> images) async {
    List<String> base64Images = [];
    for (var image in images) {
      final base64 = await imageToBase64(image);
      base64Images.add(base64);
    }
    return base64Images;
  }

// Note: Firestore document limit is 1MB
// A 100KB image becomes ~133KB in base64
// So you can only store about 7 small images per document
}