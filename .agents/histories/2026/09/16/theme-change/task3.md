# 목차

- [개요](#개요)
- [README 현행화](#readme-현행화)

---

# 개요

- `plan4.md`에 따라 프로젝트의 현재 구조와 운영 방법을 `README.md`에 반영한다.
- 작업 히스토리는 제외하고 프로젝트의 기술 정보만 문서화한다.

---

# README 현행화

## 작업 상태

- 구현 및 검증 완료
- 작업 완료

## 구현 내용

- Minimal Mistakes 기반의 기존 README를 Chirpy 7.6.0과 Jekyll 4.4.1 기준으로 전면 재작성했다.
- Ruby 3.3 기준과 Chirpy의 Ruby 지원 범위를 명시했다.
- Experiences와 Knowledge의 저장 위치, `section`, permalink 구조를 문서화했다.
- 공통 Categories와 Tags의 역할 및 표준 카테고리 목록을 정리했다.
- `_tabs`, 부분 로케일, 섹션 레이아웃과 Git 기반 수정일 hook의 역할을 설명했다.
- 현재 프로젝트 디렉터리와 주요 파일의 역할을 정리했다.
- `post.sh`의 Experience 및 Knowledge 글 생성 방법과 front matter 작성 규칙을 갱신했다.
- Docker 및 로컬 Ruby 실행, production 빌드와 `html-proofer` 검증 명령을 작성했다.
- GitHub Actions의 Pages 빌드, 검증과 배포 흐름을 문서화했다.
- README의 주요 절로 바로 이동할 수 있는 목차를 추가했다.

## 검증 결과

- README에 기록한 파일 및 디렉터리 경로 존재 확인
- 실제 글에서 사용하는 표준 카테고리 10개와 문서 목록 일치 확인
- Minimal Mistakes 및 `toc_sticky` 관련 낡은 설명 제거 확인
- Markdown 코드 fence와 문서 구조 확인
- Kramdown GFM 기반 Markdown 렌더링 성공
- 목차 링크와 실제 제목 anchor의 일치 확인
- production Jekyll 빌드 성공
- `html-proofer`로 생성 결과 345개 파일, 내부 링크 2,764개 검증 성공
- `git diff --check` 통과
