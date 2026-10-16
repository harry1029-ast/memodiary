import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:memodiary/core/services/auth_service.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

class FakeLocalAuth extends Fake implements LocalAuthentication {
  bool supported = true;
  bool canCheck = true;
  bool authSuccess = true;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      return Future.value(authSuccess);
    }
    return super.noSuchMethod(invocation);
  }
}

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

  group('AuthService Tests', () {
    test('isLockEnabled returns false initially', () async {
      expect(await authService.isLockEnabled(), isFalse);
    });

    test('setting and verifying PIN with cryptographic hash', () async {
      await authService.setPin('1234');

      expect(await authService.isLockEnabled(), isTrue);

      // Verify correct PIN
      final correct = await authService.verifyPin('1234');
      expect(correct, isTrue);

      // Verify wrong PIN fails
      final wrong = await authService.verifyPin('9999');
      expect(wrong, isFalse);

      // Verify stored PIN is not in plain text
      final rawHash = fakeStorage.data['memodiary_pin_hash'];
      expect(rawHash, isNotNull);
      expect(rawHash, isNot(contains('1234')));
      expect(rawHash!.length, 64); // SHA-256 output length
    });

    test('removePin clears all security credentials', () async {
      await authService.setPin('5678');
      await authService.setBiometricEnabled(true);
      expect(await authService.isLockEnabled(), isTrue);
      expect(await authService.isBiometricEnabled(), isTrue);

      await authService.removePin();
      expect(await authService.isLockEnabled(), isFalse);
      expect(await authService.isBiometricEnabled(), isFalse);
      expect(await authService.verifyPin('5678'), isFalse);
    });

    test('biometric authentication flow', () async {
      expect(await authService.canCheckBiometrics(), isTrue);

      fakeLocalAuth.authSuccess = true;
      expect(await authService.authenticateBiometric(), isTrue);

      fakeLocalAuth.authSuccess = false;
      expect(await authService.authenticateBiometric(), isFalse);
    });
  });
}
