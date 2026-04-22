import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/local/hive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/auth_provider.dart';
import '../../../../core/services/exam_timeline_service.dart';
import '../../../providers/remote_data_provider.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final docs = HiveService.getAllDocs(uid: uid);
    final verifiedCount = docs.where((d) => d.isVerified).length;
    final unverifiedCount = docs.length - verifiedCount;
    final eligibleResultsList = HiveService.getAllEligibilityResults(uid: uid).where((e) => e.isEligible);
    final eligibleResults = eligibleResultsList.length;

    // Get live data for upcoming
    final eligibleExamIds = eligibleResultsList.map((r) => r.examId).toSet();
    final examKey = examIdsToKey(eligibleExamIds.isEmpty ? {'ALL_EXAMS'} : eligibleExamIds);
    final deadlinesAsync = ref.watch(deadlinesStreamProvider(examKey));
    
    // Removed Fallback, only Real-time Data
    final upcomingData = deadlinesAsync.value ?? [];

    List<Map<String, dynamic>> notifications = [];
    final now = DateTime.now();

    // 1. Live Deadline Notifications (show if deadline < 14 days)
    for (var dateEvt in upcomingData) {
      final days = (dateEvt['date'] as DateTime).difference(now).inDays;
      if (days >= 0 && days <= 14) {
        notifications.add({
          'title': 'Upcoming Deadline',
          'desc': '${dateEvt['examName']} ${dateEvt['event']} is closing in $days days!',
          'icon': Icons.notifications_active_rounded,
          'color': Colors.redAccent,
          'time': '$days days left',
        });
      }
    }

    if (verifiedCount > 0) {
      notifications.add({
        'title': 'Documents Verified',
        'desc': 'You have $verifiedCount verified document(s).',
        'icon': Icons.verified_rounded,
        'color': Colors.green,
        'time': 'Just now',
      });
    }
    if (unverifiedCount > 0) {
      notifications.add({
        'title': 'Action Required',
        'desc': 'You have $unverifiedCount document(s) pending review.',
        'icon': Icons.warning_rounded,
        'color': Colors.orange,
        'time': 'Recent',
      });
    }
    if (eligibleResults > 0) {
      notifications.add({
        'title': 'New Eligibility',
        'desc': 'You are eligible for $eligibleResults exams. Check timeline for deadlines.',
        'icon': Icons.star_rounded,
        'color': Colors.blue,
        'time': 'Recent',
      });
    }
    if (notifications.isEmpty) {
      notifications.add({
        'title': 'Welcome to Yogya',
        'desc': 'Upload your marksheet to get started with eligibility tracking.',
        'icon': Icons.waving_hand_rounded,
        'color': context.colors.primary,
        'time': 'Welcome',
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.glassWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (notif['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(notif['icon'], color: notif['color']),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'],
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              notif['desc'],
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        notif['time'],
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}








