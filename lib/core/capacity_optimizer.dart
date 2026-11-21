import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'processor.dart';
import 'webp_budget_encoder.dart';
import '../l10n/studio_strings.dart';

class FittedOutput {
  final GeneratedFile file;
  final Settings settings;
  final int bytes, attempts, sampleAttempts;
  final double qualityScore;
  FittedOutput(
    this.file,
    this.settings,
    this.bytes,
    this.attempts, {
    this.qualityScore = 1,
    this.sampleAttempts = 0,
  });
}

/// Compare measured outputs, retaining the best usable candidate rather than
/// returning the first fit. Scene coverage and clip duration are preserved first.
class CapacityOptimizer {
  final MosaicProcessor processor;
  final Directory? resultRoot;
  CapacityOptimizer(this.processor, {this.resultRoot});

  static Settings copy(Settings settings) =>
      Settings.fromJson(settings.toJson())
        ..imageFormat = settings.imageFormat
        ..width = settings.width
        ..fps = settings.fps
        ..quality = settings.quality;
  static double score(
    Settings settings,
    Settings original, {
    bool still = false,
  }) {
    final spatial = math.pow(settings.width / original.width, .8);
    final temporal = still ? 1.0 : math.pow(settings.fps / original.fps, .6);
    final fidelity = still
        ? 1.0
        : math.pow(settings.quality / original.quality, .35);
    return (spatial * temporal * fidelity).toDouble();
  }

  static List<Settings> geometryCandidates(Settings initial) {
    const pairs = <(double, double)>[
      (1, 1),
      (.9, 1),
      (1, .85),
      (.8, 1),
      (.9, .85),
      (1, .67),
      (.8, .85),
      (.7, 1),
      (.9, .67),
      (.8, .67),
      (.7, .85),
      (.6, 1),
      (.7, .67),
      (.6, .85),
      (.5, 1),
      (.6, .67),
      (.7, .5),
      (.5, .85),
      (.5, .67),
      (.4, 1),
      (.6, .5),
      (.4, .85),
      (.5, .5),
      (.3, .67),
      (.4, .5),
      (.3, .33),
      (0, 0),
    ];
    final seen = <String>{};
    final candidates = <Settings>[];
    for (final pair in pairs) {
      final value = copy(initial)
        ..width =
            ((initial.width * pair.$1).round().clamp(
              math.min(320, initial.width),
              initial.width,
            ) ~/
            2 *
            2)
        ..fps = (initial.fps * pair.$2).round().clamp(
          math.min(4, initial.fps),
          initial.fps,
        );
      if (seen.add('${value.width}:${value.fps}')) candidates.add(value);
    }
    candidates.sort((a, b) => score(b, initial).compareTo(score(a, initial)));
    return candidates;
  }

  Future<FittedOutput> generate(
    QueueItem item,
    Settings initial,
    int maxBytes,
    void Function(double, String) progress,
  ) async {
    final parent =
        await (resultRoot ??
                Directory(
                  p.join(
                    (await getApplicationSupportDirectory()).path,
                    'results',
                  ),
                ))
            .create(recursive: true);
    final work = await parent.createTemp('fit_');
    final base = copy(initial);
    // A one-scene original-ratio image gains no source detail by upscaling.
    if (item.metadata != null &&
        SamplePlan.create(base, item.metadata!, base.previewKind).count == 1 &&
        base.thumbnailAspect == 'source') {
      base.width =
          math.min(base.width, item.metadata!.width).clamp(16, base.width) ~/
          2 *
          2;
    }
    if (item.metadata != null) {
      final sourceFps = (1 / item.metadata!.frameSeconds).round().clamp(1, 240);
      base.fps = math.min(base.fps, sourceFps);
    }
    final still =
        base.previewKind == OutputKind.sheet && base.imageFormat == 'png';
    var encodes = 0, accepted = false;
    var sampleAttempts = 0;
    FittedOutput? best;
    double valueScore(Settings settings) => score(settings, base, still: still);
    void status(String step) => progress(
      math.min(.95, encodes / (encodes + 5)),
      tx('품질 최적화 {0} · {1}', [encodes + 1, step]),
    );

    Future<FittedOutput> render(
      Settings settings, {
      bool fullFirst = false,
    }) async {
      processor.checkCancelled();
      if (still || maxBytes <= 0) encodes++;
      final files = await processor.generate(
        item,
        settings,
        (_, step) => status(step),
        (_) {},
        outputDirectory: work,
        encodeWebp: maxBytes <= 0 || still
            ? null
            : (arguments, output) async {
                final encoder = WebpBudgetEncoder(processor);
                try {
                  await encoder.encode(
                    arguments: arguments,
                    output: output,
                    settings: settings,
                    metadata: item.metadata!,
                    maxBytes: maxBytes,
                    progress: (sample, count) {
                      if (sample) {
                        progress(
                          math.min(.8, count / (count + 3)),
                          tx('용량 예측 {0}', [count]),
                        );
                      } else {
                        status(
                          'Q${settings.quality} · ${settings.width}px · ${settings.fps} FPS',
                        );
                      }
                    },
                  );
                } finally {
                  encodes += encoder.fullEncodes;
                  sampleAttempts += encoder.samples;
                }
              },
      );
      final file = files.single;
      return FittedOutput(
        file,
        settings,
        await File(file.path).length(),
        encodes,
        qualityScore: valueScore(settings),
        sampleAttempts: sampleAttempts,
      );
    }

    Future<bool> consider(Settings settings, {bool fullFirst = false}) async {
      final candidate = await render(settings, fullFirst: fullFirst);
      final fits = maxBytes <= 0 || candidate.bytes <= maxBytes;
      if (fits &&
          (best == null ||
              candidate.qualityScore > best!.qualityScore + .000001)) {
        if (best != null) await File(best!.file.path).delete();
        best = candidate;
      } else {
        await File(candidate.file.path).delete();
      }
      return fits;
    }

    try {
      if (await consider(copy(base), fullFirst: true) &&
          (maxBytes <= 0 || !still || best!.qualityScore >= .999999)) {
        accepted = true;
        progress(1, '');
        return best!;
      }
      // PNG has no lossy quality/FPS lever: locate the highest fitting even width.
      if (still) {
        var low = math.min(320, base.width), high = base.width;
        if (base.width > low && await consider(copy(base)..width = low)) {
          while (high - low > 2) {
            final middle = ((low + high) ~/ 4) * 2;
            if (middle <= low) break;
            if (await consider(copy(base)..width = middle)) {
              low = middle;
            } else {
              high = middle;
            }
          }
        }
      }
      // Reduce scene coverage only if no configuration of the requested scenes fits.
      if (best == null) {
        for (final count in {
          (base.gridCount * .75).ceil(),
          (base.gridCount / 2).ceil(),
          1,
        }) {
          final settings = copy(base)
            ..width = math.min(320, base.width)
            ..fps = math.min(4, base.fps)
            ..gridCount = count;
          if (await consider(settings)) break;
        }
      }
      if (best == null) throw const FormatException('capacityLimitFailed');
      processor.checkCancelled();
      accepted = true;
      progress(1, '');
      return FittedOutput(
        best!.file,
        best!.settings,
        best!.bytes,
        encodes,
        qualityScore: best!.qualityScore,
        sampleAttempts: sampleAttempts,
      );
    } finally {
      if (!accepted && p.isWithin(parent.path, work.path)) {
        await work.delete(recursive: true);
      }
    }
  }
}
