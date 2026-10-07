import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();

  bool _checking = false;
  bool _resending = false;
  String? _message;
  Color _messageColor = Color(0xFF00C9A7);

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    bool verified = await _authService.reloadUser();

    if (!mounted) return;

    if (verified) {
      setState(() {
        _message = "Email verified! Redirecting...";
        _messageColor = Color(0xFF00C9A7);
      });
      await Future.delayed(Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _checking = false;
        _message = "Email not verified yet. Please check your inbox.";
        _messageColor = Colors.orange[700]!;
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _message = null;
    });

    String? error = await _authService.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      _resending = false;
      if (error == null) {
        _message = "Verification email resent! Check your inbox.";
        _messageColor = Color(0xFF00C9A7);
      } else {
        _message = error;
        _messageColor = Colors.red[700]!;
      }
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    String email = _authService.currentUser?.email ?? "your email";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFFFFFFF),
              Color(0xFFF5F5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 420),
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF00C9A7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF1A73E8).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Verify Your Email",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B2F),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "We've sent a verification link to:",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Click the link in the email to verify your account. After verifying, come back and tap the button below.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B6B),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_message != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _messageColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _messageColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _messageColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    _primaryButton(
                      label: "I HAVE VERIFIED",
                      onTap: _checking ? null : _checkVerification,
                      loading: _checking,
                    ),
                    SizedBox(height: 12),
                    _outlineButton(
                      label: "Resend Email",
                      onTap: _resending ? null : _resendEmail,
                      loading: _resending,
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text(
                        "Use a different account",
                        style: TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF00C9A7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF1A73E8), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A73E8),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: Color(0xFF1A73E8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}