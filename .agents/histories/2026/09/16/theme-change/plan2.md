# 목차

- [개요](#개요)
- [Chirpy 전환 리팩터링 계획](#chirpy-전환-리팩터링-계획)
  - [목표](#목표)
  - [현재 상태](#현재-상태)
  - [설계 결정](#설계-결정)
  - [목표 구조](#목표-구조)
  - [단계별 작업 계획](#단계별-작업-계획)
  - [콘텐츠 변환 규칙](#콘텐츠-변환-규칙)
  - [파일별 변경 계획](#파일별-변경-계획)
  - [검증 계획](#검증-계획)
  - [위험 요소와 대응](#위험-요소와-대응)
  - [롤백 기준](#롤백-기준)
  - [완료 조건](#완료-조건)

---

# 개요

- Jekyll 테마를 Minimal Mistakes에서 Chirpy 7.6 계열로 변경한다.
- Experience와 Knowledge를 독립 메뉴로 유지한다.
- Category와 Tag는 두 메뉴에서 공통으로 사용하는 별도 분류 축으로 유지한다.
- 기존 게시글 URL과 콘텐츠를 보존한다.
- Chirpy 기본 기능을 최대한 사용하고 테마 내부 코드 재정의는 최소화한다.

---

# Chirpy 전환 리팩터링 계획

> 이제 리팩터 계획을 plan2에 작성해보자

## 답변

`plan1.md`에서 결정한 Chirpy 분류 축 분리 설계를 기준으로 실제 리팩터링 계획을 작성한다.
구현은 기반 환경, 소규모 검증, 전체 콘텐츠 이전, 메뉴 구성, 배포 전환, 검증 순서로 진행한다.
한 단계의 검증이 실패하면 다음 단계로 넘어가지 않는다.

계획 기준일은 2026-09-16이며 공식 Chirpy Starter 7.6 구성을 기준으로 한다.

## 목표

### 기능 목표

- Chirpy의 홈, 검색, 목차, 관련 글, Categories, Tags, Archives, 다크 모드를 사용한다.
- Experiences와 Knowledge를 사이드바의 독립 메뉴로 제공한다.
- Experiences에는 `section: experience` 글만 표시한다.
- Knowledge에는 `section: knowledge` 글만 표시한다.
- Categories와 Tags는 Section과 관계없이 모든 글을 통합 분류한다.
- 홈과 검색에서는 모든 글을 통합 제공한다.
- 기존 `/experiences/:title/`, `/knowledge/:title/` URL을 유지한다.

### 기술 목표

- Jekyll 커스텀 컬렉션을 제거하고 모든 글을 `site.posts`로 통합한다.
- 콘텐츠 파일은 `_posts/experiences`, `_posts/knowledge`로 물리적으로 분리한다.
- Chirpy Starter가 요구하는 `_config.yml`, `_plugins`, `_tabs`, `index.html` 구조를 적용한다.
- Minimal Mistakes 전용 레이아웃, include, 설정과 CSS 의존성을 제거한다.
- 테마 JavaScript는 수정하지 않는다.
- 새 Section 목록 기능은 하나의 프로젝트 소유 레이아웃으로 공통화한다.

## 현재 상태

### 기술 구성

- Jekyll: `~> 3.10`
- Ruby: GitHub Actions에서 `3.3`
- 테마: `minimal-mistakes-jekyll`
- 배포: `master` push 시 GitHub Actions에서 빌드 후 GitHub Pages 배포
- 콘텐츠: `_experiences`, `_knowledge` 커스텀 컬렉션
- 목록 구현: Minimal Mistakes의 `archive`, `posts`, `archive-single.html`에 의존

### 콘텐츠 인벤토리

- Experiences: 12개
- Knowledge: 152개
- 전체: 164개
- Category가 비어 있는 글: 1개
- Tag가 비어 있는 글: 1개
- 해당 글: `_knowledge/2025-09-01-이벤트 기반 아키텍처 Event-driven Architecture, EDA.md`

명백한 Category 표기 중복이 존재한다.

| 현재 값 | 정규화 값 |
|---|---|
| `Devops`, `Dev-ops` | `DevOps` |
| `Node.Js` | `Node.js` |
| `Typescript` | `TypeScript` |
| `Nest.Js` | `Nest.js` |

의미가 달라질 수 있는 Category와 Tag 재분류는 테마 전환 범위에 포함하지 않는다.
위와 같은 대소문자 및 구분자 차이만 정규화한다.

### 콘텐츠 호환성 확인 항목

- 이미지 절대 경로 `/assets/images/...`를 사용하는 글이 존재한다.
- `../assets/images/...` 상대 경로를 사용하는 글이 1개 존재하므로 절대 경로로 수정해야 한다.
- 한글, 공백, 괄호, 쉼표와 특수 문자가 포함된 파일명이 다수 존재한다.
- 같은 날짜에 작성 순서를 초 단위 `date` 값으로 구분한 글이 존재한다.
- 기존 `toc_sticky`는 Minimal Mistakes 전용 설정이므로 Chirpy 전환 후 제거한다.

## 설계 결정

### 버전과 의존성

- 테마는 `jekyll-theme-chirpy ~> 7.6`을 사용한다.
- Chirpy 7.6이 요구하는 Jekyll `~> 4.3`을 사용한다.
- 현재 Ruby 3.3은 Chirpy의 Ruby `~> 3.1` 조건을 충족하므로 유지한다.
- 공식 Starter와 같이 `html-proofer ~> 5.0`을 테스트 의존성으로 추가한다.
- `Gemfile.lock`으로 실제 배포 버전을 고정한다.
- Minimal Mistakes와 해당 테마에만 필요했던 Gem은 제거한다.

### 콘텐츠 분류

| 속성 | 값 | 용도 |
|---|---|---|
| `section` | `experience`, `knowledge` | 독립 메뉴 분류 |
| `categories` | `Back-end`, `DB`, `DevOps` 등 | 기술 영역 분류 |
| `tags` | `JVM`, `JPA`, `Kubernetes` 등 | 세부 기술 분류 |

`section`은 경로별 front matter defaults에서 자동으로 제공한다.
각 게시글에는 필요한 경우에만 값을 직접 덮어쓴다.

### Section 메뉴

- `_tabs/experiences.md`, `_tabs/knowledge.md`를 추가한다.
- 두 탭은 공통 `_layouts/section.html`을 사용한다.
- 레이아웃은 `site.posts`를 `page.section`으로 필터링한다.
- 152개 Knowledge 글을 한 화면에 카드로 표시하지 않고 연도별 compact archive 목록으로 표시한다.
- 별도 페이지네이션 플러그인과 커스텀 JavaScript는 추가하지 않는다.
- 테마가 제공하는 타이포그래피, 날짜 include와 링크 스타일을 재사용한다.

### URL

- Experiences 글: `/experiences/:title/`
- Knowledge 글: `/knowledge/:title/`
- Categories: Chirpy 기본 `/categories/:name/`
- Tags: Chirpy 기본 `/tags/:name/`
- Section 메뉴: `/experiences/`, `/knowledge/`

게시글 URL은 반드시 기존 URL과 일치시킨다.
기존 Category와 Tag 페이지의 내부 앵커 URL은 Chirpy의 개별 archive URL로 변경되는 것을 허용한다.

### 배포

- 기존 GitHub Pages Actions 배포 방식을 유지한다.
- Chirpy Starter의 현재 workflow를 기준으로 checkout, Pages, artifact, deploy Action 버전을 갱신한다.
- 배포 브랜치는 현재와 동일하게 `master`를 유지한다.
- 빌드 후 `html-proofer` 검증을 통과한 경우에만 배포한다.
- 정적 자산은 우선 Chirpy 기본 CDN 방식을 사용하며 별도 assets submodule은 추가하지 않는다.

## 목표 구조

```text
.
├── _config.yml
├── _data/
│   ├── contact.yml
│   └── share.yml
├── _layouts/
│   └── section.html
├── _plugins/
│   └── posts-lastmod-hook.rb
├── _posts/
│   ├── experiences/
│   │   └── YYYY-MM-DD-title.md
│   └── knowledge/
│       └── YYYY-MM-DD-title.md
├── _tabs/
│   ├── about.md
│   ├── archives.md
│   ├── categories.md
│   ├── experiences.md
│   ├── knowledge.md
│   └── tags.md
├── assets/
│   └── images/
├── .github/workflows/
│   └── jekyll.yml
├── Gemfile
├── Gemfile.lock
├── index.html
├── post.sh
└── README.md
```

기존 `_experiences`, `_knowledge`, `_pages`, `_data/navigation.yml`, Minimal Mistakes용 `assets/css/main.scss`는 대체 기능의 검증이 끝난 후 제거한다.

## 단계별 작업 계획

### 1단계: 변경 전 기준선 확보

1. 작업 시작 시 Git 상태를 확인하고 사용자 변경사항을 구분한다.
2. 현재 환경에서 가능한 경우 기존 사이트를 빌드한다.
3. 기존 게시글 164개의 원본 경로, 제목, Section, 생성 URL 목록을 기록한다.
4. 기존 이미지 파일과 본문 이미지 참조 목록을 기록한다.
5. 빈 Category·Tag와 표기 중복 목록을 기록한다.

완료 기준:

- 콘텐츠 수와 URL 비교에 사용할 기준 데이터가 준비되어 있다.
- 기존 빌드 실패가 있다면 테마 전환 문제와 구분할 수 있도록 원인을 기록했다.

### 2단계: Chirpy 기반 환경 구성

1. `Gemfile`을 Chirpy 7.6 기준으로 변경한다.
2. Jekyll 4.3과 Chirpy 의존성으로 `Gemfile.lock`을 갱신한다.
3. 공식 Starter의 `_config.yml`을 기준으로 사이트 설정을 재구성한다.
4. 기존 title, description, GitHub 계정, 이메일, 프로필 이미지와 사이트 URL을 이관한다.
5. `lang: ko-KR`, `timezone: Asia/Seoul`, 다크 모드 정책과 TOC 설정을 구성한다.
6. `_data/contact.yml`, `_data/share.yml`을 공식 Starter 형식으로 추가한다.
7. `_plugins/posts-lastmod-hook.rb`와 Chirpy 기본 탭을 추가한다.
8. `index.html`을 `layout: home`으로 변경한다.

완료 기준:

- 샘플 게시글 없이도 Chirpy 기본 화면이 빌드된다.
- 홈, Categories, Tags, Archives, About 탭이 렌더링된다.

### 3단계: 소규모 콘텐츠 이전 검증

1. Experiences와 Knowledge에서 대표 글을 각각 1개 선택한다.
2. 대표 글을 `_posts/experiences`, `_posts/knowledge`로 이동한다.
3. 경로별 defaults로 `section`, `layout`, `toc`, permalink를 적용한다.
4. 기존 `date`, title, categories, tags와 본문을 그대로 유지한다.
5. Jekyll이 하위 디렉터리의 글을 `site.posts`로 인식하는지 확인한다.
6. 생성 URL이 기존 URL과 일치하는지 확인한다.
7. 검색, Category, Tag, TOC, 이미지와 관련 글에 포함되는지 확인한다.

완료 기준:

- 두 대표 글이 Section만 다르고 공통 Categories와 Tags에 함께 나타난다.
- 두 글의 기존 URL이 유지된다.
- 검증 실패 시 전체 164개 글 이동을 시작하지 않는다.

### 4단계: 전체 콘텐츠 이전

1. `_experiences`의 12개 글을 `_posts/experiences`로 이동한다.
2. `_knowledge`의 152개 글을 `_posts/knowledge`로 이동한다.
3. 파일명과 본문은 변경하지 않는다.
4. 기존 `date`, categories, tags를 보존한다.
5. Minimal Mistakes 전용 `toc_sticky`를 제거한다.
6. 명백한 Category 표기 중복을 정규화한다.
7. Category와 Tag가 비어 있는 1개 글은 내용을 검토한 후 적절한 값을 지정한다.
8. 상대 이미지 경로 1개를 `/assets/images/...` 절대 경로로 변경한다.

완료 기준:

- `site.posts`에 총 164개 글이 존재한다.
- Experience 12개, Knowledge 152개로 Section 수가 일치한다.
- 원본 파일 164개와 이동된 파일 164개가 일대일로 대응한다.
- 누락되거나 중복 생성된 게시글 URL이 없다.

### 5단계: Experiences와 Knowledge 메뉴 구현

1. `_layouts/section.html` 공통 레이아웃을 작성한다.
2. `page.section` 값으로 게시글을 필터링한다.
3. 게시글을 날짜 역순으로 정렬하고 연도별로 그룹화한다.
4. 각 항목에는 제목, 날짜, Category와 대표 Tag를 표시한다.
5. `_tabs/experiences.md`, `_tabs/knowledge.md`에 아이콘, 순서, Section을 설정한다.
6. 사이드바 순서를 Home, Experiences, Knowledge, Categories, Tags, Archives, About 기준으로 구성한다.

완료 기준:

- 각 메뉴에 다른 Section의 글이 섞이지 않는다.
- 152개 Knowledge 목록도 모바일과 데스크톱에서 무리 없이 탐색할 수 있다.
- 목록 레이아웃을 한 파일에서 공통 관리한다.

### 6단계: 기존 테마 구성 제거

1. `_pages/experiences.md`, `_pages/knowledge.md`를 새 탭으로 대체한다.
2. `_pages/category-archive.md`, `_pages/tag-archive.md`, `_pages/year-archive.md`를 Chirpy 기본 탭으로 대체한다.
3. 기존 About 내용을 `_tabs/about.md`로 이관한다.
4. 404 페이지는 Chirpy 기본 동작을 확인한 뒤 기존 파일 유지 여부를 결정한다.
5. `_data/navigation.yml`을 제거한다.
6. Minimal Mistakes import가 있는 `assets/css/main.scss`를 제거한다.
7. `_config.yml`의 custom collections, author/footer 구형 설정과 archive 설정을 제거한다.
8. 사용하지 않는 Minimal Mistakes 관련 Gem과 플러그인을 제거한다.

완료 기준:

- 저장소에 Minimal Mistakes 레이아웃, include, Sass import 참조가 남아 있지 않다.
- 삭제한 페이지가 제공하던 기능이 Chirpy 탭 또는 Section 탭으로 대체되었다.

### 7단계: 글 작성 도구 변경

1. `post.sh`가 `_posts/experiences`, `_posts/knowledge`에 글을 생성하도록 변경한다.
2. 입력값 `e`, `k`에 따라 Section과 저장 경로를 결정한다.
3. Chirpy에서 사용하지 않는 `toc_sticky`를 생성하지 않는다.
4. categories와 tags는 빈 YAML 항목 대신 유효한 빈 배열 또는 사용자 입력 방식으로 생성한다.
5. 파일명에 사용할 수 없는 `/`와 URL에 문제가 되는 문자를 안전하게 처리한다.
6. 생성된 새 글이 기존 defaults를 통해 올바른 URL과 Section을 얻는지 확인한다.

완료 기준:

- 두 Section 모두 새 글을 생성할 수 있다.
- 생성된 front matter가 YAML 파싱과 Jekyll 빌드를 통과한다.

### 8단계: 배포 워크플로 전환

1. 기존 `.github/workflows/jekyll.yml`을 Chirpy Starter 흐름에 맞게 변경한다.
2. `master` push와 수동 실행 조건을 유지한다.
3. checkout에서 전체 Git history를 받아 last-modified 기능이 동작하게 한다.
4. Ruby 3.3과 Bundler cache를 사용한다.
5. production 빌드 후 `html-proofer`를 실행한다.
6. 검증 성공 후에만 Pages artifact를 업로드하고 배포한다.

완료 기준:

- 로컬과 GitHub Actions가 같은 Bundler lockfile을 사용한다.
- 빌드 또는 내부 링크 검증 실패 시 배포 단계가 실행되지 않는다.

### 9단계: 문서 반영과 작업 마무리

1. 모든 구현과 검증 결과를 먼저 사용자에게 설명한다.
2. 작업 마무리 요청을 받은 후 `done1.md`에 전체 작업 결과를 작성한다.
3. `calendar.md` 상태를 `DONE`으로 변경한다.
4. `README.md`의 설치, 실행, 테마, 구조와 글 작성 방법을 Chirpy 기준으로 갱신한다.
5. README에는 작업 히스토리를 기록하지 않는다.

## 콘텐츠 변환 규칙

### 이동 규칙

```text
_experiences/YYYY-MM-DD-title.md
→ _posts/experiences/YYYY-MM-DD-title.md

_knowledge/YYYY-MM-DD-title.md
→ _posts/knowledge/YYYY-MM-DD-title.md
```

Git이 파일 이동을 추적할 수 있도록 본문 수정과 파일 이동을 가능한 한 분리한다.

### Front Matter 규칙

유지:

- `title`
- `date`
- `categories`
- `tags`
- 글별 `toc` 값

경로별 defaults로 제공:

- `layout: post`
- `section`
- `comments`
- 기본 `toc`
- `permalink`

제거:

- `toc_sticky`
- Minimal Mistakes 전용 front matter가 추가로 발견되면 검토 후 제거

### URL 규칙

- 파일명에서 날짜를 제외한 기존 slug를 유지한다.
- 한글과 특수 문자가 포함된 URL이 이전과 동일하게 생성되는지 결과 HTML 기준으로 비교한다.
- URL 비교는 소스 문자열이 아니라 Jekyll이 생성한 `page.url` 목록을 기준으로 한다.

### 이미지 규칙

- 기존 `assets/images` 디렉터리는 유지한다.
- 본문 이미지 링크는 `/assets/images/...` 절대 경로를 기본으로 한다.
- 퍼센트 인코딩된 공백과 한글 경로의 실제 파일 존재 여부를 검사한다.
- 프로필 이미지는 기존 파일을 재사용하되 Chirpy `avatar` 설정 형식으로 연결한다.

## 파일별 변경 계획

| 파일 또는 디렉터리 | 계획 |
|---|---|
| `Gemfile`, `Gemfile.lock` | Chirpy 7.6, Jekyll 4.3, html-proofer 기준으로 변경 |
| `_config.yml` | Chirpy Starter 설정과 Section별 defaults 구성 |
| `_plugins/` | 공식 last-modified hook 추가 |
| `_data/contact.yml` | 기존 이메일, GitHub, 블로그 링크 이관 |
| `_data/share.yml` | 필요한 공유 채널만 활성화 |
| `_tabs/` | Experiences, Knowledge와 Chirpy 기본 탭 구성 |
| `_layouts/section.html` | Section 공통 archive 목록 구현 |
| `_posts/experiences/` | 기존 Experiences 12개 이동 |
| `_posts/knowledge/` | 기존 Knowledge 152개 이동 |
| `index.html` | Chirpy `home` 레이아웃 사용 |
| `post.sh` | 새 경로와 front matter 형식 적용 |
| `.github/workflows/jekyll.yml` | Chirpy 빌드, html-proofer, Pages 배포 적용 |
| `_pages/` | About 이관 후 테마 종속 페이지 제거 |
| `_data/navigation.yml` | `_tabs`로 대체 후 제거 |
| `assets/css/main.scss` | Minimal Mistakes import 제거, 필요 시 최소 커스텀 CSS만 별도 추가 |
| `README.md` | 작업 완료 단계에서 새 구조와 사용법 반영 |

## 검증 계획

테스트 실행은 구현 시작 승인 범위와 프로젝트 작업 규칙에 따라 진행한다.

### 정적 검증

- 모든 Markdown 파일의 YAML front matter 파싱
- 전체 글 수 164개 확인
- Section별 글 수 12개, 152개 확인
- title, date, categories, tags 필수값 검사
- 중복 permalink 검사
- 본문이 참조하는 로컬 이미지 존재 여부 검사
- Minimal Mistakes 문자열과 제거 대상 설정 잔존 여부 검색

### 빌드 검증

```bash
bundle install
bundle exec jekyll build
bundle exec htmlproofer _site --disable-external
```

- development 빌드와 production 빌드를 각각 확인한다.
- Jekyll warning과 Liquid warning도 실패 후보로 검토한다.
- 생성된 게시글 URL 목록을 변경 전 기준선과 비교한다.

### 기능 검증

- Home에 두 Section 글이 함께 표시되는지 확인
- Experiences에 12개 글만 표시되는지 확인
- Knowledge에 152개 글만 표시되는지 확인
- Back-end Category에 두 Section 글이 함께 표시되는지 확인
- JVM Tag에 두 Section 글이 함께 표시되는지 확인
- 검색에서 두 Section 글을 모두 찾을 수 있는지 확인
- 게시글 TOC, 코드 블록, 관련 글과 이전·다음 글 확인
- Archives의 연도별 글 수 확인
- About, 404, feed, sitemap, robots.txt 확인
- 라이트·다크 모드 전환과 설정 유지 확인

### 화면 검증

- 데스크톱과 모바일 viewport에서 Home, Section 목록, 게시글을 확인한다.
- 사이드바 메뉴와 긴 한글 제목이 겹치거나 잘리지 않는지 확인한다.
- Knowledge 152개 목록이 과도한 카드 UI 없이 읽기 쉬운지 확인한다.
- 이미지가 깨지지 않고 본문 폭을 넘지 않는지 확인한다.
- 코드 블록과 표가 모바일에서 가로 스크롤 또는 반응형으로 표시되는지 확인한다.

### 배포 검증

- GitHub Actions build job 성공
- html-proofer 성공 후 deploy job 실행
- 배포 URL에서 CSS, JavaScript와 검색 데이터 로딩 확인
- 대표 기존 URL에 직접 접근해 404가 발생하지 않는지 확인
- Pages 환경의 base path가 중복 적용되지 않는지 확인

## 위험 요소와 대응

### 하위 `_posts` 디렉터리 인식

위험:

- Jekyll 버전과 설정에 따라 `_posts/experiences`, `_posts/knowledge`의 처리 결과를 실제로 확인해야 한다.

대응:

- 2개 대표 글로 먼저 검증하고 실패하면 전체 이동을 중단한다.
- 실패 시 파일은 루트 `_posts`로 두고 `section` front matter만 사용하는 대안을 적용한다.

### URL 변경

위험:

- 커스텀 컬렉션 문서와 Post의 `:title` 처리 차이로 한글·특수 문자 URL이 달라질 수 있다.

대응:

- 변경 전후 생성 URL을 자동 비교한다.
- defaults로 해결되지 않는 글에만 명시적 `permalink`를 추가한다.

### Category와 Tag archive

위험:

- 표기 중복 때문에 사실상 같은 분류가 여러 archive 페이지로 생성될 수 있다.

대응:

- 대소문자와 하이픈 차이만 정규화하고 의미 재분류는 별도 작업으로 남긴다.

### 테마 업데이트 결합도

위험:

- Section 레이아웃이 Chirpy 내부 include와 마크업에 과도하게 의존하면 업데이트가 어려워진다.

대응:

- 공통 레이아웃 하나만 프로젝트가 소유한다.
- 테마 파일 전체를 복사하거나 JavaScript를 재정의하지 않는다.
- Chirpy 버전 갱신 시 Section 목록과 관련 include를 회귀 검증한다.

### 대량 파일 이동

위험:

- 164개 글의 누락, 중복 또는 본문 변경이 발생할 수 있다.

대응:

- 이동 전후 파일 수, 제목, 해시와 URL을 비교한다.
- 파일 이동과 front matter 정리를 구분해 검토한다.
- 관련 없는 사용자 변경은 수정하거나 되돌리지 않는다.

## 롤백 기준

다음 중 하나라도 해결되지 않으면 배포하지 않고 해당 단계 이전 상태로 돌아간다.

- 164개 글 중 하나라도 누락됨
- 기존 게시글 URL을 보존할 수 없음
- Experiences와 Knowledge 필터 결과가 정확하지 않음
- 검색, Categories 또는 Tags에 글이 누락됨
- production 빌드 또는 html-proofer 실패
- 주요 이미지나 내부 링크가 깨짐
- 모바일에서 메뉴나 본문을 정상적으로 사용할 수 없음

파일 이동은 Git이 추적 가능한 방식으로 진행해 역방향 이동이 가능하게 한다.
파괴적인 Git 명령은 사용하지 않는다.

## 완료 조건

- Chirpy 7.6과 Jekyll 4.3으로 로컬 production 빌드가 성공한다.
- GitHub Actions의 build, link check, deploy 단계가 모두 성공한다.
- 기존 게시글 164개가 모두 보존된다.
- 기존 Experiences와 Knowledge 게시글 URL이 유지된다.
- Experiences와 Knowledge가 독립 사이드바 메뉴로 동작한다.
- Category와 Tag가 두 Section을 가로질러 올바르게 집계된다.
- 검색, 목차, 관련 글, Archives, 다크 모드가 정상 동작한다.
- 데스크톱과 모바일 화면 검증을 통과한다.
- `post.sh`로 두 Section의 새 글을 생성할 수 있다.
- Minimal Mistakes 전용 의존성과 참조가 제거된다.
- 작업 결과 설명 후 `done1.md`, `calendar.md`, `README.md`가 프로젝트 규칙에 맞게 반영된다.
