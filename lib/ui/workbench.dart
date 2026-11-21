import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import '../core/models.dart';
import '../core/studio_controller.dart';
import 'mascot.dart';
import 'studio_theme.dart';
import '../l10n/studio_strings.dart';

const deskPaper = Color(0xffffffff);
const deskBorder = Color(0xff1b1b1b);
const deskMuted = Color(0xff616161);
const deskTint = Color(0xffe5f1fb);

class DeskButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  const DeskButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !primary) ...[
          Icon(icon, size: 16),
          const SizedBox(width: 7),
        ],
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (icon != null && primary) ...[
          const SizedBox(width: 7),
          Icon(icon, size: 16),
        ],
      ],
    );
    final style = f.ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: primary ? 16 : 12, vertical: 9),
      ),
    );
    return primary
        ? f.FilledButton(onPressed: onPressed, style: style, child: content)
        : f.Button(onPressed: onPressed, style: style, child: content);
  }
}

/// The complete welcome surface is one keyboard-accessible file-picker action.
class UploadLanding extends StatelessWidget {
  final VoidCallback? onPick;
  final bool dragging;
  const UploadLanding({super.key, required this.onPick, this.dragging = false});
  @override
  Widget build(BuildContext context) => Material(
    color: dragging ? deskTint : Colors.white,
    child: InkWell(
      key: const ValueKey('upload-area'),
      onTap: onPick,
      hoverColor: const Color(0xfff6f8fb),
      focusColor: deskTint,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 28,
                          top: 30,
                          child: Transform.rotate(
                            angle: -.17,
                            child: Container(
                              width: 105,
                              height: 105,
                              decoration: BoxDecoration(
                                color: const Color(0xffedf1f5),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 22,
                          top: 45,
                          child: Transform.rotate(
                            angle: .15,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xffdcecf9),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),
                        const MascotArt(MascotPose.select, size: 146),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    dragging ? tx('놓으면 바로 시작해요') : tx('영상을 모아, 한눈에.'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tx('클릭하거나 영상을 끌어놓으세요.\n장면 선택과 배치는 문어에게 맡겨두세요.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: deskMuted,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  f.FilledButton(
                    onPressed: onPick,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(tx('영상 추가')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tx('최대 50개 함께 · 원본 보존 · 내 PC에서 처리'),
                    style: TextStyle(fontSize: 11, color: deskMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class StudioWorkbench extends StatelessWidget {
  final StudioController studio;
  final Widget preview;
  final VoidCallback onPick, onGenerate, onCancel, onResults, onTogglePreview;
  final ValueChanged<QueueItem> onSelect, onRemove;
  final ValueChanged<OutputKind> onKind;
  final bool dragging, showResult;
  const StudioWorkbench({
    super.key,
    required this.studio,
    required this.preview,
    required this.onPick,
    required this.onGenerate,
    required this.onCancel,
    required this.onResults,
    required this.onTogglePreview,
    required this.onSelect,
    required this.onRemove,
    required this.onKind,
    this.dragging = false,
    this.showResult = false,
  });
  @override
  Widget build(BuildContext context) {
    final locked = studio.busy || studio.importing;
    if (studio.items.isEmpty) {
      return UploadLanding(onPick: locked ? null : onPick, dragging: dragging);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: StudioTheme.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        studio.selected?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (studio.results.containsKey(studio.selected?.path))
                      DeskButton(
                        label: showResult ? tx('원본') : tx('만든 모음'),
                        icon: showResult
                            ? Icons.play_circle_outline
                            : Icons.grid_view,
                        onPressed: locked ? null : onTogglePreview,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColoredBox(
                      color: const Color(0xff1f1f1f),
                      child: preview,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      tx('영상 {0}', [studio.items.length]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dragging ? tx('놓아서 추가하세요') : tx('아래에서 미리볼 영상을 선택하세요'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: deskMuted),
                      ),
                    ),
                    if (studio.importing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 204,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  itemCount:
                      studio.items.length + (studio.items.length < 50 ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == studio.items.length) {
                      return SizedBox(
                        width: 116,
                        child: _AddTile(enabled: !locked, onPick: onPick),
                      );
                    }
                    final item = studio.items[index];
                    return SizedBox(
                      width: 176,
                      child: VideoTile(
                        item: item,
                        number: index + 1,
                        selected: studio.selected == item,
                        onSelect: locked ? null : () => onSelect(item),
                        onRemove: locked ? null : () => onRemove(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: const Color(0xffe5e5e5)),
        _StudioOutputPanel(
          studio: studio,
          onKind: onKind,
          onGenerate: onGenerate,
          onCancel: onCancel,
          onResults: onResults,
        ),
      ],
    );
  }
}

class _OutputOption extends StatelessWidget {
  final OutputKind kind;
  final bool selected;
  final VoidCallback? onTap;
  const _OutputOption({required this.kind, required this.selected, this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: selected ? deskTint : Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: selected ? StudioTheme.accent : const Color(0xffe5e5e5),
      ),
    ),
    child: f.RadioButton(
      checked: selected,
      onChanged: onTap == null ? null : (_) => onTap!(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind == OutputKind.sheet ? tx('사진 모음') : tx('움직이는 모음'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            kind == OutputKind.sheet
                ? tx('한 장으로 저장 · PNG')
                : tx('장면이 함께 재생 · WebP'),
            style: const TextStyle(fontSize: 10, color: deskMuted),
          ),
        ],
      ),
    ),
  );
}

class EdgeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const EdgeAction({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    preferBelow: false,
    verticalOffset: 20,
    child: SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: f.IconButton(
          onPressed: onPressed,
          style: const f.ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
          ),
          icon: Icon(icon, size: 16),
        ),
      ),
    ),
  );
}

class VideoTile extends StatelessWidget {
  final QueueItem item;
  final int number;
  final bool selected;
  final VoidCallback? onSelect, onRemove;
  const VideoTile({
    super.key,
    required this.item,
    required this.number,
    required this.selected,
    this.onSelect,
    this.onRemove,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? deskTint : deskPaper,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        key: ValueKey('video-card-${item.path}'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? StudioTheme.accent.withValues(alpha: .5)
                : const Color(0xffe5e5e5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? StudioTheme.accent : deskBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.metadata == null
                        ? ''
                        : timestamp(item.metadata!.duration),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: deskMuted),
                  ),
                ),
                const SizedBox(width: 6),
                EdgeAction(
                  key: ValueKey('remove-${item.path}'),
                  label: tx('이 영상 제외'),
                  icon: Icons.close,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColoredBox(
                  key: ValueKey('video-thumbnail-${item.path}'),
                  color: const Color(0xfff0f0f0),
                  child: item.thumbnailPath == null
                      ? const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: deskMuted,
                            size: 26,
                          ),
                        )
                      : Image.file(
                          File(item.thumbnailPath!),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Tooltip(
              message: item.name,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Tooltip(
              message: item.status,
              child: Text(
                item.status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: deskMuted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddTile extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPick;
  const _AddTile({required this.enabled, required this.onPick});
  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const _DashedOutline(Color(0xffd1d1d1)),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('add-more'),
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, size: 38, color: StudioTheme.green),
            SizedBox(height: 12),
            Text(tx('더 고르기'), style: TextStyle(fontSize: 13, color: deskMuted)),
          ],
        ),
      ),
    ),
  );
}

class _DashedOutline extends CustomPainter {
  final Color color;
  const _DashedOutline(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 9) {
        canvas.drawPath(metric.extractPath(offset, offset + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline oldDelegate) => oldDelegate.color != color;
}

class ResultGallery extends StatelessWidget {
  final StudioController studio;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onEdit, onSave, onToggleAll;
  final bool saving;
  const ResultGallery({
    super.key,
    required this.studio,
    required this.selected,
    required this.onToggle,
    required this.onEdit,
    required this.onSave,
    required this.onToggleAll,
    this.saving = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DeskButton(
              label: tx('작업으로 돌아가기'),
              icon: Icons.arrow_back,
              onPressed: saving ? null : onEdit,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                tx('보관할 모음 {0}개', [studio.results.length]),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            DeskButton(
              label: selected.length == studio.results.length
                  ? tx('전체 해제')
                  : tx('전체 선택'),
              onPressed: saving ? null : onToggleAll,
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: Color(0xffe5e5e5)),
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) => GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: box.maxWidth >= 1050 ? 3 : 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 320,
            ),
            itemCount: studio.results.length,
            itemBuilder: (context, index) {
              final entry = studio.results.entries.elementAt(index);
              final name =
                  studio.items
                      .where((item) => item.path == entry.key)
                      .firstOrNull
                      ?.name ??
                  tx('모음 {0}', [index + 1]);
              return ResultCard(
                sourceKey: entry.key,
                file: entry.value,
                name: name,
                studio: studio,
                checked: selected.contains(entry.key),
                onToggle: saving ? null : () => onToggle(entry.key),
              );
            },
          ),
        ),
      ),
      const Divider(height: 1, color: Color(0xffe5e5e5)),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const MascotArt(MascotPose.complete, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx('이 장면들, 가져가세요.'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    saving ? tx('선택한 폴더에 저장하고 있어요.') : studio.message,
                    style: const TextStyle(color: deskMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            DeskButton(
              label: saving
                  ? tx('저장 중…')
                  : tx('선택한 {0}개 저장', [selected.length]),
              icon: Icons.download_rounded,
              primary: true,
              onPressed: saving || selected.isEmpty ? null : onSave,
            ),
          ],
        ),
      ),
    ],
  );
}

class ResultCard extends StatelessWidget {
  final String sourceKey, name;
  final GeneratedFile file;
  final StudioController studio;
  final bool checked;
  final VoidCallback? onToggle;
  const ResultCard({
    super.key,
    required this.sourceKey,
    required this.name,
    required this.file,
    required this.studio,
    required this.checked,
    this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    final fitted = studio.fitted[sourceKey];
    final meta = studio.items
        .where((item) => item.path == sourceKey)
        .firstOrNull
        ?.metadata;
    String details = '';
    if (fitted != null && meta != null) {
      final plan = SamplePlan.create(fitted.settings, meta, file.kind);
      final layout = SheetLayout.create(
        fitted.settings,
        meta,
        file.kind,
        plan.count,
      );
      details = file.kind == OutputKind.sheet
          ? tx('장면 {0} · {1} × {2}', [plan.count, layout.width, layout.height])
          : tx('장면 {0} · {1} FPS · {2} × {3}', [
              plan.count,
              fitted.settings.fps,
              layout.width,
              layout.height,
            ]);
      if (file.kind != OutputKind.sheet) {
        details += ' · ${tx('구간 {0}초', [plan.clip.toStringAsFixed(2)])}';
      }
    }
    return Material(
      color: checked ? deskTint : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          key: ValueKey('result-card-$sourceKey'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: checked ? StudioTheme.accent : const Color(0xffe5e5e5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    key: ValueKey('result-check-$sourceKey'),
                    width: 36,
                    height: 36,
                    child: Center(
                      child: f.Checkbox(
                        checked: checked,
                        onChanged: onToggle == null ? null : (_) => onToggle!(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: name,
                      child: Text(
                        name,
                        key: ValueKey('result-name-$sourceKey'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EdgeAction(
                    label: tx('크게 보기'),
                    icon: Icons.zoom_in,
                    onPressed: () => f.showDialog<void>(
                      context: context,
                      builder: (context) =>
                          ResultPreview(file: file, name: name),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ColoredBox(
                    color: const Color(0xff1f1f1f),
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          tx('미리보기를 읽지 못했어요.'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (details.isNotEmpty) ...[
                Text(
                  file.kind == OutputKind.animatedSheet && fitted != null
                      ? '$details · ${tx('품질 {0}', [fitted.settings.quality])}'
                      : details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: deskMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              FutureBuilder<int>(
                future: File(file.path).length(),
                builder: (context, snapshot) => Text(
                  '${file.kind == OutputKind.sheet ? tx('PNG · 사진 모음') : tx('WebP · 움직이는 모음')}${snapshot.hasData ? ' · ${(snapshot.data! / 1000000).toStringAsFixed(2)} MB' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: deskMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultPreview extends StatelessWidget {
  final GeneratedFile file;
  final String name;
  const ResultPreview({super.key, required this.file, required this.name});
  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('result-preview-dialog'),
    insetPadding: const EdgeInsets.all(24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * .85,
        height: MediaQuery.sizeOf(context).height * .8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                EdgeAction(
                  key: const ValueKey('preview-close'),
                  label: tx('닫기'),
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRect(
                child: InteractiveViewer(
                  minScale: .5,
                  maxScale: 8,
                  child: Center(
                    child: Image.file(File(file.path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingSelect<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;
  const _SettingSelect({
    required this.label,
    required this.value,
    required this.options,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: deskMuted)),
        const SizedBox(height: 4),
        f.ComboBox<T>(
          value: value,
          isExpanded: true,
          items: options.entries
              .map(
                (entry) => f.ComboBoxItem<T>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged == null
              ? null
              : (value) {
                  if (value != null) onChanged!(value);
                },
        ),
      ],
    ),
  );
}

class _AdvancedOptions extends StatefulWidget {
  final StudioController studio;
  const _AdvancedOptions({required this.studio});
  @override
  State<_AdvancedOptions> createState() => _AdvancedOptionsState();
}

class _AdvancedOptionsState extends State<_AdvancedOptions> {
  @override
  Widget build(BuildContext context) {
    final studio = widget.studio;
    return f.ContentDialog(
      title: Text(tx('고급 설정')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(tx('FPS 자동'))),
                  const SizedBox(width: 16),
                  f.ToggleSwitch(
                    key: const ValueKey('advanced-auto-fps-switch'),
                    checked: studio.autoFps,
                    onChanged: studio.kind == OutputKind.sheet
                        ? null
                        : (value) => setState(() {
                            studio.autoFps = value;
                            studio.savePreferences();
                          }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(tx('원본 FPS와 구간 길이에 맞춰 자동으로 조절합니다.')),
              const SizedBox(height: 12),
              Text(
                '${tx('애니메이션 FPS')}: ${studio.autoFps ? studio.settings(studio.selected?.metadata).fps : studio.fps}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SizedBox(
                  height: 44,
                  child: f.Slider(
                    key: const ValueKey('advanced-fps-slider'),
                    value: studio.fps.toDouble(),
                    min: 4,
                    max: 30,
                    divisions: 26,
                    onChanged: studio.kind == OutputKind.sheet || studio.autoFps
                        ? null
                        : (value) => setState(() {
                            studio.fps = value.round();
                            studio.savePreferences();
                          }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(
                key: const ValueKey('advanced-auto-clip-row'),
                children: [
                  Expanded(child: Text(tx('구간 길이 자동'))),
                  const SizedBox(width: 16),
                  f.ToggleSwitch(
                    key: const ValueKey('advanced-auto-clip-switch'),
                    checked: studio.autoClip,
                    onChanged: studio.kind == OutputKind.sheet
                        ? null
                        : (value) => setState(() {
                            studio.autoClip = value;
                            studio.savePreferences();
                          }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(tx('영상 길이와 장면 수에 맞춰 최대 10초까지 자동으로 정합니다.')),
              const SizedBox(height: 8),
              Text(
                '${tx('구간 길이 (초)')}: ${studio.autoClip ? tx('자동') : studio.clipSeconds}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: SizedBox(
                  height: 44,
                  child: f.Slider(
                    key: const ValueKey('advanced-clip-slider'),
                    value: studio.clipSeconds,
                    min: .5,
                    max: 10,
                    divisions: 19,
                    onChanged:
                        studio.kind == OutputKind.sheet || studio.autoClip
                        ? null
                        : (value) => setState(() {
                            studio.clipSeconds = (value * 2).round() / 2;
                            studio.savePreferences();
                          }),
                  ),
                ),
              ),
              if (studio.kind == OutputKind.sheet)
                Text(tx('사진 모음에는 FPS와 구간 길이를 적용하지 않습니다.')),
              const SizedBox(height: 16),
              f.HyperlinkButton(
                onPressed: () {
                  studio.resetPreferences();
                  setState(() {});
                },
                child: Text(tx('설정 초기화')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        f.HyperlinkButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tx('닫기')),
        ),
      ],
    );
  }
}

class _StudioOutputPanel extends StatelessWidget {
  final StudioController studio;
  final ValueChanged<OutputKind> onKind;
  final VoidCallback onGenerate, onCancel, onResults;
  const _StudioOutputPanel({
    required this.studio,
    required this.onKind,
    required this.onGenerate,
    required this.onCancel,
    required this.onResults,
  });
  @override
  Widget build(BuildContext context) {
    final locked = studio.busy || studio.importing;
    final metadata = studio.selected?.metadata;
    final options = studio.settings(metadata);
    final plan = metadata == null
        ? null
        : SamplePlan.create(options, metadata, studio.kind);
    return SizedBox(
      width: 264,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tx('모음 만들기'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tx('어떤 모습으로 담을까요?'),
                    style: const TextStyle(fontSize: 12, color: deskMuted),
                  ),
                  const SizedBox(height: 18),
                  for (final kind in [
                    OutputKind.animatedSheet,
                    OutputKind.sheet,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OutputOption(
                        kind: kind,
                        selected: studio.kind == kind,
                        onTap: locked ? null : () => onKind(kind),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SettingSelect<int>(
                    label: tx('장면 수'),
                    value: studio.sceneLimit,
                    options: {0: tx('자동'), 4: '4', 8: '8', 12: '12', 24: '24'},
                    onChanged: locked
                        ? null
                        : (value) {
                            studio.sceneLimit = value;
                            studio.savePreferences();
                          },
                  ),
                  _SettingSelect<String>(
                    label: tx('모음 배치'),
                    value: studio.layoutShape,
                    options: {
                      'auto': tx('자동'),
                      '16:9': tx('가로'),
                      '9:16': tx('세로'),
                    },
                    onChanged: locked
                        ? null
                        : (value) {
                            studio.layoutShape = value;
                            studio.savePreferences();
                          },
                  ),
                  _SettingSelect<String>(
                    label: tx('장면 비율'),
                    value: studio.sceneAspect,
                    options: {
                      'source': tx('원본 비율'),
                      '1:1': tx('정사각형'),
                      '16:9': '16:9',
                      '9:16': '9:16',
                    },
                    onChanged: locked
                        ? null
                        : (value) {
                            studio.sceneAspect = value;
                            studio.savePreferences();
                          },
                  ),
                  _SettingSelect<int>(
                    label: tx('파일당 최대 용량'),
                    value: studio.targetMb,
                    options: {
                      0: tx('제한 없음'),
                      1: '1 MB',
                      5: '5 MB',
                      10: '10 MB',
                      20: '20 MB',
                      50: '50 MB',
                      100: '100 MB',
                    },
                    onChanged: locked
                        ? null
                        : (value) {
                            studio.targetMb = value;
                            studio.savePreferences();
                          },
                  ),
                  Text(
                    tx('실제 크기를 측정해 용량에 맞춥니다.'),
                    style: const TextStyle(fontSize: 10, color: deskMuted),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: f.HyperlinkButton(
                      onPressed: locked
                          ? null
                          : () => f.showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  _AdvancedOptions(studio: studio),
                            ),
                      child: Text(tx('고급 설정')),
                    ),
                  ),
                  if (plan != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: deskTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        studio.kind == OutputKind.sheet
                            ? tx('장면 {0} · {1} × {2}', [
                                plan.count,
                                metadata!.width,
                                metadata.height,
                              ])
                            : tx('예상 장면 {0}개 · {1} FPS · {2}초', [
                                plan.count,
                                options.fps,
                                plan.clip.toStringAsFixed(2),
                              ]),
                        style: const TextStyle(fontSize: 11, color: deskMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xffe5e5e5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (studio.results.isNotEmpty) ...[
                  DeskButton(
                    label: tx('보관할 모음 {0}개', [studio.results.length]),
                    icon: Icons.collections_outlined,
                    onPressed: locked ? null : onResults,
                  ),
                  const SizedBox(height: 8),
                ],
                if (!studio.busy && !studio.importing) ...[
                  Text(
                    studio.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: deskMuted),
                  ),
                  const SizedBox(height: 8),
                ],
                if (studio.busy || studio.importing) ...[
                  Text(
                    studio.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: deskMuted),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: studio.importing ? null : studio.progress,
                    minHeight: 3,
                  ),
                  const SizedBox(height: 12),
                ],
                DeskButton(
                  label: studio.busy
                      ? tx('생성 중지')
                      : studio.items.length > 1
                      ? tx('{0}개 모음 만들기', [studio.items.length])
                      : tx('모음 만들기'),
                  icon: studio.busy
                      ? Icons.stop_rounded
                      : Icons.arrow_forward_rounded,
                  primary: !studio.busy,
                  onPressed: studio.busy
                      ? onCancel
                      : locked ||
                            !studio.items.any((item) => item.metadata != null)
                      ? null
                      : onGenerate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
