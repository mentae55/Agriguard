import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agriguard_project/core/localization/app_localizations.dart';
import 'package:agriguard_project/core/localization/language_provider.dart';
import 'package:agriguard_project/core/theme/theme_provider.dart';
import '../controllers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'package:agriguard_project/features/home/view/soil_analysis_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      final provider = context.read<ProfileProvider>();
      final user = provider.userProfile;
      if (user != null) {
        try {
          await provider.updateProfile(
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            phone: user.phone,
            newImage: File(pickedFile.path),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating profile picture: $e'),
              ),
            );
          }
        }
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withAlpha(isDark ? 30 : 15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 24),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                       color: Colors.red,
                       shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.tr(context, 'logout_message'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDialogButton(
                          label: AppLocalizations.tr(context, 'yes'),
                          bgColor: Colors.red.shade700,
                          textColor: Colors.white,
                          onTap: () {
                             Navigator.pop(context);
                             // Perform actual logout logic
                          }),
                      const SizedBox(width: 24),
                      _buildDialogButton(
                          label: AppLocalizations.tr(context, 'no'),
                          bgColor: isDark ? theme.colorScheme.tertiary : const Color(0xFFE2E8E4),
                          textColor: theme.colorScheme.onSurface,
                          onTap: () {
                             Navigator.pop(context);
                          }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({required String label, required Color bgColor, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    AppLocalizations.tr(context, 'my_profile'),
                    style: theme.textTheme.displayMedium,
                  ),
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 50,
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => profileProvider.loadProfile(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    if (profileProvider.isLoading && profileProvider.userProfile == null)
                      const Center(child: CircularProgressIndicator())
                    else if (profileProvider.userProfile != null)
                      Row(
                        children: [
                          // Avatar
                          GestureDetector(
                             onTap: _pickImage,
                             child: Stack(
                               children: [
                                 Container(
                                   width: 90,
                                   height: 90,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     color: theme.colorScheme.secondary,
                                     border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2),
                                   ),
                                   child: ClipOval(
                                     child: _buildAvatarImage(profileProvider.userProfile!.profileImageUrl),
                                   ),
                                 ),
                                 Positioned(
                                   bottom: 0,
                                   right: languageProvider.isArabic ? null : 0,
                                   left: languageProvider.isArabic ? 0 : null,
                                   child: Container(
                                     padding: const EdgeInsets.all(6),
                                     decoration: BoxDecoration(
                                       color: theme.colorScheme.surface,
                                       border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                       shape: BoxShape.circle,
                                     ),
                                     child: Icon(Icons.camera_alt_outlined, size: 16, color: theme.colorScheme.onSurface),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                          const SizedBox(width: 20),
                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profileProvider.userProfile!.firstName} ${profileProvider.userProfile!.lastName}',
                                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profileProvider.userProfile!.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const EditProfileScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppLocalizations.tr(context, 'edit_profile'),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),

                    // Menu Items
                    _buildMenuItem(
                      context,
                      icon: Icons.access_time_rounded,
                      title: AppLocalizations.tr(context, 'history'),
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SoilAnalysisScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildMenuItem(
                      context,
                      icon: Icons.nightlight_round,
                      title: AppLocalizations.tr(context, 'dark_mode'),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (val) => themeProvider.toggleTheme(),
                        activeThumbColor: Colors.white,
                        activeTrackColor: theme.primaryColor,
                        inactiveTrackColor: isDark ? Colors.white24 : Colors.grey.shade300,
                        inactiveThumbColor: Colors.white,
                      ),
                      onTap: () => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 16),

                    _buildMenuItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: AppLocalizations.tr(context, 'log_out'),
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      onTap: () => _showLogoutDialog(context),
                    ),
                    
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required Widget trailing, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.tertiary : const Color(0xFFDCFCE7).withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.green.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withAlpha(isDark ? 10 : 5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface.withAlpha(180), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String path) {
    if (path == 'assets/app_images/icons/logo.svg') {
      return SvgPicture.asset(
        path,
        fit: BoxFit.cover,
      );
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/app_images/images/1.png',
          fit: BoxFit.cover,
        ),
      );
    } else if (path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/app_images/images/1.png',
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Image.asset(
        'assets/app_images/images/1.png',
        fit: BoxFit.cover,
      );
    }
  }
}
