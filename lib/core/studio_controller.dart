import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'models.dart';
import 'processor.dart';
import 'capacity_optimizer.dart';
import '../l10n/studio_strings.dart';
import '../l10n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class StudioController extends ChangeNotifier {
  final processor = MosaicProcessor();
  final items = <QueueItem>[];
  final results = <String, GeneratedFile>{};
  final fitted = <String, FittedOutput>{};
  int sceneLimit = 0, targetMb = 20, fps = 24;
  double clipSeconds = 2;
  bool autoClip = true, autoFps = true;
  String layoutShape = 'auto', sceneAspect = 'source';
  Future<void> _preferenceWrite = Future.value();
  Future<void> loadPreferences() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        'studio_options_v1',
      );
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      kind = data['kind'] == 'sheet'
          ? OutputKind.sheet
          : OutputKind.animatedSheet;
      sceneLimit = [0, 4, 8, 12, 24].contains(data['scenes'])
          ? data['scenes'] as int
          : 0;
      targetMb = [0, 1, 5, 10, 20, 50, 100].contains(data['mb'])
          ? data['mb'] as int
          : 20;
      fps = ((data['fps'] as num?)?.toInt() ?? 24).clamp(4, 30);
      autoFps = data['autoFps'] as bool? ?? true;
      clipSeconds = ((data['clip'] as num?)?.toDouble() ?? 2).clamp(.5, 10);
      autoClip = data['autoClip'] as bool? ?? true;
      layoutShape = ['auto', '16:9', '9:16'].contains(data['layout'])
          ? data['layout'] as String
          : 'auto';
      sceneAspect = ['source', '1:1', '16:9', '9:16'].contains(data['aspect'])
          ? data['aspect'] as String
          : 'source';
      changed();
    } catch (_) {
      /* Invalid preferences fall back to the safe defaults. */
    }
  }

  void savePreferences() {
    final encoded = jsonEncode({
      'kind': kind.name,
      'scenes': sceneLimit,
      'mb': targetMb,
      'fps': fps,
      'autoFps': autoFps,
      'clip': clipSeconds,
      'autoClip': autoClip,
      'layout': layoutShape,
      'aspect': sceneAspect,
    });
    _preferenceWrite = _preferenceWrite
        .then((_) async {
          await (await SharedPreferences.getInstance()).setString(
            'studio_options_v1',
            encoded,
          );
        })
        .catchError((Object _) {});
    changed();
  }

  void resetPreferences() {
    if (busy || importing) return;
    kind = OutputKind.animatedSheet;
    sceneLimit = 0;
    targetMb = 20;
    fps = 24;
    autoFps = true;
    clipSeconds = 2;
    autoClip = true;
    layoutShape = 'auto';
    sceneAspect = 'source';
    savePreferences();
  }

  QueueItem? selected;
  OutputKind kind = OutputKind.animatedSheet;
  bool busy = false, importing = false, closed = false;
  double progress = 0;
  static const maxFiles = 50;
  String _messageKey = '영상을 넣으면 자동으로 장면을 골라드려요.';
  List<Object?> _messageArgs = const [];
  String get message => tx(_messageKey, _messageArgs);
  set message(String value) {
    _messageKey = value;
    _messageArgs = const [];
  }

  void setMessage(String key, [List<Object?> args = const []]) {
    _messageKey = key;
    _messageArgs = args;
  }

  void changed() {
    if (!closed) notifyListeners();
  }

  Settings settings([VideoMetadata? metadata]) {
    final value = Settings()
      ..outputs = {kind}
      ..autoArrange = true
      ..gridCount = sceneLimit > 0
          ? sceneLimit
          : ((metadata?.duration ?? 10) / 6).ceil().clamp(4, 24)
      ..fps = fps
      ..clipSeconds = clipSeconds
      ..width = 1920
      ..quality = 100
      ..sheetAspect = layoutShape
      ..thumbnailAspect = sceneAspect
      ..crop = sceneAspect != 'source'
      ..imageFormat = 'png'
      ..header = false
      ..timestamps = false;
    if (autoClip && metadata != null && kind != OutputKind.sheet) {
      // Determine usable cuts before choosing duration, avoiding a circular
      // dependency between adaptive cut count and animation clip length.
      final count = SamplePlan.create(
        value..clipSeconds = .5,
        metadata,
        kind,
      ).count;
      value.clipSeconds = (metadata.duration / count).clamp(.5, 10);
    }
    if (metadata != null && kind != OutputKind.sheet) {
      final rate = 1 / metadata.frameSeconds;
      // Nominal integer rates preserve common 23.976/29.97 sources as 24/30.
      final sourceFps = rate.isFinite && rate > 0
          ? rate.round().clamp(1, 240)
          : 24;
      final clip = SamplePlan.create(value, metadata, kind).clip;
      // Bound work for long clips without adding another encoding probe.
      final frameBudgetFps = (120 / math.max(.001, clip)).floor().clamp(1, 30);
      value.fps = math.min(sourceFps, autoFps ? frameBudgetFps : fps);
    }
    return value;
  }

  Future<void> addFiles(List<String> paths) async {
    if (busy || importing) return;
    importing = true;
    processor.begin();
    changed();
    try {
      for (final path in paths) {
        if (closed) break;
        if (items.any((item) => p.equals(item.path, path))) continue;
        if (items.length >= maxFiles) break;
        final item = QueueItem(path, p.basename(path));
        items.add(item);
        selected ??= item;
        changed();
        try {
          item.metadata = await processor.probe(path);
          item.thumbnailPath = await processor.createThumbnail(
            path,
            item.metadata!,
          );
        } catch (e) {
          item.setStatus('failed', e);
        }
        changed();
      }
      if (items.length >= maxFiles) {
        setMessage('영상은 최대 50개까지 함께 처리할 수 있어요.');
      } else {
        setMessage('{0}개 영상을 확인했습니다.', [items.length]);
      }
    } finally {
      importing = false;
      changed();
    }
  }

  Future<void> generate() async {
    if (busy || importing) return;
    final jobs = items.where((item) => item.metadata != null).toList();
    if (jobs.isEmpty) return;
    // Rebuilding replaces the visible result for every queued source. Older files
    // remain on disk, but cannot masquerade as outputs for a new size limit.
    final rebuilding = jobs.map((item) => item.path).toSet();
    results.removeWhere((path, _) => rebuilding.contains(path));
    fitted.removeWhere((path, _) => rebuilding.contains(path));
    busy = true;
    progress = 0;
    processor.begin();
    final optimizer = CapacityOptimizer(processor);
    var success = 0, failed = 0;
    changed();
    try {
      for (var i = 0; i < jobs.length; i++) {
        final item = jobs[i];
        item.setStatus('processing');
        changed();
        try {
          final result = await optimizer.generate(
            item,
            settings(item.metadata),
            targetMb * 1000000,
            (value, step) {
              progress = math.max(progress, (i + value) / jobs.length);
              message = '${i + 1}/${jobs.length} · $step';
              changed();
            },
          );
          results[item.path] = result.file;
          fitted[item.path] = result;
          success++;
          item.setStatus('done');
        } on JobCancelled {
          item.setStatus('waiting');
          rethrow;
        } catch (e) {
          failed++;
          item.setStatus(
            'failed',
            e is FormatException && e.message == 'capacityLimitFailed'
                ? tx('용량 한도에 맞추지 못했습니다. 한도를 늘리거나 영상 구간을 줄여주세요.')
                : errorText(e),
          );
        }
      }
      setMessage('{0}개 완료 · {1}개 실패', [success, failed]);
      progress = 1;
    } on JobCancelled {
      setMessage('중지했습니다. 완료된 결과는 유지됩니다.');
    } finally {
      busy = false;
      changed();
    }
  }

  Future<void> cancel() => processor.cancel();
  void remove(QueueItem item) {
    if (busy || importing) return;
    final index = items.indexOf(item);
    if (index < 0) return;
    items.removeAt(index);
    results.remove(item.path);
    fitted.remove(item.path);
    if (selected == item) {
      selected = items.isEmpty ? null : items[index.clamp(0, items.length - 1)];
    }
    setMessage('{0}개 영상을 확인했습니다.', [items.length]);
    changed();
  }

  Future<int> save(String directory, {Set<String>? selectedPaths}) async {
    var count = 0;
    final exports = results.entries
        .where(
          (entry) => selectedPaths == null || selectedPaths.contains(entry.key),
        )
        .map((entry) => entry.value)
        .toList();
    for (final result in exports) {
      final base = p.basenameWithoutExtension(result.path);
      final ext = p.extension(result.path);
      var target = p.join(directory, '$base$ext');
      var index = 2;
      while (await File(target).exists()) {
        target = p.join(directory, '$base (${index++})$ext');
      }
      await File(result.path).copy(target);
      count++;
    }
    setMessage('{0}개 저장했습니다.', [count]);
    changed();
    return count;
  }

  @override
  void dispose() {
    closed = true;
    processor.cancel();
    super.dispose();
  }
}
