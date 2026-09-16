# 목차

- [개요](#개요)
- [테마 변경 후보 조사](#테마-변경-후보-조사)
  - [현재 프로젝트 분석](#현재-프로젝트-분석)
  - [테마 선정 기준](#테마-선정-기준)
  - [후보 비교](#후보-비교)
  - [후보 상세](#후보-상세)
  - [추천 순위](#추천-순위)
  - [변경 시 영향 범위](#변경-시-영향-범위)
  - [다음 단계](#다음-단계)
- [Chirpy 콘텐츠 구분 방안](#chirpy-콘텐츠-구분-방안)
  - [요구사항](#요구사항)
  - [권장 구조](#권장-구조)
  - [화면 구성](#화면-구성)
  - [기존 URL 보존](#기존-url-보존)
  - [커스텀 컬렉션 유지 방식](#커스텀-컬렉션-유지-방식)
  - [결론](#결론)
- [Chirpy 분류 축 분리 설계](#chirpy-분류-축-분리-설계)
  - [분류 모델](#분류-모델)
  - [최종 디렉터리 구조](#최종-디렉터리-구조)
  - [Front Matter 구조](#front-matter-구조)
  - [화면별 역할](#화면별-역할)
  - [경로별 기본값](#경로별-기본값)
  - [최종 결정](#최종-결정)

---

# 개요

- 이 프로젝트는 jekyll theme으로 작성하여 github pages에 배포하는 깃헙 블로그임
- 테마가 질려서 바꾸고 싶음
- 적용할수 있는 테마 리스트들을 찾아서 내가 확인할수 있게 링크를 적어주면 내가 보고 어떤 테마로 변경할지 선택할게

---

# 테마 변경 후보 조사

> 이 프로젝트 테마를 바꾸고 싶어 plan1 만들어줘

## 답변

현재 프로젝트의 콘텐츠 구조와 GitHub Pages 배포 방식을 기준으로 적용 가능한 Jekyll 테마를 조사했다.
기술 블로그 기능을 가장 중요하게 보면 Chirpy가 우선 후보이며, 기존 컬렉션 구조를 최대한 유지하려면 So Simple이 유리하다.
아래 공식 데모에서 디자인과 사용성을 확인한 뒤 적용할 테마를 선택한다.

조사 기준일은 2026-09-16이다.

## 현재 프로젝트 분석

- 현재 테마: `minimal-mistakes-jekyll`
- Jekyll 버전: `~> 3.10`
- Ruby 버전: GitHub Actions에서 `3.3` 사용
- 배포 방식: `master` 브랜치 push 시 GitHub Actions로 직접 빌드 및 GitHub Pages 배포
- 콘텐츠 구조: `_experiences`, `_knowledge` 커스텀 컬렉션 사용
- 고정 URL: `/experiences/:title/`, `/knowledge/:title/`
- 주요 기능: 검색, 작성자 프로필, 목차, 읽기 시간, 관련 글, 카테고리, 태그, 반응형 레이아웃
- 테마 종속 요소: `single`, `archive`, `posts` 레이아웃과 `archive-single.html` include
- 커스텀 스타일: 최대 폭, 본문 글자 크기, `h2` 밑줄 제거

테마만 교체해도 기존 페이지가 그대로 동작하는 구조는 아니다. 특히 컬렉션 목록, 카테고리·태그 페이지와 각 문서의 기본 레이아웃은 선택한 테마에 맞게 변경해야 한다.

## 테마 선정 기준

- 기술 문서와 긴 글의 가독성
- 다크 모드 지원
- 검색과 목차 지원
- 코드 하이라이팅과 Mermaid 지원 가능 여부
- 카테고리와 태그 지원
- 현재 커스텀 컬렉션 유지 가능 여부
- GitHub Actions 및 GitHub Pages 배포 호환성
- 최근 유지보수 상태와 문서 품질
- 기존 URL과 콘텐츠를 보존하는 데 필요한 변경량

## 후보 비교

| 후보 | 기술 블로그 적합도 | 다크 모드 | 검색 | 목차 | 컬렉션 호환성 | 예상 이전 난이도 |
|---|---|---|---|---|---|---|
| Chirpy | 매우 높음 | 자동/수동 전환 | 기본 제공 | 기본 제공 | 추가 작업 필요 | 높음 |
| So Simple | 높음 | 고정 스킨 | 기본 제공 | 별도 보완 가능 | 높음 | 중간 |
| TeXt | 높음 | 다크 스킨 | 기본 제공 | 기본 제공 | 추가 작업 필요 | 중간~높음 |
| al-folio | 중간~높음 | 자동/수동 전환 | 플러그인 제공 | 지원 | 높음 | 높음 |
| Hydejack | 높음 | 제공 | PRO 기능 | PRO 기능 | 추가 작업 필요 | 중간~높음 |

## 후보 상세

### 1. Chirpy

- 공식 데모: https://chirpy.cotes.page/
- 공식 저장소: https://github.com/cotes2020/jekyll-theme-chirpy
- 공식 시작 템플릿: https://github.com/cotes2020/chirpy-starter
- 라이선스: MIT
- 현재 공식 Gem 버전: `7.6.0`
- 주요 특징: 기술 글 중심 디자인, 라이트·다크 모드, 검색, 자동 목차, 계층형 카테고리, 태그, Mermaid, PWA, 댓글, SEO
- 장점: 현재 블로그 주제와 가장 잘 맞고 모바일·데스크톱에서 탐색 구조가 명확함
- 단점: 최신 버전이 Jekyll `~> 4.3`을 요구하므로 현재 Jekyll `3.10`에서 업그레이드해야 함
- 마이그레이션 고려사항: 기본적으로 `_posts` 중심이므로 `_experiences`, `_knowledge`를 유지하려면 레이아웃을 확장해야 하고, 표준 구조로 옮기면 콘텐츠 파일 이동과 URL 보존 설정이 필요함

### 2. So Simple

- 공식 데모: https://mmistakes.github.io/so-simple-theme/
- 공식 저장소: https://github.com/mmistakes/so-simple-theme
- 라이선스: MIT
- 공식 문서 기준 버전: `3.2.0`
- 주요 특징: 글 중심의 단정한 레이아웃, 검색, 카테고리·태그, 페이지네이션, 코드 하이라이팅, 컬렉션 전용 레이아웃, 기본·라이트·다크 스킨
- 장점: Minimal Mistakes와 같은 제작자가 만든 테마이고 커스텀 컬렉션 레이아웃을 공식 지원하므로 현재 구조를 유지하기 가장 쉬운 후보
- 단점: 다크 모드는 방문자가 전환하는 방식이 아니라 사이트 스킨을 지정하는 방식이며, 디자인 변화가 Chirpy나 Hydejack보다 절제되어 있음
- 마이그레이션 고려사항: `experiences`, `knowledge`를 collection 레이아웃에 연결하고 Minimal Mistakes 전용 include만 교체하면 됨

### 3. TeXt

- 공식 데모: https://kitian616.github.io/jekyll-TeXt-theme/
- 레이아웃 샘플: https://kitian616.github.io/jekyll-TeXt-theme/samples.html
- 공식 저장소: https://github.com/kitian616/jekyll-TeXt-theme
- 라이선스: MIT
- 주요 특징: 6개 스킨, 검색, 목차, 다국어, 작성자, Mermaid, MathJax, Chart.js, 다양한 글·목록 레이아웃
- 장점: 화면 구성과 글 목록 스타일 선택지가 많고 한국어 UI도 지원함
- 단점: 현재 컬렉션용 목록과 카테고리·태그 통합 페이지는 프로젝트에 맞게 직접 구성해야 함
- 유지보수 참고: 공식 데모 하단 표기가 2021년으로 남아 있으므로 선택 전에 최신 Ruby/Jekyll 조합의 실제 빌드를 검증할 필요가 있음

### 4. al-folio

- 공식 데모: https://alshedivat.github.io/al-folio/
- 공식 저장소: https://github.com/alshedivat/al-folio
- 라이선스: MIT
- 주요 특징: 라이트·다크 모드, 블로그, 검색 플러그인, 커스텀 컬렉션, Mermaid와 수식, 프로젝트·이력·논문 페이지
- 장점: 블로그를 개발자 포트폴리오까지 확장하려는 경우 가장 풍부한 구성을 제공함
- 단점: 학술·포트폴리오 성격이 강해 순수 기술 블로그에는 불필요한 기능이 많음
- 마이그레이션 고려사항: 최신 `v1.x`는 여러 플러그인 Gem으로 기능이 분리된 구조이므로 기존 프로젝트에 테마만 바꾸는 방식보다 새 스타터에 콘텐츠를 이관하는 방식이 적합함

### 5. Hydejack

- 공식 데모: https://hydejack.com/
- 공식 저장소: https://github.com/hydecorp/hydejack
- 라이선스: 무료판 GPL-3.0, PRO 별도 라이선스
- 주요 특징: 강한 개인 브랜딩, 사이드바, 화면 전환 애니메이션, 코드 하이라이팅, 수식, 카테고리·태그, 다크 모드
- 장점: 다른 후보와 시각적으로 가장 뚜렷하게 다르고 블로그·포트폴리오 조합에 적합함
- 단점: 내장 검색과 목차는 PRO 기능이며 공식 사이트 기준 PRO는 79달러 일회성 구매임
- 마이그레이션 고려사항: 무료판만 사용할 경우 현재 제공 중인 검색과 목차 기능을 별도로 구현해야 함

## 추천 순위

1. **Chirpy**: 콘텐츠 구조를 일부 바꾸더라도 현대적인 기술 블로그 경험을 우선할 때
2. **So Simple**: 기존 컬렉션과 URL을 유지하면서 안정적으로 디자인을 바꿀 때
3. **TeXt**: 다양한 레이아웃과 스킨을 직접 조정하고 싶을 때
4. **al-folio**: 향후 포트폴리오, 프로젝트, 이력 페이지까지 확장할 때
5. **Hydejack**: 강한 시각적 변화가 중요하고 PRO 구매도 고려할 수 있을 때

현재 요구사항만 보면 **Chirpy와 So Simple 두 후보를 먼저 비교하는 것이 적합하다.**
Chirpy는 결과물의 기능과 현대성이 강점이고, So Simple은 마이그레이션 위험과 작업량이 적다는 점이 강점이다.

## 변경 시 영향 범위

선택한 테마에 따라 다음 파일들이 변경 대상이 된다.

- `Gemfile`, `Gemfile.lock`: 테마와 Jekyll 의존성 변경
- `_config.yml`: 테마 설정, 플러그인, 기본 레이아웃, 작성자 정보 변경
- `assets/css/main.scss`: 기존 Minimal Mistakes import 제거 및 새 테마 스타일 적용
- `_pages/*.md`: 테마별 레이아웃과 목록 페이지 구조 변경
- `index.html`: 최신 글 목록을 새 테마 컴포넌트에 맞게 변경
- `_data/navigation.yml`: 새 테마의 내비게이션 데이터 형식에 맞게 변경
- `.github/workflows/jekyll.yml`: 선택한 테마가 요구하는 Ruby, Node.js, 빌드 단계 반영
- `_experiences`, `_knowledge`: 컬렉션 유지 여부에 따라 front matter 또는 파일 위치 변경
- `README.md`: 최종 구현 완료 시 새 테마와 프로젝트 구조 반영

기존 게시글 URL은 외부 링크와 검색 색인을 보호하기 위해 그대로 유지하는 것을 기본 원칙으로 한다.

## 다음 단계

1. 공식 데모에서 디자인과 모바일 화면을 확인한다.
2. 적용할 테마를 하나 선택한다.
3. 커스텀 컬렉션을 유지할지 `_posts`로 통합할지 결정한다.
4. 선택한 테마 기준의 상세 구현 계획을 `plan2.md`에 작성한다.
5. 구현 시작 요청을 받으면 calendar 상태를 `TASK`로 변경하고 작업한다.

---

# Chirpy 콘텐츠 구분 방안

> chirpy가 좋을거 같음. 근데 글을 posts에 몰아넣는거 말고 knowledge, experience 이런 나만의 메뉴를 블로그에 만들어서 표현하고 싶은건 포기하고 싶지 않은데

> **변경됨:** 이 절의 `knowledge/_posts`, `experiences/_posts` 구조는 이후 논의에서 분류 축이 섞이는 문제가 확인되었다. 최종안은 아래의 [Chirpy 분류 축 분리 설계](#chirpy-분류-축-분리-설계)를 따른다.

## 답변

Knowledge와 Experiences 구분을 포기할 필요는 없다.
Chirpy에는 게시글로 인식시키면서 소스 디렉터리와 블로그 메뉴에서는 두 콘텐츠 영역을 명확하게 분리하는 방식을 사용한다.

## 요구사항

- Knowledge와 Experiences를 독립된 콘텐츠 영역으로 유지한다.
- 모든 글을 하나의 `_posts` 디렉터리에 평면적으로 모으지 않는다.
- 블로그 사이드바에서 Knowledge와 Experiences를 각각 별도 메뉴로 제공한다.
- 기존 `/knowledge/:title/`, `/experiences/:title/` URL을 유지한다.
- Chirpy의 검색, 목차, 관련 글, 카테고리, 태그, 최신 글 기능을 사용할 수 있어야 한다.
- 향후 Chirpy 버전 업데이트 시 커스텀 코드로 인한 충돌을 최소화한다.

## 권장 구조

Jekyll은 프로젝트 루트의 `_posts`만이 아니라 하위 경로에 배치된 `_posts` 디렉터리도 게시글 소스로 처리한다.
따라서 다음과 같이 콘텐츠 종류별로 디렉터리를 분리한다.

```text
knowledge/
└── _posts/
    ├── 2025-08-09-백엔드-아키텍처의-구조.md
    └── ...

experiences/
└── _posts/
    ├── 2022-07-06-querydsl-동적-페이징-정렬-구현하기.md
    └── ...

_tabs/
├── knowledge.md
└── experiences.md
```

참고 자료:

- Jekyll 게시글과 경로 기반 카테고리: https://jekyllrb.com/docs/posts/
- Chirpy 공식 Starter의 `_tabs`: https://github.com/cotes2020/chirpy-starter/tree/main/_tabs

`_posts` 상위 디렉터리인 `knowledge`, `experiences`는 Jekyll에서 경로 기반 카테고리로 인식된다.
각 글이 Chirpy의 일반 게시글인 `site.posts`에 포함되므로 테마의 기본 기능을 그대로 활용할 수 있다.

## 화면 구성

- Chirpy의 `_tabs`에 Knowledge와 Experiences 페이지를 추가한다.
- 사이드바에서 두 메뉴를 독립적으로 노출한다.
- Knowledge 페이지에서는 Knowledge 글만 최신순으로 표시한다.
- Experiences 페이지에서는 Experiences 글만 최신순으로 표시한다.
- 홈에서는 두 영역의 글을 합쳐 전체 최신순으로 표시한다.
- Categories와 Tags에서는 두 영역의 글을 함께 검색하고 분류할 수 있게 한다.
- `Knowledge > Backend`, `Experiences > JPA`처럼 영역 아래에 기존 카테고리를 두는 계층 구조를 사용할 수 있다.

이 구조에서 콘텐츠는 저장소와 화면 모두 분리되지만 Chirpy 내부에서는 일반 게시글로 취급된다.
따라서 검색, 자동 목차, 관련 글, 최신 글, 태그, 댓글, 다크 모드 같은 기능을 별도로 다시 구현하지 않아도 된다.

## 기존 URL 보존

현재 사용 중인 URL을 유지한다.

```text
/knowledge/:title/
/experiences/:title/
```

Chirpy 기본 permalink인 `/posts/:title/`을 그대로 사용하지 않고, 각 콘텐츠 경로에 대한 front matter 기본값이나 게시글별 permalink를 설정한다.
기존 URL을 유지하면 외부 링크, 검색 엔진 색인과 북마크가 깨지는 것을 방지할 수 있다.

## 커스텀 컬렉션 유지 방식

현재 `_knowledge`, `_experiences`를 Jekyll 커스텀 컬렉션으로 그대로 유지하는 방법도 기술적으로 가능하다.
그러나 Chirpy의 주요 기능은 `site.posts`, `site.categories`, `site.tags`를 중심으로 구현되어 있다.

커스텀 컬렉션을 유지하면 다음 부분을 별도로 확장해야 한다.

- 홈의 최신 글 목록과 페이지네이션
- 통합 검색 데이터
- 카테고리와 태그 집계 및 상세 페이지 생성
- 관련 글 계산
- Trending Tags와 사이드 패널
- RSS/Atom Feed
- 사이트맵과 빌드 검증

특히 커스텀 컬렉션의 카테고리를 화면에 표시하더라도 `jekyll-archives`가 해당 컬렉션의 카테고리 상세 페이지를 자동으로 만들지 않는 문제가 있다.

- 관련 Chirpy 논의: https://github.com/cotes2020/jekyll-theme-chirpy/discussions/2318

이 방식은 테마 내부 레이아웃과 플러그인에 대한 재정의가 늘어나고, Chirpy 업데이트 시 충돌 가능성이 높으므로 권장하지 않는다.

## 결론

이 시점에는 다음 방식을 권장했으나, 이후 분류 모델을 구체화하면서 변경되었다.

1. 현재 `_knowledge`의 글을 `knowledge/_posts`로 이동한다.
2. 현재 `_experiences`의 글을 `experiences/_posts`로 이동한다.
3. `_tabs/knowledge.md`, `_tabs/experiences.md`를 추가해 독립 메뉴로 제공한다.
4. 기존 Knowledge와 Experiences URL을 유지한다.
5. 모든 콘텐츠를 Chirpy의 `site.posts`로 처리해 기본 기능과 업데이트 호환성을 확보한다.

이 방식은 `Knowledge`, `Experiences`를 경로 기반 카테고리로도 만들기 때문에 콘텐츠 종류와 주제 카테고리를 독립적으로 사용하려는 요구사항에는 적합하지 않다.
최종 구조는 다음 절에서 정리한다.

---

# Chirpy 분류 축 분리 설계

> 아니야 experience/back-end(categories)/jvm(tags), knowledge/back-end(categories)/jvm(tags)로 나뉠수도 있으니까 categories를 써도 별도 메뉴는 포기하면 안되겠어

## 답변

Experience/Knowledge, Category, Tag는 서로 다른 분류 축이므로 하나의 Categories 계층으로 합치지 않는다.
Experience와 Knowledge는 독립 메뉴로 유지하고, Category와 Tag는 두 콘텐츠 영역에서 공통으로 사용한다.

## 분류 모델

각 분류의 역할을 다음과 같이 나눈다.

| 분류 | 역할 | 예시 |
|---|---|---|
| `section` | 글의 성격과 독립 메뉴 | `experience`, `knowledge` |
| `categories` | 글의 기술 영역 | `Back-end`, `Front-end`, `DevOps` |
| `tags` | 세부 기술과 키워드 | `JVM`, `JPA`, `Spring` |

같은 Category와 Tag를 서로 다른 Section의 글에서 함께 사용할 수 있다.

```text
Experience / Back-end / JVM
Knowledge  / Back-end / JVM
```

`section`은 Jekyll이나 Chirpy의 기본 분류가 아니라 이 프로젝트에서 추가하는 front matter 필드다.
독립 메뉴 페이지에서 `site.posts`를 `section` 값으로 필터링하는 데 사용한다.

## 최종 디렉터리 구조

모든 글이 Chirpy의 `site.posts`에 포함되도록 `_posts`를 사용하되, 그 안에서 콘텐츠 종류별 하위 디렉터리로 나눈다.

```text
_posts/
├── experiences/
│   ├── 2022-07-06-querydsl-동적-페이징-정렬-구현하기.md
│   └── ...
└── knowledge/
    ├── 2025-08-09-백엔드-아키텍처의-구조.md
    └── ...

_tabs/
├── experiences.md
└── knowledge.md
```

앞서 제안한 `knowledge/_posts`, `experiences/_posts` 구조는 사용하지 않는다.
Jekyll은 `_posts` 상위 디렉터리를 경로 기반 카테고리로 인식하므로 해당 구조를 사용하면 Knowledge와 Experiences가 Category에도 포함되어 분류 축이 섞일 수 있다.

참고 자료:

- Jekyll 게시글과 경로 기반 카테고리: https://jekyllrb.com/docs/posts/
- Chirpy 공식 Starter의 `_tabs`: https://github.com/cotes2020/chirpy-starter/tree/main/_tabs

## Front Matter 구조

Experience 글은 다음과 같이 표현한다.

```yaml
---
title: "Querydsl 동적 페이징, 정렬 구현하기"
section: experience
categories:
  - Back-end
tags:
  - JVM
  - JPA
---
```

Knowledge 글은 다음과 같이 표현한다.

```yaml
---
title: "백엔드 아키텍처의 구조"
section: knowledge
categories:
  - Back-end
tags:
  - JVM
  - Architecture
---
```

두 글은 Section은 다르지만 Back-end Category와 JVM Tag를 공유한다.

## 화면별 역할

- **Home**: Experience와 Knowledge 글을 합쳐 전체 최신순으로 표시한다.
- **Experiences**: `section: experience`인 글만 최신순으로 표시한다.
- **Knowledge**: `section: knowledge`인 글만 최신순으로 표시한다.
- **Categories**: Section과 관계없이 기술 영역별로 모든 글을 분류한다.
- **Tags**: Section과 관계없이 세부 기술과 키워드별로 모든 글을 분류한다.
- **Search**: 모든 Section의 글을 통합 검색한다.

예를 들어 Categories의 Back-end에는 Experience와 Knowledge 글이 함께 나타나고, Tags의 JVM에도 두 Section의 글이 함께 나타난다.

Experiences와 Knowledge는 Chirpy의 `_tabs`를 이용해 사이드바의 독립 메뉴로 제공한다.
각 탭은 `site.posts`를 `section` 값으로 필터링하여 해당 글 목록을 출력한다.

## 경로별 기본값

`_config.yml`의 front matter defaults를 이용해 Section과 기존 URL을 경로별로 자동 설정할 수 있다.

```yaml
defaults:
  - scope:
      path: "_posts/experiences"
      type: posts
    values:
      section: experience
      permalink: /experiences/:title/

  - scope:
      path: "_posts/knowledge"
      type: posts
    values:
      section: knowledge
      permalink: /knowledge/:title/
```

이를 통해 각 글에 `section`과 `permalink`를 반복해서 작성하지 않으면서 기존 URL을 유지한다.
실제 적용 시 Jekyll 4.3과 Chirpy 7.6 환경에서 하위 디렉터리 인식, defaults 적용 및 생성 URL을 빌드 테스트로 검증한다.

## 최종 결정

다음 구조를 최종 권장안으로 한다.

1. 콘텐츠 종류는 `section: experience`, `section: knowledge`로 구분한다.
2. 기술 영역은 `categories`로 관리한다.
3. 세부 기술과 키워드는 `tags`로 관리한다.
4. 소스 파일은 `_posts/experiences`, `_posts/knowledge`로 분리한다.
5. Experiences와 Knowledge를 `_tabs` 기반 독립 메뉴로 제공한다.
6. 홈, 검색, 카테고리와 태그에서는 모든 글을 통합 처리한다.
7. 기존 `/experiences/:title/`, `/knowledge/:title/` URL을 유지한다.

이 설계는 Experience/Knowledge 메뉴 구분과 Category/Tag의 교차 분류를 동시에 보존하며, 모든 글을 `site.posts`로 처리해 Chirpy의 기본 기능과 업데이트 호환성도 유지한다.
