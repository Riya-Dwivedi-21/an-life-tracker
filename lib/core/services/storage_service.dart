import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  Future<String?> pickAndUploadImage({
    required String bucket,
    required String folder,
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      print('📸 Picking image from $source...');
      
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ No image selected');
        return null;
      }

      print('✅ Image selected: ${image.name}');
      
      // Get file extension and create file path
      final fileExt = path.extension(image.name);
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$folder/$fileName';

      print('📤 Uploading to: $bucket/$filePath');

      // Upload to Supabase Storage (works on web and mobile)
      final bytes = await image.readAsBytes();
      await _supabase.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/${fileExt.replaceAll('.', '')}',
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
      print('✅ Upload complete: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> deleteImage(String url, String bucket) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(bucket).remove([filePath]);
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
