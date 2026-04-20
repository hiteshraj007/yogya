import '../../../core/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool isDark;
  final bool readOnly;
  final VoidCallback? onTap;

  AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.isDark = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: widget.isDark ? context.colors.textSecondary : Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: isPassword ? _obscure : false,
          validator: widget.validator,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: TextStyle(
            color: widget.isDark ? context.colors.textPrimary : context.colors.textDark,
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: widget.isDark ? context.colors.textHint : Colors.grey[400],
                    size: 20,
                  )
                : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: widget.isDark ? context.colors.textHint : Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: widget.isDark ? context.colors.bgCard : Colors.white,
            hintStyle: TextStyle(
              color: widget.isDark ? context.colors.textHint : Colors.grey[400],
              fontSize: 14,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: widget.isDark ? context.colors.glassBorder : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
