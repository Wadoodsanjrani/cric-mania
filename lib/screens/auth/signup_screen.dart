import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../pro_league/rules_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── VALIDATION ───
  String? _validateEmail(String email) {
    if (email.trim().isEmpty) return "Email is required";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      return "Invalid email format";
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return "Password is required";
    if (password.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  // ─── SIGNUP HANDLER ───
  Future<void> _handleSignup() async {
    setState(() => _errorMessage = null);

    String? emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    String? passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = "Please agree to the Terms & Rules to continue");
      return;
    }

    setState(() => _loading = true);

    String? error = await _authService.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen()),
      );
    } else {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    }
  }

  // ─── GOOGLE SIGN-IN HANDLER ───
  Future<void> _handleGoogleSignIn() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = "Please agree to the Terms & Rules to continue");
      return;
    }

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    String? error = await _authService.signInWithGoogle();

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else if (error == "cancelled") {
      setState(() => _loading = false);
    } else {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _appLogo(),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 420),
                    padding: EdgeInsets.all(24),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Your Account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1B2F),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Join Pro League for free",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                        SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          _errorBox(_errorMessage!),
                          SizedBox(height: 14),
                        ],

                        _inputLabel("Email"),
                        SizedBox(height: 6),
                        _textField(
                          controller: _emailController,
                          hint: "your@email.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 14),

                        _inputLabel("Password"),
                        SizedBox(height: 6),
                        _passwordField(
                          controller: _passwordController,
                          hint: "At least 6 characters",
                          show: _showPassword,
                          toggle: () => setState(() => _showPassword = !_showPassword),
                        ),
                        SizedBox(height: 14),

                        _inputLabel("Confirm Password"),
                        SizedBox(height: 6),
                        _passwordField(
                          controller: _confirmPasswordController,
                          hint: "Re-enter your password",
                          show: _showConfirmPassword,
                          toggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                        SizedBox(height: 16),

                        _termsCheckbox(),
                        SizedBox(height: 20),

                        _primaryButton(
                          label: "CREATE ACCOUNT",
                          onTap: _loading ? null : _handleSignup,
                        ),
                        SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "or continue with",
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        SizedBox(height: 14),

                        _googleButton(
                          onTap: _loading ? null : _handleGoogleSignIn,
                        ),
                        SizedBox(height: 18),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LoginScreen(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Color(0xFF1A73E8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appLogo() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF00C9A7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1A73E8).withValues(alpha: 0.3),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.sports_cricket, color: Colors.white, size: 34),
        ),
        SizedBox(height: 12),
        Text(
          "CRIC MANIA",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B2F),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Color(0xFF1B1B2F),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Color(0xFF1B1B2F), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Color(0xFF6B6B6B), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        style: TextStyle(color: Color(0xFF1B1B2F), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF6B6B6B), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF6B6B6B),
              size: 20,
            ),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
      ),
    );
  }

  Widget _termsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (val) {
              setState(() => _agreedToTerms = val ?? false);
            },
            activeColor: Color(0xFF00C9A7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Wrap(
            children: [
              Text(
                "I have read and agree to the ",
                style: TextStyle(fontSize: 13, color: Color(0xFF1B1B2F)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RulesScreen()),
                  );
                },
                child: Text(
                  "Terms & Rules",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onTap,
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
            child: _loading
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _googleButton({required VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      "G",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Continue with Google",
                  style: TextStyle(
                    color: Color(0xFF1B1B2F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}