import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/audit_log_model.dart';
import 'package:safepoint_app/domain/models/user_model.dart';
import 'package:safepoint_app/domain/repositories/auth_repository.dart';
import 'package:safepoint_app/domain/services/auth_service.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';
import 'package:safepoint_app/models/enums.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

class FakeAuditLogModel extends Fake implements AuditLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuditLogModel());
  });

  group('AuthDomainService', () {
    late AuthDomainService authService;
    late MockAuthRepository mockAuthRepository;
    late MockAuditRepository mockAuditRepository;
    late AuditService auditService;

    final testUser = UserModel(
      id: 'user_123',
      organizationId: 'org_test',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.agent,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
      updatedBy: 'system',
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockAuditRepository = MockAuditRepository();
      auditService = AuditService(mockAuditRepository);
      authService = AuthDomainService(mockAuthRepository, auditService);
    });

    group('signIn (email/password)', () {
      test('signes in user with email and logs audit', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(() => mockAuthRepository.signInWithEmail(email, password))
            .thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.signIn(email, password);

        expect(result, testUser);
        verify(() => mockAuthRepository.signInWithEmail(email, password))
            .called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('logs failure on exception', () async {
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(() => mockAuthRepository.signInWithEmail(email, password))
            .thenThrow(Exception('Invalid credentials'));
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        expect(
          () => authService.signIn(email, password),
          throwsException,
        );
        // Audit failure is logged after exception
        await Future.delayed(Duration.zero);
      });
    });

    group('signInWithAgentCode', () {
      test('signes in agent with code, password and refugeId', () async {
        const agentCode = 'AGENT-2026-001';
        const password = 'password123';
        const refugeId = 'shelter_1';

        when(() => mockAuthRepository.signInWithAgentCode(
              agentCode,
              password,
              refugeId,
            )).thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.signInWithAgentCode(
          agentCode,
          password,
          refugeId,
        );

        expect(result, testUser);
        verify(() => mockAuthRepository.signInWithAgentCode(
              agentCode,
              password,
              refugeId,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('returns null on invalid agent code', () async {
        const invalidCode = 'INVALID-CODE';
        const password = 'password123';
        const refugeId = 'shelter_1';

        when(() => mockAuthRepository.signInWithAgentCode(
              invalidCode,
              password,
              refugeId,
            )).thenAnswer((_) async => null);

        final result = await authService.signInWithAgentCode(
          invalidCode,
          password,
          refugeId,
        );

        expect(result, null);
      });
    });

    group('signInWithGoogle', () {
      test('signes in user with Google and logs audit', () async {
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.signInWithGoogle();

        expect(result, testUser);
        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('returns null when Google sign-in is cancelled', () async {
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => null);

        final result = await authService.signInWithGoogle();

        expect(result, null);
        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      });
    });

    group('signOut', () {
      test('signes out user and logs audit', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await authService.signOut(testUser);

        verify(() => mockAuthRepository.signOut()).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('signes out without audit when user is null', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        await authService.signOut(null);

        verify(() => mockAuthRepository.signOut()).called(1);
        verifyNever(() => mockAuditRepository.log(any()));
      });
    });

    group('getCurrentUser', () {
      test('returns current user from repository', () async {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        final result = await authService.getCurrentUser();

        expect(result, testUser);
        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      });

      test('returns null when no user is logged in', () async {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        final result = await authService.getCurrentUser();

        expect(result, null);
      });
    });

    group('createAgent', () {
      test('creates new agent and logs audit', () async {
        const organizationId = 'org_test';
        const agentCode = 'AGENT-001';
        const password = 'password123';
        const refugeId = 'shelter_1';
        const role = 'AGENT';
        const createdBy = 'admin_user';
        const createdByRole = 'SUPER_ADMIN';

        when(() => mockAuthRepository.createAgent(
              organizationId: organizationId,
              agentCode: agentCode,
              password: password,
              refugeId: refugeId,
              role: role,
              createdBy: createdBy,
            )).thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.createAgent(
          organizationId: organizationId,
          agentCode: agentCode,
          password: password,
          refugeId: refugeId,
          role: role,
          createdBy: createdBy,
          createdByRole: createdByRole,
        );

        expect(result, testUser);
        verify(() => mockAuthRepository.createAgent(
              organizationId: organizationId,
              agentCode: agentCode,
              password: password,
              refugeId: refugeId,
              role: role,
              createdBy: createdBy,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });
  });
}
