import 'package:flutter_test/flutter_test.dart';
import 'package:frame_octopus/core/models.dart';
import 'package:frame_octopus/core/studio_controller.dart';
import 'package:frame_octopus/core/webp_budget_encoder.dart';

void main() {
  test('automatic FPS follows each source and limits work for long clips', () {
    final studio = StudioController()..autoClip = false;
    expect(studio.autoFps, true);
    for (final entry in [
      (12.0, 2.0, 12),
      (23.976, 2.0, 24),
      (25.0, 2.0, 25),
      (29.97, 2.0, 30),
      (60.0, 2.0, 30),
      (120.0, 2.0, 30),
      (24.0, 6.0, 20),
      (60.0, 10.0, 12),
      (8.0, 10.0, 8),
    ]) {
      studio.clipSeconds = entry.$2;
      final meta = VideoMetadata(
        60,
        1920,
        1080,
        'h264',
        '',
        '',
        frameSeconds: 1 / entry.$1,
      );
      expect(studio.settings(meta).fps, entry.$3);
      expect(studio.fps, 24);
    }
    final source = VideoMetadata(
      60,
      1920,
      1080,
      'h264',
      '',
      '',
      frameSeconds: 1 / 60,
    );
    studio.autoFps = false;
    studio.fps = 28;
    expect(studio.settings(source).fps, 28);
    studio.autoFps = true;
    expect(studio.settings(source).fps, 12);
    expect(studio.fps, 28);
    studio.autoFps = false;
    final lowRate = VideoMetadata(
      60,
      1920,
      1080,
      'h264',
      '',
      '',
      frameSeconds: 1 / 8,
    );
    expect(studio.settings(lowRate).fps, 8);
    studio.dispose();
  });
  test(
    'size estimate pays for key frame once and preserves static compression',
    () {
      List<int> chunk(String tag, int size) => [
        ...tag.codeUnits,
        size,
        0,
        0,
        0,
        ...List.filled(size, 0),
      ];
      final header = [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits];
      final animated = [...header, ...chunk('ANMF', 100), ...chunk('ANMF', 10)];
      expect(WebpBudgetEncoder.estimatedBytes(animated, 100, 12), 282);
      final still = [...header, ...chunk('VP8 ', 100)];
      expect(WebpBudgetEncoder.estimatedBytes(still, 100, 12), still.length);
    },
  );
  test(
    'size probes cover beginning, middle and end with at most 12 frames',
    () {
      expect(WebpBudgetEncoder.sampleFrames(5), [0, 1, 2, 3, 4]);
      final frames = WebpBudgetEncoder.sampleFrames(100);
      expect(frames.length, 12);
      expect(frames.take(4), [0, 1, 2, 3]);
      expect(frames.skip(4).take(4), [48, 49, 50, 51]);
      expect(frames.skip(8), [96, 97, 98, 99]);
      expect(frames.toSet().length, frames.length);
    },
  );
  test(
    'automatic clip length follows usable cuts per source; manual overrides it',
    () {
      final controller = StudioController();
      expect(controller.autoClip, true);
      for (final entry in [
        (10.0, 4, 2.5),
        (12.0, 4, 3.0),
        (60.0, 10, 6.0),
        (600.0, 24, 10.0),
        (.2, 1, .2),
      ]) {
        final metadata = VideoMetadata(entry.$1, 640, 360, 'h264', '', '');
        final options = controller.settings(metadata);
        final plan = SamplePlan.create(
          options,
          metadata,
          OutputKind.animatedSheet,
        );
        expect(plan.count, entry.$2);
        expect(plan.clip, closeTo(entry.$3, 1e-9));
        for (final time in plan.times) {
          expect(time + plan.clip, lessThanOrEqualTo(metadata.duration + 1e-9));
        }
      }
      final metadata = VideoMetadata(11.011, 640, 360, 'h264', '', '');
      controller.sceneLimit = 12;
      final options = controller.settings(metadata);
      final plan = SamplePlan.create(
        options,
        metadata,
        OutputKind.animatedSheet,
      );
      expect(plan.count, 5);
      expect(plan.clip, closeTo(11.011 / 5, 1e-9));
      controller.autoClip = false;
      controller.clipSeconds = 5;
      expect(controller.settings(metadata).clipSeconds, 5);
      controller.autoClip = true;
      expect(
        controller.settings(metadata).clipSeconds,
        closeTo(11.011 / 5, 1e-9),
      );
      expect(controller.clipSeconds, 5);
      controller.dispose();
    },
  );
  test('short videos reduce scene count and stay inside source duration', () {
    final settings = Settings()
      ..autoArrange = true
      ..gridCount = 4
      ..clipSeconds = 2;
    for (final seconds in [0.2, 1.0, 3.0, 6.0, 10.0]) {
      final metadata = VideoMetadata(seconds, 640, 360, 'mpeg4', '', '');
      final plan = SamplePlan.create(
        settings,
        metadata,
        OutputKind.animatedSheet,
      );
      expect(plan.count, inInclusiveRange(1, 4));
      for (final start in plan.times) {
        expect(start, greaterThanOrEqualTo(0));
        expect(start + plan.clip, lessThanOrEqualTo(seconds + .0001));
      }
      if (seconds < 2) expect(plan.count, 1);
    }
  });
}
