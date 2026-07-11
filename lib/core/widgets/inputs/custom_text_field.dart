import '../../enums/app_enums.dart';
import '../../utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint, title;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final double? height, width;
  final TextAlign textAlign;
  final int? maxLength;
  final double? borderRadius;
  final TextStyle? textStyle;

  /// Whether validation should be enabled or not
  final bool enableValidation;

  /// Type of field to determine which validator to apply
  final TextFieldType fieldType;

  /// Custom validator function (overrides built-in validators)
  final String? Function(String?)? customValidator;

  const CustomTextField({
    super.key,
    this.focusNode,
    this.height,
    this.title,
    this.width,
    this.controller,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.enableValidation = true,
    this.fieldType = TextFieldType.text,
    this.prefixText,
    this.textAlign = TextAlign.start,
    this.customValidator,
    this.borderRadius,
    this.textStyle,
  });

  String? _getValidator(String? value) {
    if (!enableValidation) return null;

    // Use custom validator if provided
    if (customValidator != null) {
      return customValidator!(value);
    }

    switch (fieldType) {
      case TextFieldType.email:
        return Validators.validateEmail(value);
      case TextFieldType.password:
        return Validators.validatePassword(value);
      case TextFieldType.name:
        return Validators.validateName(value);
      case TextFieldType.phone:
        return Validators.validatePhone(value);
      case TextFieldType.text:
        return Validators.validateRequired(value, hint ?? 'Field');
      case TextFieldType.number:
        return Validators.validateNumberOnly(value, hint ?? 'Field');
    }
  }

  TextInputType _getKeyboardType() {
    switch (fieldType) {
      case TextFieldType.email:
        return TextInputType.emailAddress;
      case TextFieldType.password:
        return TextInputType.text;
      case TextFieldType.name:
        return TextInputType.name;
      case TextFieldType.phone:
        return TextInputType.phone;
      case TextFieldType.text:
        return TextInputType.text;
      case TextFieldType.number:
        return TextInputType.number;
    }
  }

  TextCapitalization _getTextCapitalization() {
    switch (fieldType) {
      case TextFieldType.name:
        return TextCapitalization.words;
      case TextFieldType.email:
      case TextFieldType.password:
      case TextFieldType.phone:
      case TextFieldType.text:
        return TextCapitalization.none;
      case TextFieldType.number:
        return TextCapitalization.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          5.ht,
        ],
        SizedBox(
          height: height,
          width: width ?? double.infinity,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textAlign: textAlign,
            obscureText: obscureText,
            keyboardType: keyboardType ?? _getKeyboardType(),
            onChanged: (val) {
              if (onChanged != null) onChanged!(val);
            },
            inputFormatters: inputFormatters,
            textCapitalization: _getTextCapitalization(),
            maxLines: maxLines,
            validator: _getValidator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            maxLength: maxLength,
            style: textStyle ??
                textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
            decoration: InputDecoration(
              hintText: hint,
              alignLabelWithHint: true,
              // do not show built-in error inside the decoration - we render it below
              errorText: null,
              border: borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                      borderSide: BorderSide.none,
                    )
                  : null,
              enabledBorder: borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                      borderSide: BorderSide.none,
                    )
                  : null,
              focusedBorder: borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                      borderSide: BorderSide.none,
                    )
                  : null,
              errorBorder: borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                      borderSide: BorderSide.none,
                    )
                  : null,
              focusedErrorBorder: borderRadius != null
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius!),
                      borderSide: BorderSide.none,
                    )
                  : null,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20.w, color: colorScheme.primary)
                  : prefixText != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 14.h,
                      ),
                      child: Text(
                        prefixText!,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon,
              filled: true,
              isDense: true,
            ),
            onTapOutside: (event) => FocusScope.of(context).unfocus(),
          ),
        ),
      ],
    );
  }
}