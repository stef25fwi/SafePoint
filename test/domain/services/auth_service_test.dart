import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safepoint_app/domain/models/user_model.dart';
import 'package:safepoint_app/domain/repositories/auth_repository.dart';
import 'package:safepoint_app/domain/services/auth_service.dart';
import 'package:safepoint_app/domain/services/audit_service.dart';
import 'package:safepoint_app/domain/repositories/audit_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  group('AuthDomainService', () {
    late AuthDomainService authService;
    late MockAuthRepository mockAuthRepository;
    late MockAuditRepository mockAuditRepository;
    late AuditService auditService;

    final testUser = UserModel(
      uid: 'user_123',
      organizationId: 'org_test',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: 'AGENT',
      refugeId: 'refuge_123',
      isActive: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      updatedBy: 'system',
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockAuditRepository = MockAuditRepository();
      auditService = AuditService(mockAuditRepository);
      authService = AuthDomainService(mockAuthRepository, auditService);
    });

    group('signInWithEmail', () {
      test('signs in user with email and logs audit', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(() => mockAuthRepository.signInWithEmail(
              email: email,
              password: password,
            )).thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.signInWithEmail(
          email: email,
          password: password,
        );

        expect(result, testUser);
        verify(() => mockAuthRepository.signInWithEmail(
              email: email,
              password: password,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('returns null on authentication failure', () async {
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(() => mockAuthRepository.signInWithEmail(
              email: email,
              password: password,
            )).thenAnswer((_) async => null);

        final result = await authService.signInWithEmail(
          email: email,
          password: password,
        );

        expect(result, null);
        verify(() => mockAuthRepository.signInWithEmail(
              email: email,
              password: password,
            )).called(1);
      });
    });

    group('signInWithAgentCode', () {
      test('signs in agent with code and logs audit', () async {
        const agentCode = 'AGENT-2026-001';

        when(() => mockAuthRepository.signInWithAgentCode(agentCode))
            .thenAnswer((_) async => testUser);
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.signInWithAgentCode(agentCode);

        expect(result, testUser);
        verify(() => mockAuthRepository.signInWithAgentCode(agentCode))
            .called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });

      test('returns null on invalid agent code', () async {
        const invalidCode = 'INVALID-CODE';

        when(() => mockAuthRepository.signInWithAgentCode(invalidCode))
            .thenAnswer((_) async => null);

        final result = await authService.signInWithAgentCode(invalidCode);

        expect(result, null);
        verify(() => mockAuthRepository.signInWithAgentCode(invalidCode))
            .called(1);
      });
    });

    group('signInWithGoogle', () {
      test('signs in user with Google and logs audit', () async {
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
      test('signs out user and logs audit', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        await authService.signOut(
          userId: 'user_123',
          userRole: 'AGENT',
          organizationId: 'org_test',
        );

        verify(() => mockAuthRepository.signOut()).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
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
        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      });
    });

    group('createUser', () {
      test('creates new user and logs audit', () async {
        const email = 'newuser@example.com';
        const password = 'password123';
        const firstName = 'New';
        const lastName = 'User';

        when(() => mockAuthRepository.createUser(
              email: email,
              password: password,
            )).thenAnswer((_) async => testUser.copyWith(
                  email: email,
                  firstName: firstName,
                  lastName: lastName,
                ));
        when(() => mockAuditRepository.log(any())).thenAnswer((_) async {});

        final result = await authService.createUser(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          organizationId: 'org_test',
          createdBy: 'admin_user',
          userRole: 'ADMINISTRATOR',
        );

        expect(result?.email, email);
        verify(() => mockAuthRepository.createUser(
              email: email,
              password: password,
            )).called(1);
        verify(() => mockAuditRepository.log(any())).called(1);
      });
    });
  });
}
