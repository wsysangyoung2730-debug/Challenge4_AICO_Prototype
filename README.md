# Challenge4_AICO_Prototype

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%20UI-0A84FF?logo=swift&logoColor=white)
![SwiftData](https://img.shields.io/badge/SwiftData-Local%20Persistence-FF8A00)
![WidgetKit](https://img.shields.io/badge/WidgetKit-Quick%20Record-34C759)
![Share Extension](https://img.shields.io/badge/Share%20Extension-Photo%20Entry-5856D6)
![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple&logoColor=white)

AICO는 자폐스펙트럼 대상자의 보호자가 일상의 상황, 행동, 대응을 A/B/C 구조로 기록하고 다시 살펴볼 수 있도록 돕는 iOS 프로토타입 앱입니다.

이 저장소는 Challenge 4 단계의 기능 검증용 프로토타입입니다. 현재 앱은 실제 회원가입, 서버, CloudKit 동기화 없이 로컬 데이터와 App Group 기반 공유 저장소를 사용합니다.

## 현재 상태

| 항목 | 내용 |
| --- | --- |
| 앱 이름 | Xcode 표시 이름은 `AICO`, App Store Connect/TestFlight 앱 이름은 `AICO Beta`로 운영 중 |
| 최소 버전 | iOS 17.0+ |
| 앱 버전 | `1.0 (1)` 기준 TestFlight 업로드 검증 |
| 저장 방식 | SwiftData 로컬 저장 |
| 외부 진입 | WidgetKit 빠른 기록, Share Extension 사진 기록 진입 |
| 배포 준비 | Main App, Widget Extension, Share Extension signing/profile 구성 필요 |
| 미구현 범위 | 실제 로그인, 서버 동기화, CloudKit Sharing, 실제 보호자 공유 |

## 핵심 사용자 흐름

| 단계 | 흐름 | 현재 프로토타입 반영 |
| --- | --- | --- |
| 1 | 앱 실행 | SwiftUI App entry와 로컬 상태 기반 진입 |
| 2 | 익명 진입 | 실제 로그인 없이 AppStorage 기반 익명 사용자 상태 사용 |
| 3 | 서비스 소개 | 최초 사용자에게 AICO 사용 목적 안내 |
| 4 | 홈 대시보드 | 최근 기록, 주간 리포트 미리보기, 정보 피드, 알림/설정 진입 |
| 5 | 홈 튜토리얼 | 최초 1회 홈 화면 오버레이 튜토리얼 |
| 6 | 대상자 등록 | 이름/나이/성별/특성/프로필 이미지 등록 |
| 7 | 기록 튜토리얼 | A/B/C 기록 방식 최초 1회 안내 |
| 8 | A/B/C 기록 | 상황, 행동, 대응을 단계별로 선택하고 메모/사진 첨부 |
| 9 | 아카이브 | 저장된 기록 목록, 날짜/단계 필터, 상세 화면 |
| 10 | 리포트 | 일일/주간/월간 요약, A/B/C Top 3, 간단 차트 |
| 11 | 설정 관리 | 대상자, 카테고리, 알림 설정, 로컬 데이터 삭제 |
| 12 | 외부 진입 | 위젯 빠른 기록, 사진 앱 공유 확장을 통한 기록 시작 |

## 주요 기능

- 실제 회원가입 없이 로컬 익명 사용자 상태로 앱을 탐색합니다.
- 대상자 등록 후 A/B/C 기반 기록을 작성하고 SwiftData에 저장합니다.
- 단계별 기본 카테고리와 사용자 커스텀 카테고리를 함께 사용합니다.
- 기록에는 자유 메모와 로컬 사진 첨부를 포함할 수 있습니다.
- 아카이브에서 저장 기록을 카드로 확인하고 날짜/단계 기준으로 필터링합니다.
- 기록 상세 화면에서 A/B/C 선택 항목, 메모, 첨부 사진을 확인하고 단일 기록을 삭제할 수 있습니다.
- 리포트 화면에서 일일/주간/월간 기록 요약과 A/B/C Top 3를 확인합니다.
- 설정 화면에서 대상자, 기록 카테고리, 알림 ON/OFF, 앱 데이터 삭제를 관리합니다.
- WidgetKit 기반 빠른 기록 위젯에서 현재 대상자와 오늘 기록 요약을 확인합니다.
- Share Extension 기반 사진 공유 진입으로 사진 앱에서 AICO 기록 흐름을 시작할 수 있습니다.
- URL Scheme 딥링크로 위젯/공유 확장 진입을 메인 앱 기록 흐름에 연결합니다.

## 기술 스택

| 구분 | 기술 |
| --- | --- |
| 언어 | Swift 5.0 |
| UI | SwiftUI |
| 로컬 저장 | SwiftData |
| 로컬 상태 | AppStorage, ObservableObject |
| 사진 선택/저장 | PhotosPicker, 로컬 파일 저장 |
| 위젯 | WidgetKit |
| 공유 확장 | iOS Share Extension |
| 딥링크 | URL Scheme `aico://` |
| 타겟 간 공유 | App Group |

## 타겟 구성

| Target | 역할 | Bundle ID |
| --- | --- | --- |
| `Challenge4_AICO_Prototype` | 메인 iOS 앱 | `com.aico.prototype.challenge4` |
| `AICOWidgetExtension` | 빠른 기록 위젯 | `com.aico.prototype.challenge4.AICOWidgetExtension` |
| `AICOShareExtension` | 사진 공유 기반 기록 시작 확장 | `com.aico.prototype.challenge4.AICOShareExtension` |

| Scheme | 구성 |
| --- | --- |
| `Challenge4_AICO_Prototype` | Main App 실행 스키마입니다. BuildAction에 Main App, Widget Extension, Share Extension이 포함됩니다. |

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
  -> 홈/아카이브/리포트에서 기록 조회
```

### 위젯 데이터 흐름

```text
SwiftData 기록/대상자
  -> WidgetSnapshotBuilder
  -> WidgetSnapshotStore
  -> App Group UserDefaults
  -> AICOWidgetExtension
  -> 빠른 기록 위젯 표시
  -> aico://quick-record 딥링크
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

## TestFlight / Signing 메모

TestFlight 업로드나 팀원 실기기 실행을 위해서는 세 타겟 모두 signing 구성이 맞아야 합니다.

필요한 provisioning profile:

```text
Main App
Widget Extension
Share Extension
```

협업 개발자가 Xcode에서 직접 빌드하려면:

1. App Store Connect / Apple Developer 팀 초대를 수락합니다.
2. 역할은 보통 `앱 관리`와 `제품 개발` 권한을 사용합니다.
3. 실기기 UDID를 Apple Developer Devices에 등록합니다.
4. 세 provisioning profile에 해당 기기가 포함되어야 합니다.
5. Xcode Settings > Accounts에서 팀 계정을 추가하고 최신 profile을 받습니다.

커밋하지 말아야 할 항목:

```text
*.mobileprovision
*.p12
인증서 비밀번호
개인 Apple ID 세션 파일
DerivedData
Xcode user-specific 파일
```

## 폴더 구조

```text
Challenge4_AICO_Prototype/
├── README.md                                      # 프로젝트 개요와 개발/배포 메모
├── Docs/                                         # 제품 흐름, Git 규칙, 단계별 계획 문서
├── Challenge4_AICO_Prototype.xcodeproj/          # Xcode 프로젝트와 공유 스키마
├── Challenge4_AICO_Prototype/                    # 메인 iOS 앱 소스
│   ├── App/                                      # 앱 진입점, 루트 내비게이션, 딥링크 수신
│   ├── Core/                                     # 모델, 저장소, 상태, 딥링크, 위젯/공유 유틸
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
└── AICOShareExtension/                           # iOS Share Sheet 기반 사진 기록 진입 확장
```

## Git Strategy

- `main`: 출시 또는 배포 기준 브랜치입니다.
- `develop`: 개발된 기능들을 최종적으로 합쳐서 확인하는 기본 개발 브랜치입니다.
- feature branches: 기능 개발, 버그 수정, 문서 수정, 설정 변경 등은 별도 브랜치에서 진행합니다.

기본 작업 흐름:

1. `develop`에서 작업 브랜치를 생성합니다.
2. 작업 브랜치에서 기능을 구현합니다.
3. 작업 완료 후 최신 `develop`을 반영합니다.
4. `develop`으로 Pull Request를 요청합니다.
5. `main`에는 release 또는 배포 정리 시점에 반영합니다.

## Commit Convention

- 태그는 반드시 소문자로 작성합니다.
- 내용은 한글로 작성합니다.
- 제목은 50자를 넘지 않도록 간단하게 명령조로 작성합니다.

예시:

```text
[feat] 로그인 기능 구현
```

사용 태그:

- `init`: 초기 프로젝트 구성
- `feat`: 새로운 기능 구현
- `fix`: 버그나 오류 해결
- `docs`: README, 문서 수정
- `setting`: 프로젝트 설정 변경
- `add`: 에셋이나 라이브러리 추가
- `refactor`: 기존 코드 구조 개선
- `chore`: 기타 관리성 작업

## Branch Convention

형식:

```text
태그/#이슈번호-작업하는-파일-또는-기능
```

예시:

```text
feat/#18-caregiver-sharing-ui
fix/#15-app-icon-remove-alpha
```

## Privacy Note

실제 개인정보, 대상자 정보, 의료 기록, 실제 사진/영상, 인증 정보, 비밀 키, 런타임 이미지 파일, provisioning profile은 커밋하지 않습니다.

현재 프로토타입의 대상자/기록/사진 데이터는 로컬 개발 및 테스트 목적의 데이터로만 다룹니다.
