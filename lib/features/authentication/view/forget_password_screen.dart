import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/core.dart';
import '../view_model/user_view_model.dart';
import 'verification_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withAlpha(isDark ? 20 : 13),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: isDark ? 0.3 : 0.8,
              child: Image.asset(
                'assets/app_images/images/plant.png',
                fit: BoxFit.cover,
                height: size.height * 0.5,
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
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
                          SizedBox(height: 20),
            
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 18),
                              ),
                            ),
                          ),
            
                          SizedBox(height: 30),
            
                          // Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withAlpha(30),
                            ),
                            child: Icon(Icons.lock_reset_rounded, color: primaryColor, size: 46),
                          ),
            
                          SizedBox(height: 24),
            
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'AbhayaLibre',
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "We'll send a reset link to your email",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'AbhayaLibre',
                              fontWeight: FontWeight.w600,
                              color: grayColor,
                            ),
                          ),
            
                          SizedBox(height: 32),
            
                          // Card
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.onSurface.withAlpha(isDark ? 15 : 10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'AbhayaLibre',
                                    color: colorScheme.onSurface.withAlpha(178),
                                  ),
                                ),
                                SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please enter your email';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  style: TextStyle(fontFamily: 'AbhayaLibre', fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(color: grayColor.withAlpha(102), fontFamily: 'AbhayaLibre'),
                                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor, size: 20),
                                    filled: true,
                                    fillColor: isDark ? colorScheme.tertiary : const Color(0xFFF5F8F3),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: redColor, width: 1.5)),
                                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: redColor, width: 1.5)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
            
                                SizedBox(height: 24),
            
                                GestureDetector(
                                  onTap: authViewModel.isLoading
                                      ? null
                                      : () async {
                                    if (_formKey.currentState!.validate()) {
                                      await authViewModel.resetPassword(
                                        _emailController.text.trim(),
                                      );
                                      if (authViewModel.errorMessage != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(authViewModel.errorMessage!, style: TextStyle(fontFamily: 'AbhayaLibre')),
                                            backgroundColor: redColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            margin: EdgeInsets.all(16),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Reset link sent! Check your inbox.', style: TextStyle(fontFamily: 'AbhayaLibre')),
                                            backgroundColor: primaryColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            margin: EdgeInsets.all(16),
                                          ),
                                        );
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VerificationScreen(
                                              email: _emailController.text.trim(),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: authViewModel.isLoading ? primaryColor.withValues(alpha: 0.6) : primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: authViewModel.isLoading
                                          ? []
                                          : [BoxShadow(color: primaryColor.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
                                    ),
                                    child: Center(
                                      child: Text(
                                        authViewModel.isLoading ? 'Sending...' : 'Send Reset Link',
                                        style: TextStyle(color: colorScheme.onPrimary, fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
            
                          SizedBox(height: 20),
            
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'AbhayaLibre',
                              ),
                            ),
                          ),
            
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (authViewModel.isLoading)
            Container(
              color: colorScheme.onSurface.withAlpha(64),
              child: Center(child: CircularProgressIndicator(color: primaryColor)),
            ),
        ],
      ),
    );
  }
}