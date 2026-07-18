import 'dart:math' as math;
import 'dart:typed_data';

/// Tamamen özgün, kısa ve tekrar oynatılabilir bir ambient WAV üretir.
///
/// Dışarıdan müzik veya telifli ses kaydı kullanmaz.
Uint8List buildHopeLofiWav() {
  const sampleRate = 22050;
  const durationSeconds = 16;
  const channels = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample ~/ 8;
  const sampleCount = sampleRate * durationSeconds;

  const chords = <List<double>>[
    <double>[261.63, 329.63, 392.00, 493.88],
    <double>[220.00, 261.63, 329.63, 392.00],
    <double>[174.61, 220.00, 261.63, 329.63],
    <double>[196.00, 246.94, 293.66, 329.63],
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
