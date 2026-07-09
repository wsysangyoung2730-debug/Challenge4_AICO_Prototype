# Challenge4_AICO_Prototype

AICO의 핵심 사용자 흐름을 검증하기 위한 iOS 프로토타입 앱입니다.

A prototype iOS app for testing AICO's core flow: anonymous onboarding, recipient registration, ABC-based recording, archive filtering, and report summaries.

## Project Background

AICO는 자폐스펙트럼 대상자의 보호자가 대상자의 상황, 행동, 대응 결과를 구조적으로 기록하고, 축적된 기록을 바탕으로 대상자를 더 정확히 이해할 수 있도록 돕는 앱입니다.

이 저장소는 Challenge 4를 위한 개인 프로토타입 저장소입니다. 추후 프로덕션 앱은 디자이너와 함께 별도로 개발하며, 현재 저장소는 핵심 앱 플로우와 정보 구조를 검증하는 데 집중합니다.

앱의 아이콘과 UI 톤은 따뜻한 오렌지 캐릭터 스타일의 AICO를 기준으로 하며, 차가운 의료 앱보다 부드럽고 지지적인 보호자 친화 경험을 목표로 합니다.

## Core Flow

1. App launch
2. Anonymous entry instead of immediate signup
3. New user service introduction
4. Home screen
   - recent records preview
   - brief report preview
   - information feed
   - notification entry
   - profile/settings entry
5. First-time tutorial per new tab/menu
6. Recording tutorial explaining A/B/C recording
7. Recipient registration required before real recording
8. Recipient profile fields
   - name/nickname: required
   - age: optional
   - gender: optional
   - autism degree or traits: optional
   - profile image: optional
9. ABC recording flow
   - A: antecedent/context before behavior
   - B: behavior/signal
   - C: consequence/response/result
   - optional photo and free text
   - custom category addition through plus button
   - custom categories persist and are editable in settings
10. Archive
   - saved records as cards
   - date filter: 1 week, 1 month, 3 months
   - category filter
11. Report
   - total weekly record count
   - notable changes
   - A/B/C Top 3
12. Data sharing will be designed later and should not be implemented now.

## Core Features

- Anonymous onboarding
- Service introduction for new users
- Home dashboard
- Recipient registration
- ABC-based recording
- Custom category management
- Archive filtering
- Weekly report summary
- Settings and notification entry

## Prototype Scope

- UI flow and data structure exploration
- Phase 1 app foundation with SwiftData models, local anonymous state, service intro gate, and tab placeholders
- Phase 2 home dashboard, refined service intro, static information feed, and first-time Home tutorial overlay
- No production authentication
- No CloudKit Sharing
- No real medical decision-making
- No sensitive real user data

## Folder Structure

```text
Challenge4_AICO_Prototype/
├── README.md
├── .gitignore
├── Challenge4_AICO_Prototype/
│   ├── App/
│   │   └── AICOPrototypeApp.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── RecipientProfile.swift
│   │   │   ├── RecordEntry.swift
│   │   │   ├── RecordCategory.swift
│   │   │   └── ReportSummary.swift
│   │   ├── Persistence/
│   │   │   └── SwiftDataContainer.swift
│   │   ├── State/
│   │   │   └── AnonymousSessionState.swift
│   │   └── Constants/
│   │       └── AppConstants.swift
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   └── ServiceIntroView.swift
│   │   ├── Home/
│   │   │   └── HomeView.swift
│   │   ├── Recording/
│   │   │   └── RecordingEntryView.swift
│   │   ├── Archive/
│   │   │   └── ArchiveView.swift
│   │   ├── Report/
│   │   │   └── ReportView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── Shared/
│   │   ├── Components/
│   │   │   └── PlaceholderCardView.swift
│   │   └── DesignSystem/
│   │       └── AICOTheme.swift
│   └── Resources/
│       └── Assets.xcassets/
└── Docs/
    ├── product-flow.md
    ├── git-convention.md
    └── phase-plan.md
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

## Development Notes

- 현재는 SwiftUI 소스 스켈레톤과 정보 구조 검증을 위한 문서 중심으로 구성합니다.
- Phase 1에서는 SwiftData 컨테이너, 로컬 익명 상태, 서비스 소개 화면, 5개 탭 placeholder를 구현했습니다.
- Phase 2에서는 서비스 소개를 다듬고 홈 대시보드, 최근 기록/간단 리포트/정보 피드 미리보기, 1회성 홈 튜토리얼 오버레이를 구현했습니다.
- 실제 Xcode 프로젝트 파일은 개발 환경에서 생성 후 이 소스 구조를 연결합니다.
- 프로덕션 인증, CloudKit Sharing, 의료 판단 기능은 구현하지 않습니다.
- 실제 사용자나 대상자의 민감 정보를 테스트 데이터로 사용하지 않습니다.

## Privacy Note

Do not commit real personal data, real recipient information, medical records, photos, videos, credentials, or secrets.
