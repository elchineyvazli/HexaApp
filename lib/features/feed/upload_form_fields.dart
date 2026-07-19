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

    final nextFocused = _focusNode.hasFocus;

    if (_focused == nextFocused) {
      return;
    }

    setState(() {
      _focused = nextFocused;
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
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.captionController,
      builder: (context, textValue, child) {
        final characterCount = textValue.text.length;

        return AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(15, 14, 10, 10),
          decoration: BoxDecoration(
            color: _focused
                ? HexaColors.surfaceMutedDark
                : HexaColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _focused
                  ? HexaColors.purple.withOpacity(0.72)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: widget.captionController,
                focusNode: _focusNode,
                enabled: !widget.isSubmitting,
                minLines: 3,
                maxLines: 6,
                maxLength: UploadFormFields.maxCaptionLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                cursorColor: HexaColors.purple,
                cursorWidth: 1.6,
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
                decoration: const InputDecoration(
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Videon hakkında bir şeyler yaz...',
                  hintStyle: TextStyle(
                    color: Color(0x70FFFFFF),
                    fontSize: 14,
                    height: 1.42,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.12,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xF2FFFFFF),
                  fontSize: 14,
                  height: 1.42,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(
                      '$characterCount / '
                      '${UploadFormFields.maxCaptionLength}',
                      style: TextStyle(
                        color:
                            characterCount >= UploadFormFields.maxCaptionLength
                            ? HexaColors.error
                            : Colors.white.withOpacity(0.38),
                        fontSize: 11,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.04,
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
        );
      },
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

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final foregroundColor = widget.enabled
        ? Colors.white
        : Colors.white.withOpacity(0.34);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Videoyu yayınla',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled
            ? (_) {
                _setPressed(true);
              }
            : null,
        onTapCancel: widget.enabled
            ? () {
                _setPressed(false);
              }
            : null,
        onTapUp: widget.enabled
            ? (_) {
                _setPressed(false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? HexaColors.purple
                  : Colors.white.withOpacity(0.065),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.enabled
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: widget.loading
                      ? SizedBox.square(
                          key: const ValueKey<String>('upload-loading'),
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foregroundColor,
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          key: const ValueKey<String>('upload-publish'),
                          size: 18,
                          color: foregroundColor,
                        ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Yayınla',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.10,
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
