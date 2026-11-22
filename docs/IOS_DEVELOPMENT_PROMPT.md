# Frame Octopus — iOS 개발 프롬프트 가이드

작성일: 2026-11-22. 아래 프롬프트를 macOS 개발 환경의 Codex에 전달하고 이 저장소를 작업 폴더로 지정하세요. 이 파일은 개발 인계 자료이며, iOS 구현·빌드·App Store 배포가 완료되었다는 의미가 아닙니다.

## 바로 전달할 프롬프트

```text
이 저장소의 docs/IOS_DEVELOPMENT_PROMPT.md, docs/android/README.md,
hosting/README.md와 현재 소스를 읽고 Frame Octopus의 iOS 버전을 단계적으로 구현해줘.

Windows와 Android의 기존 기능을 보존하고 Flutter 공통 엔진과 Fluent UI 모바일
화면을 재사용해줘. 단순히 iOS 프로젝트를 생성하고 끝내지 말고, 사진 보관함 선택,
영상 미리보기, PNG/움직이는 WebP 생성, 저장·공유·선택 삭제까지 연결해줘.
기본 조작 흐름은 영상 선택 → 만들기 → 저장이며 별도 단계형 마법사는 추가하지 마.
원본 영상은 수정하거나 삭제하지 말고 임시 파일 정리는 앱 전용 경로로 제한해줘.

먼저 macOS/Xcode/Flutter와 고정된 플러그인의 iOS 지원·네이티브 바이너리를 확인하고,
작동 가능한 최소 인코딩 경로를 검증한 뒤 화면과 저장을 연결해줘.
현재 Android 전용 분기와 MethodChannel을 조사해서 iOS 어댑터를 구현하고,
Windows 전용 초기화가 iOS에서 실행되지 않게 해줘.

디자인은 실제 fluent_ui 컨트롤을 사용하고 기존 파란색/중립색 테마와 문어 마스코트를
유지해줘. 영어 기본, 한국어·일본어를 지원하고 작은 iPhone, 큰 글씨, 노치와
홈 인디케이터에서 버튼·설명·슬라이더가 겹치거나 잘리지 않도록 해줘.

Firebase 프로젝트는 frame-octopus다. iOS Bundle ID와 Apple 개발팀이 기존 프로젝트나
사용자 설정에서 확정되어 있으면 재사용하고, 없으면 확정이 필요한 항목만 질문해줘.
Android용 FirebaseOptions를 iOS에서 사용하지 말고 iOS 앱을 별도 등록·구성해줘.
Analytics, Crashlytics, 로그인, 클라우드 미디어 업로드는 임의로 추가하지 마.

사진 앱에 움직이는 WebP를 저장할 수 있다고 가정하지 마. 실제 저장 가능 여부와
애니메이션 유지 여부를 확인하고, 지원하지 않으면 파일 앱 저장과 공유를 제공해줘.
갤러리에 PNG 저장은 별도로 검증하고 UI에는 실제 가능한 동작만 표시해줘.

검사는 간단히 핵심 경로 위주로 실행하되 성공을 확인한 것과 미검증 항목을 구분해줘.
가능하면 연결된 실제 iPhone으로 확인하고, 없으면 시뮬레이터 확인 범위를 명시해줘.
스크린샷과 테스트 요약을 docs/ios/에 남기고 README와 개인정보처리방침을 실제 구현에
맞게 갱신해줘. 서명키·인증 토큰·프로비저닝 파일은 Git에 포함하지 마.
App Store 제출, 법적 약관 동의, 새 유료 서비스 활성화는 이번 개발 범위와 구분해줘.
```

## 현재 구현과 검증 상태

- Flutter 프로젝트 하나에 Windows와 Android가 구현되어 있습니다. 현재 `ios/` 폴더는 없습니다.
- Flutter 3.41.9 / Dart 3.11.5 환경에서 작업했습니다. 실제 도구 버전은 새 환경에서 다시 확인하세요.
- `fluent_ui`는 **4.13.0**으로 고정되어 있습니다. iOS를 추가한다는 이유만으로 Flutter나 전체 의존성을 일괄 업그레이드하지 마세요.
- 앱 버전은 `pubspec.yaml` 기준 `1.0.0+3`입니다. 배포용 버전·빌드 번호는 실제 배포 기록을 확인해서 정합니다.
- 영상의 대표 장면들을 정지 PNG 또는 움직이는 WebP 모음으로 생성합니다. 움직이는 모음은 각 장면을 동시에 재생하며 소리가 없습니다.
- 전체 타임라인을 WebP로 변환하거나 시작·종료 지점을 직접 자르는 앱이 아닙니다. 우잉비는 간단한 UI 흐름의 참고이며 자르기·모자이크·배속 기능을 복제하지 않습니다.
- 기본 용량 한도는 파일당 20 MB입니다. 1 MB는 1,000,000 bytes이며 일괄 작업의 총용량이 아닙니다.
- 최대 50개 선택, 자동 장면 수, 원본 비율, 유연한 마지막 행 배치를 지원합니다. 짧은 영상은 불필요하게 장면을 반복하지 않습니다.
- 상세 설정에는 최대 장면 수(자동/4/8/12/24), 장면 비율, 모음 배치, 모바일 최대 너비(960/1280/1920), 자동·수동 FPS와 장면당 길이가 있습니다.
- Android 기본 너비는 1280px이며 Windows는 1920px입니다. 자동 FPS는 원본 프레임률 이하·최대 30이며 Android는 장면당 약 80프레임, Windows는 약 120프레임 예산을 사용합니다. 수동 장면 길이는 0.5~10초입니다.
- 샘플 기반 용량 추정 뒤 보통 한 번 전체 인코딩하고 실제 초과 시에만 제한적으로 보정합니다. 용량을 빈틈없이 채우는 세밀한 반복 탐색이나 여러 전체 인코딩의 병렬 실행을 추가하지 마세요.
- Android는 현재 포그라운드 처리입니다. 생성 중 화면을 켜 두고 앱이 배경으로 이동하면 미완료 작업을 취소합니다. 완성 결과는 현재 세션에 유지하며 다음 콜드 스타트에서 이전 앱 전용 작업 파일을 정리합니다.
- FluentApp, ComboBox, ToggleSwitch, Slider, Checkbox, InfoBar, ContentDialog와 Fluent 버튼·아이콘을 적용했습니다. Material 코드는 레이아웃·동영상·제스처 기반 구조로 일부 남아 있으며 Material 3 시각 테마를 사용하지 않습니다.
- Samsung SM-A346N(Android 16)에서 WebP/PNG 생성, 갤러리 저장, 공유창, 결과 삭제, Firebase 초기화와 개인정보처리방침 링크를 확인했습니다. Windows/Android debug 빌드와 Flutter 테스트 17개가 통과했습니다.
- **iOS의 CocoaPods 설치, 네이티브 인코딩, 사진 저장, 실제 기기 동작은 아직 검증하지 않았습니다.** Android 결과를 iOS 검증으로 간주하지 마세요.

## 먼저 읽을 소스

| 경로 | 역할 / iOS에서 확인할 점 |
|---|---|
| `lib/main.dart` | 현재 Android만 모바일 진입점을 사용합니다. iOS도 모바일로 분기하고 `windowManager`/Windows 플레이어 초기화를 피해야 합니다. |
| `lib/mobile/mobile_app.dart` | Fluent 모바일 화면과 작업 흐름. 시작 함수는 현재 Android FirebaseOptions를 명시적으로 사용하므로 플랫폼별 수정이 필요합니다. |
| `lib/mobile/fluent_mobile.dart` | Fluent 테마, 터치 크기, 카드·패널·버튼 래퍼. iPhone SafeArea와 글자 확대를 검증하세요. |
| `lib/mobile/gallery_service.dart` | `frame_octopus/gallery` 채널. iOS 구현이 없으므로 `pickVideos`/`save` 계약에 맞는 어댑터가 필요합니다. |
| `android/app/src/main/kotlin/ink/frameoctopus/frame_octopus/` | 현재 Android 갤러리 및 회전 메타데이터 구현. 경로나 MediaStore 코드를 iOS로 그대로 복사하지 마세요. |
| `lib/core/studio_controller.dart` | 공통 큐·설정·실행. 너비, 저장된 모바일 설정과 프레임 예산의 `Platform.isAndroid` 조건을 모바일 정책으로 분리해야 합니다. |
| `lib/core/models.dart` | SamplePlan, SheetLayout, 원본 표시 크기·회전 정보. iOS 세로 영상도 확인하세요. |
| `lib/core/processor.dart` | FFmpeg/FFprobe, 임시 경로, HDR와 회전 처리. `mosaic/media` 채널 의존 여부를 확인하세요. |
| `lib/core/webp_budget_encoder.dart`, `capacity_optimizer.dart` | 용량 추정 및 재시도 정책. 실제 최종 파일 크기를 기준으로 한도 충족 여부를 판정합니다. |
| `lib/firebase_options.dart`, `firebase.json` | 현재 Firebase 앱 설정은 Android만 포함합니다. Hosting 설정을 보존하면서 iOS를 추가하세요. |
| `tool/build_privacy_site.py`, `hosting/README.md` | 다국어 방침 HTML 생성·배포. 현재 방침 범위는 Windows/Android이므로 실제 iOS 동작에 맞춰 갱신해야 합니다. |

## 권장 개발 순서와 완료 기준

### 1. Mac 환경과 플러그인 검증

- `flutter doctor -v`, Xcode 버전, CocoaPods와 연결 기기를 확인합니다. 저장소의 추가 지침 파일이 있으면 먼저 읽습니다.
- 기존 파일을 보존하며 iOS 타깃을 생성합니다. Bundle ID는 아직 이 문서에서 확정하지 않았습니다. Android 패키지와 Firebase 프로젝트는 변경하지 않습니다.
- 현재 캐시의 `firebase_core 5.1.0` podspec 최소값은 iOS 15.0, `ffmpeg_kit_flutter_new_full 2.5.8` podspec 최소값은 iOS 14.0입니다. 따라서 **iOS 15를 초기 기준 후보**로 삼되 전체 플러그인과 배포 도구의 실제 요구 사항을 확인합니다.
- FFmpeg 플러그인의 XCFramework 다운로드, arm64 기기·시뮬레이터 슬라이스와 필요한 FFmpeg 필터/인코더를 검증합니다. 라이브러리 지원 표만 보고 성공했다고 판단하지 않습니다.
- 임의로 전역 패키지 캐시를 수정하거나 서명·보안 검사를 끄지 않습니다. 의존성 변경이 필요하면 프로젝트에 재현 가능한 형태로 남깁니다.
- 완료 기준: iOS 앱이 시작되고 작은 로컬 영상에서 PNG와 움직이는 WebP를 실제로 생성합니다.

### 2. 모바일 진입점과 iOS 사진 어댑터

- iOS가 Windows 초기화를 거치지 않게 하고 모바일 기본 설정을 적용합니다. Windows 설정/성능 정책은 유지합니다.
- 시스템 사진 선택기(PHPicker 등 해당 iOS 버전에 맞는 방식)로 다중 영상을 선택합니다. 취소·제한된 접근·iCloud에만 있는 영상·다운로드 실패를 처리합니다.
- 선택 파일은 소유권과 수명을 명확히 한 앱 전용 캐시에 복사하고 이름과 식별자를 보존합니다. 보안 범위 파일 URL이 필요하면 적절히 접근을 열고 닫습니다.
- UIKit/PhotoKit 처리가 필요한 권한 문구만 추가하고 사용자가 선택한 동작과 연결합니다. 전체 사진 보관함 권한을 편의상 일괄 요구하지 않습니다.
- 완료 기준: 다중 선택, 취소, 중복·실패 파일 처리와 세로 영상 미리보기가 동작합니다.

### 3. 저장·공유와 생명주기

- PNG를 PhotoKit으로 저장하고 취소·권한 거부·저장 실패를 구분합니다. 성공 알림은 실제 저장 완료 후에만 표시합니다.
- 움직이는 WebP는 파일 저장/공유를 우선 보장하고, 사진 앱에 저장했다면 다시 열어 애니메이션이 유지되는지도 확인합니다. 지원하지 않는 경우 정지 이미지로 조용히 바꾸거나 갤러리 저장 성공으로 표시하지 않습니다.
- 결과 다중 선택·삭제는 앱 전용 결과에만 적용합니다. 원본과 이미 내보낸 복사본은 유지합니다. 기존 파일을 덮어쓰지 않습니다.
- iPad 공유 팝오버의 위치 지정, 가로 회전, 시트 닫기 버튼과 터치 영역을 확인합니다.
- 포그라운드 작업부터 완성합니다. iOS에서 일반 인코딩이 무제한 백그라운드 실행된다고 가정하지 말고 중단 시 상태와 임시 파일을 정리합니다. 허용되지 않는 백그라운드 모드를 선언하지 않습니다.
- 완료 기준: 실제 저장 파일, 공유창, 선택 삭제 및 중단 뒤 앱 상태가 일치합니다.

### 4. Firebase와 개인정보처리방침

- 프로젝트: `frame-octopus`. 확정된 iOS Bundle ID에 해당하는 앱이 이미 있는지 먼저 확인하고 재사용하거나 필요한 iOS 앱만 등록합니다.
- FlutterFire 구성 시 Android 설정과 `firebase.json`의 Hosting 구성을 보존하고 iOS 플랫폼을 추가합니다. iOS 등록을 위해 Android 앱을 삭제·재생성하지 않습니다.
- `GoogleService-Info.plist`/플랫폼별 FirebaseOptions를 연결합니다. 기본 데이터 수집 비활성화를 iOS 설정에도 적용하고, Firebase 초기화 실패가 로컬 영상 도구의 사용을 막지 않도록 합니다.
- Analytics·Crashlytics·인증·Firestore·Storage·원격 미디어 업로드는 이번 범위가 아닙니다. 자동으로 활성화하지 않습니다.
- 현재 URL: https://frame-octopus.web.app/privacy (영문 기본), `/ko/privacy`, `/ja/privacy`.
- 실제 구현된 iOS 사진 권한·캐시 정리·저장 및 공유 방식을 방침 3개 언어에 반영합니다. Firebase Hosting의 IP 처리와 앱의 로컬 영상 처리를 구분합니다.
- iOS Privacy Manifest, 사용하는 API의 신고 사유, 네이티브 라이브러리의 라이선스·배포 의무와 App Store 개인정보 응답을 실제 의존성에 근거해 확인합니다. 사유 코드를 임의로 선택하거나 App Store 적합성을 검증 없이 보장하지 않습니다.
- 완료 기준: 올바른 iOS Firebase 앱으로 초기화되고 선택 언어의 방침이 열립니다. 미디어 업로드나 분석 기능이 추가되지 않습니다.

### 5. 간단한 실기기 확인과 인계

- 짧은 영상, 세로 영상, 긴 영상 한 개와 다중 선택을 대표 사례로 확인합니다. 이미 통과한 전체 인코딩을 이유 없이 반복하지 않습니다.
- 작은 iPhone, 큰 글씨, iPad에서 주요 화면의 겹침과 SafeArea를 확인합니다. 30 FPS/10초 수동 설정, 자동 설정 복귀, PNG에서 애니메이션 설정 비활성화도 확인합니다.
- 용량 상한은 실제 파일 bytes로 확인하고 시각 미리보기만으로 성공 판정하지 않습니다.
- `docs/ios/README.md`에 도구 버전·지원 OS·기기·실행 절차·검사 결과·남은 제한을, `docs/ios/screenshots/`에 실제 화면을 남깁니다.
- 가능한 범위에서 Flutter 검사와 iOS 빌드를 수행합니다. 실제 기기·서명이 없으면 그 한계를 명시합니다. 미서명 빌드 성공을 App Store 제출 성공이라고 표현하지 않습니다.
- 완료 후 변경 요약, 검사 결과, 설치/실행 방법을 보고합니다. 커밋·푸시나 심사 제출은 해당 세션의 사용자 요청 범위를 따릅니다.

## 보존 및 제외 원칙

- 기존 `C:\Workspace\mosaic`는 참고용 원본으로 유지합니다. 다른 프로젝트의 키·설정·계정을 무단 복사하지 않습니다.
- 문어 마스코트와 Fluent UI를 유지합니다. 필요한 이미지가 없는 경우에만 추가 제작합니다.
- 프로비저닝 프로파일, `.p8`, `.p12`, `.pfx`, 비공개 키, 서비스 계정 JSON, 인증 토큰은 커밋하지 않습니다. Xcode 자동 서명도 사용자가 소유한 팀 권한 범위 안에서 구성합니다.
- Firebase 클라이언트 구성 파일은 관리자 자격 증명과 구별하고 공식 지침에 맞게 관리합니다. Hosting에는 `hosting/public` 파일만 배포합니다.
- Microsoft Store의 기존 제출 초안은 별도 작업입니다. 이 가이드를 따른다는 이유로 약관 동의, 연령 확인 또는 심사 제출을 진행하지 않습니다.
- Git 저장소 공개 범위, 서비스 요금제와 보안 권한을 임의로 변경하지 않습니다.

## 개발 시 확인할 공식 자료

- Flutter iOS 설정: https://docs.flutter.dev/platform-integration/ios/setup
- Firebase Flutter 설정: https://firebase.google.com/docs/flutter/setup
- Apple PhotosUI: https://developer.apple.com/documentation/photosui
- Apple PhotoKit: https://developer.apple.com/documentation/photokit
- Apple Privacy Manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files

위 링크는 다음 개발자가 실제 작업 시 최신 요구 사항을 확인하기 위한 출발점입니다. 이 문서 자체는 현재 소스와 로컬 의존성 파일을 기준으로 작성되었으며 iOS 호환성 인증이 아닙니다.
