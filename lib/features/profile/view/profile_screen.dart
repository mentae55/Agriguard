import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isDarkMode = false;

  void _showLogoutDialog(BuildContext context) {
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
              color: primaryColor.withAlpha(220), // Dark olive green matching screenshot
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close Icon
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black87, size: 24),
                    ),
                  ),
                  // Exclamation
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
                  const Text(
                    'Are you sure you want\nto log out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDialogButton(
                          label: 'Yes',
                          bgColor: Colors.red.shade700,
                          textColor: Colors.white,
                          onTap: () {
                             Navigator.pop(context);
                             // Perform actual logout logic
                          }),
                      const SizedBox(width: 24),
                      _buildDialogButton(
                          label: 'No',
                          bgColor: const Color(0xFFE2E8E4),
                          textColor: Colors.black87,
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
            fontFamily: 'AbhayaLibre',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: secondaryColor, // Soft beige/cream
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'AbhayaLibre',
                      color: Colors.black87,
                    ),
                  ),
                  Icon(
                    Icons.smart_toy_rounded,
                    size: 50,
                    color: primaryColor,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Profile Header Info
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: secondaryColor,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              image: const DecorationImage(
                                image: AssetImage('assets/app_images/images/1.png'), // placeholder
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sabrina Aryan',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'AbhayaLibre',
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SabrinaAry208@gmail.com',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87.withAlpha(200),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withAlpha(180),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.white,
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
                    icon: Icons.access_time_rounded,
                    title: 'History',
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600),
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  
                  _buildMenuItem(
                    icon: Icons.nightlight_round,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (val) => setState(() => isDarkMode = val),
                      activeColor: Colors.white,
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: Colors.grey.shade300,
                      inactiveThumbColor: Colors.white,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  _buildMenuItem(
                    icon: Icons.language_rounded,
                    title: 'Languages',
                    trailing: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600),
                    onTap: () => _showLogoutDialog(context),
                  ),
                  
                  const SizedBox(height: 120), // Bottom padding for navigation bar overlap
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required Widget trailing, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7).withAlpha(150), // Pale green
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87.withAlpha(180), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'AbhayaLibre',
                  color: Colors.black87,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
