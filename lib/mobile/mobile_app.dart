import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../firebase_options.dart';
import 'fluent_mobile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:video_player/video_player.dart';
import '../core/models.dart';
import '../core/capacity_optimizer.dart';
import '../core/studio_controller.dart';
import '../l10n/app_language.dart';
import '../ui/mascot.dart';
import 'gallery_service.dart';
import 'mobile_strings.dart';

Future<void> runMobileApp() async {
  await AppLanguage.instance.load();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    debugPrint('Firebase connected: frame-octopus (Android).');
  } catch (_) {
    // Editing local videos must remain available when a cloud SDK is unavailable.
    debugPrint(
      'Firebase initialization unavailable; local tools remain available.',
    );
  }
  runApp(const MobileOctopusApp());
}

class MobileOctopusApp extends StatelessWidget {
  final StudioController? controller;
  const MobileOctopusApp({super.key, this.controller});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    valueListenable: AppLanguage.instance,
    builder: (context, locale, _) => f.FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Frame Octopus',
      locale: locale,
      supportedLocales: AppLanguage.supported,
      localizationsDelegates: const [
        f.FluentLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: MobileFluentTheme.fluent(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Theme(
          data: MobileFluentTheme.foundation(),
          child: Material(type: MaterialType.transparency, child: child!),
        ),
      ),
      home: MobileStudio(controller: controller),
    ),
  );
}

class MobileStudio extends StatefulWidget {
  final StudioController? controller;
  const MobileStudio({super.key, this.controller});
  @override
  State<MobileStudio> createState() => _MobileStudioState();
}

class _MobileStudioState extends State<MobileStudio>
    with WidgetsBindingObserver {
  late final studio = widget.controller ?? StudioController();
  final gallery = GalleryService();
  final selectedResults = <String>{};
  final importedIds = <String, String>{};
  bool ready = false, picking = false, saving = false, cancelling = false;
  bool get locked =>
      studio.busy || studio.importing || picking || saving || !ready;
  String t(String en, String ko, String ja) => mobileText(en, ko, ja);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    studio.addListener(refresh);
    initialize();
  }

  Future<void> initialize() async {
    try {
      if (widget.controller == null) await gallery.cleanPreviousSession();
      await studio.loadPreferences();
    } catch (_) {
      if (mounted) {
        notice(
          t(
            'Temporary files could not be cleared.',
            '임시 파일을 정리하지 못했습니다.',
            '一時ファイルを削除できませんでした。',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => ready = true);
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // V1 deliberately runs in the foreground; completed files remain available.
    if (state == AppLifecycleState.paused && studio.busy) stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    studio.removeListener(refresh);
    if (widget.controller == null) studio.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void notice(String text) {
    if (!mounted) return;
    f.displayInfoBar(
      context,
      alignment: Alignment.topCenter,
      duration: const Duration(seconds: 5),
      builder: (context, close) => f.InfoBar(title: Text(text), onClose: close),
    );
  }

  Future<void> pick() async {
    if (locked) return;
    setState(() => picking = true);
    try {
      final videos = await gallery.pick();
      if (!mounted) return;
      final available = StudioController.maxFiles - studio.items.length;
      final accepted = <GalleryVideo>[];
      for (final video in videos) {
        if (importedIds.containsValue(video.id) ||
            accepted.length >= available) {
          await File(video.path).delete();
        } else {
          importedIds[video.path] = video.id;
          accepted.add(video);
        }
      }
      await studio.addFiles(
        accepted.map((v) => v.path).toList(),
        names: {for (final v in accepted) v.path: v.name},
      );
    } catch (e) {
      notice(errorText(e));
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> generate() async {
    if (locked || studio.items.isEmpty) return;
    try {
      await WakelockPlus.enable();
      selectedResults.clear();
      await studio.generate();
      selectedResults.addAll(studio.results.keys);
      if (mounted) notice(studio.message);
    } catch (e) {
      notice(errorText(e));
    } finally {
      await WakelockPlus.disable();
      refresh();
    }
  }

  Future<void> stop() async {
    if (cancelling) return;
    setState(() => cancelling = true);
    try {
      await studio.cancel();
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  Future<void> save() async {
    if (locked || selectedResults.isEmpty) return;
    setState(() => saving = true);
    var saved = 0;
    try {
      for (final key in selectedResults.toList()) {
        final file = studio.results[key];
        if (file == null) continue;
        await gallery.save(file.path);
        saved++;
      }
      notice(
        t(
          'Saved $saved files to the Frame Octopus album.',
          '$saved개를 Frame Octopus 앨범에 저장했습니다.',
          '$saved個をFrame Octopusアルバムに保存しました。',
        ),
      );
    } catch (e) {
      notice(
        '${t('Saved $saved files.', '$saved개 저장했습니다.', '$saved個保存しました。')} ${errorText(e)}',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> share() async {
    if (locked || selectedResults.isEmpty) return;
    setState(() => saving = true);
    try {
      final files = selectedResults
          .map((key) => studio.results[key])
          .whereType<GeneratedFile>()
          .map((v) => XFile(v.path))
          .toList();
      if (files.isNotEmpty) {
        await SharePlus.instance.share(ShareParams(files: files));
      }
    } catch (e) {
      notice(errorText(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteSelected() async {
    if (locked || selectedResults.isEmpty) return;
    final confirmed = await f.showDialog<bool>(
      context: context,
      builder: (context) => f.ContentDialog(
        title: Text(
          t('Delete selected results?', '선택한 결과를 삭제할까요?', '選択した結果を削除しますか？'),
        ),
        content: Text(
          t(
            'Original videos and saved gallery copies are kept.',
            '원본 영상과 갤러리에 저장한 복사본은 유지됩니다.',
            '元動画とギャラリーに保存したコピーは残ります。',
          ),
        ),
        actions: [
          MobileButton(
            kind: MobileButtonKind.link,
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', '취소', 'キャンセル')),
          ),
          MobileButton(
            kind: MobileButtonKind.link,
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Delete', '삭제', '削除')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    try {
      for (final key in selectedResults.toList()) {
        final file = studio.results[key];
        if (file != null && await File(file.path).exists()) {
          await File(file.path).delete();
        }
        studio.results.remove(key);
        studio.fitted.remove(key);
        selectedResults.remove(key);
      }
    } catch (e) {
      notice(errorText(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void update(VoidCallback action) {
    action();
    studio.savePreferences();
  }

  Future<void> openPrivacy() async {
    final path = switch (AppLanguage.instance.code) {
      'ko' => '/ko/privacy',
      'ja' => '/ja/privacy',
      _ => '/privacy',
    };
    try {
      if (!await launchUrl(
        Uri.https('frame-octopus.web.app', path),
        mode: LaunchMode.externalApplication,
      )) {
        notice(
          t(
            'Could not open the privacy policy.',
            '개인정보처리방침을 열지 못했습니다.',
            'プライバシーポリシーを開けませんでした。',
          ),
        );
      }
    } catch (_) {
      notice(
        t(
          'Could not open the privacy policy.',
          '개인정보처리방침을 열지 못했습니다.',
          'プライバシーポリシーを開けませんでした。',
        ),
      );
    }
  }

  String resultDetails(String key, FittedOutput fit) {
    final metadata = studio.items
        .where((i) => i.path == key)
        .firstOrNull
        ?.metadata;
    var text = '${(fit.bytes / 1000000).toStringAsFixed(2)} MB';
    if (metadata != null) {
      final plan = SamplePlan.create(fit.settings, metadata, fit.file.kind);
      final layout = SheetLayout.create(
        fit.settings,
        metadata,
        fit.file.kind,
        plan.count,
      );
      text +=
          ' · ${plan.count} ${t('scenes', '장면', 'シーン')} · ${layout.width} × ${layout.height}';
    }
    if (fit.file.kind != OutputKind.sheet) {
      text +=
          ' · ${fit.settings.fps} FPS · ${fit.settings.clipSeconds.toStringAsFixed(1)} s';
    }
    return text;
  }

  Future<void> advanced() async {
    await showFluentSettings(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: studio,
        builder: (context, _) => FractionallySizedBox(
          heightFactor: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('Advanced', '상세 설정', '詳細設定'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    MobileIconButton(
                      tooltip: t('Close', '닫기', '閉じる'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(f.FluentIcons.cancel),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                dropdown<int>(
                  t('Scenes (maximum)', '장면 수 (최대)', 'シーン数（最大）'),
                  studio.sceneLimit,
                  {
                    0: t('Automatic', '자동', '自動'),
                    4: '4',
                    8: '8',
                    12: '12',
                    24: '24',
                  },
                  (v) => update(() => studio.sceneLimit = v),
                ),
                const SizedBox(height: 20),
                dropdown<String>(
                  t('Scene shape', '개별 장면 비율', '各シーンの比率'),
                  studio.sceneAspect,
                  {
                    'source': t('Original', '원본', '元の比率'),
                    '1:1': '1:1',
                    '16:9': '16:9',
                    '9:16': '9:16',
                  },
                  (v) => update(() => studio.sceneAspect = v),
                ),
                const SizedBox(height: 20),
                dropdown<String>(
                  t('Collection layout', '전체 모음 배치', '一覧の配置'),
                  studio.layoutShape,
                  {
                    'auto': t('Automatic', '자동', '自動'),
                    '16:9': t('Wide', '가로', '横長'),
                    '9:16': t('Tall', '세로', '縦長'),
                  },
                  (v) => update(() => studio.layoutShape = v),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                dropdown<int>(
                  t('Maximum output width', '출력 최대 너비', '出力の最大幅'),
                  studio.outputWidth,
                  {960: '960 px', 1280: '1280 px', 1920: '1920 px'},
                  (v) => update(() => studio.outputWidth = v),
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    '1280 px balances detail and processing time on a phone. The size limit may reduce it further.',
                    '1280px는 휴대폰의 화질과 처리 시간을 고려한 기본값입니다. 용량 제한에 따라 더 작아질 수 있습니다.',
                    '1280pxは画質とスマートフォンでの処理時間のバランスを考えた初期値です。容量に応じてさらに縮小します。',
                  ),
                ),
                const Divider(height: 32),
                Text(
                  t('Animation', '애니메이션', 'アニメーション'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                MobileToggle(
                  title: Text(t('Automatic FPS', '자동 FPS', 'FPSを自動調整')),
                  value: studio.autoFps,
                  onChanged: studio.kind == OutputKind.sheet
                      ? null
                      : (v) => update(() => studio.autoFps = v),
                ),
                Text(
                  'FPS: ${studio.autoFps ? t('Automatic', '자동', '自動') : studio.fps}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: f.Slider(
                    min: 4,
                    max: 30,
                    divisions: 26,
                    value: studio.fps.toDouble(),
                    onChanged: studio.autoFps || studio.kind == OutputKind.sheet
                        ? null
                        : (v) => update(() => studio.fps = v.round()),
                  ),
                ),
                const Divider(height: 32),
                MobileToggle(
                  title: Text(
                    t(
                      'Automatic scene duration',
                      '장면당 재생 길이 자동',
                      'シーンの再生時間を自動調整',
                    ),
                  ),
                  value: studio.autoClip,
                  onChanged: studio.kind == OutputKind.sheet
                      ? null
                      : (v) => update(() => studio.autoClip = v),
                ),
                Text(
                  '${t('Seconds per scene', '장면당 재생 시간 (초)', 'シーンの再生時間（秒）')}: ${studio.autoClip ? t('Automatic', '자동', '自動') : studio.clipSeconds}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: f.Slider(
                    min: .5,
                    max: 10,
                    divisions: 19,
                    value: studio.clipSeconds,
                    onChanged:
                        studio.autoClip || studio.kind == OutputKind.sheet
                        ? null
                        : (v) => update(
                            () => studio.clipSeconds = (v * 2).round() / 2,
                          ),
                  ),
                ),
                Text(
                  t(
                    'Automatic values use video length and source FPS. Still PNG does not use animation settings.',
                    '자동 설정은 영상 길이와 원본 FPS를 기준으로 합니다. 정지 PNG에는 애니메이션 설정이 적용되지 않습니다.',
                    '動画の長さと元のFPSから自動調整します。静止PNGにはアニメーション設定を適用しません。',
                  ),
                ),
                const SizedBox(height: 20),
                MobileButton(
                  kind: MobileButtonKind.link,
                  onPressed: studio.resetPreferences,
                  child: Text(t('Reset settings', '설정 초기화', '設定をリセット')),
                ),
                const Divider(height: 32),
                MobileButton.icon(
                  kind: MobileButtonKind.link,
                  onPressed: openPrivacy,
                  icon: const Icon(f.FluentIcons.shield),
                  label: Text(t('Privacy policy', '개인정보처리방침', 'プライバシーポリシー')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dropdown<T>(
    String label,
    T value,
    Map<T, String> values,
    ValueChanged<T> onChanged,
  ) => f.InfoLabel(
    label: label,
    child: SizedBox(
      height: 44,
      child: f.ComboBox<T>(
        key: ValueKey('$label:$value'),
        value: value,
        isExpanded: true,
        items: values.entries
            .map(
              (e) => f.ComboBoxItem<T>(
                value: e.key,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: locked
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !studio.busy,
    onPopInvokedWithResult: (popped, result) {
      if (!popped) {
        notice(
          t(
            'Stop creating before leaving.',
            '나가기 전에 생성을 중지해 주세요.',
            '終了する前に作成を停止してください。',
          ),
        );
      }
    },
    child: Scaffold(
      appBar: MobileHeader(
        title: const Text(
          'Frame Octopus',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          SizedBox(
            width: 114,
            height: 44,
            child: f.ComboBox<String>(
              value: AppLanguage.instance.code,
              isExpanded: true,
              selectedItemBuilder: (context) => [
                for (final code in ['en', 'ko', 'ja'])
                  Row(
                    children: [
                      const Icon(f.FluentIcons.globe, size: 16),
                      const SizedBox(width: 8),
                      Text(code.toUpperCase()),
                    ],
                  ),
              ],
              items: [
                for (final e in {
                  'en': 'English',
                  'ko': '한국어',
                  'ja': '日本語',
                }.entries)
                  f.ComboBoxItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (code) {
                if (code != null) AppLanguage.instance.select(Locale(code));
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !ready
          ? const MascotStartup()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    MobileCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: dropdown<int>(
                                    t(
                                      'Size per file',
                                      '파일당 최대 용량',
                                      'ファイルの最大容量',
                                    ),
                                    studio.targetMb,
                                    {
                                      0: t('Unlimited', '제한 없음', '無制限'),
                                      for (final n in [1, 5, 10, 20, 50, 100])
                                        n: '$n MB',
                                    },
                                    (v) => update(() => studio.targetMb = v),
                                  ),
                                ),
                                SizedBox(
                                  width: 158,
                                  child: dropdown<OutputKind>(
                                    t('Output', '출력 형식', '出力形式'),
                                    studio.kind,
                                    {
                                      OutputKind.animatedSheet: 'WebP',
                                      OutputKind.sheet: 'PNG',
                                    },
                                    (v) => update(() => studio.kind = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              studio.kind == OutputKind.sheet
                                  ? t(
                                      'One still image · PNG',
                                      '한 장의 정지 이미지 · PNG',
                                      '1枚の静止画像 · PNG',
                                    )
                                  : t(
                                      'Scenes play together · WebP',
                                      '여러 장면이 함께 재생 · WebP',
                                      '複数のシーンを同時再生 · WebP',
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t(
                                      'Scenes and layout, automatically.',
                                      '장면과 배치는 자동으로.',
                                      'シーンと配置は自動で。',
                                    ),
                                  ),
                                ),
                                MobileButton(
                                  kind: MobileButtonKind.link,
                                  onPressed: locked ? null : advanced,
                                  child: Text(t('Advanced', '상세 설정', '詳細設定')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (studio.items.isEmpty)
                      MobileCard(
                        child: InkWell(
                          onTap: locked ? null : pick,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 36,
                            ),
                            child: Column(
                              children: [
                                const MascotArt(MascotPose.select, size: 132),
                                const SizedBox(height: 16),
                                Text(
                                  t('Choose videos', '영상 고르기', '動画を選ぶ'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t(
                                    'From your gallery. Octopus will arrange the scenes.',
                                    '갤러리에서 고르면 문어가 장면을 배치해요.',
                                    'ギャラリーから選ぶと、シーンを自動で配置します。',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t(
                                    'On this device · Originals preserved',
                                    '내 기기에서 처리 · 원본 유지',
                                    '端末内で処理・元動画を保持',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (studio.selected != null)
                        MobileVideoPreview(
                          key: ValueKey(studio.selected!.path),
                          path: studio.selected!.path,
                          enabled: !studio.busy,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${t('Videos', '영상', '動画')} ${studio.items.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          MobileButton.icon(
                            kind: MobileButtonKind.link,
                            onPressed: locked || studio.items.length >= 50
                                ? null
                                : pick,
                            icon: const Icon(f.FluentIcons.add),
                            label: Text(t('Add', '추가', '追加')),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 178,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: studio.items.length,
                          separatorBuilder: (_, i) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = studio.items[index];
                            return SizedBox(
                              width: 164,
                              child: MobileCard(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: studio.selected == item
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xffdce1e8),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        Text('${index + 1}'),
                                        const Spacer(),
                                        MobileIconButton(
                                          tooltip: t(
                                            'Remove video',
                                            '영상 제외',
                                            '動画を除外',
                                          ),
                                          onPressed: locked
                                              ? null
                                              : () {
                                                  importedIds.remove(item.path);
                                                  studio.remove(item);
                                                },
                                          icon: const Icon(
                                            f.FluentIcons.cancel,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: locked
                                            ? null
                                            : () {
                                                studio.selected = item;
                                                studio.changed();
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: item.thumbnailPath == null
                                              ? const Center(
                                                  child: Icon(
                                                    f.FluentIcons.video,
                                                  ),
                                                )
                                              : Image.file(
                                                  File(item.thumbnailPath!),
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  cacheWidth: 328,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            item.status,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (studio.importing || picking || studio.busy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            if (studio.busy) const LoadingMascot(size: 64),
                            MobileProgress(
                              value: studio.busy ? studio.progress : null,
                            ),
                            const SizedBox(height: 12),
                            Text(studio.message),
                            if (studio.busy)
                              Text(
                                t(
                                  'Keep this app open. The screen stays awake.',
                                  '앱을 열어 두세요. 화면이 꺼지지 않도록 유지합니다.',
                                  'アプリを開いたままにしてください。画面を点灯したまま処理します。',
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    if (studio.results.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t('Results', '결과', '結果'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          MobileButton(
                            kind: MobileButtonKind.link,
                            onPressed: locked
                                ? null
                                : () => setState(() {
                                    if (selectedResults.length ==
                                        studio.results.length) {
                                      selectedResults.clear();
                                    } else {
                                      selectedResults.addAll(
                                        studio.results.keys,
                                      );
                                    }
                                  }),
                            child: Text(t('Select all', '전체 선택', 'すべて選択')),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          MobileButton.icon(
                            kind: MobileButtonKind.link,
                            onPressed: locked || selectedResults.isEmpty
                                ? null
                                : share,
                            icon: const Icon(f.FluentIcons.share),
                            label: Text(t('Share', '공유', '共有')),
                          ),
                          MobileButton.icon(
                            kind: MobileButtonKind.link,
                            onPressed: locked || selectedResults.isEmpty
                                ? null
                                : deleteSelected,
                            icon: const Icon(f.FluentIcons.delete),
                            label: Text(
                              t('Delete selected', '선택 삭제', '選択した結果を削除'),
                            ),
                          ),
                        ],
                      ),
                      for (final entry in studio.results.entries)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: MobileCard(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      MobileCheck(
                                        value: selectedResults.contains(
                                          entry.key,
                                        ),
                                        onChanged: locked
                                            ? null
                                            : (v) => setState(() {
                                                if (v == true) {
                                                  selectedResults.add(
                                                    entry.key,
                                                  );
                                                } else {
                                                  selectedResults.remove(
                                                    entry.key,
                                                  );
                                                }
                                              }),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          studio.items
                                                  .where(
                                                    (i) => i.path == entry.key,
                                                  )
                                                  .firstOrNull
                                                  ?.name ??
                                              'Collection',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () => f.showDialog<void>(
                                      context: context,
                                      builder: (context) => MobilePreviewDialog(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      t(
                                                        'Preview',
                                                        '미리보기',
                                                        'プレビュー',
                                                      ),
                                                    ),
                                                  ),
                                                  MobileIconButton(
                                                    tooltip: t(
                                                      'Close',
                                                      '닫기',
                                                      '閉じる',
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    icon: const Icon(
                                                      f.FluentIcons.cancel,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Flexible(
                                                child: InteractiveViewer(
                                                  child: Image.file(
                                                    File(entry.value.path),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Image.file(
                                      File(entry.value.path),
                                      fit: BoxFit.contain,
                                      height: 220,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (studio.fitted[entry.key] case final fit?)
                                    Text(resultDetails(entry.key, fit)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xffe5e5e5))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: studio.busy
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MobileProgress(value: studio.progress),
                      const SizedBox(height: 8),
                      Text(
                        '${(studio.progress * 100).round()}% · ${studio.message}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      MobileButton.icon(
                        kind: MobileButtonKind.standard,
                        onPressed: cancelling ? null : stop,
                        icon: const Icon(f.FluentIcons.stop),
                        label: Text(t('Stop', '생성 중지', '停止')),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (studio.results.isNotEmpty) ...[
                        MobileButton.icon(
                          kind: MobileButtonKind.primary,
                          onPressed: locked || selectedResults.isEmpty
                              ? null
                              : save,
                          icon: const Icon(f.FluentIcons.download),
                          label: Text(
                            saving
                                ? t('Saving…', '저장 중…', '保存中…')
                                : t(
                                    'Save ${selectedResults.length} to gallery',
                                    '${selectedResults.length}개 갤러리에 저장',
                                    '${selectedResults.length}個をギャラリーに保存',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (studio.results.isEmpty)
                        MobileButton.icon(
                          kind: MobileButtonKind.primary,
                          onPressed:
                              locked ||
                                  !studio.items.any((i) => i.metadata != null)
                              ? null
                              : generate,
                          icon: const Icon(f.FluentIcons.photo_collection),
                          label: Text(
                            t('Create collection', '모음 만들기', '一覧を作成'),
                          ),
                        )
                      else
                        MobileButton(
                          kind: MobileButtonKind.standard,
                          onPressed: locked ? null : generate,
                          child: Text(t('Create again', '다시 만들기', 'もう一度作成')),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

class MobileVideoPreview extends StatefulWidget {
  final String path;
  final bool enabled;
  const MobileVideoPreview({
    super.key,
    required this.path,
    this.enabled = true,
  });
  @override
  State<MobileVideoPreview> createState() => _MobileVideoPreviewState();
}

class _MobileVideoPreviewState extends State<MobileVideoPreview>
    with WidgetsBindingObserver {
  late final VideoPlayerController player = VideoPlayerController.file(
    File(widget.path),
  );
  bool failed = false;
  @override
  void didUpdateWidget(covariant MobileVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) player.pause();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => failed = true);
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) player.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileCard(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: !player.value.isInitialized
          ? SizedBox(
              height: 180,
              child: Center(
                child: failed
                    ? Text(
                        mobileText(
                          'Preview unavailable. You can still create a collection.',
                          '미리보기를 재생할 수 없습니다. 모음 생성은 가능합니다.',
                          'プレビューを再生できません。一覧は作成できます。',
                        ),
                      )
                    : const f.ProgressRing(),
              ),
            )
          : Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: AspectRatio(
                    aspectRatio: player.value.aspectRatio,
                    child: VideoPlayer(player),
                  ),
                ),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: player,
                  builder: (context, value, _) => Row(
                    children: [
                      MobileIconButton(
                        tooltip: value.isPlaying
                            ? mobileText('Pause', '일시정지', '一時停止')
                            : mobileText('Play', '재생', '再生'),
                        onPressed: !widget.enabled
                            ? null
                            : () => value.isPlaying
                                  ? player.pause()
                                  : player.play(),
                        icon: Icon(
                          value.isPlaying
                              ? f.FluentIcons.pause
                              : f.FluentIcons.play,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            height: 44,
                            child: f.Slider(
                              min: 0,
                              max: value.duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              value: value.position.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                    0,
                                    value.duration.inMilliseconds
                                        .toDouble()
                                        .clamp(1, double.infinity),
                                  ),
                              onChanged: !widget.enabled
                                  ? null
                                  : (position) => player.seekTo(
                                      Duration(milliseconds: position.round()),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(timestamp(value.position.inMilliseconds / 1000)),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}
