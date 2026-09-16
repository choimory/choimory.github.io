# choimory

`choimory.github.io`에서 운영하는 개인 기술 블로그입니다. Jekyll과 Chirpy를 기반으로 하며, 글의 성격에 따라 Experiences와 Knowledge를 독립 메뉴로 제공하면서 Categories와 Tags는 전체 글에서 공통으로 사용합니다.

## 목차

- [기술 스택](#기술-스택)
- [콘텐츠 아키텍처](#콘텐츠-아키텍처)
- [메뉴와 화면 구성](#메뉴와-화면-구성)
- [프로젝트 구조](#프로젝트-구조)
- [글 작성](#글-작성)
- [로컬 실행](#로컬-실행)
- [빌드와 검증](#빌드와-검증)
- [배포](#배포)

## 기술 스택

- Ruby 3.3
- Jekyll 4.4.1
- [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 7.6.0
- Docker
- GitHub Pages
- GitHub Actions

Chirpy 7.6.0의 Ruby 요구사항은 `~> 3.1`입니다. 프로젝트는 Ruby 3.3 Docker 이미지로 실행하므로 호스트에 Ruby와 Bundler를 설치할 필요가 없습니다.

## 콘텐츠 아키텍처

모든 글은 Jekyll의 `posts` 컬렉션에 속하며 저장 디렉터리에 따라 섹션과 URL이 결정됩니다.

| 저장 위치 | `section` | URL |
| --- | --- | --- |
| `_posts/experiences` | `experience` | `/experiences/:title/` |
| `_posts/knowledge` | `knowledge` | `/knowledge/:title/` |

`_config.yml`의 front matter 기본값이 `section`, `layout`과 permalink를 적용하므로 개별 글에서 이를 반복해서 선언하지 않습니다.

### 분류 기준

- `section`: Experiences 또는 Knowledge 메뉴를 결정합니다. 저장 디렉터리에서 자동으로 설정됩니다.
- `categories`: 글의 기술 또는 주제 영역을 나타냅니다. 두 섹션 전체에서 공통으로 집계됩니다.
- `tags`: 글의 세부 기술과 키워드를 나타냅니다. 두 섹션 전체에서 공통으로 집계됩니다.

현재 사용하는 표준 카테고리는 다음과 같습니다.

- `Back-end`
- `CS`
- `DB`
- `DevOps`
- `Front-end`
- `JVM`
- `Nest.js`
- `Network`
- `Node.js`
- `TypeScript`

기존 표기와 동일한 카테고리를 우선 사용하고, 태그도 대소문자와 기술의 공식 표기를 일관되게 유지합니다.

## 메뉴와 화면 구성

사이드바 메뉴는 `_tabs` 컬렉션으로 관리하며 다음 순서로 표시됩니다.

1. Experiences
2. Knowledge
3. Categories
4. Tags
5. Archives
6. About

Experiences와 Knowledge는 `_layouts/section.html`을 사용해 해당 `section`의 글만 연도별로 표시합니다. Categories와 Tags는 모든 post를 대상으로 Chirpy와 `jekyll-archives`가 생성합니다.

사이트 언어는 `ko-KR`이며 `_data/locales/ko-KR.yml`에서 사이드바 탭 이름만 영어로 덮어씁니다. 사이트명, 소개, 프로필 이미지와 기타 전역 설정은 `_config.yml`에서 관리합니다.

## 프로젝트 구조

```text
.
├── .github/workflows/jekyll.yml   # GitHub Pages 빌드 및 배포
├── .dockerignore                  # Docker build context 제외 목록
├── _config.yml                    # 사이트, 컬렉션, URL과 Chirpy 설정
├── _data/
│   ├── contact.yml                # 사이드바 연락처 링크
│   ├── locales/ko-KR.yml          # 한국어 UI의 탭 이름 재정의
│   └── share.yml                  # 글 공유 서비스
├── _layouts/section.html          # Experiences/Knowledge 연도별 목록
├── _plugins/posts-lastmod-hook.rb # Git 이력 기반 최종 수정일 계산
├── _posts/
│   ├── experiences/               # 경험과 적용 사례
│   └── knowledge/                 # 개념과 기술 지식
├── _tabs/                         # 사이드바 탭 페이지와 표시 순서
├── assets/images/                 # 프로필 및 글 첨부 이미지
├── Dockerfile                     # Ruby 3.3 기반 로컬 실행 이미지
├── Gemfile                        # Ruby gem 의존성
├── Gemfile.lock                   # 해석된 의존성 버전
├── index.html                     # Chirpy 홈 레이아웃 진입점
├── local.sh                       # Docker 실행, 검증 및 정리 스크립트
└── post.sh                        # 새 글 생성 스크립트
```

`_plugins/posts-lastmod-hook.rb`는 각 글의 Git 이력을 조회해 수정 커밋이 두 개 이상이면 `last_modified_at`을 설정합니다. 이 기능 때문에 CI checkout은 전체 Git 이력을 가져옵니다.

## 글 작성

### 생성 스크립트

Experience 글을 생성합니다.

```bash
./post.sh e "글 제목"
```

Knowledge 글을 생성합니다.

```bash
./post.sh k "글 제목"
```

대문자 `E`, `K`도 사용할 수 있습니다. 스크립트는 현재 날짜를 사용해 `YYYY-MM-DD-제목.md` 파일을 해당 디렉터리에 생성하며, 제목의 `/`는 파일명에서 `-`로 치환합니다.

같은 날짜와 제목의 파일이 이미 있으면 덮어쓸 수 있으므로 생성 전에 기존 파일을 확인합니다.

### Front matter

생성된 글의 front matter에서 `categories`와 `tags`를 채운 뒤 본문을 작성합니다.

```yaml
---
title: "글 제목"
date: YYYY-MM-DDT00:00:00
toc: true
categories:
  - Back-end
tags:
  - JVM
  - JPA
---
```

- 파일명은 `YYYY-MM-DD-제목.md` 형식을 유지합니다.
- `section`, `layout`, permalink는 직접 작성하지 않습니다.
- `toc`는 글의 목차 표시 여부를 제어합니다.
- 글 이미지는 `assets/images` 아래에 저장하고 본문에서는 `/assets/images/...` 절대 경로로 참조합니다.

## 로컬 실행

Docker daemon이 실행 중인 상태에서 다음 명령을 사용합니다. 이미지 빌드, port 연결과 소스 volume 설정은 `local.sh`가 처리합니다.

```bash
./local.sh serve
```

실행 후 `http://localhost:4000`에서 확인합니다. 다른 포트를 사용하려면 `PORT` 환경 변수를 지정합니다.

```bash
PORT=4001 ./local.sh serve
```

서버를 종료하면 `--rm`으로 실행된 컨테이너가 자동 삭제됩니다. gem 의존성은 이미지에 포함되며 별도 named volume은 만들지 않습니다.

## 빌드와 검증

production 사이트를 생성합니다.

```bash
./local.sh build
```

생성된 HTML의 이미지, 내부 링크와 스크립트를 검증합니다.

```bash
./local.sh test
```

`test`는 production 빌드를 먼저 실행한 후 `html-proofer`를 수행합니다.

로컬 이미지와 Jekyll 생성물을 정리합니다.

```bash
./local.sh clean
```

`clean`은 `choimory-blog:local` 이미지와 `_site`, `.jekyll-cache`, `.sass-cache`만 삭제합니다. 다른 프로젝트에서 사용하는 Docker build cache는 건드리지 않습니다.

## 배포

`.github/workflows/jekyll.yml`이 GitHub Pages 배포를 담당합니다.

1. `master` 브랜치에 변경사항을 push하거나 workflow를 수동 실행합니다.
2. 전체 Git 이력을 checkout합니다.
3. Ruby 3.3과 Bundler 의존성을 준비합니다.
4. `JEKYLL_ENV=production`으로 사이트를 빌드합니다.
5. `html-proofer`로 생성 결과를 검증합니다.
6. Pages artifact를 업로드하고 GitHub Pages에 배포합니다.

저장소를 처음 설정할 때는 GitHub의 **Settings > Pages > Source**를 **GitHub Actions**로 지정해야 합니다. `README.md`, `.gitignore`, `LICENSE`만 변경된 push는 배포 workflow를 실행하지 않습니다.
