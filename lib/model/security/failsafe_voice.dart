import 'dart:math';
import 'dart:typed_data';

import 'package:aves/l10n/l10n.dart';
import 'package:aves/model/security/failsafe_config.dart';
import 'package:aves/services/common/services.dart';

// Fail-Safe's voice: a procedural "babble" in the spirit of Animal Crossing or Celeste.
// Every letter becomes a short blip whose pitch depends on the letter, so the same text always sounds the same.
// Everything is synthesized here (no audio files, no samples, nothing to license).
class FailsafeVoice {
  // 44.1 kHz is supported by every Android device; 16 kHz made the audio track fail to initialize on some.
  static const _rate = 44100;
  static const _maxLetters = 60;

  static const statusOk = 'ok';
  static const statusOff = 'off';
  static const statusEmpty = 'empty';

  // `force`: plays even if the voice is turned off (test button).
  // Returns `ok`, `off` (the voice is turned off), `empty` (nothing to say) or the reason why the clip was not played.
  static Future<String> say(String text, {bool force = false}) async {
    if (!force && !await FailsafeConfig.voiceEnabled) return statusOff;
    final pcm = synthesize(text);
    if (pcm.isEmpty) return statusEmpty;
    return securityService.playPcm(pcm, _rate);
  }

  // whether the voice should have been heard but was not
  static bool isFailure(String status) => status != statusOk && status != statusOff && status != statusEmpty;

  // readable message for the user, shown wherever Fail-Safe speaks
  static String describe(AppLocalizations l10n, String status) {
    final reason = switch (status) {
      'muted' => l10n.failsafeVoiceMuted,
      'init' => l10n.failsafeVoiceInitFailed,
      'write' => l10n.failsafeVoiceWriteFailed,
      _ => status,
    };
    return '${l10n.failsafeVoiceError} $reason';
  }

  static Uint8List synthesize(String text) {
    final samples = <int>[];
    var letters = 0;
    for (final rune in text.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') {
        samples.addAll(List.filled((_rate * .045).round(), 0));
        continue;
      }
      if (!RegExp(r'[a-záéíóúüñ]').hasMatch(ch)) {
        // punctuation: a longer pause
        samples.addAll(List.filled((_rate * .12).round(), 0));
        continue;
      }
      if (++letters > _maxLetters) break;
      samples.addAll(_blip(rune));
    }
    final bytes = ByteData(samples.length * 2);
    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(i * 2, samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  static List<int> _blip(int rune) {
    const vowels = 'aeiouáéíóúü';
    final isVowel = vowels.contains(String.fromCharCode(rune));
    // pitch: letters spread over about one octave, vowels a bit longer and rounder
    final base = 300 + (rune * 37 % 24) * 12.0;
    final duration = isVowel ? .075 : .05;
    final n = (_rate * duration).round();
    final out = List<int>.filled(n, 0);
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / n;
      // small upward glide, like a voice inflection
      final freq = base * (1 + .12 * t);
      phase += 2 * pi * freq / _rate;
      // soft square-ish wave (triangle + a bit of the third harmonic)
      final wave = sin(phase) + .35 * sin(3 * phase) + (isVowel ? .0 : .15 * sin(5 * phase));
      // quick attack, smooth decay: no clicks
      final env = min(1.0, t * 14) * pow(1 - t, 1.6);
      out[i] = (wave * env * 14000).round().clamp(-32768, 32767);
    }
    return out;
  }
}
