# Git Convention

## Tag Convention

- `init`: 가장 처음 Initial Commit에 태그 붙이기
- `feat`: 새로운 기능 구현 시 사용
- `fix`: 버그나 오류 해결 시 사용
- `docs`: README, 템플릿 등 프로젝트 내 문서 수정 시 사용
- `setting`: 프로젝트 관련 설정 변경 시 사용
- `add`: 사진 등 에셋이나 라이브러리 추가 시 사용
- `refactor`: 기존 코드를 리팩토링하거나 수정할 시 사용
- `chore`: 별로 중요한 수정이 아닐 시 사용

## Commit Convention

- 태그는 반드시 소문자로 작성합니다.
- 내용은 한글로 작성합니다.
- 제목은 50자를 넘지 않도록 간단하게 명령조로 작성합니다.
- 설명이 필요한 경우 commit description에 작성합니다.

예시:

```text
[feat] 로그인 기능 구현
```

## Branch Convention

형식:

```text
태그/#이슈번호-작업하는-파일-또는-기능
```

예시:

```text
feat/#1-loginUI
```

## Branch Strategy

### main

출시(release)에 사용하는 브랜치입니다.

### develop

개발된 기능들을 최종적으로 합쳐서 확인하는 브랜치입니다. 기본 개발 브랜치이며 개발을 마친 후에는 반드시 `develop`에 머지합니다.

### Feature Branches

태그를 붙이는 모든 작업 브랜치를 의미합니다. 기능 개발, 버그 수정, 문서 수정, 설정 변경 등은 반드시 별도 브랜치에서 진행합니다.

## Workflow

1. `develop`에서 작업 브랜치를 생성합니다.
2. 작업 브랜치에서 작업합니다.
3. 작업 완료 후 `develop`을 작업 브랜치에 병합하거나 rebase하여 최신 상태를 반영합니다.
4. `develop`으로 Pull Request를 요청합니다.
5. `main`에는 release 시점에만 병합합니다.

## Initial Setup Task

- 작업 브랜치: `setting/#1-initial-project-setup`
- 커밋 메시지: `[init] 프로젝트 초기 구조 설정`
