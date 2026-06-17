import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../../connection_to_device/view/select_device_screen.dart';
import '../view_model/user_view_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isPasswordHidden = true;

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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (route) => false,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: Stack(
        children: [
          // Background decoration circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/app_images/images/plant.png',
                fit: BoxFit.cover,
                height: size.height * 0.18,
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 36),

                        // Logo Container
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(18),
                          child: SvgPicture.asset('assets/app_images/icons/logo.svg'),
                        ),

                        SizedBox(height: 24),

                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'AbhayaLibre',
                            color: blackColor,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Join AgriGuard and grow smarter',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'AbhayaLibre',
                            fontWeight: FontWeight.w600,
                            color: grayColor,
                          ),
                        ),

                        SizedBox(height: 28),

                        // Card
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildField(
                                controller: _nameController,
                                hint: 'Enter your name',
                                icon: Icons.person_outline,
                                title: 'Full Name',
                                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                              ),
                              SizedBox(height: 16),
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
                              SizedBox(height: 16),
                              _buildField(
                                controller: _passwordController,
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                title: 'Password',
                                obscure: isPasswordHidden,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: grayColor,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter your password';
                                  if (v.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              _buildField(
                                controller: _confirmPasswordController,
                                hint: 'Confirm your password',
                                icon: Icons.lock_outline,
                                title: 'Confirm Password',
                                obscure: isPasswordHidden,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: grayColor,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),

                              SizedBox(height: 24),

                              // Sign Up Button
                              _buildPrimaryButton(
                                label: authViewModel.isLoading ? 'Creating Account...' : 'Sign Up',
                                isLoading: authViewModel.isLoading,
                                onTap: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await authViewModel.register(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                      _nameController.text.trim(),
                                    );
                                    if (authViewModel.errorMessage != null) {
                                      _showSnackBar(authViewModel.errorMessage!, redColor);
                                    } else if (authViewModel.currentUser != null) {
                                      _showSnackBar('Account created successfully!', primaryColor);
                                      _navigateTo(const SelectDeviceScreen());
                                    }
                                  }
                                },
                              ),

                              SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: grayColor.withAlpha(50))),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or sign up with',
                                      style: TextStyle(
                                        color: grayColor,
                                        fontSize: 13,
                                        fontFamily: 'AbhayaLibre',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: grayColor.withAlpha(50))),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Google button
                              _buildGoogleButton(
                                isLoading: authViewModel.isLoading,
                                onTap: () async {
                                  await authViewModel.signInWithGoogle();
                                  if (authViewModel.errorMessage != null) {
                                    _showSnackBar(authViewModel.errorMessage!, redColor);
                                  } else if (authViewModel.currentUser != null) {
                                    _navigateTo(const SelectDeviceScreen());
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        // Switch to Login screen
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: grayColor,
                                fontSize: 15,
                                fontFamily: 'AbhayaLibre',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                              child: Text(
                                'Sign In',
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
                        SizedBox(height: 100),
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
              child: Center(child: CircularProgressIndicator()),
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
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700, color: blackColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: grayColor.withOpacity(0.4), fontFamily: 'AbhayaLibre'),
            prefixIcon: Icon(icon, color: primaryColor, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F8F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8E4), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8E4), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: redColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: redColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Color(0xFFE2E8E4), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_images/icons/google.png', height: 22),
            SizedBox(width: 12),
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