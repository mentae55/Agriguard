import 'package:flutter/material.dart';
import 'package:agriguard_project/core/core.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: secondaryColor, // Soft cream background
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_return_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.smart_toy_rounded, color: primaryColor, size: 36),
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
                 opacity: 0.8,
                 child: Image.asset(
                   'assets/app_images/images/plant.png',
                   height: 120,
                   errorBuilder: (_, __, ___) => const SizedBox(),
                 ),
               ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar Edit
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: secondaryColor,
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/app_images/images/1.png'), // Placeholder
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(200), // Olive green
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(label: 'First Name', initialValue: 'Sabrina'),
                const SizedBox(height: 16),
                _buildTextField(label: 'Last Name', initialValue: 'Aryan'),
                const SizedBox(height: 16),
                _buildTextField(label: 'Username', initialValue: '@Sabrina'),
                const SizedBox(height: 16),
                _buildTextField(label: 'Email', initialValue: '@SabrinaAry208@gmailcom', isEmail: true),
                const SizedBox(height: 16),
                _buildTextField(label: 'Phone Number', initialValue: '+234'),
                
                const SizedBox(height: 48),

                // Save Changes Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Save changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'AbhayaLibre',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String initialValue, bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w700,
             color: Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1EFE9), // Soft beige matching screenshot
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
      ],
    );
  }
}
