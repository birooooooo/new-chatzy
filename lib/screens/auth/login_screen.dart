import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_text_field.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_container.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn(
        loginInput: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Let AuthWrapper handle the navigation automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient Orbs (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.1),
                boxShadow: [
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Section
                    Center(
                      child: GlassContainer(
                        width: 120,
                        height: 120,
                        blur: 20,
                        borderRadius: AppTheme.borderRadiusLarge,
                        gradient: AppTheme.glassGradient,
                        child: Center(
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ).animate()
                       .fadeIn(duration: 600.ms)
                       .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 48),
                    
                    // Form Section
                    Column(
                      children: [
                        GlassTextField(
                          controller: _emailController,
                          hintText: 'Email or Username',
                          prefixIcon: const Icon(Icons.person_pin_rounded),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          suffixIcon: const Icon(Icons.visibility_off_outlined),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 24),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryLight,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    
                    const SizedBox(height: 32),
                    
                    GlassButton(
                      onPressed: _isLoading ? null : _login,
                      text: 'Sign In',
                      height: 56,
                      isLoading: _isLoading,
                      gradient: AppTheme.primaryGradient,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 24),
                    
                    // Social Login Divider? Maybe later. 
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
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
