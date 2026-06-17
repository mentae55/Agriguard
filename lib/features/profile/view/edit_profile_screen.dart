import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agriguard_project/core/core.dart';
import 'package:agriguard_project/core/localization/app_localizations.dart';
import '../controllers/profile_provider.dart';
import '../widgets/profile_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _firstName;
  String? _lastName;
  String? _username;
  String? _phone;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<ProfileProvider>();
    final theme = Theme.of(context);
    
    try {
      await provider.updateProfile(
        firstName: _firstName ?? '',
        lastName: _lastName ?? '',
        username: _username ?? '',
        phone: _phone ?? '',
        newImage: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tr(context, 'profile_updated'),
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.tr(context, 'error_occurred')}: $e',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ProfileProvider>();
    final user = provider.userProfile;

    if (user == null && provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.tr(context, 'edit_profile'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.tr(context, 'edit_profile'))),
        body: Center(child: Text(AppLocalizations.tr(context, 'error_occurred'))),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.tr(context, 'edit_profile'),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SvgPicture.asset(
              'assets/app_images/icons/logo.svg',
              height: 36,
              width: 36,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background plant decoration at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
               padding: const EdgeInsets.all(24.0),
               child: Opacity(
                 opacity: isDark ? 0.3 : 0.8,
                 child: Image.asset(
                   'assets/app_images/images/plant.png',
                   height: 120,
                   errorBuilder: (_, _, _) => const SizedBox(),
                 ),
               ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Avatar Edit
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.secondary,
                              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200, width: 2),
                            ),
                            child: ClipOval(
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : _buildAvatarImage(user.profileImageUrl),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: Icon(Icons.edit, size: 14, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'first_name'),
                    initialValue: user.firstName,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _firstName = val,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'last_name'),
                    initialValue: user.lastName,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _lastName = val,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'username'),
                    initialValue: user.username,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _username = val,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'email'),
                    initialValue: user.email,
                    isEmail: true,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'phone_number'),
                    initialValue: user.phone,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) return AppLocalizations.tr(context, 'required_field');
                      if (val.length < 8) return AppLocalizations.tr(context, 'invalid_phone');
                      return null;
                    },
                    onSaved: (val) => _phone = val,
                  ),
                  
                  const SizedBox(height: 48),

                  // Save Changes Button
                  provider.isLoading
                      ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                      : GestureDetector(
                          onTap: _saveProfile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.tr(context, 'save_changes'),
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
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
