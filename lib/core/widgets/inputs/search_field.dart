import 'package:flutter/material.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class SearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextAlign textAlign;
  final bool enabled;
  final double? height, width;

  const SearchTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.height,
    this.width,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width ?? double.infinity,
      child: TextFormField(
        controller: _controller,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        textAlign: widget.textAlign,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search...',
          alignLabelWithHint: true,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.colorScheme.primary,
            size: 20.sp,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20.sp,
                  ),
                  onPressed: _handleClear,
                )
              : null,
          border: InputBorder.none,
          // contentPadding: EdgeInsets.symmetric(
          //   horizontal: 16.w,
          //   vertical: 12.h,
          // ),
        ),
        onTapOutside: (event) {
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
