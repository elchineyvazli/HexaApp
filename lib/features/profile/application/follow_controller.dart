import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/features/auth/application/auth_service.dart';

import '../data/follow_repository.dart';

final followStatusProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  targetUserId,
) {
  ref.watch(authStateProvider);

  return ref.watch(followRepositoryProvider).watchIsFollowing(targetUserId);
});

final followControllerProvider = StateNotifierProvider.autoDispose
    .family<FollowController, AsyncValue<void>, String>((ref, targetUserId) {
      return FollowController(
        repository: ref.watch(followRepositoryProvider),
        targetUserId: targetUserId,
      );
    });

class FollowController extends StateNotifier<AsyncValue<void>> {
  FollowController({
    required FollowRepository repository,
    required String targetUserId,
  }) : _repository = repository,
       _targetUserId = targetUserId,
       super(const AsyncData<void>(null));

  final FollowRepository _repository;
  final String _targetUserId;

  Future<void> toggle({required bool isFollowing}) async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading<void>();

    try {
      if (isFollowing) {
        await _repository.unfollow(_targetUserId);
      } else {
        await _repository.follow(_targetUserId);
      }

      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

String followErrorMessage(Object error) {
  if (error is FollowException) {
    return error.message;
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Takip işlemi güvenlik kuralları tarafından reddedildi.';
      case 'unavailable':
        return 'Bağlantı kurulamadı. İnternetini kontrol et.';
      case 'aborted':
        return 'İşlem çakıştı. Bir kez daha dene.';
      case 'not-found':
        return 'Kullanıcı bulunamadı.';
    }
  }

  return 'Takip işlemi tamamlanamadı. Bir kez daha dene.';
}
