import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agriguard_project/core/localization/app_localizations.dart';
import '../controllers/profile_provider.dart';
import '../widgets/profile_text_field.dart';

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
    // Allow user to pick image from gallery
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
            content: Text(AppLocalizations.tr(context, 'profile_updated')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.tr(context, 'error_occurred')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final user = provider.userProfile;

    if (user == null && provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.tr(context, 'edit_profile'))),
        body: Center(child: CircularProgressIndicator()),
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
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: theme.primaryColor, size: 36),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background plant decoration at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
               padding: EdgeInsets.all(24.0),
               child: Opacity(
                 opacity: 0.8,
                 child: Image.asset(
                   'assets/app_images/images/plant.png',
                   height: 120,
                   errorBuilder: (_, __, ___) => SizedBox(),
                 ),
               ),
            ),
          ),
          
          SingleChildScrollView(
            padding: EdgeInsets.all(32),
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
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : user.profileImageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: user.profileImageUrl.startsWith('http')
                                              ? NetworkImage(user.profileImageUrl) as ImageProvider
                                              : FileImage(File(user.profileImageUrl)),
                                          fit: BoxFit.cover,
                                        )
                                      : const DecorationImage(
                                          image: AssetImage('assets/app_images/images/1.png'),
                                          fit: BoxFit.cover,
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0, // Using standard right for edit icon generally
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(200),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Form Fields
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'first_name'),
                    initialValue: user.firstName,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _firstName = val,
                  ),
                  SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'last_name'),
                    initialValue: user.lastName,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _lastName = val,
                  ),
                  SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'username'),
                    initialValue: user.username,
                    validator: (val) => val == null || val.isEmpty ? AppLocalizations.tr(context, 'required_field') : null,
                    onSaved: (val) => _username = val,
                  ),
                  SizedBox(height: 16),
                  ProfileTextField(
                    label: AppLocalizations.tr(context, 'email'),
                    initialValue: user.email,
                    isEmail: true,
                    readOnly: true, // Typically emails are not editable directly here or need auth flow
                  ),
                  SizedBox(height: 16),
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
                  
                  SizedBox(height: 48),

                  // Save Changes Button
                  provider.isLoading
                      ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                      : GestureDetector(
                          onTap: _saveProfile,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withAlpha(200),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withAlpha(40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.tr(context, 'save_changes'),
                                style: TextStyle(
                                  color: Colors.white,
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
}
