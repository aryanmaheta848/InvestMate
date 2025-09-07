import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/screens/home/main_screen.dart';
import 'package:invest_mate/screens/auth/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('login_form_column'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // App Logo and Title
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSizes.padding),
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Welcome back! Sign in to your account',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.padding),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.paddingSmall),
                    
                    // Remember Me and Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Sign In Button
                    ElevatedButton(
                      key: const ValueKey('sign_in_button'),
                      onPressed: authProvider.isLoading ? null : _signIn,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    
                    const SizedBox(height: AppSizes.padding),
                    
                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.padding),
                    
                    // Google Sign In Button
                    OutlinedButton.icon(
                      key: const ValueKey('google_sign_in_button'),
                      onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.account_circle);
                        },
                      ),
                      label: const Text('Continue with Google'),
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Error Message
                    if (authProvider.errorMessage != null)
                      Container(
                        key: const ValueKey('error_message'),
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('close_error_button'),
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.error,
                              ),
                              onPressed: () {
                                authProvider.clearError();
                              },
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.body2,
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const SignupScreen());
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Get.offAll(() => const MainScreen());
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();

    if (success) {
      Get.offAll(() => const MainScreen());
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive password reset instructions.'),
            const SizedBox(height: AppSizes.padding),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.resetPassword(emailController.text.trim());
              
              Navigator.of(context).pop();
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Password reset email sent successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }
}
