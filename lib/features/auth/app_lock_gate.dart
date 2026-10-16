import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

/// AppLockGate wraps the application content and intercepts cold starts and
/// app resumes to enforce local PIN or biometric authentication.
class AppLockGate extends StatefulWidget {
  final Widget child;
  final AuthService? authService;

  const AppLockGate({
    super.key,
    required this.child,
    this.authService,
  });

  @override
  State<AppLockGate> createState() => AppLockGateState();
}

class AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late final AuthService _authService;
  bool _isInitialized = false;
  bool _isLocked = false;
  bool _canBiometrics = false;
  bool _wasInBackground = false;
  String _enteredPin = '';
  String? _errorMessage;

  /// Visible for testing to verify lock state
  bool get isLocked => _isLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = widget.authService ?? AuthService();
    _checkInitialLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _handleAppResume();
    }
  }

  Future<void> _checkInitialLockState() async {
    final lockEnabled = await _authService.isLockEnabled();
    final canBio = await _authService.canCheckBiometrics();
    final bioEnabled = await _authService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isLocked = lockEnabled;
        _canBiometrics = canBio && bioEnabled;
        _isInitialized = true;
      });
    }

    if (lockEnabled && canBio && bioEnabled) {
      _attemptBiometricAuth();
    }
  }

  Future<void> _handleAppResume() async {
    final lockEnabled = await _authService.isLockEnabled();
    if (!lockEnabled) return;

    final canBio = await _authService.canCheckBiometrics();
    final bioEnabled = await _authService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _isLocked = true;
        _enteredPin = '';
        _errorMessage = null;
        _canBiometrics = canBio && bioEnabled;
      });
    }

    if (canBio && bioEnabled) {
      _attemptBiometricAuth();
    }
  }

  Future<void> _attemptBiometricAuth() async {
    final authenticated = await _authService.authenticateBiometric(
      localizedReason: 'Unlock MemoDiary',
    );
    if (authenticated && mounted) {
      setState(() {
        _isLocked = false;
        _enteredPin = '';
        _errorMessage = null;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4 || _enteredPin.length == 6) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await _authService.verifyPin(_enteredPin);
    if (mounted) {
      if (success) {
        setState(() {
          _isLocked = false;
          _enteredPin = '';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _enteredPin = '';
        });
      }
    }
  }

  /// Manually lock the app (for security button or testing)
  void lock() {
    setState(() {
      _isLocked = true;
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isLocked) {
      return widget.child;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'MemoDiary Locked',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter PIN to unlock your private entries',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // PIN Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? Colors.deepPurple : Colors.grey.shade300,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                )
              else
                const SizedBox(height: 16),

              const Spacer(),

              // Numeric Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _canBiometrics
                            ? IconButton(
                                icon: const Icon(Icons.fingerprint, size: 36, color: Colors.deepPurple),
                                onPressed: _attemptBiometricAuth,
                              )
                            : const SizedBox(width: 64, height: 64),
                        _buildKeypadButton('0'),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _onDeletePressed,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeypadButton).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: Colors.grey.shade300),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => _onDigitPressed(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
    );
  }
}

