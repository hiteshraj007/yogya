import '../../../core/theme/theme_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {

  final _formKey             = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();

  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmail(
          email:       _emailController.text,
          password:    _passwordController.text,
          displayName: _nameController.text.trim(),
        );

    if (!success && mounted) {
      final error =
          ref.read(authNotifierProvider).errorMessage ?? 'Sign up failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error,
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          backgroundColor: context.colors.ineligible,
          behavior:        SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    // On success: router redirect handles navigation to /dashboard
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.loginGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40),

                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: context.colors.primary),
                        onPressed: () => context.pop(),
                      ),
                    ),

                    SizedBox(height: 8),

                    // Logo
                    Center(
                      child: Container(
                        width:  72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient:     context.colors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:      context.colors.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset:     Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size:  36),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Heading
                    Text(
                      AppStrings.createAccount,
                      style: TextStyle(
                        fontSize:   26,
                        fontWeight: FontWeight.w800,
                        color:      context.colors.textDark,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.signUpSubtitle,
                      style: TextStyle(
                        fontSize:   13,
                        color:      Colors.grey[500],
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 36),

                    // Full name
                    AppTextField(
                      label:      AppStrings.fullName,
                      hintText:   'Aditi Sharma',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline_rounded,
                      isDark:     false,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (val.trim().length < 2) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Email
                    AppTextField(
                      label:        AppStrings.email,
                      hintText:     'you@example.com',
                      controller:   _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon:   Icons.email_outlined,
                      isDark:       false,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                            .hasMatch(val.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Password
                    AppTextField(
                      label:       AppStrings.password,
                      hintText:    '••••••••',
                      controller:  _passwordController,
                      obscureText: true,
                      prefixIcon:  Icons.lock_outline_rounded,
                      isDark:      false,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Minimum 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Confirm password
                    AppTextField(
                      label:       AppStrings.confirmPassword,
                      hintText:    '••••••••',
                      controller:  _confirmController,
                      obscureText: true,
                      prefixIcon:  Icons.lock_outline_rounded,
                      isDark:      false,
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 32),

                    // Sign up button
                    AppButton(
                      label:     AppStrings.createAccount,
                      onPressed: _handleSignUp,
                      isLoading: isLoading,
                    ),

                    SizedBox(height: 24),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: TextStyle(
                            color:      Colors.grey[500],
                            fontSize:   14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            AppStrings.login,
                            style: TextStyle(
                              color:      context.colors.primary,
                              fontSize:   14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
