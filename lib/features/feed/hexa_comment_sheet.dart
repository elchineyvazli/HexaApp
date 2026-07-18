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

    setState(() {
      _isFocused = _commentFocusNode.hasFocus;
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final screenHeight = MediaQuery.sizeOf(context).height;

    final panelHeight = screenHeight * 0.72;

    return AnimatedPadding(
      duration: HexaMotion.normal,
      curve: HexaMotion.emphasized,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: panelHeight,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(HexaRadius.lg),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: HexaColors.earth.withAlpha(222),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(HexaRadius.lg),
                  ),
                  border: Border(
                    top: BorderSide(color: HexaColors.white.withAlpha(36)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: <Widget>[
                      const _CommentSheetHeader(),
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
  const _CommentSheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HexaSpacing.md,
        HexaSpacing.sm,
        HexaSpacing.md,
        HexaSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 38,
            height: 3,
            decoration: BoxDecoration(
              color: HexaColors.white.withAlpha(76),
              borderRadius: HexaRadius.borderPill,
            ),
          ),
          const SizedBox(height: HexaSpacing.md),
          Row(
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: HexaColors.hopePink,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: HexaColors.signalGlow, blurRadius: 11),
                  ],
                ),
              ),
              const SizedBox(width: HexaSpacing.sm),
              Text(
                'Yorumlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HexaColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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

        return AnimatedContainer(
          duration: reduceMotion ? Duration.zero : HexaMotion.normal,
          curve: HexaMotion.emphasized,
          margin: const EdgeInsets.all(HexaSpacing.sm),
          padding: const EdgeInsets.fromLTRB(
            HexaSpacing.sm,
            HexaSpacing.xs,
            HexaSpacing.xs,
            HexaSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: HexaColors.white.withAlpha(18),
            borderRadius: HexaRadius.borderLg,
            border: Border.all(
              color: isFocused
                  ? HexaColors.signal
                  : HexaColors.white.withAlpha(30),
              width: isFocused ? 1.4 : 1,
            ),
            boxShadow: isFocused ? HexaShadows.signal : HexaShadows.none,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (onOpenArtifacts != null)
                IconButton(
                  tooltip: 'Artefakt gönder',
                  onPressed: isPosting ? null : onOpenArtifacts,
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: HexaColors.hopePink,
                    size: 20,
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
                  style: const TextStyle(
                    color: HexaColors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
                    hintText: 'Bir iz bırak…',
                    hintStyle: TextStyle(color: HexaColors.inkSoftOnDark),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: HexaSpacing.xs,
                      vertical: HexaSpacing.sm,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: canSend ? 1 : 0.35,
                duration: reduceMotion ? Duration.zero : HexaMotion.fast,
                child: IconButton(
                  tooltip: 'Yorumu gönder',
                  onPressed: canSend ? onSubmit : null,
                  style: IconButton.styleFrom(
                    backgroundColor: canSend
                        ? HexaColors.signal
                        : HexaColors.white.withAlpha(18),
                    foregroundColor: HexaColors.white,
                  ),
                  icon: isPosting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HexaColors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, size: 19),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
