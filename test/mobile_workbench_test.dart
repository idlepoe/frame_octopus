import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:frame_octopus/core/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frame_octopus/core/studio_controller.dart';
import 'package:frame_octopus/mobile/mobile_app.dart';

void main() {
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

  testWidgets('Fluent result selection and confirmation stay usable at large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final studio = StudioController();
    final item = QueueItem('sample.mp4', 'A long filename for a collection with multiple scenes.mp4');
    studio.items.add(item);
    studio.results[item.path] = GeneratedFile('assets/icon/mosaic_octopus.png', OutputKind.sheet);
    await tester.pumpWidget(MobileOctopusApp(controller: studio));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(f.Checkbox), 180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(find.byType(f.Checkbox)), alignment: .4);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(f.Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Save 1 to gallery'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete selected'), -100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Delete selected'));
    await tester.pumpAndSettle();
    expect(find.byType(f.ContentDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(studio.results.length, 1);
    expect(tester.takeException(), isNull);
  });
}
