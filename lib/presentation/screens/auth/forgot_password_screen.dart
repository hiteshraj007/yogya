import '../../../core/theme/theme_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent        = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (mounted) {
      final error =
          ref.read(authNotifierProvider).errorMessage ?? 'Reset failed';
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
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.loginGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: context.colors.primary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  SizedBox(height: 24),

                  if (!_emailSent) ...[
                    // ── Reset form ─────────────────────
                    Icon(Icons.lock_reset_rounded,
                        size: 60, color: context.colors.primary),
                    SizedBox(height: 20),
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize:   26,
                        fontWeight: FontWeight.w800,
                        color:      context.colors.textDark,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Enter your email and we\'ll send you a reset link.',
                      style: TextStyle(
                        fontSize:   14,
                        color:      Colors.grey[500],
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    AppTextField(
                      label:        'Email Address',
                      hintText:     'you@example.com',
                      controller:   _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon:   Icons.email_outlined,
                      isDark:       false,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 28),
                    AppButton(
                      label:     'Send Reset Link',
                      onPressed: _handleReset,
                      isLoading: isLoading,
                    ),
                  ] else ...[
                    // ── Success state ──────────────────
                    SizedBox(height: 40),
                    Container(
                      padding:    EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.mark_email_read_rounded,
                              size: 60, color: context.colors.eligible),
                          SizedBox(height: 16),
                          Text(
                            'Email Sent!',
                            style: TextStyle(
                              fontSize:   22,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color:      context.colors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Check ${_emailController.text} for the reset link.',
                            style: TextStyle(
                              fontSize:   13,
                              color:      Colors.grey[500],
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          AppButton(
                            label:     'Back to Login',
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
