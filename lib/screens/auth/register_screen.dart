import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_container.dart';
import '../home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms & Conditions'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          
          // Let AuthWrapper handle the navigation automatically
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fixed background opacity for better contrast
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
           Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: GlassContainer(
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(15),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    // Header
                    Text(
                      'Join CHATZY',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Create an account to start chatting',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Profile Avatar Picker
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo picker opened')),
                          );
                        },
                        child: Stack(
                          children: [
                            GlassContainer(
                              width: 100,
                              height: 100,
                              borderRadius: BorderRadius.circular(50),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                    
                    const SizedBox(height: 40),
                    
                    // Full Name Field
                    GlassTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 16),

                    // Username Field
                    GlassTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Please enter a username';
                         if (value.length < 3) return 'Username too short';
                         if (value.contains(' ')) return 'No spaces allowed';
                         return null;
                      },
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Email Field
                    GlassTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Please enter your email';
                         if (!value.contains('@')) return 'Please enter a valid email';
                         return null;
                      },
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Phone Field
                    GlassTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    GlassTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    GlassTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 20),
                    
                    // Terms & Conditions
                    Row(
                      children: [
                        Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.white70),
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppTheme.primary,
                            checkColor: Colors.white,
                            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                    
                    const SizedBox(height: 30),
                    
                    // Register Button
                    GlassButton(
                      text: 'Create Account',
                      onPressed: _isLoading ? null : () => _register(),
                      isLoading: _isLoading,
                       width: double.infinity,
                      height: 56,
                      gradient: AppTheme.primaryGradient,
                    ).animate().fadeIn(delay: 900.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
