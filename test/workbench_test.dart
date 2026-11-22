import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frame_octopus/core/models.dart';
import 'package:frame_octopus/core/studio_controller.dart';
import 'package:frame_octopus/ui/studio_theme.dart';
import 'package:frame_octopus/ui/workbench.dart';

void main() {
  testWidgets('welcome whitespace and keyboard both open the picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [f.FluentLocalizations.delegate],
        builder: (context, child) =>
            f.FluentTheme(data: StudioTheme.fluent(), child: child!),
        theme: StudioTheme.material(Brightness.light),
        home: Scaffold(body: UploadLanding(onPick: () => picks++)),
      ),
    );
    await tester.pumpAndSettle();
    final zone = find.byKey(const ValueKey('upload-area'));
    final bounds = tester.getRect(zone);
    await tester.tapAt(bounds.bottomLeft + const Offset(25, -25));
    await tester.pump();
    expect(picks, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picks, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact editor keeps add/remove usable and locks them during jobs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(930, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final studio = StudioController();
      addTearDown(studio.dispose);
      final item = QueueItem(
        'example.mp4',
        'A long video filename for layout.mp4',
      )..metadata = const VideoMetadata(10, 1920, 1080, 'h264', '', '');
      studio.items.add(item);
      studio.selected = item;
      var additions = 0, removals = 0;
      Widget editor() => MaterialApp(
        localizationsDelegates: const [f.FluentLocalizations.delegate],
        builder: (context, child) =>
            f.FluentTheme(data: StudioTheme.fluent(), child: child!),
        theme: StudioTheme.material(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: StudioWorkbench(
              studio: studio,
              preview: const SizedBox.expand(),
              onPick: () => additions++,
              onRemove: (_) => removals++,
              onGenerate: () {},
              onCancel: () {},
              onResults: () {},
              onTogglePreview: () {},
              onSelect: (_) {},
              onKind: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final remove = tester.getRect(
        find.byKey(const ValueKey('remove-example.mp4')),
      );
      final thumbnail = tester.getRect(
        find.byKey(const ValueKey('video-thumbnail-example.mp4')),
      );
      final card = tester.getRect(
        find.byKey(const ValueKey('video-card-example.mp4')),
      );
      expect(remove.overlaps(thumbnail), false);
      expect(card.right - remove.right, greaterThanOrEqualTo(9.9));
      await tester.tap(find.byKey(const ValueKey('add-more')));
      await tester.tap(find.byKey(const ValueKey('remove-example.mp4')));
      expect(additions, 1);
      expect(removals, 1);
      await tester.ensureVisible(find.text('Advanced'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(studio.autoClip, true);
      await tester.ensureVisible(
        find.byKey(const ValueKey('advanced-timestamps-switch')),
      );
      await tester.tap(
        find.byKey(const ValueKey('advanced-timestamps-switch')),
      );
      await tester.pumpAndSettle();
      expect(studio.settings().timestamps, true);
      expect(
        tester
            .widget<f.Slider>(find.byKey(const ValueKey('advanced-fps-slider')))
            .onChanged,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('advanced-auto-fps-switch')),
      );
      await tester.tap(find.byKey(const ValueKey('advanced-auto-fps-switch')));
      await tester.pumpAndSettle();
      expect(studio.autoFps, false);
      expect(
        tester
            .widget<f.Slider>(find.byKey(const ValueKey('advanced-fps-slider')))
            .onChanged,
        isNotNull,
      );
      final fpsSlider = tester.getRect(
        find.byKey(const ValueKey('advanced-fps-slider')),
      );
      final autoRow = tester.getRect(
        find.byKey(const ValueKey('advanced-auto-clip-row')),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('advanced-fps-slider')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(autoRow.top - fpsSlider.bottom, greaterThanOrEqualTo(24));
      expect(fpsSlider.overlaps(autoRow), false);
      await tester.ensureVisible(
        find.byKey(const ValueKey('advanced-auto-clip-switch')),
      );
      await tester.tap(find.byKey(const ValueKey('advanced-auto-clip-switch')));
      await tester.pumpAndSettle();
      expect(studio.autoClip, false);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('advanced-clip-slider')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      studio.busy = true;
      await tester.pumpWidget(editor());
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('add-more')));
      await tester.tap(find.byKey(const ValueKey('remove-example.mp4')));
      expect(additions, 1);
      expect(removals, 1);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  testWidgets(
    'result checks and preview close stay inset at large text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final studio = StudioController();
      addTearDown(studio.dispose);
      Widget shell(Widget child) => MaterialApp(
        localizationsDelegates: const [f.FluentLocalizations.delegate],
        builder: (context, child) =>
            f.FluentTheme(data: StudioTheme.fluent(), child: child!),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: Center(child: child)),
        ),
      );
      await tester.pumpWidget(shell(const SizedBox.shrink()));
      late Directory root;
      late File file;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('octopus_controls_');
        final image = await createTestImage(width: 64, height: 36);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        file = await File(
          '${root.path}/result.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        await precacheImage(
          FileImage(file),
          tester.element(find.byType(Scaffold)),
        );
      });
      addTearDown(() => root.delete(recursive: true));
      final result = GeneratedFile(file.path, OutputKind.sheet);
      await tester.pumpWidget(
        shell(
          SizedBox(
            width: 400,
            height: 340,
            child: ResultCard(
              sourceKey: 'test',
              name: 'Long filename with a detailed description.mp4',
              file: result,
              studio: studio,
              checked: true,
              onToggle: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.getRect(
        find.byKey(const ValueKey('result-card-test')),
      );
      final check = tester.getRect(
        find.byKey(const ValueKey('result-check-test')),
      );
      final name = tester.getRect(
        find.byKey(const ValueKey('result-name-test')),
      );
      expect(check.left - card.left, greaterThanOrEqualTo(13.9));
      expect(name.left - check.right, greaterThanOrEqualTo(11.9));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        shell(ResultPreview(file: result, name: 'Preview')),
      );
      await tester.pumpAndSettle();
      final dialog = tester.getRect(
        find.byKey(const ValueKey('result-preview-dialog')),
      );
      final close = tester.getRect(find.byKey(const ValueKey('preview-close')));
      expect(dialog.right - close.right, greaterThanOrEqualTo(15.9));
      expect(close.top - dialog.top, greaterThanOrEqualTo(15.9));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'export saves only checked results and preserves existing files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'frame_octopus_export_test_',
      );
      final studio = StudioController();
      try {
        final a = await File('${root.path}/a.webp').writeAsBytes([1, 2, 3]);
        final b = await File('${root.path}/b.webp').writeAsBytes([4, 5]);
        final target = await Directory('${root.path}/saved').create();
        studio.results['a'] = GeneratedFile(a.path, OutputKind.animatedSheet);
        studio.results['b'] = GeneratedFile(b.path, OutputKind.animatedSheet);
        final count = await studio.save(target.path, selectedPaths: {'a'});
        expect(count, 1);
        expect(studio.message, contains('1'));
        await studio.save(target.path, selectedPaths: {'a'});
        final files = await target
            .list()
            .where((entity) => entity is File)
            .toList();
        expect(files.length, 2);
        expect(await File('${target.path}/b.webp').exists(), false);
        for (final file in files) {
          expect(await File(file.path).readAsBytes(), [1, 2, 3]);
        }
      } finally {
        studio.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
