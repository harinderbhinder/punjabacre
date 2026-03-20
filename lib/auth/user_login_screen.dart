import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/user_auth_provider.dart';

const _green = Color(0xFF6CA651);
const _orange = Color(0xFFFF8C42);

class UserLoginScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const UserLoginScreen({super.key, this.onSuccess});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  int _step = 0; // 0 = email, 1 = OTP

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<UserAuthProvider>().sendOtp(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _step = 1;
      _startResendTimer();
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<UserAuthProvider>().verifyOtp(
      _emailCtrl.text.trim(),
      otp,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    widget.onSuccess?.call();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              GestureDetector(
                onTap: () {
                  if (_step == 1) {
                    setState(() {
                      _step = 0;
                      _error = null;
                      _otpCtrl.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 28, color: Colors.black87),
                  children: [
                    const TextSpan(text: "Let's "),
                    TextSpan(
                      text: _step == 0 ? 'Sign In' : 'Verify',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: '  👋'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _step == 0
                    ? 'Enter your email to receive a one-time password'
                    : 'Enter the 6-digit code sent to ${_emailCtrl.text.trim()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // Error
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Step content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _step == 0 ? _emailStep() : _otpStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(
          controller: _emailCtrl,
          hint: 'Continue with email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 32),
        _primaryBtn('Continue', _sendOtp),
        const SizedBox(height: 28),
        _orDivider(),
        const SizedBox(height: 20),
        _socialRow(),
        const SizedBox(height: 28),
        _registerRow(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _otpField(),
        const SizedBox(height: 12),
        // Resend row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _resendCountdown > 0
                ? Text(
                    'Resend in ${_resendCountdown}s',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  )
                : GestureDetector(
                    onTap: () {
                      _otpCtrl.clear();
                      setState(() => _error = null);
                      _sendOtp();
                    },
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 13,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 32),
        _primaryBtn('Verify & Continue', _verifyOtp),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _otpField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 14,
        ),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '------',
          hintStyle: TextStyle(
            color: Colors.black26,
            letterSpacing: 14,
            fontSize: 24,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _socialRow() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _loading ? null : _googleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                  TextSpan(
                    text: 'o',
                    style: TextStyle(color: Color(0xFFFBBC05)),
                  ),
                  TextSpan(
                    text: 'g',
                    style: TextStyle(color: Color(0xFF4285F4)),
                  ),
                  TextSpan(
                    text: 'l',
                    style: TextStyle(color: Color(0xFF34A853)),
                  ),
                  TextSpan(
                    text: 'e',
                    style: TextStyle(color: Color(0xFFEA4335)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<UserAuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    widget.onSuccess?.call();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _registerRow() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black45),
          children: [
            const TextSpan(text: "Don't have an account? "),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  // same flow — OTP auto-registers new users
                },
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 13,
                    color: _green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
