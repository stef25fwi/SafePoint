import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/file_repository.dart';
import '../../core/constants/app_constants.dart';

class FirebaseFileRepository implements FileRepository {
  FirebaseFileRepository() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadFile({
    required String organizationId,
    required String ownerType,
    required String ownerId,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  }) async {
    final path =
        '${StoragePaths.organizations(organizationId)}/$ownerType/$ownerId/$fileName';
    final ref = _storage.ref(path);

    try {
      await ref.putData(
        Uint8List.fromList(fileBytes),
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'organizationId': organizationId,
            'ownerType': ownerType,
            'ownerId': ownerId,
          },
        ),
      );
      debugPrint('[FirebaseFileRepository] Uploaded: $path');
      return path;
    } catch (e) {
      debugPrint('[FirebaseFileRepository] Upload error: $e');
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadFile(String storagePath) async {
    try {
      const maxSize = 10 * 1024 * 1024; // 10 MB max
      final ref = _storage.ref(storagePath);
      final data = await ref.getData(maxSize);
      return data ?? [];
    } catch (e) {
      debugPrint('[FirebaseFileRepository] Download error: $e');
      rethrow;
    }
  }

  @override
  Future<String> getSignedUrl(
    String storagePath, {
    Duration validity = const Duration(hours: 24),
  }) async {
    try {
      final ref = _storage.ref(storagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('[FirebaseFileRepository] SignedUrl error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      await ref.delete();
      debugPrint('[FirebaseFileRepository] Deleted: $storagePath');
    } catch (e) {
      debugPrint('[FirebaseFileRepository] Delete error: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> listFiles(String directory) async {
    try {
      final ref = _storage.ref(directory);
      final result = await ref.listAll();
      return result.items.map((item) => item.fullPath).toList();
    } catch (e) {
      debugPrint('[FirebaseFileRepository] List error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getFileMetadata(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      final metadata = await ref.getMetadata();
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('[FirebaseFileRepository] Metadata error: $e');
      return null;
    }
  }
}
