import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _slideCtrl;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _slideAnims = List.generate(6, (i) {
      return Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideCtrl,
        curve: Interval(i * 0.1, 0.5 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    });

    _fadeAnims = List.generate(6, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _slideCtrl,
        curve: Interval(i * 0.1, 0.5 + i * 0.1, curve: Curves.easeOut),
      ));
    });

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Widget _staggered(int i, Widget child) {
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  Future<void> _handleEmailLogin() async {
    ref.read(authNotifierProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).loginWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!success && mounted) {
      _showErrorSnackbar(
        ref.read(authNotifierProvider).errorMessage ?? 'Login failed',
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    ref.read(authNotifierProvider.notifier).clearError();
    final success = await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (!success && mounted) {
      _showErrorSnackbar(
        ref.read(authNotifierProvider).errorMessage ?? 'Google sign-in failed',
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: context.colors.ineligible,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

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
                  SizedBox(height: 50),
                  _staggered(
                    0,
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: context.colors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28),
                  _staggered(
                    1,
                    Column(
                      children: [
                        Text(
                          AppStrings.welcomeBack,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textDark,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppStrings.loginSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  _staggered(
                    2,
                    AppTextField(
                      label: AppStrings.email,
                      hintText: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      isDark: false,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(val.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  _staggered(
                    3,
                    Column(
                      children: [
                        AppTextField(
                          label: AppStrings.password,
                          hintText: '••••••••',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          isDark: false,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password is required';
                            if (val.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.forgotPassword),
                            child: Text(
                              AppStrings.forgotPassword,
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _staggered(
                    4,
                    AppButton(
                      label: AppStrings.login,
                      onPressed: _handleEmailLogin,
                      isLoading: isLoading,
                    ),
                  ),
                  SizedBox(height: 28),
                  _staggered(
                    5,
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppStrings.orContinueWith,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: isLoading ? null : _handleGoogleLogin,
                          child: AnimatedOpacity(
                            opacity: isLoading ? 0.6 : 1.0,
                            duration: Duration(milliseconds: 200),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    AppStrings.googleSignIn,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.noAccount,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.signUp),
                              child: Text(
                                AppStrings.signUp,
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
