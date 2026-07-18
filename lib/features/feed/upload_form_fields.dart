import 'package:flutter/material.dart';

import '../../core/theme/hexa_theme.dart';

class UploadFormFields extends StatefulWidget {
  const UploadFormFields({
    required this.captionController,
    required this.onSubmit,
    required this.isSubmitEnabled,
    this.isSubmitting = false,
    super.key,
  });

  static const int maxCaptionLength = 300;

  final TextEditingController captionController;
  final VoidCallback onSubmit;
  final bool isSubmitEnabled;
  final bool isSubmitting;

  @override
  State<UploadFormFields> createState() {
    return _UploadFormFieldsState();
  }
}

class _UploadFormFieldsState extends State<UploadFormFields> {
  late final FocusNode _focusNode;

  bool _focused = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }

    setState(() {
      _focused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : HexaMotion.slow,
      curve: HexaMotion.listEnter,
      builder: (context, value, child) {
        final visible = value.clamp(0, 1).toDouble();

        return Opacity(
          opacity: visible,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - visible)),
            child: child,
          ),
        );
      },
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.captionController,
        builder: (context, textValue, child) {
          final characterCount = textValue.text.length;

          return AnimatedContainer(
            duration: reduceMotion ? Duration.zero : HexaMotion.normal,
            curve: HexaMotion.emphasized,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(220),
              borderRadius: HexaRadius.borderLg,
              border: Border.all(
                color: _focused
                    ? theme.colorScheme.primary.withAlpha(145)
                    : theme.colorScheme.outlineVariant,
                width: _focused ? 1.4 : 1,
              ),
              boxShadow: _focused ? HexaShadows.signal : HexaShadows.none,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                HexaSpacing.md,
                HexaSpacing.sm,
                HexaSpacing.sm,
                HexaSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: widget.captionController,
                    focusNode: _focusNode,
                    enabled: !widget.isSubmitting,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: UploadFormFields.maxCaptionLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onTapOutside: (_) {
                      _focusNode.unfocus();
                    },
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          required maxLength,
                        }) {
                          return null;
                        },
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Bir düşünce bırak…',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(
                          150,
                        ),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: HexaSpacing.sm),
                  Row(
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : HexaMotion.fast,
                        child: Text(
                          characterCount == 0
                              ? 'Açıklama isteğe bağlı'
                              : '$characterCount/'
                                    '${UploadFormFields.maxCaptionLength}',
                          key: ValueKey<int>(
                            characterCount == 0 ? -1 : characterCount,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _PublishControl(
                        enabled: widget.isSubmitEnabled && !widget.isSubmitting,
                        loading: widget.isSubmitting,
                        onTap: widget.onSubmit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PublishControl extends StatefulWidget {
  const _PublishControl({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_PublishControl> createState() {
    return _PublishControlState();
  }
}

class _PublishControlState extends State<_PublishControl> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final foreground = widget.enabled
        ? HexaColors.white
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Videoyu yayınla',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) {
                setState(() => _pressed = true);
              }
            : null,
        onTapCancel: widget.enabled
            ? () {
                setState(() => _pressed = false);
              }
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? HexaMotion.pressScale : 1,
          duration: reduceMotion ? Duration.zero : HexaMotion.fast,
          curve: HexaMotion.elastic,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : HexaMotion.normal,
            curve: HexaMotion.emphasized,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: HexaSpacing.md),
            decoration: BoxDecoration(
              gradient: widget.enabled ? HexaGradients.signal : null,
              color: widget.enabled
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: HexaRadius.borderPill,
              boxShadow: widget.enabled ? HexaShadows.signal : HexaShadows.none,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : HexaMotion.fast,
                  child: widget.loading
                      ? SizedBox.square(
                          key: const ValueKey<String>('loading'),
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          key: const ValueKey<String>('publish'),
                          size: 18,
                          color: foreground,
                        ),
                ),
                const SizedBox(width: HexaSpacing.xs),
                Text(
                  'Yayınla',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
