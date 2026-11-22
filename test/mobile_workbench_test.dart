import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:frame_octopus/core/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frame_octopus/core/studio_controller.dart';
import 'package:frame_octopus/mobile/mobile_app.dart';
import 'package:frame_octopus/mobile/progress_flow.dart';
import 'package:frame_octopus/mobile/fluent_mobile.dart';

class _StoppableStudio extends StudioController {
  @override
  Future<void> cancel() async {
    busy = false;
    activeItem = null;
    changed();
  }
}

void main() {
  testWidgets('timestamps are optional and remain available for still PNG', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final studio = StudioController()..kind = OutputKind.sheet;
    await tester.pumpWidget(MobileOctopusApp(controller: studio));
    await tester.pumpAndSettle();
    expect(studio.timestamps, false);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mobile-timestamps-switch')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Show timestamps'));
    await tester.pumpAndSettle();
    expect(studio.settings().timestamps, true);
    final restored = StudioController();
    await restored.loadPreferences();
    expect(restored.timestamps, true);
    restored.kind = OutputKind.animatedSheet;
    expect(restored.settings().timestamps, true);
    restored.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('processing replaces inputs and completion replaces processing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final studio = StudioController();
    final item = QueueItem('sample.mp4', 'sample.mp4');
    studio.items.add(item);
    studio.busy = true;
    studio.activeItem = item;
    studio.activeJobIndex = studio.activeJobCount = 1;
    studio.progress = .42;
    await tester.pumpWidget(MobileOctopusApp(controller: studio));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MobileProcessingView), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Size per file'), findsNothing);
    studio.results[item.path] = GeneratedFile(
      'assets/icon/mosaic_octopus.png',
      OutputKind.sheet,
    );
    studio.busy = false;
    studio.changed();
    await tester.pumpAndSettle();
    expect(find.byType(MobileProcessingView), findsNothing);
    expect(find.text('Your collection is ready'), findsOneWidget);
    expect(find.text('Size per file'), findsNothing);
    expect(find.text('Save 1 to gallery'), findsOneWidget);
    await tester.tap(find.text('New collection'));
    await tester.pumpAndSettle();
    expect(find.text('Size per file'), findsOneWidget);
    expect(studio.items, isEmpty);
    expect(studio.results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stop remains visible at large text and is not reported as success',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final studio = _StoppableStudio()..busy = true;
      await tester.pumpWidget(MobileOctopusApp(controller: studio));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(find.text('Stop')).bottom, lessThan(640));
      expect(tester.getSize(find.byType(MobileButton)).height, lessThan(80));
      expect(
        tester.getSize(find.byType(MobileProcessingView)).height,
        greaterThan(300),
      );
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Your collection is ready'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow mobile settings scroll and keep animation overrides separate',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final studio = StudioController();
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MobileOctopusApp(controller: studio));
      await tester.pumpAndSettle();
      expect(find.text('20 MB'), findsOneWidget);
      expect(find.byType(f.FilledButton), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Choose videos'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Advanced'),
        -160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(find.text('Scenes (maximum)'), findsOneWidget);
      expect(find.text('Scene shape'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Automatic FPS'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Automatic FPS'));
      await tester.pumpAndSettle();
      expect(studio.autoFps, false);
      expect(studio.autoClip, true);
      await tester.scrollUntilVisible(
        find.text('Automatic scene duration'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Automatic scene duration'));
      await tester.pumpAndSettle();
      expect(studio.autoClip, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fluent result selection and confirmation stay usable at large text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final studio = StudioController();
      final item = QueueItem(
        'sample.mp4',
        'A long filename for a collection with multiple scenes.mp4',
      );
      studio.items.add(item);
      studio.results[item.path] = GeneratedFile(
        'assets/icon/mosaic_octopus.png',
        OutputKind.sheet,
      );
      await tester.pumpWidget(MobileOctopusApp(controller: studio));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(f.Checkbox),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.byType(f.Checkbox)),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(f.Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('Save 1 to gallery'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Delete selected'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete selected'));
      await tester.pumpAndSettle();
      expect(find.byType(f.ContentDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(studio.results.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
