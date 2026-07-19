import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/hexa_theme.dart';
import 'comment_list_view.dart';

class HexaCommentSheet extends StatefulWidget {
  const HexaCommentSheet({
    required this.videoId,
    this.onOpenArtifacts,
    super.key,
  });

  final String videoId;

  /// Gerçek Coin ve Artefakt altyapısı bağlandığında gösterilir.
  final VoidCallback? onOpenArtifacts;

  @override
  State<HexaCommentSheet> createState() {
    return _HexaCommentSheetState();
  }
}

class _HexaCommentSheetState extends State<HexaCommentSheet> {
  static const Color _panelBackground = Color(0xF7111116);
  static const Color _accentPurple = Color(0xFF8B5CF6);

  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;

  bool _isPosting = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _commentController = TextEditingController();

    _commentFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }

    final nextFocused = _commentFocusNode.hasFocus;

    if (_isFocused == nextFocused) {
      return;
    }

    setState(() {
      _isFocused = nextFocused;
    });
  }

  @override
  void dispose() {
    _commentFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();

    _commentController.dispose();

    super.dispose();
  }

  Future<void> _postComment() async {
    if (_isPosting) {
      return;
    }

    final text = _cleanComment(_commentController.text);

    if (text.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Yorum yapmak için giriş yapmalısın.');
      return;
    }

    final videoId = widget.videoId.trim();

    if (videoId.isEmpty) {
      _showMessage('Video bilgisi bulunamadı.');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final videoReference = firestore.collection('videos').doc(videoId);

      final commentReference = videoReference.collection('comments').doc();

      final batch = firestore.batch();
      final serverTime = FieldValue.serverTimestamp();

      final displayName = user.displayName?.trim() ?? '';

      final emailName = user.email?.split('@').first.trim() ?? '';

      final username = displayName.isNotEmpty
          ? displayName
          : emailName.isNotEmpty
          ? '@$emailName'
          : '@hexa_user';

      batch.set(commentReference, <String, dynamic>{
        'schemaVersion': 2,
        'id': commentReference.id,
        'videoId': videoId,
        'userId': user.uid,
        'username': username,
        'displayName': displayName,
        'avatarUrl': user.photoURL?.trim() ?? '',
        'text': text,
        'sticker': '',
        'status': 'visible',
        'createdAt': serverTime,
        'updatedAt': serverTime,
      });

      batch.update(videoReference, <String, dynamic>{
        'commentsCount': FieldValue.increment(1),
        'updatedAt': serverTime,
      });

      await batch.commit();

      _commentController.clear();

      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    } on FirebaseException catch (error) {
      _showMessage(_firebaseMessage(error));
    } catch (_) {
      _showMessage('Yorum gönderilemedi.');
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  String _cleanComment(String value) {
    final clean = value
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '')
        .trim();

    if (clean.length <= 500) {
      return clean;
    }

    return clean.substring(0, 500);
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return 'Yorum göndermeye izin verilmedi.';

      case 'unavailable':
      case 'network-request-failed':
        return 'Bağlantını kontrol edip tekrar dene.';

      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Yorum gönderilemedi.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xF216161B),
          elevation: 0,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      );
  }

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    final panelHeight = (screenHeight * 0.74)
        .clamp(420.0, screenHeight - 18)
        .toDouble();

    return AnimatedPadding(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: panelHeight,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _panelBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 42,
                      offset: Offset(0, -12),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: <Widget>[
                      _CommentSheetHeader(onClose: _closeSheet),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                      Expanded(child: CommentListView(videoId: widget.videoId)),
                      _CommentComposer(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        isFocused: _isFocused,
                        isPosting: _isPosting,
                        onSubmit: _postComment,
                        onOpenArtifacts: widget.onOpenArtifacts,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentSheetHeader extends StatelessWidget {
  const _CommentSheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 9,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(
            left: 56,
            right: 56,
            bottom: 16,
            child: Text(
              'Yorumlar',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.30,
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 8,
            child: Semantics(
              button: true,
              label: 'Yorumları kapat',
              child: IconButton(
                tooltip: 'Kapat',
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  foregroundColor: Colors.white.withValues(alpha: 0.72),
                  minimumSize: const Size(40, 40),
                  maximumSize: const Size(40, 40),
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isPosting,
    required this.onSubmit,
    required this.onOpenArtifacts,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final bool isFocused;
  final bool isPosting;

  final VoidCallback onSubmit;
  final VoidCallback? onOpenArtifacts;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final canSend = value.text.trim().isNotEmpty && !isPosting;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xF20D0D11),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: EdgeInsets.only(
                    left: onOpenArtifacts == null ? 14 : 4,
                    right: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isFocused ? 0.08 : 0.055,
                    ),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0x998B5CF6)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (onOpenArtifacts != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: IconButton(
                            tooltip: 'İçerik ekle',
                            onPressed: isPosting ? null : onOpenArtifacts,
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.58,
                              ),
                              minimumSize: const Size(38, 38),
                              maximumSize: const Size(38, 38),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 22),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: !isPosting,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          cursorColor: const Color(0xFF8B5CF6),
                          cursorWidth: 1.6,
                          style: const TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.12,
                          ),
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
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            hintText: 'Yorum ekle...',
                            hintStyle: TextStyle(
                              color: Color(0x73FFFFFF),
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              AnimatedOpacity(
                opacity: canSend ? 1 : 0.42,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                child: IconButton(
                  tooltip: 'Yorumu gönder',
                  onPressed: canSend ? onSubmit : null,
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.08),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.44,
                    ),
                    minimumSize: const Size(46, 46),
                    maximumSize: const Size(46, 46),
                    shape: const CircleBorder(),
                  ),
                  icon: isPosting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
