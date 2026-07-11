// lib/features/feed/video_action_buttons.dart

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';

import 'feed_models.dart';
import 'hexa_comment_sheet.dart';

class VideoActionButtons extends StatefulWidget {
  const VideoActionButtons({
    super.key,
    required this.video,
    this.qualifiedWatchMsProvider,
  });

  final VideoModel video;
  final int Function()? qualifiedWatchMsProvider;

  @override
  State<VideoActionButtons> createState() => _VideoActionButtonsState();
}

class _VideoActionButtonsState extends State<VideoActionButtons> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _sessionId;
  bool _isSignalBusy = false;
  bool _isSaveBusy = false;
  bool _legacyLiked = false;
  SignalReason? _legacyReason;

  @override
  void initState() {
    super.initState();
    _sessionId = _newSessionId();
    _loadLegacyLike();
  }

  @override
  void didUpdateWidget(covariant VideoActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _sessionId = _newSessionId();
      _legacyLiked = false;
      _legacyReason = null;
      _loadLegacyLike();
    }
  }

  String _newSessionId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${widget.video.id}';
  }

  Future<void> _loadLegacyLike() async {
    final user = FirebaseAuth.instance.currentUser;
    final videoId = widget.video.id;
    if (user == null || videoId.trim().isEmpty) {
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('likes')
          .doc(user.uid)
          .get();

      if (!mounted || widget.video.id != videoId) {
        return;
      }

      final data = snapshot.data();
      setState(() {
        _legacyLiked = snapshot.exists;
        _legacyReason = snapshot.exists
            ? SignalReason.fromValue(data?['reason']) ?? SignalReason.other
            : null;
      });
    } on FirebaseException {
      // Yeni güvenlik modelinde eski likes koleksiyonu yalnızca geçiş içindir.
      // Okunamaması ana Signal deneyimini durdurmaz.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final videoRef = _firestore.collection('videos').doc(widget.video.id);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: videoRef.snapshots(),
      builder: (context, videoSnapshot) {
        final videoData = videoSnapshot.data?.data();
        final signalCount = _readCount(
          videoData?['signalCount'] ?? videoData?['likesCount'],
          widget.video.signalCount,
        );
        final commentsCount = _readCount(
          videoData?['commentsCount'],
          widget.video.commentsCount,
        );

        if (user == null) {
          return _buildRail(
            context: context,
            signalCount: signalCount,
            commentsCount: commentsCount,
            isSignaled: false,
            signalReason: null,
            isSaved: false,
          );
        }

        final signalRef = videoRef.collection('signals').doc(user.uid);
        final savedRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('savedVideos')
            .doc(widget.video.id);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: signalRef.snapshots(),
          builder: (context, signalSnapshot) {
            final signalData = signalSnapshot.data?.data();
            final hasModernSignal = signalSnapshot.data?.exists == true;
            final signalReason = hasModernSignal
                ? SignalReason.fromValue(signalData?['reason']) ??
                    SignalReason.other
                : _legacyReason;
            final isSignaled = hasModernSignal || _legacyLiked;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: savedRef.snapshots(),
              builder: (context, savedSnapshot) {
                final isSaved = savedSnapshot.data?.exists == true;

                return _buildRail(
                  context: context,
                  signalCount:
                      isSignaled ? math.max(1, signalCount) : signalCount,
                  commentsCount: commentsCount,
                  isSignaled: isSignaled,
                  signalReason: signalReason,
                  isSaved: isSaved,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRail({
    required BuildContext context,
    required int signalCount,
    required int commentsCount,
    required bool isSignaled,
    required SignalReason? signalReason,
    required bool isSaved,
  }) {
    return Positioned(
      right: 10,
      bottom: 62,
      child: SafeArea(
        top: false,
        left: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileAvatarButton(
              imageUrl: widget.video.uploaderAvatarUrl,
              enabled: widget.video.hasUploaderProfile,
              onPressed: _openProfile,
            ),
            const SizedBox(height: 14),
            _ActionButton(
              tooltip: isSignaled
                  ? 'Signal’i kaldır. Nedenini değiştirmek için basılı tut.'
                  : 'Signal gönder. Neden seçmek için basılı tut.',
              icon: isSignaled
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: isSignaled ? HexaColors.signal : Colors.white,
              label: _compactNumber(signalCount),
              isActive: isSignaled,
              isBusy: _isSignalBusy,
              onPressed: () {
                _toggleSignal(
                  isActive: isSignaled,
                  currentReason: signalReason,
                );
              },
              onLongPress: () {
                _chooseSignalReason(currentReason: signalReason);
              },
            ),
            const SizedBox(height: 13),
            _ActionButton(
              tooltip: 'Yorumları aç',
              icon: Icons.mode_comment_outlined,
              iconColor: Colors.white,
              label: _compactNumber(commentsCount),
              onPressed: _openComments,
            ),
            const SizedBox(height: 13),
            _ActionButton(
              tooltip: isSaved ? 'Kaydedilenlerden çıkar' : 'Videoyu kaydet',
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              iconColor: isSaved ? HexaColors.mint : Colors.white,
              label: isSaved ? 'Kayıtlı' : 'Kaydet',
              isActive: isSaved,
              isBusy: _isSaveBusy,
              onPressed: () => _toggleSaved(isSaved),
            ),
            const SizedBox(height: 13),
            _ActionButton(
              tooltip: 'Video bağlantısını kopyala',
              icon: Icons.ios_share_rounded,
              iconColor: Colors.white,
              label: 'Paylaş',
              onPressed: _copyVideoLink,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSignal({
    required bool isActive,
    required SignalReason? currentReason,
  }) async {
    if (_isSignalBusy) {
      return;
    }

    HapticFeedback.mediumImpact();
    await _runSignalMutation(
      remove: isActive,
      selectedReason: isActive
          ? currentReason
          : currentReason ?? SignalReason.helpful,
    );
  }

  Future<void> _chooseSignalReason({
    required SignalReason? currentReason,
  }) async {
    if (_isSignalBusy) {
      return;
    }

    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<SignalReason>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x990B141B),
      builder: (sheetContext) {
        return _SignalReasonSheet(currentReason: currentReason);
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    await _runSignalMutation(
      remove: false,
      selectedReason: selected,
    );
  }

  Future<void> _runSignalMutation({
    required bool remove,
    required SignalReason? selectedReason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Signal göndermek için giriş yapmalısın.');
      return;
    }

    setState(() => _isSignalBusy = true);

    try {
      try {
        await _writeModernSignal(
          user: user,
          remove: remove,
          selectedReason: selectedReason ?? SignalReason.helpful,
        );
        if (mounted) {
          setState(() {
            _legacyLiked = false;
            _legacyReason = null;
          });
        }
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }

        // Geçiş desteği: Firebase Console'daki yeni kurallar yayımlanana kadar
        // mevcut likes koleksiyonuyla çalışır. Yeni rules sonrasında bu yol
        // otomatik olarak kullanılmaz.
        await _writeLegacySignal(
          user: user,
          remove: remove,
          selectedReason: selectedReason ?? SignalReason.helpful,
        );
      }
    } on FirebaseException catch (error) {
      _showMessage(_friendlyFirebaseMessage(error));
    } catch (_) {
      _showMessage('Signal işlemi tamamlanamadı. Bir kez daha dene.');
    } finally {
      if (mounted) {
        setState(() => _isSignalBusy = false);
      }
    }
  }

  Future<void> _writeModernSignal({
    required User user,
    required bool remove,
    required SignalReason selectedReason,
  }) async {
    final videoRef = _firestore.collection('videos').doc(widget.video.id);
    final signalRef = videoRef.collection('signals').doc(user.uid);
    final legacyLikeRef = videoRef.collection('likes').doc(user.uid);

    final ownerId = widget.video.uploaderId.trim();
    final canNotify = ownerId.isNotEmpty &&
        ownerId != 'unknown_user' &&
        ownerId != 'system_admin' &&
        ownerId != user.uid;
    final notificationRef = canNotify
        ? _firestore
            .collection('users')
            .doc(ownerId)
            .collection('notifications')
            .doc('signal_${user.uid}_${widget.video.id}')
        : null;

    await _firestore.runTransaction((transaction) async {
      final videoSnapshot = await transaction.get(videoRef);
      final signalSnapshot = await transaction.get(signalRef);
      final legacySnapshot = await transaction.get(legacyLikeRef);

      if (!videoSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Video bulunamadı.',
        );
      }

      final videoData = videoSnapshot.data() ?? const <String, dynamic>{};
      final signalData = signalSnapshot.data();
      final hasSignal = signalSnapshot.exists;
      final hasLegacyLike = legacySnapshot.exists;
      final currentReason = hasSignal
          ? SignalReason.fromValue(signalData?['reason']) ?? SignalReason.other
          : SignalReason.fromValue(legacySnapshot.data()?['reason']) ??
              SignalReason.other;
      final beforeCount = _readCount(
        videoData['signalCount'] ?? videoData['likesCount'],
        widget.video.signalCount,
      );
      final distribution = _readDistribution(
        videoData['signalDistribution'],
      );
      final serverTime = FieldValue.serverTimestamp();
      final qualifiedWatchMs = math.max(
        0,
        widget.qualifiedWatchMsProvider?.call() ?? 0,
      );

      if (remove) {
        if (!hasSignal && !hasLegacyLike) {
          return;
        }

        if (hasSignal) {
          transaction.delete(signalRef);
        }
        if (hasLegacyLike) {
          transaction.delete(legacyLikeRef);
        }

        _decrementReason(distribution, currentReason);
        final nextCount = math.max(0, beforeCount - 1);
        transaction.update(videoRef, <String, dynamic>{
          'signalCount': nextCount,
          'likesCount': nextCount,
          'uniqueSignalersCount': nextCount,
          'signalDistribution': distribution,
          'updatedAt': serverTime,
        });

        return;
      }

      if (hasSignal) {
        transaction.update(signalRef, <String, dynamic>{
          'reason': selectedReason.value,
          'qualifiedWatchMs': qualifiedWatchMs,
          'sessionId': _sessionId,
          'updatedAt': serverTime,
        });

        if (currentReason != selectedReason) {
          _decrementReason(distribution, currentReason);
          _incrementReason(distribution, selectedReason);
          transaction.update(videoRef, <String, dynamic>{
            'signalCount': beforeCount,
            'likesCount': beforeCount,
            'uniqueSignalersCount': beforeCount,
            'signalDistribution': distribution,
            'updatedAt': serverTime,
          });
        }
      } else {
        if (hasLegacyLike) {
          transaction.delete(legacyLikeRef);
          _decrementReason(distribution, currentReason);
        }

        transaction.set(signalRef, <String, dynamic>{
          'videoId': widget.video.id,
          'userId': user.uid,
          'reason': selectedReason.value,
          'qualifiedWatchMs': qualifiedWatchMs,
          'sessionId': _sessionId,
          'createdAt': serverTime,
          'updatedAt': serverTime,
        });

        _incrementReason(distribution, selectedReason);
        final nextCount = hasLegacyLike
            ? math.max(1, beforeCount)
            : beforeCount + 1;
        transaction.update(videoRef, <String, dynamic>{
          'signalCount': nextCount,
          'likesCount': nextCount,
          'uniqueSignalersCount': nextCount,
          'signalDistribution': distribution,
          'updatedAt': serverTime,
        });
      }

      if (notificationRef != null) {
        transaction.set(notificationRef, <String, dynamic>{
          'type': 'signal',
          'senderId': user.uid,
          'senderName': _trimTo(
            user.displayName ??
                user.email?.split('@').first ??
                widget.video.username,
            80,
          ),
          'senderAvatar': _trimTo(user.photoURL ?? '', 2048),
          'message': '${selectedReason.label} Signali gönderdi.',
          'targetId': widget.video.id,
          'createdAt': serverTime,
          'isRead': false,
        });
      }
    });

    if (remove && notificationRef != null) {
      try {
        await notificationRef.delete();
      } on FirebaseException {
        // Signal kaldırıldı; eski bildirimin silinememesi işlemi geri almaz.
      }
    }
  }

  Future<void> _writeLegacySignal({
    required User user,
    required bool remove,
    required SignalReason selectedReason,
  }) async {
    final videoRef = _firestore.collection('videos').doc(widget.video.id);
    final likeRef = videoRef.collection('likes').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final videoSnapshot = await transaction.get(videoRef);
      final likeSnapshot = await transaction.get(likeRef);
      if (!videoSnapshot.exists) {
        return;
      }

      final data = videoSnapshot.data() ?? const <String, dynamic>{};
      final currentCount = _readCount(
        data['likesCount'] ?? data['signalCount'],
        widget.video.signalCount,
      );

      if (remove) {
        if (!likeSnapshot.exists) {
          return;
        }
        transaction.delete(likeRef);
        transaction.update(videoRef, <String, dynamic>{
          'likesCount': math.max(0, currentCount - 1),
        });
        return;
      }

      if (likeSnapshot.exists) {
        transaction.set(
          likeRef,
          <String, dynamic>{
            'reason': selectedReason.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }

      transaction.set(likeRef, <String, dynamic>{
        'userId': user.uid,
        'reason': selectedReason.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(videoRef, <String, dynamic>{
        'likesCount': currentCount + 1,
      });
    });

    if (mounted) {
      setState(() {
        _legacyLiked = !remove;
        _legacyReason = remove ? null : selectedReason;
      });
    }
  }

  Future<void> _toggleSaved(bool isSaved) async {
    if (_isSaveBusy) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Video kaydetmek için giriş yapmalısın.');
      return;
    }

    setState(() => _isSaveBusy = true);
    HapticFeedback.selectionClick();

    final reference = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedVideos')
        .doc(widget.video.id);

    try {
      if (isSaved) {
        await reference.delete();
      } else {
        await reference.set(<String, dynamic>{
          'videoId': widget.video.id,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (error) {
      _showMessage(_friendlyFirebaseMessage(error));
    } catch (_) {
      _showMessage('Video kaydedilemedi. Bir kez daha dene.');
    } finally {
      if (mounted) {
        setState(() => _isSaveBusy = false);
      }
    }
  }

  void _openProfile() {
    if (!widget.video.hasUploaderProfile) {
      _showMessage('Bu eski videonun üretici bilgisi eksik.');
      return;
    }

    HapticFeedback.selectionClick();
    context.push('/profile/${widget.video.uploaderId}');
  }

  void _openComments() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x990B141B),
      builder: (context) {
        return HexaCommentSheet(videoId: widget.video.id);
      },
    );
  }

  Future<void> _copyVideoLink() async {
    final source = widget.video.playbackUrl.trim();
    if (source.isEmpty) {
      _showMessage('Paylaşılabilir video bağlantısı bulunamadı.');
      return;
    }

    final caption = widget.video.caption.trim();
    final shareText = caption.isEmpty ? source : '$caption\n$source';
    await Clipboard.setData(ClipboardData(text: shareText));
    HapticFeedback.lightImpact();
    _showMessage('Video bağlantısı panoya kopyalandı.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyFirebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firebase güvenlik kuralları bu işleme henüz izin vermiyor.';
      case 'unavailable':
        return 'Bağlantı kurulamadı. İnternetini kontrol et.';
      case 'not-found':
        return 'Bu video artık mevcut değil.';
      case 'aborted':
        return 'İşlem çakıştı. Lütfen yeniden dene.';
      default:
        return 'İşlem tamamlanamadı. Bir kez daha dene.';
    }
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.imageUrl,
    required this.enabled,
    required this.onPressed,
  });

  final String imageUrl;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Üretici profilini aç',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? HexaColors.signal : Colors.white38,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF273238),
              backgroundImage:
                  imageUrl.trim().isEmpty ? null : NetworkImage(imageUrl),
              onBackgroundImageError: imageUrl.trim().isEmpty
                  ? null
                  : (error, stackTrace) {},
              child: imageUrl.trim().isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 23,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onPressed,
    this.onLongPress,
    this.isActive = false,
    this.isBusy = false,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final bool isActive;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.06 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Material(
              color: isActive
                  ? const Color(0xE6FFFFFF)
                  : const Color(0x99141C21),
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: isBusy ? null : onPressed,
                onLongPress: isBusy ? null : onLongPress,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: isBusy
                        ? SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: isActive
                                  ? HexaColors.signal
                                  : Colors.white,
                            ),
                          )
                        : Icon(icon, color: iconColor, size: 27),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 62),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(color: Color(0xCC000000), blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalReasonSheet extends StatelessWidget {
  const _SignalReasonSheet({required this.currentReason});

  final SignalReason? currentReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HexaColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HexaRadius.lg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HexaColors.borderStrong,
                    borderRadius: BorderRadius.circular(HexaRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: HexaColors.signalSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: HexaColors.signal,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu video sana nasıl değer kattı?',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Seçimin videonun doğru insanlara ulaşmasına yardım eder.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: HexaColors.inkMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...SignalReason.primaryReasons.map((reason) {
                final selected = currentReason == reason;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    color: selected
                        ? HexaColors.signalSoft
                        : HexaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(HexaRadius.md),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(reason),
                      borderRadius: BorderRadius.circular(HexaRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: HexaColors.surface,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: HexaColors.border),
                              ),
                              child: Text(
                                reason.emoji,
                                style: const TextStyle(fontSize: 21),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason.label,
                                    style: const TextStyle(
                                      color: HexaColors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reason.description,
                                    style: const TextStyle(
                                      color: HexaColors.inkMuted,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: selected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      key: ValueKey<String>('selected'),
                                      color: HexaColors.signal,
                                    )
                                  : const Icon(
                                      Icons.chevron_right_rounded,
                                      key: ValueKey<String>('unselected'),
                                      color: HexaColors.inkSoft,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (currentReason != null) ...[
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Signal’i kaldırmak için kalbe bir kez dokun.',
                    style: TextStyle(
                      color: HexaColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int _readCount(Object? value, int fallback) {
  if (value is int) {
    return math.max(0, value);
  }
  if (value is num) {
    return math.max(0, value.toInt());
  }
  final parsed = int.tryParse(value?.toString() ?? '');
  return math.max(0, parsed ?? fallback);
}

Map<String, int> _readDistribution(Object? value) {
  if (value is! Map) {
    return <String, int>{};
  }

  final result = <String, int>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    if (key.isEmpty) {
      continue;
    }
    result[key] = _readCount(entry.value, 0);
  }
  return result;
}

void _incrementReason(
  Map<String, int> distribution,
  SignalReason reason,
) {
  distribution[reason.value] = (distribution[reason.value] ?? 0) + 1;
}

void _decrementReason(
  Map<String, int> distribution,
  SignalReason reason,
) {
  final current = distribution[reason.value] ?? 0;
  if (current <= 1) {
    distribution.remove(reason.value);
  } else {
    distribution[reason.value] = current - 1;
  }
}

String _compactNumber(int value) {
  final safeValue = math.max(0, value);
  if (safeValue < 1000) {
    return '$safeValue';
  }
  if (safeValue < 1000000) {
    return '${_oneDecimal(safeValue / 1000)} B';
  }
  return '${_oneDecimal(safeValue / 1000000)} Mn';
}

String _oneDecimal(double value) {
  final text = value.toStringAsFixed(value >= 100 ? 0 : 1);
  return text.replaceFirst('.0', '').replaceFirst('.', ',');
}

String _trimTo(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  return trimmed.substring(0, maxLength);
}
