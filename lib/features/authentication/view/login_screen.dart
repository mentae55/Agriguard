import 'package:agriguard_project/features/connection_to_device/view/select_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../view_model/user_view_model.dart';
import 'forget_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? redColor : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/app_images/images/plant.png',
              fit: BoxFit.cover,
              height: size.height * 0.22,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.1),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: SvgPicture.asset('assets/app_images/icons/logo.svg'),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'AbhayaLibre',
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue to AgriGuard',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'AbhayaLibre',
                            fontWeight: FontWeight.w600,
                            color: grayColor,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildField(
                                controller: _emailController,
                                hint: 'Enter your email',
                                icon: Icons.email_outlined,
                                title: 'Email',
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter your email';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildField(
                                controller: _passwordController,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                title: 'Password',
                                obscure: !isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: grayColor,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter your password';
                                  if (v.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                                  ),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'AbhayaLibre',
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Sign In Button
                              _buildPrimaryButton(
                                label: authViewModel.isLoading ? 'Signing In...' : 'Sign In',
                                isLoading: authViewModel.isLoading,
                                onTap: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await authViewModel.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                    if (authViewModel.errorMessage != null) {
                                      _showSnackBar(authViewModel.errorMessage!);
                                    } else if (authViewModel.currentUser != null) {
                                      _showSnackBar('Welcome Back!', isError: false);
                                      _navigateTo(SelectDeviceScreen());
                                    }
                                  }
                                },
                              ),

                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: grayColor.withOpacity(0.3))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        color: grayColor,
                                        fontSize: 13,
                                        fontFamily: 'AbhayaLibre',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: grayColor.withOpacity(0.3))),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Google Button
                              _buildGoogleButton(
                                isLoading: authViewModel.isLoading,
                                onTap: () async {
                                  await authViewModel.signInWithGoogle();
                                  if (authViewModel.errorMessage != null) {
                                    _showSnackBar(authViewModel.errorMessage!);
                                  } else if (authViewModel.currentUser != null) {
                                    _showSnackBar('Welcome Back!', isError: false);
                                    _navigateTo(SelectDeviceScreen());
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: grayColor,
                                fontSize: 15,
                                fontFamily: 'AbhayaLibre',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _navigateTo(const RegisterScreen()),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'AbhayaLibre',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (authViewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String title,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'AbhayaLibre',
            color: blackColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700, color: blackColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: grayColor.withOpacity(0.6), fontFamily: 'AbhayaLibre'),
            prefixIcon: Icon(icon, color: primaryColor, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F8F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: redColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: redColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLoading ? primaryColor.withOpacity(0.6) : primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'AbhayaLibre',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_images/icons/google.png', height: 22),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: blackColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'AbhayaLibre',
              ),
            ),
          ],
        ),
      ),
    );
  }
}