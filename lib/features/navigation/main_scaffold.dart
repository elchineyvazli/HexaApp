import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/feed/discover_screen.dart';
import 'package:hexa/features/feed/feed_screen.dart';
import 'package:hexa/features/feed/notifications_screen.dart';
import 'package:hexa/features/profile/profile_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Ayarlar ve profil ekranının daha sonra doğrudan kullanacağı ortak müzik
/// denetleyicisi. Kullanıcı tercihi cihazda saklanır.
final ambientMusicControllerProvider =
    StateNotifierProvider<AmbientMusicController, AmbientMusicState>((ref) {
      return AmbientMusicController();
    });

@immutable
class AmbientMusicState {
  const AmbientMusicState({
    this.enabled = true,
    this.isReady = false,
    this.isPlaying = false,
    this.isSuppressed = true,
    this.hasError = false,
  });

  final bool enabled;
  final bool isReady;
  final bool isPlaying;

  /// Video veya başka sesli medya açıkken ambient müzik bastırılır.
  final bool isSuppressed;
  final bool hasError;

  AmbientMusicState copyWith({
    bool? enabled,
    bool? isReady,
    bool? isPlaying,
    bool? isSuppressed,
    bool? hasError,
  }) {
    return AmbientMusicState(
      enabled: enabled ?? this.enabled,
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isSuppressed: isSuppressed ?? this.isSuppressed,
      hasError: hasError ?? this.hasError,
    );
  }
}

class AmbientMusicController extends StateNotifier<AmbientMusicState> {
  AmbientMusicController() : super(const AmbientMusicState()) {
    unawaited(_initialize());
  }

  static const String preferenceKey = 'hexa_ambient_music_enabled';
  static const double _targetVolume = 0.16;

  final AudioPlayer _player = AudioPlayer();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  bool _isApplicationActive = true;
  bool _hasActiveMediaSound = true;
  int _fadeGeneration = 0;
  bool _isDisposed = false;

  Future<void> _initialize() async {
    try {
      final enabled =
          await _preferences.getBool(preferenceKey) ?? state.enabled;
      if (_isDisposed) return;

      state = state.copyWith(enabled: enabled, hasError: false);

      final wavBytes = await Isolate.run<Uint8List>(_buildHopeLofiWav);
      if (_isDisposed) return;

      final file = File(
        '${Directory.systemTemp.path}/hexa_hope_ambient_v1.wav',
      );
      await file.writeAsBytes(wavBytes, flush: true);
      if (_isDisposed) return;

      await _player.setFilePath(file.path);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0);
      if (_isDisposed) return;

      state = state.copyWith(isReady: true, hasError: false);
      await _reconcilePlayback();
    } catch (_) {
      if (_isDisposed) return;
      state = state.copyWith(isReady: false, isPlaying: false, hasError: true);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.enabled == enabled) return;

    state = state.copyWith(enabled: enabled);
    await _preferences.setBool(preferenceKey, enabled);
    await _reconcilePlayback();
  }

  Future<void> toggle() => setEnabled(!state.enabled);

  Future<void> setMediaSoundActive(bool isActive) async {
    if (_hasActiveMediaSound == isActive) return;

    _hasActiveMediaSound = isActive;
    state = state.copyWith(isSuppressed: isActive);
    await _reconcilePlayback();
  }

  Future<void> setApplicationActive(bool isActive) async {
    if (_isApplicationActive == isActive) return;

    _isApplicationActive = isActive;
    await _reconcilePlayback();
  }

  Future<void> retry() async {
    if (state.isReady || _isDisposed) return;
    state = state.copyWith(hasError: false);
    await _initialize();
  }

  bool get _shouldPlay {
    return state.enabled &&
        state.isReady &&
        _isApplicationActive &&
        !_hasActiveMediaSound;
  }

  Future<void> _reconcilePlayback() async {
    if (_isDisposed || !state.isReady) return;

    if (_shouldPlay) {
      await _fadeTo(_targetVolume, pauseAtEnd: false);
    } else {
      await _fadeTo(0, pauseAtEnd: true);
    }
  }

  Future<void> _fadeTo(double target, {required bool pauseAtEnd}) async {
    final generation = ++_fadeGeneration;
    final start = _player.volume;
    const steps = 14;
    const stepDuration = Duration(milliseconds: 28);

    if (target > 0 && !_player.playing) {
      unawaited(_player.play());
      if (!_isDisposed) {
        state = state.copyWith(isPlaying: true);
      }
    }

    for (var step = 1; step <= steps; step++) {
      if (_isDisposed || generation != _fadeGeneration) return;

      final progress = step / steps;
      final eased = Curves.easeInOutCubic.transform(progress);
      final volume = start + ((target - start) * eased);
      await _player.setVolume(volume.clamp(0, 1).toDouble());
      await Future<void>.delayed(stepDuration);
    }

    if (_isDisposed || generation != _fadeGeneration) return;

    if (pauseAtEnd && target == 0) {
      await _player.pause();
      if (!_isDisposed) {
        state = state.copyWith(isPlaying: false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fadeGeneration++;
    unawaited(_player.dispose());
    super.dispose();
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with WidgetsBindingObserver {
  static const int _uploadTabIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future<void>.microtask(() async {
      if (!mounted) return;
      final currentIndex = ref.read(currentTabIndexProvider);
      await ref
          .read(ambientMusicControllerProvider.notifier)
          .setMediaSoundActive(currentIndex == 0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActive = state == AppLifecycleState.resumed;
    unawaited(
      ref
          .read(ambientMusicControllerProvider.notifier)
          .setApplicationActive(isActive),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      unawaited(
        ref
            .read(ambientMusicControllerProvider.notifier)
            .setMediaSoundActive(next == 0),
      );
    });

    final pages = <Widget>[
      FeedScreen(isTabActive: currentIndex == 0),
      const DiscoverScreen(),
      const SizedBox.shrink(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    Future<void> selectDestination(int index) async {
      final musicController = ref.read(ambientMusicControllerProvider.notifier);

      if (index == _uploadTabIndex) {
        // Yükleme/önizleme ekranında video sesiyle çakışmayı engeller.
        await musicController.setMediaSoundActive(true);
        if (!context.mounted) return;

        await context.push('/upload');
        if (!mounted) return;

        await musicController.setMediaSoundActive(
          ref.read(currentTabIndexProvider) == 0,
        );
        return;
      }

      ref.read(currentTabIndexProvider.notifier).state = index;
    }

    return Scaffold(
      backgroundColor: HexaColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: HexaGradients.page),
        child: IndexedStack(index: currentIndex, children: pages),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCFD), Color(0xFFFFF5F9)],
          ),
          border: Border(top: BorderSide(color: HexaColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x182F1713),
              blurRadius: 28,
              spreadRadius: -8,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              unawaited(selectDestination(index));
            },
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
                tooltip: 'Ana Sayfa',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Keşfet',
                tooltip: 'Keşfet',
              ),
              NavigationDestination(
                icon: _UploadDestinationIcon(),
                selectedIcon: _UploadDestinationIcon(),
                label: 'Yükle',
                tooltip: 'Video Yükle',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Bildirimler',
                tooltip: 'Bildirimler',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
                tooltip: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadDestinationIcon extends StatefulWidget {
  const _UploadDestinationIcon();

  @override
  State<_UploadDestinationIcon> createState() => _UploadDestinationIconState();
}

class _UploadDestinationIconState extends State<_UploadDestinationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ScaleTransition(
      scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _scale,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: HexaGradients.signal,
          borderRadius: BorderRadius.circular(HexaRadius.md),
          boxShadow: HexaShadows.signal,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

/// Tamamen özgün, kısa ve loop edilebilir bir ambient/lo-fi WAV üretir.
/// Herhangi bir şarkının melodisini veya kaydını kullanmaz.
Uint8List _buildHopeLofiWav() {
  const sampleRate = 22050;
  const durationSeconds = 16;
  const channels = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample ~/ 8;
  const sampleCount = sampleRate * durationSeconds;

  const chords = <List<double>>[
    [261.63, 329.63, 392.00, 493.88], // Cmaj7
    [220.00, 261.63, 329.63, 392.00], // Am7
    [174.61, 220.00, 261.63, 329.63], // Fmaj7
    [196.00, 246.94, 293.66, 329.63], // G6
  ];
  const roots = <double>[130.81, 110.00, 87.31, 98.00];
  const melody = <double>[
    523.25,
    587.33,
    659.25,
    783.99,
    659.25,
    587.33,
    523.25,
    493.88,
  ];

  final random = math.Random(0x48455841);
  final pcm = Int16List(sampleCount);
  var filteredNoise = 0.0;

  for (var index = 0; index < sampleCount; index++) {
    final time = index / sampleRate;
    final remaining = durationSeconds - time;
    final chordIndex = (time ~/ 4) % chords.length;
    final chordTime = time % 4;

    final attack = (chordTime / 0.55).clamp(0, 1).toDouble();
    final release = ((4 - chordTime) / 0.8).clamp(0, 1).toDouble();
    final chordEnvelope = math.min(attack, release);

    var pad = 0.0;
    final chord = chords[chordIndex];
    for (var noteIndex = 0; noteIndex < chord.length; noteIndex++) {
      final frequency = chord[noteIndex];
      final drift = 0.18 * math.sin(2 * math.pi * 0.07 * time + noteIndex);
      final phase = 2 * math.pi * (frequency + drift) * time;
      pad += math.sin(phase) + (0.28 * math.sin(phase * 0.5));
    }
    pad = (pad / chord.length) * chordEnvelope * 0.23;

    final bassPhase = 2 * math.pi * roots[chordIndex] * time;
    final bass = (math.sin(bassPhase) + 0.18 * math.sin(bassPhase * 2)) * 0.10;

    final noteStep = (time / 0.5).floor();
    final noteTime = time % 0.5;
    final noteFrequency = melody[noteStep % melody.length];
    final pluckEnvelope = math.exp(-6.2 * noteTime);
    final pluck =
        (math.sin(2 * math.pi * noteFrequency * time) +
            0.24 * math.sin(4 * math.pi * noteFrequency * time)) *
        pluckEnvelope *
        0.075;

    final beatTime = time % 2;
    final kickEnvelope = math.exp(-7.5 * beatTime);
    final kickFrequency = 48 + (35 * math.exp(-11 * beatTime));
    final kick =
        math.sin(2 * math.pi * kickFrequency * time) * kickEnvelope * 0.065;

    final rawNoise = (random.nextDouble() * 2) - 1;
    filteredNoise += 0.035 * (rawNoise - filteredNoise);
    final tapeNoise = filteredNoise * 0.022;

    final slowSwell = 0.92 + (0.08 * math.sin(2 * math.pi * time / 8));
    var sample = (pad + bass + pluck + kick + tapeNoise) * slowSwell;

    final fadeIn = (time / 0.75).clamp(0, 1).toDouble();
    final fadeOut = (remaining / 0.75).clamp(0, 1).toDouble();
    sample *= math.min(fadeIn, fadeOut);

    // Yumuşak clip: yüksek pikleri distorsiyonsuz biçimde sınırlar.
    sample = sample / (1 + sample.abs());
    pcm[index] = (sample.clamp(-1, 1) * 32767).round();
  }

  final dataLength = sampleCount * channels * bytesPerSample;
  final byteData = ByteData(44 + dataLength);

  void writeAscii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      byteData.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  writeAscii(0, 'RIFF');
  byteData.setUint32(4, 36 + dataLength, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, channels, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  byteData.setUint16(32, channels * bytesPerSample, Endian.little);
  byteData.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  byteData.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < pcm.length; index++) {
    byteData.setInt16(44 + (index * bytesPerSample), pcm[index], Endian.little);
  }

  return byteData.buffer.asUint8List();
}
