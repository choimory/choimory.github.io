# 목차

- [개요](#개요)
- [파비콘 교체 구현](#파비콘-교체-구현)
  - [작업 상태](#작업-상태)
  - [이미지 준비와 원본 보존](#이미지-준비와-원본-보존)
  - [생성 및 변경 파일](#생성-및-변경-파일)
  - [브라우저 및 홈 화면 아이콘 연결](#브라우저-및-홈-화면-아이콘-연결)
  - [PWA manifest 구성](#pwa-manifest-구성)
  - [캐시 갱신 방식](#캐시-갱신-방식)
  - [검증 결과](#검증-결과)
  - [확인 범위와 한계](#확인-범위와-한계)
  - [검증 도구와 생성물](#검증-도구와-생성물)
- [원형 파비콘 및 브라우저 제목 변경](#원형-파비콘-및-브라우저-제목-변경)
  - [추가 요청과 적용 결과](#추가-요청과-적용-결과)
  - [원형 아이콘 처리](#원형-아이콘-처리)
  - [브라우저 제목과 프로필 이름 분리](#브라우저-제목과-프로필-이름-분리)
  - [추가 변경 파일](#추가-변경-파일)
  - [추가 검증 결과](#추가-검증-결과)
  - [추가 검증 생성물](#추가-검증-생성물)

---

# 개요

- `plan1.md`의 분석과 계획에 따라 지정한 사진을 바탕으로 브라우저·홈 화면·PWA 아이콘을 교체했다.
- 테마 기본 파비콘 연결을 프로젝트 include로 덮어쓰고, PWA manifest도 프로젝트에서 관리하도록 추가했다.
- 이 문서는 실제 구현 사항과 구현 작업 중 수행한 검증 결과를 기록한다.

--

# 파비콘 교체 구현

> 작업 시작

## 작업 상태

- 파비콘 파일 생성, 연결 변경 및 로컬 검증 완료.
- 캘린더의 파비콘 수정 상태는 `TASK`로 유지한다.
- 실제 휴대폰 홈 화면 추가 및 PWA 설치 확인은 수행하지 않았다.
- 이번 요청에서는 작업 내용을 기록하며, `done1.md` 작성과 `DONE` 전환은 진행하지 않는다.
- 커밋과 푸시는 진행하지 않았다.

## 이미지 준비와 원본 보존

- 원본은 같은 디렉터리의 `images_(38).jpg`이며, 443×332px JPEG 이미지다.
- imagegen 내장 도구로 원본을 바탕으로 한 얼굴 중심 정사각형 이미지를 만들었다. 투명 배경·문자·테두리·둥근 모서리는 추가하지 않도록 요청했다.
- 생성 결과는 1254×1254px PNG다. 이후 `sips`로 각 PNG 규격을 만들고, 16·32·48px PNG 프레임을 ICO 파일로 묶었다.
- 생성 이미지는 원본 파일을 단순 리사이즈한 결과와는 구분한다. 원본 JPG 자체는 수정하지 않았다.
- 원본 보존은 SHA-256으로 확인했다.

```text
a60b04077e095c2f0cbd62eef93a5b983c4e1e32f82477b6ebf5748f272142ef
```

### 이미지 편집 지시

imagegen 내장 도구에 원본 JPG를 편집 대상으로 전달하고 다음 프롬프트를 사용했다.

```text
Edit target: the provided local JPG. Asset: square browser favicon and app icon master for this exact supplied picture. Make only a square crop/framing adjustment around the existing turquoise character's face, preserving the exact existing artwork, spiral eyes, open pink mouth, orientation, yellow background, outlines and colors. Do not redraw, reinterpret, enhance, invent or change the character. Keep both spiral eyes and mouth in frame, centered, with a little breathing room so recognizability survives tiny icon sizes. Retain original yellow background; no transparency, text, border, rounded corners, shadows or new objects. Output one square image.
```

## 생성 및 변경 파일

| 파일 | 규격 및 역할 |
|---|---|
| `assets/img/favicons/favicon.ico` | 16×16·32×32·48×48 PNG 프레임을 포함하는 ICO |
| `assets/img/favicons/favicon-96x96.png` | 96×96 브라우저용 PNG |
| `assets/img/favicons/apple-touch-icon.png` | 180×180 홈 화면용 PNG |
| `assets/img/favicons/web-app-manifest-192x192.png` | 192×192 PWA 아이콘, `purpose: any` |
| `assets/img/favicons/web-app-manifest-512x512.png` | 512×512 PWA 아이콘, `purpose: maskable` |
| `assets/img/favicons/site.webmanifest` | 사이트 설정을 반영하는 PWA manifest |
| `_includes/favicons.html` | 테마 기본 파비콘 연결을 덮어쓰는 프로젝트 include |
| `.agents/histories/calendar.md` | 파비콘 수정 작업 상태를 `PLAN`에서 `TASK`로 변경 |

- PNG 4개와 ICO 1개, 총 아이콘 파일 5종을 생성했다.
- 512px 마스크용 아이콘은 생성 이미지를 360×360px로 축소한 뒤 512×512px 캔버스 중앙에 배치했다. 사방에 76px 여백을 두고 배경색은 `#ffdf73`을 사용했다.
- 이미지를 찌그러뜨리는 가로·세로 비율 변경 없이 정사각형 이미지를 규격별로 축소했다.
- `_config.yml`, 사이트 공통 레이아웃과 게시글은 변경하지 않았다.
- 작업 중 확인된 별도의 `.gitignore` 변경은 수정하거나 되돌리지 않았다.

## 브라우저 및 홈 화면 아이콘 연결

- 프로젝트에 `_includes/favicons.html`을 추가했다. Chirpy 테마의 동일한 include를 덮어쓴다.
- PNG 파비콘, ICO 및 Apple Touch Icon을 새 파일에 연결했다.
- `site.pwa.enabled`가 참인 경우에만 manifest 링크를 출력한다.
- 테마 기본 `favicon.svg`의 링크를 제거했다. 테마의 SVG 파일이 빌드 결과에 남더라도 페이지의 파비콘으로 참조하지 않는다.
- 경로에는 `relative_url`을 적용해 사이트의 `baseurl` 설정을 반영하도록 했다. 별도 하위 경로 배포 검증은 수행하지 않았다.
- `_site`의 파일을 직접 편집하지 않고 Jekyll 빌드로 결과를 생성했다.

## PWA manifest 구성

- `name`, `short_name`, `description`은 `site.title`과 `site.description`을 사용한다.
- 사이트 설정 문자열은 `jsonify` 필터를 통해 JSON 문자열로 출력한다.
- 시작 URL은 `/index.html`에 `relative_url`을 적용한다.
- 192px 일반 아이콘과 512px 마스크용 아이콘을 각각 연결했다.
- 설치 화면의 `theme_color`와 `background_color`는 아이콘 여백과 같은 `#ffdf73`으로 지정했다.
- 앱 실행 방식은 기존과 동일한 `display: standalone`을 유지했다.

## 캐시 갱신 방식

- include와 manifest의 `favicon_version`을 `20261118`로 지정했다.
- 아이콘과 manifest 링크에 `?v=20261118` 쿼리를 붙여 기존 아이콘 URL과 구분했다.
- 이후 아이콘을 다시 교체한다면 `_includes/favicons.html`과 `assets/img/favicons/site.webmanifest`의 버전 값을 함께 갱신해야 한다.
- 기존 방문자나 이미 설치한 앱의 아이콘 갱신 시점까지 보장하는 것은 아니며, 이번 브라우저 검증은 새 Chrome 세션에서 수행했다.

## 검증 결과

아래 결과는 아이콘 교체 구현 중 수행한 검증이다. 이번 문서 작성 요청에서는 구현 테스트를 다시 실행하지 않았다.

| 검증 항목 | 결과 |
|---|---|
| PNG 크기와 형식 | 96·180·192·512px 정사각형 PNG 모두 확인 |
| ICO 구조 | 16·32·48px 프레임 3개, 각 PNG 데이터의 크기와 오프셋 확인 |
| 원본 보존 | SHA-256 일치 |
| 빌드 결과의 아이콘 | 소스 파일과 생성 파일의 해시 일치 |
| `./local.sh test` | production Jekyll 빌드 및 HTML-Proofer 통과 |
| HTML-Proofer 검사 규모 | 생성 파일 367개, 내부 링크 2,994개 |
| manifest JSON | JSON 파싱, 사이트 이름, 시작 URL 및 아이콘 설정 확인 |
| Chrome의 manifest 해석 | `Page.getAppManifest` 오류 0개 |
| `git diff --check` | 통과 |

### 실제 브라우저 파일 로딩 확인

Chrome과 Playwright로 로컬 사이트의 홈(`/`)과 글 상세(`/knowledge/JPA-Transaction/`)를 확인했다.

- 각 페이지에서 PNG, ICO, Apple Touch Icon, manifest 링크 4개가 출력되는 것을 확인했다.
- 각 링크의 HTTP 응답이 200인 것을 확인했다.
- 기본 SVG 아이콘 링크가 없는 것을 확인했다.
- 브라우저에서 PNG는 96×96, Apple Touch Icon은 180×180으로 디코딩되었다.
- ICO는 Chrome에서 48×48 프레임으로 디코딩되었다. 16·32px 프레임은 파일 구조 검사로 확인했다.
- manifest가 참조하는 PWA 아이콘 2개도 HTTP 200 응답을 확인했다.

## 확인 범위와 한계

- 작은 아이콘의 16·32·48·96px 미리보기와 홈 화면용 180·192px 미리보기를 확인했다.
- 512px 아이콘에 원형과 둥근 사각형 CSS 마스크를 씌운 미리보기로 얼굴이 잘리지 않는지 확인했다. 이는 실제 운영체제의 아이콘 표시를 대신하는 시뮬레이션이다.
- Chrome에서 아이콘 파일 로딩·디코딩과 manifest 해석을 확인했으며, 네이티브 브라우저 탭 UI의 표시를 직접 확인한 것은 아니다.
- 실제 iPhone·Android 홈 화면 추가, PWA 설치 및 기존 설치 앱의 아이콘 갱신은 확인하지 않았다.
- GitHub Pages 배포와 운영 사이트 검증은 수행하지 않았다.

## 검증 도구와 생성물

- 빌드·링크 검증은 기존 프로젝트 Docker 환경과 `./local.sh test`를 사용했다.
- 이미지 규격 변환 스크립트: `/tmp/generate-blog-favicons.cjs`.
- 브라우저·파일 검증 스크립트: `/tmp/validate-blog-favicons.cjs`.
- 아이콘 크기와 마스크 미리보기: `/tmp/blog-favicons-preview.png`.
- 이미지 편집 프롬프트 사본: `/tmp/favicon-image-prompt.txt`.
- imagegen의 정사각형 생성 원본은 Codex의 `generated_images` 디렉터리에 보존되어 있다. 사이트에서 사용하는 최종 아이콘 5종은 프로젝트의 `assets/img/favicons/`에 저장했다.
- 임시 스크립트·미리보기와 빌드 결과는 이후 정리될 수 있으며, 사이트는 해당 임시 파일을 참조하지 않는다.

--

# 원형 파비콘 및 브라우저 제목 변경

> 1. 파비콘이 원형이였으면 좋겠음
> 2. 브라우저 제목이 choimory에서 choimory-blog로 바뀌었으면 좋겠음. 근데 좌측 프로필은 choimory를 유지했으면 좋겠음

계획을 설명하고 사용자의 `ㄱㄱ` 승인 후 추가 변경을 진행했다. 앞 절은 최초 구현 당시 기록이며, 아래 내용이 추가 변경 후의 상태다.

## 추가 요청과 적용 결과

| 항목 | 적용 결과 |
|---|---|
| 브라우저 파비콘 | 원형 이미지, 바깥 영역은 투명 |
| 홈의 브라우저 탭 제목 | `choimory-blog` |
| 글 상세의 브라우저 탭 제목 | `글 제목 | choimory-blog` |
| 좌측 프로필 이름 | `choimory` |
| 아이콘 캐시 버전 | `20261118-2` |

## 원형 아이콘 처리

- 기존 정사각형 생성 이미지를 imagegen 내장 도구의 편집 대상으로 전달했다.
- 원 안의 캐릭터·노란 배경·방향·색감은 유지하고 원 밖은 투명하게 처리하도록 요청했다.
- 원형 생성 결과는 1254×1254px PNG이며 알파 채널을 포함한다.
- `sips`로 투명도를 유지한 96px PNG 및 16·32·48px ICO 프레임을 생성했다.
- 브라우저용 `favicon-96x96.png`와 `favicon.ico`를 교체했다.
- Apple Touch Icon과 PWA용 192·512px 이미지 파일은 기존 형태로 유지했다. 홈 화면·설치 아이콘은 운영체제의 마스크 규칙을 고려한 최초 구성을 사용한다.
- include와 manifest의 `favicon_version`을 모두 `20261118-2`로 올렸다.
- 원본 `images_(38).jpg`는 수정하지 않았다.

### 원형 편집 지시

```text
Edit target: the supplied square favicon artwork. Make this exact existing artwork into a circular browser favicon: preserve the character, colors, orientation and composition inside a centered circle, and make everything outside that circle fully transparent with a clean antialiased edge. Retain the yellow image background inside the circle. Keep both spiral eyes and the pink mouth recognizable. Do not extract the character from the yellow background; this is a circular crop of the whole picture. Do not redraw, rotate, add borders, shadows, text or new objects. Output a square PNG canvas with a circular image filling it and genuinely transparent corners.
```

## 브라우저 제목과 프로필 이름 분리

Chirpy는 기본적으로 브라우저 제목과 좌측 프로필 이름에 모두 `site.title`을 사용한다. 프로필 이름은 유지하면서 브라우저 제목만 바꾸기 위해 설정을 분리했다.

```yaml
title: choimory
browser_title: choimory-blog
```

- `_config.yml`에 `browser_title`을 추가했다.
- 테마의 `_includes/head.html`을 프로젝트에 추가하고 `<title>`의 사이트명 부분만 다음과 같이 변경했다.

```liquid
{{- site.browser_title | default: site.title | escape -}}
```

- 홈은 탭 전용 이름만 표시하고, 글과 목록 페이지는 기존 페이지 제목 뒤에 ` | choimory-blog`를 붙인다.
- `browser_title`을 지정하지 않으면 기존 `site.title`을 사용한다.
- 좌측 프로필은 테마의 기존 `site.title`을 사용하므로 `choimory`로 유지된다.
- SEO 사이트명과 PWA 이름을 만드는 `site.title`도 `choimory`로 유지된다.
- head 템플릿을 프로젝트에서 덮어쓰므로 이후 Chirpy 테마를 업데이트할 때 테마의 head 변경 사항도 함께 비교해야 한다.

## 추가 변경 파일

| 파일 | 변경 내용 |
|---|---|
| `_config.yml` | `browser_title: choimory-blog` 추가 |
| `_includes/head.html` | 테마 head를 기준으로 브라우저 제목의 사이트명 분리 |
| `_includes/favicons.html` | 캐시 버전 `20261118-2` 적용 |
| `assets/img/favicons/favicon-96x96.png` | 원형·투명 배경 PNG로 교체 |
| `assets/img/favicons/favicon.ico` | 원형·투명 배경 ICO 프레임으로 교체 |
| `assets/img/favicons/site.webmanifest` | 캐시 버전 `20261118-2` 적용 |

## 추가 검증 결과

아래 검증은 추가 변경 구현 중 수행한 결과이며, 이번 문서 추가 요청에서는 다시 실행하지 않았다.

| 검증 항목 | 결과 |
|---|---|
| `./local.sh test` | production Jekyll 빌드 및 HTML-Proofer 통과 |
| HTML-Proofer 검사 규모 | 생성 파일 367개, 내부 링크 2,994개 |
| PNG 및 ICO 구조 | 96px PNG, ICO의 16·32·48px 프레임 확인 |
| PNG 알파 채널 | 포함 확인 |
| Chrome의 PNG·ICO 투명도 | 네 모서리 알파값 모두 0 |
| Chrome의 PNG·ICO 중앙 불투명도 | 알파값 253, 거의 불투명한 이미지 영역 확인 |
| 각 페이지의 `<title>` | 하나씩 존재하고 예상 제목과 일치 |
| 좌측 프로필 이름 | 확인한 모든 페이지에서 `choimory` |
| 아이콘·manifest 링크 | 각 페이지에서 HTTP 200, 기본 SVG 연결 없음 |
| manifest 해석 | Chrome `Page.getAppManifest` 오류 0개 |
| 원본 보존 | 최초 원본 SHA-256과 일치 |
| `git diff --check` | 통과 |

중앙 픽셀의 알파값이 255와 정확히 같아야 한다는 초기 검증 조건은 생성 이미지의 실제 알파값 253에서 실패했다. 모서리의 완전 투명과 중앙의 높은 불투명도를 구분해 확인하도록 검증 조건을 조정했다.

### 페이지별 제목 확인

| 경로 | 실제 브라우저 제목 | 좌측 프로필 |
|---|---|---|
| `/` | `choimory-blog` | `choimory` |
| `/knowledge/JPA-Transaction/` | `JPA Transaction \| choimory-blog` | `choimory` |
| `/knowledge/` | `Knowledge \| choimory-blog` | `choimory` |
| `/categories/` | `Categories \| choimory-blog` | `choimory` |

- 제목은 Chrome의 `document.title`에 해당하는 값으로 확인했다.
- 원형 파비콘은 밝은 배경과 어두운 배경의 크기별 미리보기로 확인했다.
- 실제 휴대폰 홈 화면 추가·PWA 설치 및 운영 사이트 배포 검증은 수행하지 않았다.

## 추가 검증 생성물

- 원형 편집 프롬프트 사본: `/tmp/favicon-round-prompt.txt`.
- 원형 파비콘 크기별 미리보기: `/tmp/blog-favicons-round-preview.png`.
- 홈 화면과 좌측 프로필 스크린샷: `/tmp/blog-title-profile-preview.png`. 브라우저의 네이티브 탭 UI를 촬영한 것은 아니다.
- 기존 `/tmp/generate-blog-favicons.cjs`에 브라우저 아이콘만 변환하는 `--browser-only` 옵션을 추가해 사용했다.
- 기존 `/tmp/validate-blog-favicons.cjs`에 제목·프로필·투명도 검증을 추가해 사용했다.
- 임시 생성물은 사이트에서 참조하지 않으며, 이후 정리될 수 있다.
