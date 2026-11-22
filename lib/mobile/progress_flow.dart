import 'package:flutter/material.dart';
import '../core/studio_controller.dart';
import '../ui/mascot.dart';
import 'fluent_mobile.dart';
import 'mobile_strings.dart';

enum MobileStage { selection, processing, complete }

class MobileStageIndicator extends StatelessWidget {
  final MobileStage stage;
  const MobileStageIndicator({super.key, required this.stage});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final value in MobileStage.values) ...[
        if (value.index > 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('›', style: TextStyle(color: Color(0xff8a8886))),
          ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: stage == value
                      ? const Color(0xff0078d4)
                      : const Color(0xffe5e5e5),
                ),
              ),
            ),
            child: Text(
              switch (value) {
                MobileStage.selection => mobileText('Select', '선택', '選択'),
                MobileStage.processing => mobileText('Creating', '진행 중', '作成中'),
                MobileStage.complete => mobileText('Complete', '완료', '完了'),
              },
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: stage == value
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: stage == value
                    ? const Color(0xff0067b8)
                    : const Color(0xff616161),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class MobileProcessingView extends StatelessWidget {
  final StudioController studio;
  final bool preparing;
  final bool cancelling;
  const MobileProcessingView({
    super.key,
    required this.studio,
    required this.preparing,
    required this.cancelling,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MobileStageIndicator(stage: MobileStage.processing),
            const SizedBox(height: 24),
            MobileCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LoadingMascot(size: 116)),
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        preparing
                            ? mobileText(
                                'Preparing your videos',
                                '영상을 준비하고 있어요',
                                '動画を準備しています',
                              )
                            : cancelling
                            ? mobileText('Stopping…', '중지하고 있어요…', '停止しています…')
                            : mobileText(
                                'Creating your collection',
                                '모음을 만들고 있어요',
                                '一覧を作成しています',
                              ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!preparing) ...[
                      Text(
                        '${(studio.progress.clamp(0, 1) * 100).round()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    MobileProgress(
                      value: preparing ? null : studio.progress.clamp(0, 1),
                    ),
                    const SizedBox(height: 20),
                    if (studio.activeItem != null) ...[
                      Text(
                        '${studio.activeJobIndex} / ${studio.activeJobCount}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        studio.activeItem!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      preparing
                          ? mobileText(
                              'Reading the selected videos. Please wait.',
                              '선택한 영상을 확인하고 있습니다. 잠시 기다려 주세요.',
                              '選択した動画を確認しています。しばらくお待ちください。',
                            )
                          : mobileText(
                              'Keep this app open. Completed results appear automatically.',
                              '앱을 열어 두세요. 끝나면 결과가 자동으로 표시됩니다.',
                              'アプリを開いたままにしてください。完了すると結果を表示します。',
                            ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
