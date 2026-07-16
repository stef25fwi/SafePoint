abstract class FileRepository {
  /// Upload a file and return the storage path
  Future<String> uploadFile({
    required String organizationId,
    required String ownerType, // 'person', 'alert', 'report'
    required String ownerId,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  });

  /// Download a file by storage path
  Future<List<int>> downloadFile(String storagePath);

  /// Get a signed URL (valid for 24 hours)
  Future<String> getSignedUrl(String storagePath,
      {Duration validity = const Duration(hours: 24)});

  /// Delete a file by storage path
  Future<void> deleteFile(String storagePath);

  /// List files in a directory
  Future<List<String>> listFiles(String directory);

  /// Get file metadata (size, last modified, etc)
  Future<Map<String, dynamic>?> getFileMetadata(String storagePath);
}
