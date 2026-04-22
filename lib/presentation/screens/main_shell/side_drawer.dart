import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class SideDrawer extends ConsumerWidget {
  SideDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final userName = profileState.profile?.name ?? user?.displayName ?? 'Aspirant';
    final examGoal = profileState.profile?.primaryExamGoal.isNotEmpty == true
        ? profileState.profile!.primaryExamGoal
        : 'ASPIRANT';
    final initials = userName.isNotEmpty
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'YG';

    return Drawer(
      backgroundColor: context.colors.bgDark,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, initials, userName, examGoal),

            SizedBox(height: 8),
            Divider(color: context.colors.bgCardLight),
            SizedBox(height: 8),

            // Nav items
            _buildNavItem(
              context,
              icon: Icons.dashboard_rounded,
              label: 'Home',
              route: '/dashboard',
              isActive: true,
            ),
            _buildNavItem(
              context,
              icon: Icons.verified_rounded,
              label: 'Eligibility Engine',
              route: '/eligibility-engine',
              badge: '!',
            ),
            _buildNavItem(
              context,
              icon: Icons.folder_rounded,
              label: 'My Documents',
              route: '/documents',
            ),
            _buildNavItem(
              context,
              icon: Icons.history_rounded,
              label: 'Attempt History',
              route: '/attempt-history',
            ),

            Divider(color: context.colors.bgCardLight),

            _buildNavItem(
              context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              route: '/settings',
            ),
            _buildNavItem(
              context,
              icon: Icons.help_rounded,
              label: 'Help & Support',
              route: '/help-support',
            ),

            Spacer(),

            // Exam readiness card
            _buildReadinessCard(context),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String initials, String userName, String examGoal) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.colors.primaryGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${examGoal.toUpperCase()} • Batch of ${DateTime.now().year}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool isActive = false,
    String? badge,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? context.colors.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? context.colors.primary
              : context.colors.textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive
                ? context.colors.primary
                : context.colors.textSecondary,
            fontSize: 14,
            fontWeight: isActive
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        trailing: badge != null
            ? Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: context.colors.partial,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context); // close drawer
          final tabRoutes = ['/dashboard', '/timeline', '/documents', '/profile'];
          if (tabRoutes.contains(route)) {
            context.go(route);
          } else {
            context.push(route);
          }
        },
      ),
    );
  }

  Widget _buildReadinessCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.colors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'EXAM READINESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Complete your profile to unlock full eligibility analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 4),
          Text(
            '60% Complete',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
