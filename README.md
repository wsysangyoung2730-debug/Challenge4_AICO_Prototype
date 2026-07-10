# Challenge4_AICO_Prototype

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%20UI-0A84FF?logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-Local%20Persistence-FF8A00)
![WidgetKit](https://img.shields.io/badge/WidgetKit-Quick%20Record-34C759)
![Share Extension](https://img.shields.io/badge/Share%20Extension-Photo%20Entry-5856D6)
![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white)

AICO의 핵심 사용자 흐름을 검증하기 위한 iOS 프로토타입 앱입니다.

A prototype iOS app for testing AICO's core flow: anonymous onboarding, recipient registration, ABC-based recording, archive filtering, report summaries, quick record widget entry, and photo-based share extension entry.

## Project Background

AICO는 자폐스펙트럼 대상자의 보호자가 대상자의 상황, 행동, 대응 결과를 구조적으로 기록하고, 축적된 기록을 바탕으로 대상자를 더 정확히 이해할 수 있도록 돕는 앱입니다.

이 저장소는 Challenge 4를 위한 개인 프로토타입 저장소입니다. 추후 프로덕션 앱은 디자이너와 함께 별도로 개발하며, 현재 저장소는 핵심 앱 플로우와 정보 구조를 검증하는 데 집중합니다.

앱의 아이콘과 UI 톤은 따뜻한 오렌지 캐릭터 스타일의 AICO를 기준으로 하며, 차가운 의료 앱보다 부드럽고 지지적인 보호자 친화 경험을 목표로 합니다.

### Core Flow

| 단계 | 흐름 | 현재 프로토타입 반영 |
| --- | --- | --- |
| 1 | 앱 실행 | SwiftUI App entry와 로컬 상태 기반 진입 |
| 2 | 익명 진입 | 실제 로그인 없이 AppStorage 기반 익명 사용자 상태 사용 |
| 3 | 서비스 소개 | 최초 사용자에게 AICO 사용 목적 안내 |
| 4 | 홈 대시보드 | 최근 기록, 간단 리포트, 정보 피드, 알림/설정 진입 |
| 5 | 홈 튜토리얼 | 최초 1회 홈 화면 오버레이 튜토리얼 |
| 6 | 대상자 등록 | 실제 기록 전 대상자 이름/나이/성별/특성/프로필 이미지 등록 |
| 7 | 기록 튜토리얼 | A/B/C 기록 방식 최초 1회 안내 |
| 8 | A/B/C 기록 | 상황, 행동, 대응을 단계별로 선택하고 메모/사진 첨부 |
| 9 | 아카이브 | 저장된 기록 카드 목록, 날짜/단계 필터, 상세 화면 |
| 10 | 리포트 | 일일/주간/월간 요약, A/B/C Top 3, 간단 차트 |
| 11 | 설정 관리 | 대상자, 카테고리, 알림 설정, 로컬 데이터 삭제 |
| 12 | 외부 진입 | 위젯 빠른 기록, 사진 앱 공유 확장을 통한 기록 시작 실험 |

### Core Features

| 기능 | 설명 | 구현 위치 |
| --- | --- | --- |
| 익명 온보딩 | 민감정보 입력 전 앱을 먼저 둘러보는 진입 흐름 | `Features/Onboarding` |
| 홈 대시보드 | 최근 기록, 리포트 미리보기, 정보 피드 제공 | `Features/Home` |
| 대상자 등록/관리 | 기록 대상자의 기본 프로필 생성, 수정, 삭제 | `Features/Recording`, `Features/Settings` |
| A/B/C 기록 | Antecedent, Behavior, Consequence 기반 기록 작성 | `Features/Recording` |
| 커스텀 카테고리 | A/B/C 단계별 사용자 카테고리 추가 및 관리 | `Features/Recording`, `Features/Settings` |
| 아카이브 | SwiftData 기록 목록, 필터, 상세, 단일 기록 삭제 | `Features/Archive` |
| 리포트 | 기간별 기록 수, Top 3, 반복 패턴 요약 | `Features/Report` |
| 위젯 | 오늘 기록 수와 빠른 기록 진입점 제공 | `AICOWidgetExtension` |
| 사진 공유 확장 | 사진 앱 공유 버튼에서 AICO 기록 흐름 진입 실험 | `AICOShareExtension` |

## 주요 기능

- 실제 회원가입 없이 로컬 익명 사용자 상태로 앱을 탐색합니다.
- 대상자 등록 후 A/B/C 기반 기록을 작성하고 SwiftData에 저장합니다.
- 단계별 기본 카테고리와 커스텀 카테고리를 함께 사용합니다.
- 기록에는 자유 메모와 로컬 사진 첨부를 포함할 수 있습니다.
- 아카이브에서 저장 기록을 카드로 확인하고 날짜/단계 기준으로 필터링합니다.
- 기록 상세 화면에서 A/B/C 선택 항목, 메모, 첨부 사진을 확인하고 단일 기록을 삭제할 수 있습니다.
- 리포트 화면에서 일일/주간/월간 기록 요약과 A/B/C Top 3를 확인합니다.
- 설정 화면에서 대상자, 카테고리, 알림 ON/OFF, 앱 데이터 삭제를 관리합니다.
- WidgetKit 기반 빠른 기록 위젯을 통해 현재 대상자와 오늘 기록 요약을 확인합니다.
- Share Extension 기반 사진 공유 진입을 통해 사진 앱에서 기록 시작 흐름을 검증합니다.

## 기술 스택

| 구분 | 기술 |
| --- | --- |
| 언어 | ![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white) |
| UI | ![SwiftUI](https://img.shields.io/badge/SwiftUI-Declarative%20UI-0A84FF?logo=swift&logoColor=white) |
| 로컬 저장 | ![SwiftData](https://img.shields.io/badge/SwiftData-iOS%2017%2B-FF8A00) |
| 로컬 상태 | ![AppStorage](https://img.shields.io/badge/AppStorage-Local%20State-8E8E93) |
| 사진 선택 | ![PhotosPicker](https://img.shields.io/badge/PhotosPicker-Photo%20Library-34C759) |
| 위젯 | ![WidgetKit](https://img.shields.io/badge/WidgetKit-iOS%20Widget-34C759) |
| 공유 확장 | ![Share Extension](https://img.shields.io/badge/Share%20Extension-iOS%20Share%20Sheet-5856D6) |
| 딥링크 | ![URL Scheme](https://img.shields.io/badge/URL%20Scheme-aico%3A%2F%2F-007AFF) |
| 공유 저장소 | ![App Group](https://img.shields.io/badge/App%20Group-Shared%20Container-6E6E73) |

## 타겟 구성과 스키마

| Target | 역할 | Bundle ID |
| --- | --- | --- |
| `Challenge4_AICO_Prototype` | 메인 iOS 앱 | `com.aico.prototype.challenge4` |
| `AICOWidgetExtension` | 빠른 기록 위젯 | `com.aico.prototype.challenge4.AICOWidgetExtension` |
| `AICOShareExtension` | 사진 공유 기반 기록 시작 확장 | `com.aico.prototype.challenge4.AICOShareExtension` |

| Scheme | 구성 |
| --- | --- |
| `Challenge4_AICO_Prototype` | Main App 실행 스키마입니다. BuildAction에 Main App, Widget Extension, Share Extension이 포함되어 있습니다. |

공통 App Group:

```text
group.com.wsysangyoung2730.aico
```

사용 URL Scheme:

```text
aico://quick-record?recipientId=<recipientId>
aico://select-recipient-for-record
aico://record-from-photo?attachmentId=<attachmentId>
```

## 데이터 흐름

### 앱 내부 기록 흐름

```text
사용자
  -> + 기록
  -> 대상자 등록 여부 확인
  -> 기록 튜토리얼 확인
  -> A단계 상황 선택
  -> B단계 행동 선택
  -> C단계 대응/결과 선택
  -> 메모/사진 첨부
  -> SwiftData RecordEntry 저장
  -> 아카이브/홈/리포트에서 기록 조회
```

### 위젯 데이터 흐름

```text
SwiftData 기록/대상자
  -> WidgetSnapshotBuilder
  -> WidgetSnapshotStore
  -> App Group UserDefaults
  -> AICOWidgetExtension
  -> 빠른 기록 위젯 표시
```

### 사진 공유 확장 흐름

```text
iOS 사진 앱
  -> 공유 버튼
  -> AICOShareExtension
  -> 공유 이미지 App Group 저장
  -> aico://record-from-photo?attachmentId=<id>
  -> Main App 딥링크 라우팅
  -> RecordingEntryView
  -> A/B/C 기록 흐름
  -> RecordEntry attachmentNames 저장
```

## Folder Structure

```text
Challenge4_AICO_Prototype/
├── README.md                                      # 프로젝트 개요와 개발 규칙
├── .gitignore                                    # Git 제외 파일 규칙
├── Challenge4_AICO_Prototype.xcodeproj/          # Xcode 프로젝트와 공유 스키마
├── Challenge4_AICO_Prototype/                    # 메인 iOS 앱 소스
│   ├── App/                                      # 앱 진입점, 루트 내비게이션, 딥링크 수신
│   ├── Core/                                     # 도메인 모델, 저장소, 상태, 딥링크, 위젯/공유 유틸
│   │   ├── Constants/                            # 앱 공통 상수
│   │   ├── DeepLink/                             # aico:// 딥링크 타입과 라우터
│   │   ├── Models/                               # SwiftData 모델과 리포트 모델
│   │   ├── Persistence/                          # SwiftData ModelContainer 구성
│   │   ├── Share/                                # 공유 사진 App Group 저장 유틸
│   │   ├── Shared/                               # App Group 등 타겟 공통 상수
│   │   ├── State/                                # 익명 사용자/튜토리얼 로컬 상태
│   │   ├── Utilities/                            # 이미지 로컬 저장 유틸
│   │   └── Widget/                               # 위젯 스냅샷 모델, 저장, 생성 로직
│   ├── Features/                                 # 화면 단위 기능 모듈
│   │   ├── Archive/                              # 기록 목록, 필터, 상세, 기록 삭제
│   │   ├── Home/                                 # 홈 대시보드, 튜토리얼, 정보 피드
│   │   ├── Onboarding/                           # 서비스 소개 화면
│   │   ├── Recording/                            # 대상자 등록, A/B/C 기록, 사진 첨부
│   │   ├── Report/                               # 일일/주간/월간 리포트
│   │   └── Settings/                             # 대상자/카테고리/알림/데이터 관리
│   ├── Resources/                                # 앱 아이콘과 에셋 카탈로그
│   └── Shared/                                   # 공용 컴포넌트와 디자인 시스템
├── AICOWidgetExtension/                          # WidgetKit 기반 빠른 기록 위젯
├── AICOShareExtension/                           # iOS Share Sheet 기반 사진 기록 진입 확장
└── Docs/                                         # 제품 흐름, Git 규칙, 단계별 계획 문서
```

## Git Strategy

- `main`: 출시(release)에 사용하는 브랜치입니다.
- `develop`: 개발된 기능들을 최종적으로 합쳐서 확인하는 기본 개발 브랜치입니다.
- feature branches: 기능 개발, 버그 수정, 문서 수정, 설정 변경 등은 별도 브랜치에서 진행합니다.

작업 흐름:

1. `develop`에서 작업 브랜치를 생성합니다.
2. 작업 브랜치에서 작업합니다.
3. 작업 완료 후 `develop`을 작업 브랜치에 병합하거나 rebase하여 최신 상태를 반영합니다.
4. `develop`으로 Pull Request를 요청합니다.
5. `main`에는 release 시점에만 병합합니다.

## Commit Convention

- 태그는 반드시 소문자로 작성합니다.
- 내용은 한글로 작성합니다.
- 제목은 50자를 넘지 않도록 간단하게 명령조로 작성합니다.
- 설명이 필요한 경우 commit description에 작성합니다.

예시:

```text
[feat] 로그인 기능 구현
```

사용 태그:

- `init`: 가장 처음 Initial Commit에 태그 붙이기
- `feat`: 새로운 기능 구현 시 사용
- `fix`: 버그나 오류 해결 시 사용
- `docs`: README, 템플릿 등 프로젝트 내 문서 수정 시 사용
- `setting`: 프로젝트 관련 설정 변경 시 사용
- `add`: 사진 등 에셋이나 라이브러리 추가 시 사용
- `refactor`: 기존 코드를 리팩토링하거나 수정할 시 사용
- `chore`: 별로 중요한 수정이 아닐 시 사용

## Branch Convention

형식:

```text
태그/#이슈번호-작업하는-파일-또는-기능
```

예시:

```text
feat/#1-loginUI
```

## Privacy Note

실제 개인정보, 대상자 정보, 의료 기록, 실제 사진/영상, 인증 정보, 비밀 키, 런타임 이미지 파일, provisioning profile은 커밋하지 않습니다.
