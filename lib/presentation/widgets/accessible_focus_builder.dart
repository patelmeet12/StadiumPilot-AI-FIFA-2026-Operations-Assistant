import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibleFocusBuilder extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final String? semanticValue;
  final FocusNode? focusNode;

  const AccessibleFocusBuilder({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.semanticValue,
    this.focusNode,
  });

  @override
  State<AccessibleFocusBuilder> createState() => _AccessibleFocusBuilderState();
}

class _AccessibleFocusBuilderState extends State<AccessibleFocusBuilder> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    // Only dispose if we created it locally
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = theme.brightness == Brightness.dark &&
        theme.scaffoldBackgroundColor == Colors.black;

    final border = _isFocused
        ? Border.all(
            color: isHighContrast
                ? const Color(0xFFFF5F1F) // Neon Orange for High Contrast focus
                : theme.colorScheme.primary,
            width: isHighContrast ? 3.0 : 2.0,
          )
        : null;

    Widget result = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: border,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: _isFocused ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );

    if (widget.semanticLabel != null) {
      result = Semantics(
        container: true,
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        value: widget.semanticValue,
        focused: _isFocused,
        onTap: widget.onTap,
        child: result,
      );
    }

    return result;
  }
}
