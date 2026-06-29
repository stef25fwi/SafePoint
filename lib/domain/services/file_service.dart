import '../repositories/file_repository.dart';
import 'audit_service.dart';
import '../models/audit_log_model.dart';

class FileService {
  FileService(this._repo, this._audit);

  final FileRepository _repo;
  final AuditService _audit;

  Future<String> uploadFile({
    required String organizationId,
    required String ownerType,
    required String ownerId,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    required String uploadedBy,
    required String uploadedByRole,
  }) async {
    final storagePath = await _repo.uploadFile(
      organizationId: organizationId,
      ownerType: ownerType,
      ownerId: ownerId,
      fileName: fileName,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );

    await _audit.log(
      organizationId: organizationId,
      userId: uploadedBy,
      role: uploadedByRole,
      action: 'UPLOAD_FILE',
      targetType: 'file',
      targetId: storagePath,
      metadata: {
        'fileName': fileName,
        'ownerType': ownerType,
        'ownerId': ownerId,
        'size': fileBytes.length,
        'mimeType': mimeType,
      },
    );

    return storagePath;
  }

  Future<List<int>> downloadFile(
    String storagePath, {
    required String downloadedBy,
    required String downloadedByRole,
    required String organizationId,
  }) async {
    final data = await _repo.downloadFile(storagePath);

    await _audit.log(
      organizationId: organizationId,
      userId: downloadedBy,
      role: downloadedByRole,
      action: 'DOWNLOAD_FILE',
      targetType: 'file',
      targetId: storagePath,
      metadata: {'size': data.length},
    );

    return data;
  }

  Future<String> getSignedUrl(
    String storagePath, {
    Duration validity = const Duration(hours: 24),
  }) async {
    return _repo.getSignedUrl(storagePath, validity: validity);
  }

  Future<void> deleteFile(
    String storagePath, {
    required String deletedBy,
    required String deletedByRole,
    required String organizationId,
  }) async {
    await _repo.deleteFile(storagePath);

    await _audit.log(
      organizationId: organizationId,
      userId: deletedBy,
      role: deletedByRole,
      action: 'DELETE_FILE',
      targetType: 'file',
      targetId: storagePath,
    );
  }

  Future<List<String>> listFiles(String directory) async {
    return _repo.listFiles(directory);
  }

  Future<Map<String, dynamic>?> getFileMetadata(String storagePath) async {
    return _repo.getFileMetadata(storagePath);
  }
}
