import 'package:aves/model/security/failsafe_config.dart';
import 'dart:async';
import 'dart:convert';

import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// "System Failsafe": the local, always-on equivalent of a crash reporter.
// Nothing is ever sent anywhere. It records what happened, looks for the likely cause,
// and after an unclean exit the app starts in safe mode: security cannot be lowered,
// vaults cannot be opened or deleted and nothing can be deleted until a clean launch.
final Failsafe failsafe = Failsafe._();

class Failsafe with WidgetsBindingObserver {
  Failsafe._();

  static const _stateKey = 'failsafe_state';
  static const _crashesKey = 'failsafe_crashes';
  static const _logKey = 'failsafe_log';
  static const _errorsKey = 'failsafe_errors';
  static const _uncleanKey = 'failsafe_unclean';
  static const _maxLines = 60;
  static const _maxLogChars = 12000;
  static const _healthyAfter = Duration(seconds: 20);
  static const _errorsBeforeSafeMode = 3;

  // always on: there is deliberately no setting to turn this off
  final ValueNotifier<bool> safeMode = ValueNotifier(false);
  final ValueNotifier<int> eventCount = ValueNotifier(0);

  // the lockdown covers the whole app until the Master Code is entered
  final ValueNotifier<bool> lockdown = ValueNotifier(false);

  final List<String> _lines = [];
  String _route = '-';
  int _sessionErrors = 0;
  int _crashes = 0;
  bool _dirty = false;
  Timer? _healthyTimer;
  Timer? _flushTimer;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final state = await securityService.readValue<String>(_stateKey);
      _crashes = int.tryParse(await securityService.readValue<String>(_crashesKey) ?? '') ?? 0;
      final previous = await securityService.readValue<String>(_logKey);
      if (previous != null && previous.isNotEmpty) _lines.addAll(const LineSplitter().convert(previous));

      final previousErrors = int.tryParse(await securityService.readValue<String>(_errorsKey) ?? '') ?? 0;
      var unclean = int.tryParse(await securityService.readValue<String>(_uncleanKey) ?? '') ?? 0;
      if (state == 'running') {
        // the previous session ended while in the foreground. It could be a crash, or simply the app being
        // force-stopped, so safe mode needs more evidence: errors in that session, or two unclean exits in a row
        unclean++;
        if (previousErrors > 0 || unclean >= 2) {
          _crashes++;
          _add('CRASH', 'Unclean exit detected (errors in previous session=$previousErrors, in a row=$unclean)');
        } else {
          _add('INFO', 'Unclean exit without errors, ignored once');
        }
      } else {
        unclean = 0;
      }
      await securityService.writeValue<String>(_uncleanKey, '$unclean');
      await securityService.writeValue<String>(_errorsKey, '0');
      safeMode.value = _crashes > 0;
      lockdown.value = await FailsafeConfig.lockdownActive;
      if (safeMode.value) _add('SAFE', 'Safe mode enabled for this session (failures=$_crashes)');
      _add('BOOT', 'Launch');
      await securityService.writeValue<String>(_crashesKey, '$_crashes');
      await securityService.writeValue<String>(_stateKey, 'running');
    } catch (e) {
      debugPrint('Failsafe init failed: $e');
    }
    WidgetsBinding.instance.addObserver(this);
    _flushTimer = Timer.periodic(const Duration(seconds: 6), (_) => _flush());
    _scheduleHealthy();
    unawaited(_flush());
  }

  void _scheduleHealthy() {
    _healthyTimer?.cancel();
    // a session that runs for a while without serious errors counts as clean:
    // the next launch will be back to normal
    _healthyTimer = Timer(_healthyAfter, () async {
      if (_sessionErrors >= _errorsBeforeSafeMode) return;
      _crashes = 0;
      _add('OK', 'Healthy session, safe mode will be off at the next launch');
      await securityService.writeValue<String>(_crashesKey, '0');
      await _flush();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .paused || state == .hidden || state == .detached) {
      unawaited(securityService.writeValue<String>(_stateKey, 'background'));
      unawaited(_flush());
    } else if (state == .resumed) {
      unawaited(securityService.writeValue<String>(_stateKey, 'running'));
    }
  }

  static const _welcomeKey = 'failsafe_welcomed';

  Future<bool> get needsWelcome async => await securityService.readValue<String>(_welcomeKey) == null;

  Future<void> markWelcomed() => securityService.writeValue<String>(_welcomeKey, '1');

  Future<void> engageLockdown() async {
    await FailsafeConfig.setLockdownActive(true);
    lockdown.value = true;
    _add('LOCK', 'Lockdown engaged after repeated failed attempts');
    await _flush();
  }

  Future<void> releaseLockdown() async {
    await FailsafeConfig.setLockdownActive(false);
    lockdown.value = false;
    _add('LOCK', 'Lockdown lifted with the Master Code');
  }

  void breadcrumb(String message) {
    _add('NAV', message);
    final match = RegExp(r'to (.+)$').firstMatch(message);
    if (match != null) _route = match.group(1)!;
  }

  // an uncaught error (Flutter framework, async zone or isolate)
  void record(Object error, StackTrace? stack, {String source = 'ERR'}) {
    _sessionErrors++;
    unawaited(securityService.writeValue<String>(_errorsKey, '$_sessionErrors'));
    final text = '$error\n${stack ?? ''}';
    _add(source, '${error.toString().split('\n').first} | likely cause: ${diagnose(text).first} | route=$_route');
    if (stack != null) _add('STACK', stack.toString().split('\n').take(4).join(' <- '));
    if (_sessionErrors >= _errorsBeforeSafeMode) {
      // too many errors in one session: next launch starts in safe mode
      _crashes = _crashes < 1 ? 1 : _crashes;
      unawaited(securityService.writeValue<String>(_crashesKey, '$_crashes'));
    }
    unawaited(_flush());
  }

  void recordFlutter(FlutterErrorDetails details) => record(details.exception, details.stack, source: 'FLUTTER');

  void _add(String tag, String message) {
    final t = DateTime.now().toIso8601String().substring(5, 19).replaceFirst('T', ' ');
    _lines.add('$t [$tag] $message');
    while (_lines.length > _maxLines) {
      _lines.removeAt(0);
    }
    _dirty = true;
    eventCount.value++;
  }

  Future<void> _flush() async {
    if (!_dirty) return;
    _dirty = false;
    var text = _lines.join('\n');
    if (text.length > _maxLogChars) text = text.substring(text.length - _maxLogChars);
    try {
      await securityService.writeValue<String>(_logKey, text);
    } catch (_) {}
  }

  static const _rules = <(String, String)>[
    (r'Vault|vault|Tink|keyset|Keystore|AVXENC', 'Vaults / Bat-Curity encryption'),
    (r'OutOfMemory|out of memory|OOM', 'Out of memory (very large media or too many thumbnails)'),
    (r'mpv|media_kit|MediaCodec|decoder|video', 'Video player / decoder'),
    (r'sqlite|SQLite|Database|database', 'Local database'),
    (r'SecurityException|Permission|permission|EACCES', 'Missing permission or storage access'),
    (r'FileSystemException|PathNotFound|ENOENT|No such file', 'A file or folder is missing or unreadable'),
    (r'Analysis|analyz|Worker', 'Background media scan'),
    (r'Nuke|nuke', 'Nuke / auto-delete'),
    (r'RenderFlex|RenderBox|overflow|layout|Layout', 'Interface layout'),
    (r'PlatformException|MissingPlugin|MethodChannel', 'Communication with the Android side'),
    (r'Bitmap|decode|codec|image', 'Image decoding'),
  ];

  List<String> diagnose(String text) {
    final causes = <String>[
      for (final (pattern, cause) in _rules)
        if (RegExp(pattern).hasMatch(text)) cause,
    ];
    if (causes.isEmpty) causes.add('Unknown (see the log below)');
    return causes;
  }

  String buildReport() {
    final all = _lines.join('\n');
    // only the error lines, without the screen names that would match unrelated rules
    final recent = _lines
        .where((l) => l.contains('[ERR]') || l.contains('[FLUTTER]') || l.contains('[ISOLATE]') || l.contains('[STACK]'))
        .map((l) => l.replaceAll(RegExp(r'route=\S+'), '').replaceAll(RegExp(r'likely cause: [^|]*\|'), ''))
        .join('\n');
    final causes = diagnose(recent);
    return [
      'Aves-X System Failsafe report',
      'Safe mode: ${safeMode.value ? 'ON' : 'off'} | failures counted: $_crashes | errors this session: $_sessionErrors',
      'Last screen: $_route',
      'Likely causes: ${causes.join('; ')}',
      '',
      all,
    ].join('\n');
  }

  // true (and tells the user) if the action must be refused
  bool blocked(BuildContext context) {
    if (!safeMode.value) return false;
    _add('SAFE', 'Blocked a restricted action');
    unawaited(
      showWarningDialog(
        context: context,
        message: context.l10n.failsafeBlocked,
      ),
    );
    return true;
  }
}
