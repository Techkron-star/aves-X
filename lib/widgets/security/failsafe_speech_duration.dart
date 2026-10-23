/// UI-only estimate of Fail-Safe's synthesized voice length, used to stop the character
/// animation around the time its audio ends. Keep these timings aligned with FailsafeVoice:
/// consonants 50 ms, vowels 75 ms, spaces 45 ms, punctuation 120 ms, maximum 60 letters.
/// This helper never starts, stops, or changes audio playback.
Duration estimateFailsafeSpeechMotionDuration(String text) {
  const maxLetters = 60;
  const vowels = 'aeiouáéíóúü';
  final letterPattern = RegExp(r'[a-záéíóúüñ]');
  var letters = 0;
  var milliseconds = 0;

  for (final rune in text.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    if (ch == ' ') {
      milliseconds += 45;
      continue;
    }
    if (!letterPattern.hasMatch(ch)) {
      milliseconds += 120;
      continue;
    }
    if (++letters > maxLetters) break;
    milliseconds += vowels.contains(ch) ? 75 : 50;
  }
  return Duration(milliseconds: milliseconds);
}
