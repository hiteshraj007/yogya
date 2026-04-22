import '../../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';

class WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  WizardStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = currentStep > stepIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: AppAnimations.normal,
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted ? context.colors.primary : context.colors.glassBorder,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }

        // Step circle
        final stepIndex = index ~/ 2;
        final isActive = currentStep == stepIndex;
        final isCompleted = currentStep > stepIndex;

        return Column(
          children: [
            AnimatedContainer(
              duration: AppAnimations.normal,
              width: isActive ? 36 : 28,
              height: isActive ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? context.colors.primary
                    : isActive
                        ? context.colors.primary.withOpacity(0.15)
                        : context.colors.bgCard,
                border: Border.all(
                  color: isActive || isCompleted
                      ? context.colors.primary
                      : context.colors.glassBorder,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive
                              ? context.colors.primary
                              : context.colors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              steps[stepIndex],
              style: TextStyle(
                color: isActive || isCompleted
                    ? context.colors.textPrimary
                    : context.colors.textHint,
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        );
      }),
    );
  }
}
