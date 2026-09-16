# 개요

- Chirpy 테마 전환과 후속 사이드바 변경으로 프로젝트 구조와 운영 방법이 크게 달라졌다.
- 현재 구현을 기준으로 `README.md`의 기술 문서를 전반적으로 현행화한다.
- 작업 과정이나 변경 히스토리는 README에 기록하지 않고 `.agents/histories`에서 관리한다.

---

# README 반영 범위

## 테마와 실행 환경

- Minimal Mistakes에서 `jekyll-theme-chirpy` 7.6.0으로 전환된 내용을 반영한다.
- 실제 의존성으로 사용 중인 Jekyll 4.4.1을 명시한다.
- 로컬 기본 Ruby 4.0.6 대신 Ruby 3.3 Docker 환경에서 빌드하고 검증하는 방법을 설명한다.

## 콘텐츠 구조

- 기존 `_experiences`, `_knowledge` 컬렉션 설명을 제거한다.
- 현재 구조인 `_posts/experiences`, `_posts/knowledge`를 설명한다.
- 디렉터리별 front matter 기본값으로 `section`과 permalink가 적용되는 구조를 설명한다.
- Experiences와 Knowledge가 독립 메뉴 및 URL을 유지하는 방식을 설명한다.

## 분류 체계

- Categories와 Tags는 Experiences 및 Knowledge 전체 글에서 공통으로 집계된다는 점을 설명한다.
- `section`, `categories`, `tags` 각각의 역할과 사용 기준을 정리한다.
- 카테고리 및 태그 표기 규칙과 현재 정규화된 명칭을 반영한다.

## URL 구조

- Experience 글은 `/experiences/:title/` 형식을 사용한다.
- Knowledge 글은 `/knowledge/:title/` 형식을 사용한다.
- 테마 전환 후에도 기존 글 URL을 유지하도록 구성한 방식을 설명한다.

## 메뉴와 화면 구성

- `_tabs`를 이용한 Experiences, Knowledge, Categories, Tags, Archives, About 메뉴 구조를 설명한다.
- `_layouts/section.html`이 Experiences와 Knowledge의 연도별 글 목록을 생성하는 역할을 설명한다.
- 사이트 언어는 `ko-KR`로 유지하면서 `_data/locales/ko-KR.yml`에서 일부 메뉴만 영어로 덮어쓰는 구조를 설명한다.
- 사이트명, 소개와 프로필 이미지는 `_config.yml`에서 관리한다는 점을 명시한다.

## 글 작성 방법

- `post.sh`의 현재 사용 방법을 설명한다.
- `e` 옵션은 `_posts/experiences`, `k` 옵션은 `_posts/knowledge`에 글을 생성한다는 점을 명시한다.
- 생성되는 front matter와 글 작성 시 필요한 categories, tags 작성 규칙을 정리한다.

## 빌드와 검증

- production Jekyll 빌드 명령을 현재 환경에 맞게 갱신한다.
- `html-proofer`를 이용한 이미지, 내부 링크와 스크립트 검증 방법을 설명한다.
- 필요하면 Docker 기반 로컬 미리보기 실행 방법도 포함한다.

## 배포

- 현재 `.github/workflows/jekyll.yml`의 GitHub Pages 배포 흐름을 설명한다.
- master 브랜치 반영, Ruby 설정, production 빌드, `html-proofer`, Pages artifact 업로드 및 배포 단계를 정리한다.

## 프로젝트 구조

- 현재 파일과 디렉터리를 기준으로 README의 프로젝트 구조를 다시 작성한다.
- `_config.yml`, `_data`, `_layouts`, `_plugins`, `_posts`, `_tabs`, `assets`, `post.sh`, GitHub Actions의 역할을 설명한다.
- 삭제된 Minimal Mistakes 전용 구조와 존재하지 않는 컬렉션을 README에서 제거한다.

---

# 작성 원칙

- 현재 코드와 설정에서 확인할 수 있는 사실만 기록한다.
- 작업 날짜, 계획 번호, 구현 과정과 같은 히스토리는 기록하지 않는다.
- 처음 프로젝트를 접하는 사람이 글 작성, 로컬 실행, 검증과 배포 구조를 이해할 수 있도록 작성한다.
- 명령어는 실제 실행 가능한 현재 명령을 기준으로 작성한다.
- 중복 설명을 줄이고 프로젝트 구조, 설정, 운영 방법을 중심으로 구성한다.

---

# 현행 README 분석

## 분석 결론

- 현재 README는 대부분 Minimal Mistakes 기준으로 작성되어 있다.
- 현재 Chirpy 구현과 맞지 않는 설명이 많아 부분 수정이 아니라 전체 재구성이 적절하다.

## 유지 가능한 내용

- `master` 브랜치에 push하면 GitHub Pages 배포 workflow가 실행된다는 설명
- GitHub Pages Source를 GitHub Actions로 설정하는 안내
- 포스트 파일의 `YYYY-MM-DD-제목.md` 이름 규칙
- `_config.yml`, `Gemfile`, `assets`의 일반적인 역할

## 삭제하거나 교체할 내용

- `brew install ruby`로 최신 Ruby를 설치하는 안내
  - Chirpy 7.6.0의 Ruby 요구사항은 `~> 3.1`이므로 Ruby 4를 지원하지 않는다.
- Minimal Mistakes 테마 설명과 관련 링크
- `_data/navigation.yml`, `_pages`, 상단 메뉴 관리 설명
- Minimal Mistakes 전용 `toc_sticky` front matter
- `_posts` 하위 디렉터리를 사용할 수 없다는 설명
- `./post.sh "글 제목"` 형식의 기존 스크립트 사용법
- Posts, Categories, Tags, About으로 구성된 기존 메뉴 설명

## 새로 작성할 내용

- Chirpy 7.6.0, Jekyll 4.4.1과 Ruby 3.3 실행 환경
- `_posts/experiences`, `_posts/knowledge` 콘텐츠 구조
- 저장 위치에 따라 자동 적용되는 `section`과 permalink
- Experiences와 Knowledge 독립 메뉴 및 공통 Categories와 Tags 구조
- `_tabs`와 `_layouts/section.html`의 역할
- `_data/locales/ko-KR.yml`을 이용한 부분 영문화
- `_plugins/posts-lastmod-hook.rb`의 Git 이력 기반 수정일 계산
- `./post.sh e "제목"`, `./post.sh k "제목"` 사용법
- Docker 기반 로컬 실행, production 빌드와 `html-proofer` 검증
- GitHub Actions의 checkout, 빌드, 검증, artifact 업로드와 deploy 단계

## 권장 README 구성

1. 프로젝트 개요
2. 기술 스택과 요구 환경
3. 콘텐츠 아키텍처
4. 프로젝트 구조
5. 글 작성 방법과 front matter
6. 로컬 실행
7. 빌드 및 검증
8. 배포 구조

## 문서화 판단

- 현재 글 개수는 계속 변경되므로 README에 고정하지 않는다.
- 전체 태그 목록은 변경 빈도가 높고 항목이 많으므로 README에 나열하지 않는다.
- 현재 사용하는 표준 카테고리 10개는 글 작성 규칙으로 정리할 수 있다.
  - Back-end
  - CS
  - DB
  - DevOps
  - Front-end
  - JVM
  - Nest.js
  - Network
  - Node.js
  - TypeScript
- `README2.md`에는 Minimal Mistakes starter 내용이 남아 있지만 현재 Jekyll 빌드에서는 제외된다.
- `README2.md` 정리는 README 현행화와 별도의 정리 대상으로 판단한다.

---

# 작업 계획

1. 현재 `README.md`의 내용을 분석하고 유지할 내용과 제거할 내용을 구분한다.
2. 실제 프로젝트 구조, 설정, 스크립트와 workflow를 README 내용과 대조한다.
3. 프로젝트 개요와 기술 스택을 Chirpy 기반으로 현행화한다.
4. 콘텐츠 구조, 분류 체계, URL과 메뉴 구조를 문서화한다.
5. 글 작성, 로컬 실행, 빌드, 검증과 배포 방법을 현재 명령으로 갱신한다.
6. 프로젝트 디렉터리 구조와 주요 파일의 역할을 갱신한다.
7. README에 작업 히스토리가 섞이지 않았는지 확인한다.
8. 문서의 링크, 명령어, 파일 경로와 Markdown 형식을 검증한다.

---

# 변경 예정 파일

- `README.md`
