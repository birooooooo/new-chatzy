import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final _userService = UserService(); // Add UserService
  final _usernameController = TextEditingController(); // Add controller

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authUser = Provider.of<AuthService>(context, listen: false).currentUser;
    if (authUser != null) {
      // Fetch full details from Firestore
      final fullUser = await _userService.getUser(authUser.id);
      if (mounted) {
        setState(() {
          _nameController.text = fullUser?.name ?? authUser.name;
          _emailController.text = fullUser?.email ?? authUser.email;
          _usernameController.text = fullUser?.username ?? '';
          _bioController.text = fullUser?.bio ?? "Digital Nomad | Tech Enthusiast";
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Update Auth Profile
      await authService.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary))
              : const Text('Save', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // File picker logic here
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms),
            
            const SizedBox(height: 40),

            // Fields
            _buildField(
              label: 'Display Name',
              controller: _nameController,
              icon: Icons.person_outline_rounded,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            _buildField(
              label: 'Email (Read-only)',
              controller: _emailController,
              icon: Icons.email_outlined,
              enabled: false,
            ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            _buildField(
              label: 'Username (Read-only)',
              controller: _usernameController,
              icon: Icons.alternate_email_rounded,
              enabled: false,
            ).animate().fadeIn(delay: 175.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            _buildField(
              label: 'Bio',
              controller: _bioController,
              icon: Icons.info_outline_rounded,
              maxLines: 3,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 40),

            // Tip
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              opacity: 0.05,
              child: Row(
                children: [
                   const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.warning),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'Your profile is visible to all your contacts in CHATZY.',
                       style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                     ),
                   ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: enabled ? 0.05 : 0.02,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            style: TextStyle(color: enabled ? Colors.white : Colors.white.withOpacity(0.3)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? AppTheme.secondary : AppTheme.secondary.withOpacity(0.3), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
