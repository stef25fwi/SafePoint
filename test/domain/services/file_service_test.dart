import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/repositories/file_repository.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/services/file_service.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';

class MockFileRepository extends Mock implements FileRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
    registerFallbackValue(const Duration());
  });

  group('FileService', () {
    late FileService fileService;
    late MockFileRepository mockFileRepository;
    late MockAuditRepository mockAuditRepository;
    late AuditService auditService;

    setUp(() {
      mockFileRepository = MockFileRepository();
      mockAuditRepository = MockAuditRepository();
      auditService = AuditService(mockAuditRepository);
      fileService = FileService(mockFileRepository, auditService);
    });

    group('uploadFile', () {
      test('uploads file and logs audit', () async {
        const fileBytes = [1, 2, 3, 4, 5];
        const organizationId = 'org_test';
        const ownerType = 'person';
        const ownerId = 'person_123';
        const fileName = 'document.pdf';
        const mimeType = 'application/pdf';
        const uploadedBy = 'user_456';
        const uploadedByRole = 'AGENT';

        when(() => mockFileRepository.uploadFile(
                  organizationId: organizationId,
                  ownerType: ownerType,
                  ownerId: ownerId,
                  fileName: fileName,
                  fileBytes: fileBytes,
                  mimeType: mimeType,
                ))
            .thenAnswer((_) async =>
                'organizations/$organizationId/$ownerType/$ownerId/$fileName');

        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await fileService.uploadFile(
          organizationId: organizationId,
          ownerType: ownerType,
          ownerId: ownerId,
          fileName: fileName,
          fileBytes: fileBytes,
          mimeType: mimeType,
          uploadedBy: uploadedBy,
          uploadedByRole: uploadedByRole,
        );

        expect(
          result,
          'organizations/$organizationId/$ownerType/$ownerId/$fileName',
        );
        verify(() => mockFileRepository.uploadFile(
              organizationId: organizationId,
              ownerType: ownerType,
              ownerId: ownerId,
              fileName: fileName,
              fileBytes: fileBytes,
              mimeType: mimeType,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('downloadFile', () {
      test('downloads file and logs audit', () async {
        const storagePath = 'organizations/org_test/person/person_123/doc.pdf';
        const downloadedBy = 'user_456';
        const downloadedByRole = 'AGENT';
        const organizationId = 'org_test';
        const fileBytes = [1, 2, 3];

        when(() => mockFileRepository.downloadFile(storagePath))
            .thenAnswer((_) async => fileBytes);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await fileService.downloadFile(
          storagePath,
          downloadedBy: downloadedBy,
          downloadedByRole: downloadedByRole,
          organizationId: organizationId,
        );

        expect(result, fileBytes);
        verify(() => mockFileRepository.downloadFile(storagePath)).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('deleteFile', () {
      test('deletes file and logs audit', () async {
        const storagePath = 'organizations/org_test/person/person_123/doc.pdf';
        const deletedBy = 'user_456';
        const deletedByRole = 'AGENT';
        const organizationId = 'org_test';

        when(() => mockFileRepository.deleteFile(storagePath))
            .thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await fileService.deleteFile(
          storagePath,
          deletedBy: deletedBy,
          deletedByRole: deletedByRole,
          organizationId: organizationId,
        );

        verify(() => mockFileRepository.deleteFile(storagePath)).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });

    group('getSignedUrl', () {
      test('returns signed URL from repository', () async {
        const storagePath = 'organizations/org_test/person/person_123/doc.pdf';
        const signedUrl = 'https://example.com/signed-url?token=xyz';

        when(() => mockFileRepository.getSignedUrl(
              storagePath,
              validity: any(named: 'validity'),
            )).thenAnswer((_) async => signedUrl);

        final result = await fileService.getSignedUrl(storagePath);

        expect(result, signedUrl);
        verify(() => mockFileRepository.getSignedUrl(
              storagePath,
              validity: any(named: 'validity'),
            )).called(1);
      });
    });

    group('listFiles', () {
      test('returns list of files from repository', () async {
        const directory = 'organizations/org_test/person';
        final files = ['doc1.pdf', 'doc2.pdf', 'photo.jpg'];

        when(() => mockFileRepository.listFiles(directory))
            .thenAnswer((_) async => files);

        final result = await fileService.listFiles(directory);

        expect(result, files);
        verify(() => mockFileRepository.listFiles(directory)).called(1);
      });
    });

    group('getFileMetadata', () {
      test('returns metadata from repository', () async {
        const storagePath = 'organizations/org_test/person/person_123/doc.pdf';
        final metadata = {
          'name': 'doc.pdf',
          'size': 1024,
          'contentType': 'application/pdf',
        };

        when(() => mockFileRepository.getFileMetadata(storagePath))
            .thenAnswer((_) async => metadata);

        final result = await fileService.getFileMetadata(storagePath);

        expect(result, metadata);
        verify(() => mockFileRepository.getFileMetadata(storagePath)).called(1);
      });
    });
  });
}
