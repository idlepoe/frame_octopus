import 'dart:io';
import 'package:frame_octopus/core/processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frame_octopus/core/models.dart';
import 'package:frame_octopus/core/capacity_optimizer.dart';
import 'package:frame_octopus/core/studio_controller.dart';
import 'package:frame_octopus/l10n/studio_strings.dart';
import 'package:frame_octopus/l10n/app_language.dart';
import 'package:flutter/widgets.dart';

void main() {
  test(
    'sample prediction preserves scenes and FPS and accepts only measured fits',
    () async {
      final root = await Directory.systemTemp.createTemp('octopus_quality_');
      final item = QueueItem('fixture.mp4', 'fixture.mp4');
      final initial = Settings()
        ..outputs = {OutputKind.animatedSheet}
        ..autoArrange = true
        ..gridCount = 4
        ..width = 960
        ..fps = 30
        ..quality = 100;
      try {
        final fake = _EncodedFixture();
        final fitted = await CapacityOptimizer(
          fake,
          resultRoot: root,
        ).generate(item, initial, 1000, (_, _) {});
        expect(fitted.settings.quality, inInclusiveRange(60, 95));
        expect(fitted.attempts, 1);
        expect(fitted.sampleAttempts, 1);
        expect(
          Settings.fromJson((Settings()..quality = 97.6).toJson()).quality,
          97.6,
        );
        expect(fitted.settings.width, 960);
        expect(fitted.settings.fps, 30);
        expect(fitted.settings.gridCount, 4);
        expect(fitted.bytes, 500);
        expect(
          (await File(fitted.file.path).readAsBytes()).first,
          fitted.settings.quality.round(),
        );
        expect(await File(fitted.file.path).parent.list().length, 1);
        expect(fake.encodes, 1);
        expect(fake.encodes, lessThanOrEqualTo(8));
        expect(fake.preparations, 1);
        final roomy = await CapacityOptimizer(
          _EncodedFixture(),
          resultRoot: root,
        ).generate(item, initial, 2500, (_, _) {});
        expect(roomy.settings.quality, 95);
        expect(roomy.qualityScore, greaterThanOrEqualTo(fitted.qualityScore));
        final unlimited = await CapacityOptimizer(
          _EncodedFixture(),
          resultRoot: root,
        ).generate(item, initial, 0, (_, _) {});
        expect(unlimited.settings.quality, 100);
        expect(unlimited.attempts, 1);
        final before = await root.list().length;
        await expectLater(
          CapacityOptimizer(
            _EncodedFixture(neverFits: true),
            resultRoot: root,
          ).generate(item, initial, 1, (_, _) {}),
          throwsA(isA<FormatException>()),
        );
        expect(await root.list().length, before);
        await expectLater(
          CapacityOptimizer(
            _EncodedFixture(shouldCancel: true),
            resultRoot: root,
          ).generate(item, initial, 1000, (_, _) {}),
          throwsA(isA<JobCancelled>()),
        );
        expect(await root.list().length, before);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
  test(
    'an underestimated sample is corrected against actual final bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('octopus_correction_');
      try {
        final processor = _EncodedFixture(underestimateSamples: true);
        final result = await CapacityOptimizer(processor, resultRoot: root)
            .generate(
              QueueItem('fixture.mp4', 'fixture.mp4'),
              Settings()
                ..outputs = {OutputKind.animatedSheet}
                ..width = 960
                ..fps = 30
                ..quality = 100,
              1000,
              (_, _) {},
            );
        expect(result.bytes, lessThanOrEqualTo(1000));
        expect(result.attempts, 2);
        expect(result.settings.quality, lessThan(100));
        expect(processor.preparations, 1);
        expect(await File(result.file.path).parent.list().length, 1);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
  test('lossless PNG chooses the largest fitting even width', () async {
    final root = await Directory.systemTemp.createTemp('octopus_png_');
    try {
      final settings = Settings()
        ..outputs = {OutputKind.sheet}
        ..imageFormat = 'png'
        ..width = 1920
        ..quality = 100;
      final result =
          await CapacityOptimizer(_EncodedFixture(), resultRoot: root).generate(
            QueueItem('fixture.mp4', 'fixture.mp4'),
            settings,
            1000,
            (_, _) {},
          );
      expect(result.settings.width, 1000);
      expect(result.bytes, 1000);
      expect(settings.width, 1920);
    } finally {
      await root.delete(recursive: true);
    }
  });
  test(
    'flexible rows cover every row without empty cells for portrait and landscape',
    () {
      for (final ratio in [9 / 16, 16 / 9, 1.0]) {
        for (final count in [1, 3, 5, 7, 11, 24]) {
          final settings = Settings()
            ..autoArrange = true
            ..gridCount = count;
          final meta = VideoMetadata(
            120,
            (720 * ratio).round(),
            720,
            'h264',
            '',
            '',
          );
          final layout = SheetLayout.create(
            settings,
            meta,
            OutputKind.animatedSheet,
            count,
          );
          expect(layout.width * layout.height, lessThanOrEqualTo(8000000));
          for (var row = 0; row < layout.rows; row++) {
            var end = layout.left;
            for (var col = 0; col < layout.rowCount(row); col++) {
              final cell = layout.cell(row * layout.columns + col);
              expect(cell.x, end);
              expect(cell.width % 2, 0);
              expect(cell.height % 2, 0);
              expect((cell.width / cell.height - ratio).abs(), lessThan(.025));
              end = cell.x + cell.width + layout.gap;
            }
            expect(end - layout.gap, layout.left + layout.gridWidth);
          }
          expect(
            layout.cell(count - 1).y + layout.cell(count - 1).height,
            layout.top + layout.gridHeight,
          );
        }
      }
    },
  );
  test(
    'geometry search changes one dimension at a time and preserves source settings',
    () {
      final initial = Settings()
        ..gridCount = 24
        ..fps = 30
        ..width = 1920
        ..quality = 100;
      final candidates = CapacityOptimizer.geometryCandidates(initial);
      expect(candidates.any((s) => s.width == 1920 && s.fps < 30), true);
      expect(candidates.any((s) => s.width < 1920 && s.fps == 30), true);
      expect(
        candidates.every(
          (s) =>
              s.width >= 320 &&
              s.fps >= 4 &&
              s.gridCount == 24 &&
              s.quality == 100,
        ),
        true,
      );
      expect(initial.width, 1920);
      expect(initial.fps, 30);
    },
  );
  test(
    'preferences restore and reset; desktop translations cover each supported language',
    () async {
      expect(
        AppLanguage.resolve(null, const [Locale('ko')]),
        const Locale('en'),
      );
      SharedPreferences.setMockInitialValues({
        'studio_options_v1':
            '{"kind":"sheet","scenes":12,"mb":5,"fps":30,"clip":10,"autoClip":false,"autoFps":false,"timestamps":true,"layout":"16:9","aspect":"1:1"}',
      });
      final controller = StudioController();
      await controller.loadPreferences();
      expect(controller.kind, OutputKind.sheet);
      expect(controller.sceneLimit, 12);
      expect(controller.targetMb, 5);
      expect(controller.settings().clipSeconds, 10);
      expect(controller.autoClip, false);
      expect(controller.autoFps, false);
      expect(controller.timestamps, true);
      expect(controller.settings().timestamps, true);
      controller.resetPreferences();
      expect(controller.targetMb, 20);
      expect(controller.autoClip, true);
      expect(controller.autoFps, true);
      expect(controller.timestamps, false);
      expect(controller.sceneAspect, 'source');
      for (final entry in desktopCopy.entries) {
        expect(entry.value.length, 2);
        expect(entry.value.every((text) => text.isNotEmpty), true);
      }
      AppLanguage.instance.value = const Locale('en');
      expect(tx('선택한 {0}개 저장', [3]), 'Save 3 selected');
      AppLanguage.instance.value = const Locale('ja');
      expect(tx('선택한 {0}개 저장', [3]), '選択した3個を保存');
      AppLanguage.instance.value = null;
      controller.dispose();
    },
  );
}

class _EncodedFixture extends MosaicProcessor {
  final bool neverFits, shouldCancel, underestimateSamples;
  int activeWidth = 960;
  int preparations = 0, encodes = 0;
  _EncodedFixture({
    this.neverFits = false,
    this.shouldCancel = false,
    this.underestimateSamples = false,
  });
  @override
  Future<String> run(List<String> arguments) async {
    if (shouldCancel) throw JobCancelled();
    final sample = arguments.last.endsWith('.sample.webp');
    if (!sample) encodes++;
    final quality = double.parse(arguments[arguments.indexOf('-quality') + 1]);
    const maxQuality = 95;
    var count = neverFits || quality > maxQuality ? 2000 : 500;
    if (!sample && underestimateSamples) {
      final filter = arguments[arguments.indexOf('-filter_complex') + 1];
      final width = int.parse(RegExp(r'scale=(\d+):').firstMatch(filter)![1]!);
      count = (count * 4 * width * width / (960 * 960)).ceil();
    }
    if (sample) {
      final filter = arguments[arguments.indexOf('-filter_complex') + 1];
      final frames = RegExp(r'eq\(n,').allMatches(filter).length;
      final fps = int.parse(RegExp(r'fps=(\d+)').firstMatch(filter)![1]!);
      count = (count * frames / (2 * fps).ceil()).ceil();
      if (underestimateSamples) count = (count / 4).ceil();
    }
    await File(
      arguments.last,
    ).writeAsBytes(List.filled(count, quality.round()));
    return '';
  }

  @override
  Future<List<GeneratedFile>> generate(
    QueueItem item,
    Settings settings,
    void Function(double, String) progress,
    void Function(GeneratedFile) onResult, {
    Directory? outputDirectory,
    Future<void> Function(List<String>, String)? encodeWebp,
  }) async {
    if (shouldCancel) throw JobCancelled();
    preparations++;
    item.metadata ??= const VideoMetadata(12, 960, 540, 'h264', '', '');
    activeWidth = settings.width;
    final path =
        '${outputDirectory!.path}/candidate_$preparations.${settings.outputs.single == OutputKind.sheet ? 'png' : 'webp'}';
    if (settings.outputs.single == OutputKind.sheet) {
      await File(
        path,
      ).writeAsBytes(List.filled(neverFits ? 2000 : settings.width, 0));
    } else {
      final args = [
        '-filter_complex',
        '[0:v]null[out]',
        '-quality',
        '${settings.quality}',
        path,
      ];
      if (encodeWebp != null) {
        await encodeWebp(args, path);
      } else {
        await run(args);
      }
    }
    final result = GeneratedFile(path, settings.outputs.single);
    onResult(result);
    return [result];
  }
}
