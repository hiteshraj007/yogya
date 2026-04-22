import '../../../core/theme/theme_colors.dart';
// import 'package:flutter/material.dart';
// // import '../../../core/constants/strings.dart';
// import '../../../core/constants/app_animations.dart';

// class SettingsScreen extends StatefulWidget {
//   SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen>
//     with SingleTickerProviderStateMixin {
//   bool _darkMode = true;
//   bool _pushNotifications = true;
//   bool _examReminders = true;
//   bool _deadlineAlerts = true;

//   late AnimationController _ctrl;
//   late List<Animation<double>> _fadeAnims;
//   late List<Animation<Offset>> _slideAnims;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 1200),
//     );

//     _fadeAnims = List.generate(5, (i) {
//       return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
//         parent: _ctrl,
//         curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOut),
//       ));
//     });

//     _slideAnims = List.generate(5, (i) {
//       return Tween<Offset>(
//         begin: Offset(0, 0.15),
//         end: Offset.zero,
//       ).animate(CurvedAnimation(
//         parent: _ctrl,
//         curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOutCubic),
//       ));
//     });

//     _ctrl.forward();
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   Widget _animItem(int index, Widget child) {
//     final i = index.clamp(0, 4);
//     return SlideTransition(
//       position: _slideAnims[i],
//       child: FadeTransition(opacity: _fadeAnims[i], child: child),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: context.colors.bgDark,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           'Settings',
//           style: TextStyle(
//             color: context.colors.textPrimary,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             fontFamily: 'Poppins',
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: BouncingScrollPhysics(),
//           padding: EdgeInsets.all(20),
//           child: Column(
//             children: [
//               // Appearance
//               _animItem(
//                 0,
//                 _buildSection(
//                   'Appearance',
//                   Icons.palette_outlined,
//                   [
//                     _buildToggleTile(
//                       'Dark Mode',
//                       'Switch between light and dark theme',
//                       Icons.dark_mode_rounded,
//                       _darkMode,
//                       (val) => setState(() => _darkMode = val),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 16),

//               // Notifications
//               _animItem(
//                 1,
//                 _buildSection(
//                   'Notifications',
//                   Icons.notifications_outlined,
//                   [
//                     _buildToggleTile(
//                       'Push Notifications',
//                       'Receive push notifications',
//                       Icons.notifications_active_rounded,
//                       _pushNotifications,
//                       (val) => setState(() => _pushNotifications = val),
//                     ),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildToggleTile(
//                       'Exam Reminders',
//                       'Get notified before exam dates',
//                       Icons.alarm_rounded,
//                       _examReminders,
//                       (val) => setState(() => _examReminders = val),
//                     ),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildToggleTile(
//                       'Deadline Alerts',
//                       'Application deadline notifications',
//                       Icons.timer_rounded,
//                       _deadlineAlerts,
//                       (val) => setState(() => _deadlineAlerts = val),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 16),

//               // Data & Storage
//               _animItem(
//                 2,
//                 _buildSection(
//                   'Data & Storage',
//                   Icons.storage_rounded,
//                   [
//                     _buildActionTile(
//                       'Clear Cache',
//                       'Free up storage space',
//                       Icons.cleaning_services_rounded,
//                       () => _showSnack('Cache cleared'),
//                     ),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildActionTile(
//                       'Export Data',
//                       'Download your data as JSON',
//                       Icons.download_rounded,
//                       () => _showSnack('Data exported'),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 16),

//               // About
//               _animItem(
//                 3,
//                 _buildSection(
//                   'About',
//                   Icons.info_outline_rounded,
//                   [
//                     _buildInfoTile('Version', AppStrings.version, Icons.tag_rounded),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildActionTile(
//                       'Terms of Service',
//                       'Read our terms',
//                       Icons.description_rounded,
//                       () {},
//                     ),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildActionTile(
//                       'Privacy Policy',
//                       'How we handle your data',
//                       Icons.privacy_tip_rounded,
//                       () {},
//                     ),
//                     Divider(color: context.colors.glassBorder, height: 1),
//                     _buildActionTile(
//                       'Open Source Licenses',
//                       'Third party licenses',
//                       Icons.code_rounded,
//                       () {},
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 16),

//               // Logout
//               _animItem(
//                 4,
//                 GestureDetector(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         backgroundColor: context.colors.bgCard,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         title: Text(
//                           'Logout',
//                           style: TextStyle(
//                             color: context.colors.textPrimary,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                         content: Text(
//                           'Are you sure you want to logout?',
//                           style: TextStyle(
//                             color: context.colors.textSecondary,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: Text('Cancel'),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               // TODO: Implement actual logout
//                             },
//                             child: Text(
//                               'Logout',
//                               style: TextStyle(color: context.colors.ineligible),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: context.colors.ineligible.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(14),
//                       border: Border.all(
//                         color: context.colors.ineligible.withOpacity(0.3),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.logout_rounded,
//                             color: context.colors.ineligible, size: 20),
//                         SizedBox(width: 10),
//                         Text(
//                           'Logout',
//                           style: TextStyle(
//                             color: context.colors.ineligible,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             fontFamily: 'Poppins',
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSection(String title, IconData icon, List<Widget> children) {
//     return Container(
//       decoration: BoxDecoration(
//         color: context.colors.bgCard,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: context.colors.glassBorder),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
//             child: Row(
//               children: [
//                 Icon(icon, color: context.colors.primaryLight, size: 18),
//                 SizedBox(width: 10),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: context.colors.textPrimary,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildToggleTile(
//     String title,
//     String subtitle,
//     IconData icon,
//     bool value,
//     ValueChanged<bool> onChanged,
//   ) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Row(
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: context.colors.bgCardLight,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: context.colors.textSecondary, size: 18),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: context.colors.textPrimary,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: context.colors.textHint,
//                     fontSize: 11,
//                     fontFamily: 'Poppins',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Switch(
//             value: value,
//             onChanged: onChanged,
//             activeColor: context.colors.primary,
//             activeTrackColor: context.colors.primary.withValues(alpha: 0.3),
//             inactiveThumbColor: context.colors.textHint,
//             inactiveTrackColor: context.colors.bgCardLight,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionTile(
//     String title,
//     String subtitle,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Row(
//           children: [
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: context.colors.bgCardLight,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(icon, color: context.colors.textSecondary, size: 18),
//             ),
//             SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       color: context.colors.textPrimary,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       fontFamily: 'Poppins',
//                     ),
//                   ),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       color: context.colors.textHint,
//                       fontSize: 11,
//                       fontFamily: 'Poppins',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right_rounded,
//                 color: context.colors.textHint, size: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile(String title, String value, IconData icon) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: context.colors.bgCardLight,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: context.colors.textSecondary, size: 18),
//           ),
//           SizedBox(width: 12),
//           Text(
//             title,
//             style: TextStyle(
//               color: context.colors.textPrimary,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               fontFamily: 'Poppins',
//             ),
//           ),
//           Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               color: context.colors.textHint,
//               fontSize: 13,
//               fontFamily: 'Poppins',
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';

// ── Change 1: StatefulWidget → ConsumerStatefulWidget ──────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// ── Change 2: State → ConsumerState ────────────────────────
class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnims = List.generate(5, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOut),
      ));
    });

    _slideAnims = List.generate(5, (i) {
      return Tween<Offset>(
        begin: Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.12, 0.5 + i * 0.1, curve: Curves.easeOutCubic),
      ));
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animItem(int index, Widget child) {
    final i = index.clamp(0, 4);
    return SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child),
    );
  }

  // ── Change 3: Logout function — real Firebase logout ──────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(
                color: context.colors.ineligible,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // User ne confirm kiya → real Firebase logout
    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      // Router automatically /login par redirect kar dega
      // authStateProvider stream trigger hogi — kuch aur nahi karna
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state watch karo (logout ke time spinner dikhayenge)
    final isLoggingOut = ref.watch(authNotifierProvider).isLoading;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Profile Card ──────────────────────────
              _animItem(0, _buildProfileCard()),
              SizedBox(height: 24),
              // Appearance — same as before
              _animItem(
                1,
                _buildSection(
                  'Appearance',
                  Icons.palette_outlined,
                  [
                    _buildToggleTile(
                      'Dark Mode',
                      'Switch between light and dark theme',
                      Icons.dark_mode_rounded,
                      settings.darkMode,
                      (val) => settingsNotifier.setDarkMode(val),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Notifications — same as before
              _animItem(
                2,
                _buildSection(
                  'Notifications',
                  Icons.notifications_outlined,
                  [
                    _buildToggleTile(
                      'Push Notifications',
                      'Receive push notifications',
                      Icons.notifications_active_rounded,
                      settings.pushNotifications,
                      (val) => settingsNotifier.setPushNotifications(val),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    _buildToggleTile(
                      'Exam Reminders',
                      'Get notified before exam dates',
                      Icons.alarm_rounded,
                      settings.examReminders,
                      (val) => settingsNotifier.setExamReminders(val),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    _buildToggleTile(
                      'Deadline Alerts',
                      'Application deadline notifications',
                      Icons.timer_rounded,
                      settings.deadlineAlerts,
                      (val) => settingsNotifier.setDeadlineAlerts(val),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // About
              _animItem(
                3,
                _buildSection(
                  'About',
                  Icons.info_outline_rounded,
                  [
                    _buildInfoTile(
                        'Version', AppStrings.version, Icons.tag_rounded),
                    Divider(color: context.colors.glassBorder, height: 1),
                    _buildActionTile(
                      'Terms of Service',
                      'Read our terms & conditions',
                      Icons.description_rounded,
                      () => _showInfoDialog(
                        title: 'Terms of Service',
                        icon: Icons.description_rounded,
                        sections: [
                          _InfoSection(
                            heading: '1. Acceptance of Terms',
                            body:
                                'By downloading or using Yogya, you agree to be bound by these Terms of Service. If you do not agree with any part of the terms, please do not use the app.',
                          ),
                          _InfoSection(
                            heading: '2. Who Can Use This App',
                            body:
                                'Yogya is designed for students preparing for competitive examinations (SSC, Railways, Defence, Banking, etc.). You must be at least 13 years old to use this application.',
                          ),
                          _InfoSection(
                            heading: '3. Your Account',
                            body:
                                'You are responsible for safeguarding your account credentials. Please use a strong password and do not share your login details with anyone. Notify us immediately if you suspect any unauthorized access.',
                          ),
                          _InfoSection(
                            heading: '4. Acceptable Use',
                            body:
                                'You agree not to misuse the app — this includes attempting to hack, reverse-engineer, or distribute the app content without permission. Use Yogya only for lawful purposes.',
                          ),
                          _InfoSection(
                            heading: '5. Content Accuracy',
                            body:
                                'While we strive to keep all exam eligibility information accurate and up-to-date, Yogya does not guarantee 100% accuracy. Always cross-check with the official exam notification before applying.',
                          ),
                          _InfoSection(
                            heading: '6. Termination',
                            body:
                                'We reserve the right to suspend or terminate accounts that violate these Terms of Service without prior notice.',
                          ),
                          _InfoSection(
                            heading: '7. Changes to Terms',
                            body:
                                'We may update these Terms from time to time. Continued use of the app after changes means you accept the new terms. We will notify you of significant changes via the app.',
                          ),
                          _InfoSection(
                            heading: '8. Contact',
                            body:
                                'For any questions regarding these Terms, please reach us at support@yogya.app.',
                          ),
                        ],
                      ),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    _buildActionTile(
                      'Privacy Policy',
                      'How we handle your data',
                      Icons.privacy_tip_rounded,
                      () => _showInfoDialog(
                        title: 'Privacy Policy',
                        icon: Icons.privacy_tip_rounded,
                        sections: [
                          _InfoSection(
                            heading: 'What Information We Collect',
                            body:
                                'We collect information you provide directly — such as your name, email address, qualification details, date of birth, and exam preferences. This helps us give you accurate eligibility results.',
                          ),
                          _InfoSection(
                            heading: 'How We Use Your Information',
                            body:
                                'Your data is used to:\n• Determine your eligibility for government exams\n• Personalize your exam preparation experience\n• Send you important exam reminders and updates\n• Improve the accuracy of our eligibility engine',
                          ),
                          _InfoSection(
                            heading: 'Data Storage & Security',
                            body:
                                'Your data is stored securely on Firebase (Google Cloud). We use industry-standard encryption to protect your personal information. We do not sell or share your data with third-party advertisers.',
                          ),
                          _InfoSection(
                            heading: 'Document Scanning (OCR)',
                            body:
                                'When you scan your marksheet, the image is processed to extract your academic scores. The processed image is not stored permanently — only the extracted data is saved to your profile.',
                          ),
                          _InfoSection(
                            heading: 'Your Rights',
                            body:
                                'You have the right to:\n• Access your personal data at any time\n• Correct inaccurate information\n• Delete your account and all associated data\n• Opt out of non-essential notifications',
                          ),
                          _InfoSection(
                            heading: 'Third-Party Services',
                            body:
                                'Yogya uses Firebase (for authentication and storage) and Google ML Kit (for document scanning). These services have their own privacy policies which we encourage you to review.',
                          ),
                          _InfoSection(
                            heading: 'Contact Us',
                            body:
                                'For privacy-related queries, contact us at privacy@yogya.app. We will respond within 7 business days.',
                          ),
                        ],
                      ),
                    ),
                    Divider(color: context.colors.glassBorder, height: 1),
                    _buildActionTile(
                      'Open Source Licenses',
                      'Third-party libraries used in the app',
                      Icons.code_rounded,
                      () => _showInfoDialog(
                        title: 'Open Source Licenses',
                        icon: Icons.code_rounded,
                        sections: [
                          _InfoSection(
                            heading: 'Flutter SDK',
                            body:
                                'License: BSD 3-Clause\nCopyright © 2023 Google LLC\nFlutter is Google\'s open source UI toolkit for building natively compiled applications.',
                          ),
                          _InfoSection(
                            heading: 'firebase_core & firebase_auth',
                            body:
                                'License: BSD 3-Clause\nCopyright © Google LLC\nProvides Firebase authentication and core services integration for Flutter applications.',
                          ),
                          _InfoSection(
                            heading: 'cloud_firestore',
                            body:
                                'License: BSD 3-Clause\nCopyright © Google LLC\nA flexible, scalable NoSQL cloud database used to store and sync app data in real time.',
                          ),
                          _InfoSection(
                            heading: 'flutter_riverpod',
                            body:
                                'License: MIT\nCopyright © 2020 Remi Rousselet\nA reactive state management library for Flutter — used throughout the app for clean architecture.',
                          ),
                          _InfoSection(
                            heading: 'go_router',
                            body:
                                'License: BSD 3-Clause\nCopyright © Google LLC\nA declarative routing package for Flutter, used for all navigation within the app.',
                          ),
                          _InfoSection(
                            heading: 'google_mlkit_text_recognition',
                            body:
                                'License: MIT\nCopyright © Google LLC\nPowers the OCR (Optical Character Recognition) feature used to scan and extract data from marksheets.',
                          ),
                          _InfoSection(
                            heading: 'image_picker',
                            body:
                                'License: Apache 2.0\nCopyright © Flutter Community\nUsed to allow users to pick images from their gallery or camera for document scanning.',
                          ),
                          _InfoSection(
                            heading: 'shared_preferences',
                            body:
                                'License: BSD 3-Clause\nCopyright © Flutter Community\nUsed to persist simple key-value data (like settings and preferences) locally on the device.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // ── Logout button — ab real Firebase logout ───
              _animItem(
                4,
                GestureDetector(
                  onTap: isLoggingOut ? null : _handleLogout,
                  child: AnimatedOpacity(
                    opacity: isLoggingOut ? 0.6 : 1.0,
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.ineligible.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.colors.ineligible.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logout ho raha hai to spinner, warna icon
                          if (isLoggingOut)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.ineligible,
                              ),
                            )
                          else
                            Icon(Icons.logout_rounded,
                                color: context.colors.ineligible, size: 20),
                          SizedBox(width: 10),
                          Text(
                            isLoggingOut ? 'Logging out...' : 'Logout',
                            style: TextStyle(
                              color: context.colors.ineligible,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────

  Widget _buildProfileCard() {
    final profileState = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);

    final name = profileState.profile?.name ?? user?.displayName ?? 'User';
    final email = profileState.profile?.email ?? user?.email ?? '';
    final role = profileState.profile?.qualification.isNotEmpty == true
        ? '${profileState.profile!.qualification} Aspirant'
        : 'Exam Aspirant';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.colors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
            ),
          ),
          SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: context.colors.primaryLight, size: 18),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.textSecondary, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.colors.textHint,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.colors.primary,
            activeTrackColor: context.colors.primary.withOpacity(0.3),
            inactiveThumbColor: context.colors.textHint,
            inactiveTrackColor: context.colors.bgCardLight,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.bgCardLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.colors.textSecondary, size: 18),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.colors.textHint,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.textSecondary, size: 18),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: context.colors.textHint,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Dialog (Terms / Privacy / Licenses) ─────────────
  void _showInfoDialog({
    required String title,
    required IconData icon,
    required List<_InfoSection> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: context.colors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: context.colors.textHint),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(color: context.colors.glassBorder),
              // Content
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => SizedBox(height: 20),
                  itemBuilder: (_, i) {
                    final s = sections[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.heading,
                          style: TextStyle(
                            color: context.colors.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          s.body,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13.5,
                            fontFamily: 'Poppins',
                            height: 1.65,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple data class for info dialog sections
class _InfoSection {
  final String heading;
  final String body;
  const _InfoSection({required this.heading, required this.body});
}
