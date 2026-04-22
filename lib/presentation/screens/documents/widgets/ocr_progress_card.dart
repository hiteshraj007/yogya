import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../../../data/providers/ocr_provider.dart';
import 'dart:async';

class OcrProgressCard extends StatefulWidget {
  final OcrState ocrState;
  final VoidCallback? onCancel;

  const OcrProgressCard({
    super.key,
    required this.ocrState,
    this.onCancel,
  });

  @override
  State<OcrProgressCard> createState() => _OcrProgressCardState();
}

class _OcrProgressCardState extends State<OcrProgressCard>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _showCancel = false;

  // After 15 seconds, show cancel button; after 60s, show strong warning
  static const int _cancelAfterSeconds = 15;
  static const int _warnAfterSeconds = 60;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _cancelAfterSeconds) {
          _showCancel = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // Determine which layer is currently processing
  String get _currentLayer {
    final progress = widget.ocrState.progress;
    if (progress < 0.25) return 'Layer 1 of 4';
    if (progress < 0.50) return 'Layer 2 of 4';
    if (progress < 0.75) return 'Layer 3 of 4';
    return 'Layer 4 of 4';
  }

  String get _layerDescription {
    final progress = widget.ocrState.progress;
    if (progress < 0.25) return 'Image Pre-processing';
    if (progress < 0.50) return 'Layout Detection';
    if (progress < 0.75) return 'Text Extraction';
    return 'Structured Data Parsing';
  }

  String get _elapsedText {
    if (_elapsedSeconds < 60) return '${_elapsedSeconds}s';
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m}m ${s}s';
  }

  bool get _isSlow => _elapsedSeconds >= _warnAfterSeconds;

  @override
  Widget build(BuildContext context) {
    final progress = widget.ocrState.progress;
    final percent = (progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isSlow
                  ? context.colors.urgencyHigh.withValues(alpha: 0.5)
                  : context.colors.glassBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isSlow
                        ? context.colors.urgencyHigh
                        : context.colors.primary)
                    .withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extracting Marks Data...',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Processing $_currentLayer',
                          style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Percentage + elapsed timer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$percent%',
                          style: TextStyle(
                            color: context.colors.primaryLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _pulseAnim,
                        child: Text(
                          _elapsedText,
                          style: TextStyle(
                            color: _isSlow
                                ? context.colors.urgencyHigh
                                : context.colors.textHint,
                            fontSize: 10,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.colors.bgCardLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B5BDB),
                              Color(0xFF7C3AED),
                              Color(0xFFE91E90),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Current step description
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.bgCardLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _layerDescription,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Step badges — 4 layers
              Row(
                children: [
                  _buildStepBadge(context, 'Pre-process',
                      progress >= 0.25, progress >= 0.0 && progress < 0.25),
                  const SizedBox(width: 6),
                  _buildStepBadge(context, 'Layout',
                      progress >= 0.50, progress >= 0.25 && progress < 0.50),
                  const SizedBox(width: 6),
                  _buildStepBadge(context, 'Text',
                      progress >= 0.75, progress >= 0.50 && progress < 0.75),
                  const SizedBox(width: 6),
                  _buildStepBadge(context, 'Parse',
                      progress >= 1.0, progress >= 0.75 && progress < 1.0),
                ],
              ),
            ],
          ),
        ),

        // ── Slow / Cancel section ────────────────────────────────
        if (_showCancel) ...[
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: _showCancel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Column(
              children: [
                if (_isSlow)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colors.urgencyHigh.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              context.colors.urgencyHigh.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: context.colors.urgencyHigh, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is taking unusually long. The PDF may be too large or the parser is busy. You can cancel and try again.',
                            style: TextStyle(
                              color: context.colors.urgencyHigh,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: context.colors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            color: context.colors.textHint, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Taking longer than expected. You can wait or cancel and try again.',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Cancel & Go Back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isSlow
                          ? context.colors.urgencyHigh
                          : context.colors.textPrimary,
                      side: BorderSide(
                        color: _isSlow
                            ? context.colors.urgencyHigh
                            : context.colors.glassBorder,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepBadge(
      BuildContext context, String label, bool isDone, bool isActive) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (isDone) {
      bgColor = context.colors.eligible.withValues(alpha: 0.15);
      borderColor = context.colors.eligible.withValues(alpha: 0.4);
      textColor = context.colors.eligible;
      icon = Icons.check_rounded;
    } else if (isActive) {
      bgColor = context.colors.primary.withValues(alpha: 0.15);
      borderColor = context.colors.primary;
      textColor = context.colors.primaryLight;
    } else {
      bgColor = context.colors.bgCardLight;
      borderColor = context.colors.glassBorder;
      textColor = context.colors.textHint;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 9),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}