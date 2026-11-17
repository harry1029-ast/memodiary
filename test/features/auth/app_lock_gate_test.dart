import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/auth_service.dart';
import 'package:memodiary/features/auth/app_lock_gate.dart';
import '../../core/services/auth_service_test.dart';

void main() {
  late FakeSecureStorage fakeStorage;
  late FakeLocalAuth fakeLocalAuth;
  late AuthService authService;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    fakeLocalAuth = FakeLocalAuth();
    authService = AuthService(
      storage: fakeStorage,
      localAuth: fakeLocalAuth,
    );
  });

  group('AppLockGate Widget Tests', () {
    testWidgets('renders child immediately when lock is disabled', (tester) async {
      await tester.pumpWidget(
        AppLockGate(
          authService: authService,
          child: const MaterialApp(
            home: Text('Secret Diary Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret Diary Content'), findsOneWidget);
      expect(find.text('拾光日记已锁定'), findsNothing);
    });

    testWidgets('displays lock screen when lock is enabled, unlocks with correct PIN', (tester) async {
      await authService.setPin('1234');

      await tester.pumpWidget(
        AppLockGate(
          authService: authService,
          child: const MaterialApp(
            home: Text('Secret Diary Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify lock screen is shown and content is hidden
      expect(find.text('拾光日记已锁定'), findsOneWidget);
      expect(find.text('请输入密码解锁私密日记'), findsOneWidget);
      expect(find.text('Secret Diary Content'), findsNothing);

      // Enter wrong PIN: 0, 0, 0, 0
      await tester.tap(find.widgetWithText(OutlinedButton, '0'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '0'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '0'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '0'));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.text('密码错误，请重试'), findsOneWidget);
      expect(find.text('Secret Diary Content'), findsNothing);

      // Enter correct PIN: 1, 2, 3, 4
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '2'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '4'));
      await tester.pumpAndSettle();

      // Verify gate unlocks and child content is revealed
      expect(find.text('Secret Diary Content'), findsOneWidget);
      expect(find.text('拾光日记已锁定'), findsNothing);
    });

    testWidgets('re-locks on app resume lifecycle transition', (tester) async {
      await authService.setPin('4321');

      await tester.pumpWidget(
        AppLockGate(
          authService: authService,
          child: const MaterialApp(
            home: Text('Secret Diary Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unlock with correct PIN
      for (final digit in ['4', '3', '2', '1']) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Secret Diary Content'), findsOneWidget);

      // Simulate backgrounding the app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Simulate resuming the app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Should be re-locked
      expect(find.text('拾光日记已锁定'), findsOneWidget);
      expect(find.text('Secret Diary Content'), findsNothing);
    });
  });
}

