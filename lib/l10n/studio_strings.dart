import 'app_language.dart';

// New desktop copy lives here; the inherited processor retains its own catalog.
const desktopCopy = <String, List<String>>{
  '표시 옵션': ['Appearance', '表示'],
  '타임스탬프 표시': ['Show timestamps', 'タイムスタンプを表示'],
  '각 장면의 원본 영상 시작 시간을 표시합니다.': [
    'Show each scene’s start time in the source video.',
    '元動画における各シーンの開始時刻を表示します。',
  ],
  '애니메이션': ['Animation', 'アニメーション'],
  '품질 최적화 {0} · {1}': ['Optimizing quality {0} · {1}', '画質最適化 {0} · {1}'],
  '품질 {0}': ['Quality {0}', '画質 {0}'],
  '크게 보기': ['Zoom preview', '拡大表示'],
  '장면 {0} · {1} × {2}': ['{0} scenes · {1} × {2}', '{0}シーン · {1} × {2}'],
  '장면 {0} · {1} FPS · {2} × {3}': [
    '{0} scenes · {1} FPS · {2} × {3}',
    '{0}シーン · {1} FPS · {2} × {3}',
  ],
  '영상을 모아, 한눈에.': ['Your videos. One view.', '動画をまとめて、ひと目で。'],
  '놓으면 바로 시작해요': ['Drop to get started', 'ドロップして開始'],
  '클릭하거나 영상을 끌어놓으세요.\n장면 선택과 배치는 문어에게 맡겨두세요.': [
    'Click or drop videos here.\nLet Octopus pick and arrange the scenes.',
    'クリック、または動画をドロップ。\nシーンの選択と配置はおまかせ。',
  ],
  '영상 추가': ['Add videos', '動画を追加'],
  '최대 50개 함께 · 원본 보존 · 내 PC에서 처리': [
    'Up to 50 videos · Originals preserved · On this PC',
    '最大50本 · 元動画を保持 · PC内で処理',
  ],
  '놓아서 추가하세요': ['Drop to add', 'ドロップして追加'],
  '아래에서 미리볼 영상을 선택하세요': ['Choose a video below to preview', '下の動画を選択してプレビュー'],
  '모음 만들기': ['Create collection', '一覧を作成'],
  '어떤 모습으로 담을까요?': ['Choose your output', '出力形式を選択'],
  '자동으로 준비해요': ['Ready automatically', '自動で準備します'],
  '원본 비율 유지 · 장면 자동 선택': [
    'Original ratio · Automatic scenes',
    '元の比率 · シーン自動選択',
  ],
  '장면 고르는 일은\n제가 할게요.': [
    'I will pick\nthe scenes for you.',
    'シーン選びは\nおまかせください。',
  ],
  '생성 중지': ['Stop', '停止'],
  '원본': ['Original', '元動画'],
  '만든 모음': ['Collection', '作成した一覧'],
  '사진 모음': ['Still sheet', '静止画一覧'],
  '움직이는 모음': ['Animated sheet', 'アニメーション一覧'],
  '한 장으로 저장 · PNG': ['One image · PNG', '1枚の画像 · PNG'],
  '장면이 함께 재생 · WebP': ['Scenes play together · WebP', 'シーンを同時再生 · WebP'],
  '이 영상 제외': ['Remove from queue', '一覧から除外'],
  '더 고르기': ['Add more', '追加'],
  '작업으로 돌아가기': ['Back to editing', '編集に戻る'],
  '전체 해제': ['Deselect all', 'すべて解除'],
  '전체 선택': ['Select all', 'すべて選択'],
  '미리보기를 읽지 못했어요.': ['Preview unavailable.', 'プレビューを読み込めません。'],
  'PNG · 사진 모음': ['PNG · Still sheet', 'PNG · 静止画一覧'],
  'WebP · 움직이는 모음': ['WebP · Animated sheet', 'WebP · アニメーション一覧'],
  '이 장면들, 가져가세요.': ['Your scenes are ready.', 'シーンの準備ができました。'],
  '선택한 폴더에 저장하고 있어요.': ['Saving to your folder…', '選択したフォルダーに保存中…'],
  '저장 중…': ['Saving…', '保存中…'],
  '나만의 장면 보관함': ['Your scene collection', '自分だけのシーン集'],
  '영상을 확인하고 있어요…': ['Reading video…', '動画を確認中…'],
  '이 PC에서만 처리해요. 원본 영상은 그대로 보관됩니다.': [
    'Processed on this PC. Original videos stay untouched.',
    'このPC内で処理します。元動画は変更しません。',
  ],
  '미리보기를 재생하지 못했어요. 다른 영상을 확인해 주세요.': [
    'Could not play the preview. Please try another video.',
    '再生できません。別の動画を確認してください。',
  ],
  'MP4, MOV, MKV, WebM, AVI, M4V 영상을 골라주세요.': [
    'Choose an MP4, MOV, MKV, WebM, AVI or M4V video.',
    'MP4、MOV、MKV、WebM、AVI、M4Vの動画を選択してください。',
  ],
  '파일 선택 창을 열지 못했어요. 영상을 끌어놓아 주세요.': [
    'Could not open the picker. Try dropping videos here.',
    '選択画面を開けません。動画をドロップしてください。',
  ],
  '선택한 모음을 저장할 폴더': ['Folder for selected collections', '選択した一覧の保存先'],
  '저장하지 못했습니다. 폴더의 쓰기 권한을 확인하세요.': [
    'Could not save. Check folder write permissions.',
    '保存できません。フォルダーの書き込み権限を確認してください。',
  ],
  '영상을 넣으면 자동으로 장면을 골라드려요.': [
    'Add videos to select scenes automatically.',
    '動画を追加するとシーンを自動選択します。',
  ],
  '영상은 최대 50개까지 함께 처리할 수 있어요.': [
    'Process up to 50 videos together.',
    '最大50本の動画をまとめて処理できます。',
  ],
  '중지했습니다. 완료된 결과는 유지됩니다.': [
    'Stopped. Finished results are kept.',
    '停止しました。完了した結果は保持されます。',
  ],
  '장면 수': ['Scenes', 'シーン数'],
  '자동': ['Automatic', '自動'],
  '용량 예측 {0}': ['Estimating size · sample {0}', '容量を予測中 · サンプル{0}'],
  '모음 배치': ['Layout', '配置'],
  '가로': ['Wide', '横長'],
  '세로': ['Tall', '縦長'],
  '장면 비율': ['Scene ratio', 'シーン比率'],
  '원본 비율': ['Original ratio', '元の比率'],
  '정사각형': ['Square', '正方形'],
  '파일당 최대 용량': ['Maximum per file', '1ファイルの上限'],
  '제한 없음': ['No limit', '制限なし'],
  '고급 설정': ['Advanced', '詳細設定'],
  '구간 길이 (초)': ['Clip length (seconds)', '区間の長さ（秒）'],
  '구간 길이 자동': ['Automatic clip length', '区間の長さを自動設定'],
  'FPS 자동': ['Automatic FPS', 'FPSを自動設定'],
  '원본 FPS와 구간 길이에 맞춰 자동으로 조절합니다.': [
    'Uses the source frame rate and clip length to set FPS automatically.',
    '元動画のFPSと区間の長さに合わせて自動調整します。',
  ],
  '구간 {0}초': ['{0}s per scene', '各シーン{0}秒'],
  '영상 길이와 장면 수에 맞춰 최대 10초까지 자동으로 정합니다.': [
    'Uses video length and usable scenes, up to 10 seconds per scene.',
    '動画の長さとシーン数に合わせて、各区間を最大10秒まで自動設定します。',
  ],
  '애니메이션 FPS': ['Animation FPS', 'アニメーションFPS'],
  '닫기': ['Close', '閉じる'],
  '앱 정보 및 라이선스': ['About and licenses', 'アプリ情報とライセンス'],
  '개인정보 처리방침': ['Privacy policy', 'プライバシーポリシー'],
  '설정 초기화': ['Reset settings', '設定をリセット'],
  '용량 한도에 맞추지 못했습니다. 한도를 늘리거나 영상 구간을 줄여주세요.': [
    'Could not fit the limit. Increase it or shorten the clips.',
    '上限に収まりません。上限を増やすか区間を短くしてください。',
  ],
  '실제 크기를 측정해 용량에 맞춥니다.': [
    'Measured output is fitted to your limit.',
    '実際の出力サイズを測定して調整します。',
  ],
  '생성 중에는 앱을 닫을 수 없습니다. 먼저 중지해 주세요.': [
    'Stop generation before closing the app.',
    '作成を停止してからアプリを閉じてください。',
  ],
  '사진 모음에는 FPS와 구간 길이를 적용하지 않습니다.': [
    'FPS and clip length apply only to animation.',
    'FPSと区間の長さはアニメーションのみに適用します。',
  ],
  '예상 장면 {0}개 · {1} FPS · {2}초': [
    'Up to {0} scenes · {1} FPS · {2}s',
    '最大{0}シーン · {1} FPS · {2}秒',
  ],
  '영상 {0}': ['Videos {0}', '動画 {0}'],
  '모음 {0}': ['Collection {0}', '一覧 {0}'],
  '{0}개 모음 만들기': ['Create {0} collections', '{0}個の一覧を作成'],
  '보관할 모음 {0}개': ['Collections to keep: {0}', '保存する一覧：{0}'],
  '선택한 {0}개 저장': ['Save {0} selected', '選択した{0}個を保存'],
  '{0}개 영상을 확인했습니다.': ['{0} videos ready.', '{0}本の動画を確認しました。'],
  '{0}개 저장했습니다.': ['Saved {0} files.', '{0}個を保存しました。'],
  '{0}개 완료 · {1}개 실패': ['{0} completed · {1} failed', '{0}個完了 · {1}個失敗'],
  '용량 조정 {0}/8 · {1}': ['Fitting size {0}/8 · {1}', '容量調整 {0}/8 · {1}'],
  '목표 {0} MB 이하': ['Target ≤ {0} MB', '目標 {0} MB以下'],
  '실제 {0} MB · {1}장면': ['Actual {0} MB · {1} scenes', '実測 {0} MB · {1}シーン'],
};
String tx(String key, [List<Object?> args = const []]) {
  final code = AppLanguage.instance.code;
  final value = code == 'ko'
      ? key
      : desktopCopy[key]?[code == 'ja' ? 1 : 0] ?? key;
  return value.replaceAllMapped(RegExp(r'\{(\d+)\}'), (m) {
    final index = int.parse(m[1]!);
    return index < args.length ? '${args[index]}' : m[0]!;
  });
}
