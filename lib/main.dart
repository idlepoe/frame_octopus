import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'core/models.dart';
import 'core/studio_controller.dart';
import 'l10n/app_language.dart';
import 'l10n/studio_strings.dart';
import 'package:window_manager/window_manager.dart';
import 'ui/mascot.dart';
import 'ui/workbench.dart';
import 'ui/studio_theme.dart';
import 'mobile/mobile_app.dart';

final _applicationCaptureKey = GlobalKey();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await runMobileApp();
    return;
  }
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  MediaKit.ensureInitialized();
  await AppLanguage.instance.load();
  runApp(OctopusApp(arguments: args));
}

class OctopusApp extends StatelessWidget {
  final List<String> arguments;
  const OctopusApp({super.key, this.arguments = const []});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    valueListenable: AppLanguage.instance,
    builder: (context, locale, _) => f.FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Frame Octopus',
      theme: StudioTheme.fluent(),
      locale: AppLanguage.resolve(
        locale,
        ui.PlatformDispatcher.instance.locales,
      ),
      supportedLocales: AppLanguage.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => RepaintBoundary(
        key: _applicationCaptureKey,
        child: Theme(
          data: StudioTheme.material(Brightness.light),
          child: ScaffoldMessenger(child: child!),
        ),
      ),
      home: DesktopStudio(arguments: arguments),
    ),
  );
}

class DesktopStudio extends StatefulWidget {
  final List<String> arguments;
  const DesktopStudio({super.key, required this.arguments});
  @override
  State<DesktopStudio> createState() => _DesktopStudioState();
}

class _DesktopStudioState extends State<DesktopStudio> with WindowListener {
  late final Future<void> preferences;
  final studio = StudioController();
  final player = Player();
  late final VideoController video;
  Future<void>? opening;
  String? playing;
  int _lastVerificationProgress = 0;
  bool showResult = false,
      resultsOpen = false,
      dragging = false,
      saving = false,
      picking = false;
  final selectedExports = <String>{};
  final captureKey = _applicationCaptureKey;
  @override
  void initState() {
    super.initState();
    video = VideoController(player);
    studio.addListener(refresh);
    preferences = studio.loadPreferences();
    AppLanguage.instance.addListener(refresh);
    windowManager.addListener(this);
    if (widget.arguments.length == 3 &&
        [
          '--verify-engine',
          '--verify-batch',
          '--capture-demo',
          '--verify-quality',
        ].contains(widget.arguments.first)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => verify());
    }
  }

  void refresh() {
    if (!mounted) return;
    final path = studio.selected?.path;
    if (path != null && path != playing && studio.selected?.metadata != null) {
      playing = path;
      opening = player.open(Media(path), play: false).catchError((
        Object error,
      ) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tx('미리보기를 재생하지 못했어요. 다른 영상을 확인해 주세요.'))),
          );
        }
      });
    }
    if (path == null && playing != null) {
      playing = null;
      player.stop();
    }
    selectedExports.retainAll(studio.results.keys);
    if (widget.arguments.length == 3 &&
        studio.busy &&
        DateTime.now().millisecondsSinceEpoch - _lastVerificationProgress >
            500) {
      _lastVerificationProgress = DateTime.now().millisecondsSinceEpoch;
      unawaited(
        File('${widget.arguments[2]}.progress.json')
            .writeAsString(
              jsonEncode({
                'message': studio.message,
                'progress': studio.progress,
                'limitMb': studio.targetMb,
                'kind': studio.kind.name,
              }),
            )
            .then<void>((_) {})
            .catchError((Object _) {}),
      );
    }
    setState(() {});
  }

  Future<void> captureVerificationView(String name) async {
    for (final pose in ['select', 'splash', 'complete']) {
      if (!mounted) return;
      await precacheImage(AssetImage('assets/mascot/$pose.png'), context);
    }
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${widget.arguments[2]}.$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  }

  int _demoFrame = 0;
  bool get capturingDemo => widget.arguments.first == '--capture-demo';
  Future<void> captureDemoFrame() async {
    final watch = Stopwatch()..start();
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = await Directory(
      '${widget.arguments[2]}.frames',
    ).create(recursive: true);
    await File(
      '${folder.path}/${(_demoFrame++).toString().padLeft(6, '0')}.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    final remaining = 100 - watch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }
  }

  Future<void> captureDemoFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await captureDemoFrame();
    }
  }

  Future<void> verify() async {
    final report = <String, dynamic>{'ok': false, 'outputs': <Object>[]};
    try {
      await preferences;
      studio.sceneLimit = capturingDemo ? 0 : 12;
      studio.targetMb = capturingDemo ? 20 : 1;
      studio.fps = capturingDemo ? 24 : 30;
      studio.autoFps = capturingDemo;
      studio.clipSeconds = 2;
      studio.autoClip = capturingDemo;
      studio.layoutShape = 'auto';
      studio.sceneAspect = 'source';
      await captureVerificationView('welcome');
      if (capturingDemo) await captureDemoFrames(15);
      final payload = widget.arguments.first == '--verify-engine'
          ? null
          : jsonDecode(await File(widget.arguments[1]).readAsString());
      if (payload is Map && payload['autoClip'] is bool) {
        studio.autoClip = payload['autoClip'] as bool;
      }
      if (payload is Map && payload['autoFps'] is bool) {
        studio.autoFps = payload['autoFps'] as bool;
      }
      if (payload is Map && payload['timestamps'] is bool) {
        studio.timestamps = payload['timestamps'] as bool;
      }
      final inputs = payload is Map
          ? (payload['inputs'] as List).cast<String>()
          : payload is List
          ? payload.cast<String>()
          : [widget.arguments[1]];
      final qualityBudgets = payload is Map && payload['budgets'] is List
          ? (payload['budgets'] as List).cast<int>()
          : [1, 20];
      if (qualityBudgets.any((value) => value < 1 || value > 100)) {
        throw const FormatException('Invalid verification budgets');
      }
      await studio.addFiles(inputs);
      report['inputCount'] = studio.items.length;
      report['sourceDurations'] = {
        for (final item in studio.items)
          if (item.metadata != null) item.name: item.metadata!.duration,
      };
      report['invalidInputCount'] = studio.items
          .where((item) => item.metadata == null)
          .length;
      if (studio.selected?.metadata == null) throw StateError('Probe failed');
      await opening;
      final duration = player.state.duration > Duration.zero
          ? player.state.duration
          : await player.stream.duration
                .firstWhere((value) => value > Duration.zero)
                .timeout(const Duration(seconds: 15));
      report['playbackDurationMs'] = duration.inMilliseconds;
      await video.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 15),
      );
      report['firstVideoFrameRendered'] = true;
      await captureVerificationView('editor');
      if (capturingDemo) {
        await player.play();
        await captureDemoFrames(30);
        await player.pause();
      }
      for (final budget
          in widget.arguments.first == '--verify-quality'
              ? qualityBudgets
              : [studio.targetMb]) {
        studio.targetMb = budget;
        for (final kind in [OutputKind.sheet, OutputKind.animatedSheet]) {
          studio.kind = kind;
          if (capturingDemo) {
            final operation = studio.generate();
            while (studio.busy) {
              await captureDemoFrame();
              await Future<void>.delayed(const Duration(milliseconds: 400));
            }
            await operation;
          } else {
            await studio.generate();
          }
          for (final entry in studio.results.entries) {
            final result = entry.value;
            final sourceItem = studio.items.firstWhere(
              (item) => item.path == entry.key,
            );
            if (result.kind != kind) {
              throw StateError('Generation failed');
            }
            final codec = await ui.instantiateImageCodec(
              await File(result.path).readAsBytes(),
            );
            final frame = await codec.getNextFrame();
            (report['outputs'] as List).add({
              'kind': kind.name,
              'limitMb': budget,
              'path': result.path,
              'bytes': await File(result.path).length(),
              'width': frame.image.width,
              'height': frame.image.height,
              'frames': codec.frameCount,
              'attempts': studio.fitted[entry.key]!.attempts,
              'sampleAttempts': studio.fitted[entry.key]!.sampleAttempts,
              'quality': studio.fitted[entry.key]!.settings.quality,
              'qualityScore': studio.fitted[entry.key]!.qualityScore,
              'clipSeconds': SamplePlan.create(
                studio.fitted[entry.key]!.settings,
                sourceItem.metadata!,
                kind,
              ).clip,
              'sceneCount': SamplePlan.create(
                studio.fitted[entry.key]!.settings,
                sourceItem.metadata!,
                kind,
              ).count,
              'fps': studio.fitted[entry.key]!.settings.fps,
              'sourceSeconds': sourceItem.metadata!.duration,
            });
            if (kind == OutputKind.animatedSheet && codec.frameCount <= 1) {
              throw StateError('Not animated');
            }
            if (await File(result.path).length() > studio.targetMb * 1000000) {
              throw StateError('Output exceeds capacity limit');
            }
            frame.image.dispose();
            codec.dispose();
          }
        }
      }
      final export = await Directory(
        '${widget.arguments[2]}.exports',
      ).create(recursive: true);
      await studio.save(export.path);
      await studio.save(export.path);
      report['exportedCopies'] = await export.list().length;
      if (report['exportedCopies'] != studio.results.length * 2) {
        throw StateError('Export collision handling failed');
      }
      showResult = true;
      resultsOpen = true;
      selectedExports.addAll(studio.results.keys);
      refresh();
      for (final result in studio.results.values) {
        if (mounted) await precacheImage(FileImage(File(result.path)), context);
      }
      await captureVerificationView('results');
      if (capturingDemo) await captureDemoFrames(30);
      final first = studio.results.entries.first;
      final title = studio.items
          .firstWhere((item) => item.path == first.key)
          .name;
      if (!mounted) throw StateError('Capture view is closed');
      final dialog = f.showDialog<void>(
        context: context,
        builder: (context) => ResultPreview(file: first.value, name: title),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await captureVerificationView('preview');
      if (capturingDemo) await captureDemoFrames(20);
      if (mounted) Navigator.pop(context);
      await dialog;
      report['demoFrames'] = _demoFrame;
      final previousLocale = AppLanguage.instance.value;
      for (final locale in [const Locale('en'), const Locale('ja')]) {
        AppLanguage.instance.value = locale;
        await captureVerificationView('results-${locale.languageCode}');
      }
      AppLanguage.instance.value = previousLocale;
      report['languagesRendered'] = ['en', 'ja'];
      report['ok'] = true;
    } catch (e, stack) {
      report['error'] = '$e';
      report['stack'] = '$stack';
    }
    await File(
      widget.arguments[2],
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  }

  Future<void> addPaths(List<String> paths) async {
    if (studio.busy || studio.importing || saving) return;
    const extensions = {'.mp4', '.mov', '.mkv', '.webm', '.avi', '.m4v'};
    final videos = paths
        .where((path) => extensions.contains(p.extension(path).toLowerCase()))
        .toList();
    if (videos.isEmpty) {
      studio.message = tx('MP4, MOV, MKV, WebM, AVI, M4V 영상을 골라주세요.');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(studio.message)));
      }
      return;
    }
    setState(() {
      resultsOpen = false;
      showResult = false;
    });
    await studio.addFiles(videos);
  }

  Future<void> pick() async {
    if (picking || studio.busy || studio.importing || saving) return;
    setState(() => picking = true);
    try {
      final files = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v'],
      );
      if (files != null && mounted) {
        await addPaths(files.paths.whereType<String>().toList());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tx('파일 선택 창을 열지 못했어요. 영상을 끌어놓아 주세요.'))),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> make() async {
    await player.pause();
    await studio.generate();
    if (!mounted || studio.results.isEmpty) return;
    setState(() {
      resultsOpen = true;
      selectedExports
        ..clear()
        ..addAll(studio.results.keys);
    });
  }

  Future<void> save() async {
    if (saving || selectedExports.isEmpty) return;
    setState(() => saving = true);
    final selection = Set<String>.of(selectedExports);
    try {
      final folder = await FilePicker.platform.getDirectoryPath(
        dialogTitle: tx('선택한 모음을 저장할 폴더'),
      );
      if (folder != null) {
        final count = await studio.save(folder, selectedPaths: selection);
        if (!mounted || count == 0) return;
        await f.displayInfoBar(
          context,
          alignment: Alignment.topCenter,
          duration: const Duration(seconds: 5),
          builder: (context, close) => f.InfoBar(
            title: Text(tx('{0}개 저장했습니다.', [count])),
            content: Text(folder, maxLines: 2, overflow: TextOverflow.ellipsis),
            severity: f.InfoBarSeverity.success,
            action: f.IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: close,
            ),
          ),
        );
      }
    } catch (_) {
      studio.message = tx('저장하지 못했습니다. 폴더의 쓰기 권한을 확인하세요.');
      studio.changed();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void onWindowClose() async {
    if (studio.busy || studio.importing || saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tx('생성 중에는 앱을 닫을 수 없습니다. 먼저 중지해 주세요.'))),
      );
      return;
    }
    await windowManager.destroy();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    AppLanguage.instance.removeListener(refresh);
    studio.removeListener(refresh);
    studio.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = studio.selected;
    final result = item == null ? null : studio.results[item.path];
    final preview = showResult && result != null
        ? Image.file(
            File(result.path),
            key: ValueKey(result.path),
            fit: BoxFit.contain,
          )
        : item?.metadata == null
        ? Center(
            child: Text(
              studio.importing ? tx('영상을 확인하고 있어요…') : item?.status ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          )
        : Video(controller: video);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xfff3f3f3))),
              ),
              child: Row(
                children: [
                  MascotArt(MascotPose.splash, size: 32),
                  SizedBox(width: 9),
                  Text(
                    'Frame Octopus',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Spacer(),
                  SizedBox(
                    width: 112,
                    child: f.ComboBox<String>(
                      value: AppLanguage.instance.code,
                      isExpanded: true,
                      items: const [
                        f.ComboBoxItem(value: 'en', child: Text('English')),
                        f.ComboBoxItem(value: 'ko', child: Text('한국어')),
                        f.ComboBoxItem(value: 'ja', child: Text('日本語')),
                      ],
                      onChanged: studio.busy || studio.importing
                          ? null
                          : (code) {
                              if (code != null) {
                                AppLanguage.instance.select(Locale(code));
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: tx('앱 정보 및 라이선스'),
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => f.showDialog<void>(
                      context: context,
                      builder: (context) => f.ContentDialog(
                        title: const Text('Frame Octopus'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MascotArt(MascotPose.splash, size: 64),
                            const Text('Version 0.2.0'),
                            const SizedBox(height: 12),
                            Text(tx('이 PC에서만 처리해요. 원본 영상은 그대로 보관됩니다.')),
                            const SizedBox(height: 12),
                            const SelectableText(
                              'Original Mosaic: https://github.com/mosaicvideo/mosaic\nFlutter port: https://github.com/idlepoe/mosaic',
                            ),
                            const SizedBox(height: 12),
                            f.HyperlinkButton(
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: 'Frame Octopus',
                                applicationVersion: '0.2.0',
                              ),
                              child: Text(tx('앱 정보 및 라이선스')),
                            ),
                            f.HyperlinkButton(
                              onPressed: () => f.showDialog<void>(
                                context: context,
                                builder: (context) => f.ContentDialog(
                                  title: Text(tx('개인정보 처리방침')),
                                  content: Text(
                                    tx('이 PC에서만 처리해요. 원본 영상은 그대로 보관됩니다.'),
                                  ),
                                  actions: [
                                    f.Button(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(tx('닫기')),
                                    ),
                                  ],
                                ),
                              ),
                              child: Text(tx('개인정보 처리방침')),
                            ),
                          ],
                        ),
                        actions: [
                          f.FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(tx('닫기')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    tx('나만의 장면 보관함'),
                    style: TextStyle(fontSize: 12, color: deskMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: DropTarget(
                      enable:
                          !studio.busy &&
                          !studio.importing &&
                          !saving &&
                          !picking &&
                          (ModalRoute.of(context)?.isCurrent ?? true),
                      onDragEntered: (_) => setState(() => dragging = true),
                      onDragExited: (_) => setState(() => dragging = false),
                      onDragDone: (details) {
                        setState(() => dragging = false);
                        addPaths(
                          details.files.map((file) => file.path).toList(),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: deskPaper,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: dragging
                                ? StudioTheme.green
                                : const Color(0xffe5e5e5),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: resultsOpen
                              ? ResultGallery(
                                  studio: studio,
                                  selected: selectedExports,
                                  saving: saving,
                                  onToggle: (path) => setState(() {
                                    if (!selectedExports.remove(path)) {
                                      selectedExports.add(path);
                                    }
                                  }),
                                  onEdit: () => setState(() {
                                    resultsOpen = false;
                                    showResult = false;
                                  }),
                                  onSave: save,
                                  onToggleAll: () => setState(() {
                                    if (selectedExports.length ==
                                        studio.results.length) {
                                      selectedExports.clear();
                                    } else {
                                      selectedExports.addAll(
                                        studio.results.keys,
                                      );
                                    }
                                  }),
                                )
                              : StudioWorkbench(
                                  studio: studio,
                                  preview: preview,
                                  dragging: dragging,
                                  showResult: showResult,
                                  onPick: pick,
                                  onGenerate: make,
                                  onCancel: studio.cancel,
                                  onResults: () {
                                    player.pause();
                                    setState(() {
                                      resultsOpen = true;
                                      selectedExports
                                        ..clear()
                                        ..addAll(studio.results.keys);
                                    });
                                  },
                                  onTogglePreview: () {
                                    player.pause();
                                    setState(() => showResult = !showResult);
                                  },
                                  onSelect: (item) {
                                    studio.selected = item;
                                    showResult = false;
                                    refresh();
                                  },
                                  onRemove: studio.remove,
                                  onKind: (kind) => setState(() {
                                    studio.kind = kind;
                                    studio.savePreferences();
                                  }),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                tx('이 PC에서만 처리해요. 원본 영상은 그대로 보관됩니다.'),
                style: TextStyle(color: deskMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
