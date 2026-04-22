import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final TextEditingController _searchCtrl = TextEditingController();
  int _expandedIndex = -1;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Exam Eligibility',
      'badge': 'ESSENTIAL',
      'icon': Icons.school_rounded,
      'color': Color(0xFF3B5BDB),
      'subtopics': ['Age Criteria', 'Syllabus', 'Qualification Requirements'],
    },
    {
      'title': 'Account Help',
      'icon': Icons.person_rounded,
      'color': Color(0xFF7C3AED),
      'subtopics': ['Passwords', 'Security', 'Profile Settings'],
    },
    {
      'title': 'OCR Troubleshooting',
      'icon': Icons.document_scanner_rounded,
      'color': Color(0xFFE91E63),
      'subtopics': ['Document Scan Issues', 'Photo ID Recognition', 'Low Confidence Scores'],
    },
    {
      'title': 'Documents & Certificates',
      'icon': Icons.folder_rounded,
      'color': Color(0xFF2ECC71),
      'subtopics': ['Upload', 'Verify', 'Store & Manage'],
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How does OCR scanning work?',
      'a': 'Yogya uses a 4-layer OCR pipeline that processes your marksheet image through pre-processing, layout detection, text extraction, and structured parsing to extract your marks data with 95% accuracy.',
    },
    {
      'q': 'Is my data safe?',
      'a': 'Yes! Your raw document images are purged immediately after OCR processing. Only extracted structured data (like marks and dates) is stored. JWT tokens are secured in hardware-backed storage.',
    },
    {
      'q': 'How is my eligibility calculated?',
      'a': 'The Eligibility Engine checks your age (computed from DOB), qualification level, social category, and attempt count against each exam\'s official criteria. Results update in real-time.',
    },
    {
      'q': 'Can I track multiple exams?',
      'a': 'Absolutely! Select any number of exams from our database of 10+ competitive examinations. The Timeline shows all your eligible exams chronologically.',
    },
    {
      'q': 'How do I update my profile?',
      'a': 'Go to Profile tab from the bottom navigation. You can update your personal info, category, and academic details. Changes automatically trigger a re-evaluation of your eligibility.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              'Yogya',
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),

              // ── Header Banner (Section 7.2.9) ────────────────
              FadeTransition(
                opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Search our FAQ or browse categories below',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 16),
                        // Search bar
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: context.colors.textHint, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search FAQs...',
                                    hintStyle: TextStyle(
                                      color: context.colors.textHint,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // ── Browse Categories (Section 7.2.9) ───────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Browse Categories',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SELECTED TOPICS',
                        style: TextStyle(
                          color: context.colors.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Category cards
              ...List.generate(_categories.length, (index) {
                final cat = _categories[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCategoryCard(cat, index),
                );
              }),

              SizedBox(height: 24),

              // ── FAQs ──────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(height: 12),

              ...List.generate(_faqs.length, (index) {
                return _buildFaqItem(index);
              }),

              SizedBox(height: 24),

              // ── Support Status Banner (Section 7.2.9) ───────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(0xFFFFCC80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.colors.partial.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.support_agent_rounded,
                            color: Color(0xFFE65100), size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'SUPPORT STATUS',
                                  style: TextStyle(
                                    color: Color(0xFFE65100),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.colors.partial,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'HIGH VOLUME',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Response time may be longer than usual',
                              style: TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Contact Support Card ──────────────────────────
              Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.headset_mic_rounded,
                          color: context.colors.primaryLight, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'Need more help?',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Contact our support team',
                        style: TextStyle(
                          color: context.colors.textHint,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.email_rounded, size: 18),
                          label: Text('Contact Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, int index) {
    final color = cat['color'] as Color;
    final subtopics = cat['subtopics'] as List<String>;
    final badge = cat['badge'] as String?;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat['icon'] as IconData, color: color, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cat['title'] as String,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtopics.join(' • '),
                    style: TextStyle(
                      color: context.colors.textHint,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () => setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        }),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? context.colors.primary.withOpacity(0.3)
                  : context.colors.glassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq['q']!,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.textHint,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                SizedBox(height: 12),
                Text(
                  faq['a']!,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
