"""Generate the static, script-free Firebase Hosting privacy pages."""
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBLIC = ROOT / "hosting" / "public"
UPDATED = "2026-11-22"
CONTENT = {
    "en": {
        "title": "Privacy policy",
        "updated": "Last updated: November 22, 2026",
        "summary": "Your videos are processed on your device. You choose what to save or share.",
        "intro": "This policy covers Frame Octopus for Windows and Android, and this privacy website. Frame Octopus creates still PNG and animated WebP contact sheets from videos.",
        "sections": [
            ("Local media processing", [
                "Video selection, playback, scene sampling and image encoding take place on your device. The app does not upload source videos or generated images to the developer or Firebase. Source videos are not modified.",
                "On Android, the system picker grants access to the videos you select. The app copies selected videos into its private cache to process them. Saving uses the system media library; older Android versions may request storage permission when saving. Windows uses the files and destination folders you choose.",
            ]),
            ("Preferences, temporary files and results", [
                "Language and output preferences are stored locally. Preview thumbnails, imported copies and encoding intermediates are stored in app-private or temporary folders. Generated results are kept locally for preview and export.",
                "On Android, previous-session imports, thumbnails, processing intermediates and private results are cleared on the next cold start. Save results you want to keep to your gallery before exiting. On Windows, retained private results can be removed from the Frame Octopus application support folder after closing the app. Operating systems may also clear temporary storage.",
                "Deleting an app result does not delete its original video or copies already saved to a gallery or another folder. Manage exported copies with your gallery or file manager. Uninstalling the app generally removes its private data; exported copies are managed separately by the operating system.",
            ]),
            ("Accounts and tracking", [
                "This release does not require an account and does not enable advertising, Google Analytics, Firebase Crashlytics, Firebase Authentication, cloud media storage or behavioral tracking. The developer does not operate an account, media-upload or analytics backend for this release.",
                "The Android app initializes Firebase Core to associate the app with the Frame Octopus Firebase project. This project connection does not add a media-upload feature. Local video processing remains independent of cloud services.",
            ]),
            ("This website and Firebase Hosting", [
                "This privacy website is delivered by Google Firebase Hosting. When you visit it, Google processes technical request information, including your IP address, to deliver and protect the service. Firebase states that Hosting retains IP data for a few months. Hosting uses global infrastructure, so technical data may be processed outside your country.",
                "We do not add analytics scripts, advertising, contact forms or tracking cookies to these pages. Google's processing is described in its privacy and Firebase privacy information linked below.",
            ]),
            ("Sharing, support and platform services", [
                "If you choose Share, Android passes selected results to the destination app you select. That app's privacy policy then applies. No destination is selected or contacted automatically by Frame Octopus.",
                "Microsoft Store, Google Play, Windows and Android may process installation, updates, account or diagnostic information under their own policies. Opening this policy or another external link uses your browser and an internet connection.",
                "If you email support, we receive your email address and the contents you choose to send, and use them to respond. Do not attach private videos unless you intend to share them. We keep support correspondence only as needed to handle the inquiry or meet applicable obligations; you may request deletion by email.",
            ]),
            ("Your choices and privacy requests", [
                "You can stop processing, delete app results, change or reset local preferences, remove gallery exports, revoke media access in system settings or uninstall the app. We do not hold a server-side copy of your locally processed videos to retrieve or delete.",
                "For questions, access or deletion requests relating to support correspondence, contact the developer using the address below. We do not knowingly request children's personal information through the app. If you believe a child sent personal information to support, contact us to request its removal.",
            ]),
            ("Changes and contact", [
                "We will update this page and its date when the app's data practices change. Developer and privacy contact: Jeyoung Lee (이제영), idlepoe@gmail.com.",
            ]),
        ],
    },
    "ko": {
        "title": "개인정보처리방침",
        "updated": "최종 수정일: 2026년 11월 22일",
        "summary": "영상은 사용자 기기에서 처리됩니다. 저장과 공유는 사용자가 선택합니다.",
        "intro": "이 방침은 Windows 및 Android용 Frame Octopus 앱과 이 개인정보처리방침 웹사이트에 적용됩니다. Frame Octopus는 영상의 여러 장면을 정지 PNG 또는 움직이는 WebP 모음으로 만듭니다.",
        "sections": [
            ("기기 내 영상 처리", [
                "영상 선택, 재생, 장면 추출 및 이미지 인코딩은 사용자 기기에서 이루어집니다. 앱은 원본 영상이나 생성한 이미지를 개발자 또는 Firebase로 업로드하지 않으며 원본 영상을 수정하지 않습니다.",
                "Android에서는 시스템 선택기를 통해 사용자가 선택한 영상에 접근하며, 처리를 위해 앱 전용 캐시에 복사합니다. 저장에는 시스템 미디어 보관함을 사용하며, 구형 Android에서는 저장 시 저장 공간 권한을 요청할 수 있습니다. Windows에서는 사용자가 선택한 파일과 저장 폴더를 사용합니다.",
            ]),
            ("설정, 임시 파일 및 결과", [
                "언어와 출력 설정은 기기에 저장됩니다. 미리보기 썸네일, 불러온 영상의 복사본 및 인코딩 중간 파일은 앱 전용 또는 임시 폴더에 저장됩니다. 생성 결과는 미리보기와 내보내기를 위해 기기에 보관됩니다.",
                "Android에서는 앱을 새로 시작할 때 이전 세션의 불러온 복사본, 썸네일, 처리 중간 파일 및 앱 전용 결과를 정리합니다. 보관하려는 결과는 종료 전에 갤러리에 저장하세요. Windows의 앱 전용 결과는 앱 종료 후 Frame Octopus 애플리케이션 지원 폴더에서 삭제할 수 있습니다. 운영체제도 임시 저장 공간을 정리할 수 있습니다.",
                "앱에서 결과를 삭제해도 원본 영상이나 이미 갤러리·다른 폴더에 저장한 복사본은 삭제되지 않습니다. 내보낸 파일은 갤러리나 파일 관리자로 관리하세요. 앱 삭제 시 일반적으로 앱 전용 데이터는 제거되며, 내보낸 파일은 운영체제에서 별도로 관리됩니다.",
            ]),
            ("계정과 추적", [
                "현재 버전은 계정 가입을 요구하지 않으며 광고, Google Analytics, Firebase Crashlytics, Firebase Authentication, 클라우드 미디어 저장 또는 행동 추적을 활성화하지 않습니다. 개발자는 현재 버전을 위한 계정·미디어 업로드·분석 서버를 운영하지 않습니다.",
                "Android 앱은 Frame Octopus Firebase 프로젝트와 앱을 연결하기 위해 Firebase Core를 초기화합니다. 이 프로젝트 연결은 영상 업로드 기능을 추가하지 않으며, 기기 내 영상 처리는 클라우드 서비스와 독립적으로 동작합니다.",
            ]),
            ("웹사이트와 Firebase Hosting", [
                "이 개인정보처리방침 웹사이트는 Google Firebase Hosting으로 제공됩니다. 방문 시 Google은 콘텐츠 제공과 서비스 보호를 위해 IP 주소를 포함한 기술적 요청 정보를 처리합니다. Firebase 안내에 따르면 Hosting의 IP 데이터 보관 기간은 수개월입니다. 글로벌 인프라를 사용하므로 기술적 데이터가 거주 국가 밖에서 처리될 수 있습니다.",
                "이 페이지에는 분석 스크립트, 광고, 문의 입력 양식 또는 추적 쿠키를 추가하지 않습니다. Google의 처리 방식은 아래에 연결된 Google 개인정보처리방침 및 Firebase 개인정보 안내에서 확인할 수 있습니다.",
            ]),
            ("공유, 문의 및 플랫폼 서비스", [
                "공유를 선택하면 Android가 선택한 결과를 사용자가 지정한 대상 앱에 전달합니다. 이후에는 해당 앱의 개인정보처리방침이 적용됩니다. Frame Octopus가 공유 대상을 자동으로 선택하거나 연락하지 않습니다.",
                "Microsoft Store, Google Play, Windows 및 Android는 자체 방침에 따라 설치, 업데이트, 계정 또는 진단 정보를 처리할 수 있습니다. 이 방침이나 외부 링크를 열면 브라우저와 인터넷 연결을 사용합니다.",
                "이메일로 문의하면 개발자는 이메일 주소와 사용자가 보낸 내용을 받아 답변에 사용합니다. 공유할 의도가 없다면 개인 영상을 첨부하지 마세요. 문의 내역은 답변 처리나 관련 의무 이행에 필요한 범위에서 보관하며 이메일로 삭제를 요청할 수 있습니다.",
            ]),
            ("사용자 선택과 개인정보 요청", [
                "처리 중지, 앱 결과 삭제, 기기 설정 변경·초기화, 갤러리 파일 삭제, 시스템 설정의 미디어 접근 철회 또는 앱 제거가 가능합니다. 개발자는 기기에서 처리한 영상의 서버 사본을 보유하지 않으므로 해당 영상을 조회하거나 서버에서 삭제할 수 없습니다.",
                "문의 내역에 대한 열람·삭제 요청 또는 개인정보 관련 질문은 아래 연락처로 보내주세요. 앱을 통해 아동의 개인정보를 의도적으로 요청하지 않습니다. 아동이 문의 이메일로 개인정보를 보냈다고 판단되면 삭제를 요청할 수 있습니다.",
            ]),
            ("변경 및 연락처", [
                "앱의 데이터 처리 방식이 변경되면 이 페이지와 수정일을 갱신합니다. 개발자 및 개인정보 문의: 이제영 (Jeyoung Lee), idlepoe@gmail.com.",
            ]),
        ],
    },
    "ja": {
        "title": "プライバシーポリシー",
        "updated": "最終更新日：2026年11月22日",
        "summary": "動画はお使いの端末内で処理します。保存と共有は利用者が選択します。",
        "intro": "本ポリシーはWindows・Android版Frame Octopusと、このプライバシーサイトに適用されます。Frame Octopusは動画の複数シーンから静止PNGまたはアニメーションWebPの一覧画像を作成します。",
        "sections": [
            ("端末内での動画処理", [
                "動画の選択・再生、シーン抽出、画像エンコードは端末内で行います。元動画や作成画像を開発者やFirebaseにアップロードせず、元動画を変更しません。",
                "Androidではシステムの選択画面で選んだ動画にアクセスし、処理用のコピーをアプリ専用キャッシュに作成します。保存にはシステムのメディアライブラリを使用し、古いAndroidでは保存時にストレージ権限を求める場合があります。Windowsでは選択したファイルと保存先を使用します。",
            ]),
            ("設定、一時ファイル、作成結果", [
                "言語と出力設定は端末に保存します。サムネイル、読み込んだ動画のコピー、処理中間ファイルはアプリ専用または一時フォルダーに保存します。作成結果はプレビューと書き出しのため端末内に保持します。",
                "Androidでは次回のコールドスタート時に前回セッションの読み込みコピー、サムネイル、中間ファイル、アプリ専用の作成結果を削除します。必要な結果は終了前にギャラリーへ保存してください。Windowsでは終了後にFrame Octopusのアプリケーションサポートフォルダーから保持結果を削除できます。OSが一時ファイルを削除する場合もあります。",
                "アプリの結果を削除しても、元動画やギャラリー・別フォルダーへ保存済みのコピーは削除しません。書き出したファイルはギャラリーやファイル管理アプリで管理してください。アンインストールすると通常はアプリ専用データが削除され、書き出したコピーはOSが別途管理します。",
            ]),
            ("アカウントと追跡", [
                "現在のバージョンではアカウント登録は不要です。広告、Google Analytics、Firebase Crashlytics、Firebase Authentication、クラウドへのメディア保存、行動追跡を有効にしていません。開発者はこのバージョン向けのアカウント・メディアアップロード・分析サーバーを運用していません。",
                "AndroidアプリはFrame OctopusのFirebaseプロジェクトと関連付けるためFirebase Coreを初期化します。この接続に動画アップロード機能は含まれず、端末内の動画処理はクラウドサービスから独立しています。",
            ]),
            ("ウェブサイトとFirebase Hosting", [
                "このサイトはGoogle Firebase Hostingで配信します。訪問時にGoogleは配信とサービス保護のためIPアドレスを含む技術的なリクエスト情報を処理します。Firebaseの説明によるとHostingのIPデータは数か月保持されます。グローバルなインフラを使用するため、居住国外で処理される場合があります。",
                "このページには分析スクリプト、広告、お問い合わせフォーム、追跡Cookieを追加していません。Googleによる処理については、下記のGoogleおよびFirebaseのプライバシー情報をご覧ください。",
            ]),
            ("共有、お問い合わせ、プラットフォーム", [
                "共有を選ぶと、Androidが選択した結果を利用者が指定したアプリへ渡します。その後は共有先アプリのポリシーが適用されます。Frame Octopusが共有先を自動選択したり連絡したりすることはありません。",
                "Microsoft Store、Google Play、Windows、Androidは各自のポリシーに従ってインストール、更新、アカウント、診断情報を処理する場合があります。本ポリシーや外部リンクを開く際はブラウザーとインターネット接続を使用します。",
                "メールでお問い合わせいただいた場合、開発者はメールアドレスと送信内容を受け取り、返信に使用します。共有する意図がない個人的な動画は添付しないでください。対応や適用される義務に必要な範囲で問い合わせ記録を保持し、メールによる削除依頼を受け付けます。",
            ]),
            ("利用者の選択とプライバシーに関する依頼", [
                "処理停止、結果削除、ローカル設定の変更・リセット、保存済みファイルの削除、OS設定でのメディアアクセス取消、アンインストールが可能です。開発者は端末内で処理した動画のサーバーコピーを保持していないため、その動画を取得したりサーバー上で削除したりすることはできません。",
                "問い合わせ記録の確認・削除やプライバシーに関する質問は下記へご連絡ください。アプリで子どもの個人情報を意図的に求めることはありません。子どもがサポートメールで個人情報を送信したと思われる場合は削除をご依頼ください。",
            ]),
            ("変更と連絡先", [
                "データの取り扱いが変わる場合は本ページと更新日を変更します。開発者・プライバシー窓口：Jeyoung Lee（이제영）、idlepoe@gmail.com。",
            ]),
        ],
    },
}


def build():
    PUBLIC.mkdir(parents=True, exist_ok=True)
    routes = {"en": "/privacy", "ko": "/ko/privacy", "ja": "/ja/privacy"}
    for lang, data in CONTENT.items():
        nav = "".join(f'<a href="{path}" lang="{code}" hreflang="{code}"' + (' aria-current="page"' if code == lang else '') + f'>{name}</a>' for code, path, name in [("en", routes["en"], "English"), ("ko", routes["ko"], "한국어"), ("ja", routes["ja"], "日本語")])
        sections = "".join(f'<section><h2>{escape(title)}</h2>' + "".join(f'<p>{escape(p)}</p>' for p in paragraphs) + '</section>' for title, paragraphs in data["sections"])
        html = f'''<!doctype html>
<html lang="{lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{escape(data['title'])} · Frame Octopus</title><meta name="description" content="{escape(data['summary'])}">
<link rel="canonical" href="https://frame-octopus.web.app{routes[lang]}"><link rel="stylesheet" href="/style.css">
</head><body><header><a class="brand" href="/privacy">Frame Octopus</a><nav aria-label="Language">{nav}</nav></header>
<main><p class="eyebrow">FRAME OCTOPUS · WINDOWS &amp; ANDROID</p><h1>{escape(data['title'])}</h1><p class="updated"><time datetime="{UPDATED}">{escape(data['updated'])}</time></p>
<aside>{escape(data['summary'])}</aside><p>{escape(data['intro'])}</p>{sections}
<section id="contact"><h2>Contact</h2><p><a href="mailto:idlepoe@gmail.com">idlepoe@gmail.com</a></p></section>
<footer><a href="https://firebase.google.com/support/privacy" rel="noreferrer">Firebase privacy information</a><a href="https://policies.google.com/privacy" rel="noreferrer">Google Privacy Policy</a><span>© 2026 Frame Octopus</span></footer></main></body></html>'''
        target = PUBLIC / ("privacy.html" if lang == "en" else f"{lang}/privacy.html")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(html, encoding="utf-8")
        if lang == "en":
            (PUBLIC / "index.html").write_text(html, encoding="utf-8")
    en = CONTENT["en"]
    markdown = f"# Frame Octopus — Privacy Policy\n\n{en['updated']}\n\n{en['summary']}\n\n{en['intro']}\n\n"
    for title, paragraphs in en["sections"]:
        markdown += f"## {title}\n\n" + "\n\n".join(paragraphs) + "\n\n"
    markdown += "[Firebase privacy information](https://firebase.google.com/support/privacy) · [Google Privacy Policy](https://policies.google.com/privacy)\n"
    (ROOT / "docs/PRIVACY.md").write_text(markdown, encoding="utf-8")
    (PUBLIC / "404.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Page not found · Frame Octopus</title><link rel="stylesheet" href="/style.css"><main><h1>Page not found</h1><p><a href="/privacy">Read the privacy policy</a></p></main></html>', encoding="utf-8")


if __name__ == "__main__":
    build()
