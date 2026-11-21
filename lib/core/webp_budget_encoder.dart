import 'dart:io';
import 'dart:math' as math;
import 'models.dart';
import 'processor.dart';

/// Estimate with short runs from three temporal regions, then encode the full
/// animation. All probes reuse the same prepared/merged source and overlay.
class WebpBudgetEncoder {
  final MosaicProcessor processor;
  int samples = 0, fullEncodes = 0;
  WebpBudgetEncoder(this.processor);

  static List<int> sampleFrames(int total) {
    if (total <= 12) return List.generate(total, (i) => i);
    return {
      for (final start in [0, (total - 4) ~/ 2, total - 4])
        for (var offset = 0; offset < 4; offset++) start + offset,
    }.toList()..sort();
  }

  static int estimatedBytes(List<int> bytes, int total, int sampled) {
    final length = bytes.length;
    // A WebP key frame is paid for once, not once per sampled window. Separating
    // it avoids treating a nearly static animation as a large moving one.
    if (length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
      var cursor = 12;
      while (cursor + 8 <= length) {
        final tag = String.fromCharCodes(bytes.skip(cursor).take(4));
        final size =
            bytes[cursor + 4] |
            bytes[cursor + 5] << 8 |
            bytes[cursor + 6] << 16 |
            bytes[cursor + 7] << 24;
        final end = cursor + 8 + size;
        if (end > length || size < 0) break;
        if (tag == 'ANMF') {
          return (end + (length - end) * (total - 1) / math.max(1, sampled - 1))
              .ceil();
        }
        cursor = end + (size & 1);
      }
      // A single-frame VP8/VP8L file needs no temporal multiplier.
      return length;
    }
    return (length * total / sampled).ceil();
  }

  Future<void> encode({
    required List<String> arguments,
    required String output,
    required Settings settings,
    required VideoMetadata metadata,
    required int maxBytes,
    required void Function(bool sample, int count) progress,
  }) async {
    final originalQuality = settings.quality;
    final floorQuality = math.min(60.0, originalQuality);
    final plan = SamplePlan.create(settings, metadata, settings.previewKind);
    final count = plan.count;
    final target = maxBytes * .90;
    final sampleFile = File('$output.sample.webp');

    Future<int> run(double quality, {required bool sample}) async {
      processor.checkCancelled();
      final layout = SheetLayout.create(
        settings,
        metadata,
        settings.previewKind,
        count,
      );
      final total = math.max(1, (plan.clip * settings.fps).ceil());
      final frames = sampleFrames(total);
      final args = List<String>.of(arguments);
      args[args.indexOf('-quality') + 1] = '$quality';
      final filterIndex = args.indexOf('-filter_complex') + 1;
      final selection = sample
          ? ",select='${frames.map((n) => 'eq(n,$n)').join('+')}',setpts=N/(${settings.fps}*TB)"
          : '';
      args[filterIndex] = args[filterIndex].replaceFirst(
        '[out]',
        ',scale=${layout.width}:${layout.height}:flags=bilinear,fps=${settings.fps}$selection[out]',
      );
      args.insertAll(args.length - 1, ['-fps_mode', 'passthrough']);
      args[args.length - 1] = sample ? sampleFile.path : output;
      if (sample) {
        samples++;
      } else {
        fullEncodes++;
      }
      progress(sample, sample ? samples : fullEncodes);
      await processor.run(args);
      final bytes = await File(args.last).length();
      // Discontinuous sample windows can overestimate inter-frame cost. Keep a
      // conservative estimate; only actual final bytes decide acceptance.
      return sample
          ? estimatedBytes(await sampleFile.readAsBytes(), total, frames.length)
          : bytes;
    }

    try {
      // Fast default: one representative sample, no search for the last byte
      // or fractional quality gain. Spare budget is deliberately acceptable.
      var quality = math.min(90.0, originalQuality);
      final estimate = await run(quality, sample: true);
      if (estimate < target * .60) {
        quality = math.min(95.0, originalQuality);
      } else if (estimate > target) {
        final desired = settings.width * math.sqrt(target / estimate) * .95;
        final width =
            desired.floor().clamp(
              math.min(320, settings.width),
              settings.width,
            ) ~/
            2 *
            2;
        final remaining =
            target / (estimate * math.pow(width / settings.width, 2));
        settings.width = width;
        if (remaining < 1) {
          settings.fps = (settings.fps * remaining * .95).floor().clamp(
            1,
            settings.fps,
          );
        }
      }
      // Normally one full encode. Correct only actual overflow, never try to
      // fill spare capacity. Reuse the same prepared source for every correction.
      for (var correction = 0; correction < 3; correction++) {
        settings.quality = quality;
        final bytes = await run(quality, sample: false);
        if (bytes <= maxBytes) return;
        if (correction == 2) break;
        quality = math.max(floorQuality, quality - 5);
        final desired = settings.width * math.sqrt(target / bytes) * .95;
        final width =
            desired.floor().clamp(
              math.min(320, settings.width),
              settings.width,
            ) ~/
            2 *
            2;
        final remaining =
            target / (bytes * math.pow(width / settings.width, 2));
        settings.width = width;
        if (remaining < 1) {
          settings.fps = (settings.fps * remaining * .95).floor().clamp(
            1,
            settings.fps,
          );
        }
      }
      // The caller still measures bytes and may reduce scene coverage or fail.
    } finally {
      if (await sampleFile.exists()) await sampleFile.delete();
    }
  }
}
