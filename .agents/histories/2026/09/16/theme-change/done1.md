# 목차

- [개요](#개요)
- [완료 내용](#완료-내용)
- [콘텐츠 아키텍처](#콘텐츠-아키텍처)
- [사이트 구성](#사이트-구성)
- [로컬 실행 환경](#로컬-실행-환경)
- [검증 결과](#검증-결과)
- [최종 사용 방법](#최종-사용-방법)

---

# 개요

- Jekyll 블로그 테마를 Minimal Mistakes에서 Chirpy로 전환했다.
- Experiences와 Knowledge를 독립 메뉴로 유지하면서 Categories와 Tags를 공통 분류 체계로 구성했다.
- 사이트 정보와 프로필, 메뉴 표시를 현재 운영 방향에 맞게 변경했다.
- README를 현재 아키텍처와 운영 방법을 기준으로 전면 현행화했다.
- 호스트 Ruby에 의존하지 않는 Docker 로컬 실행 환경을 구축하고 이 프로젝트를 위해 설치했던 Homebrew Ruby를 제거했다.

---

# 완료 내용

## Chirpy 테마 전환

- `jekyll-theme-chirpy` 7.6.0과 Jekyll 4.4.1을 적용했다.
- Chirpy 설정, 탭, 연락처, 공유 메뉴와 GitHub Pages workflow를 구성했다.
- Minimal Mistakes 전용 설정, 페이지, navigation과 스타일 파일을 제거했다.
- 기존 글의 Liquid 예제와 이미지 경로를 Chirpy 빌드에 맞게 보완했다.

## 콘텐츠 이전

- Experience 글 12개를 `_posts/experiences`로 이전했다.
- Knowledge 글 152개를 `_posts/knowledge`로 이전했다.
- 디렉터리별 `section`과 permalink 기본값을 설정했다.
- 기존 `/experiences/:title/`, `/knowledge/:title/` URL 구조를 유지했다.
- 카테고리와 태그 표기를 정규화하고 YAML front matter를 정리했다.

## 사이트 정보 변경

- 사이트 이름을 `choimory`로 변경했다.
- 소개 문구를 `Back-end, Dev-ops Engineer`로 변경했다.
- 프로필 이미지를 886x886 정사각형 이미지로 변경했다.
- Categories, Tags, Archives, About 메뉴를 영어로 표시했다.
- Experiences와 Knowledge의 HTML 문서 제목을 정상화했다.

## 문서 현행화

- README를 Chirpy 기반 프로젝트 구조와 운영 방법으로 전면 재작성했다.
- 콘텐츠 구조, 분류 체계, URL, 메뉴, 글 작성, 실행, 검증과 배포 방법을 문서화했다.
- README에 주요 절로 이동하는 목차를 추가했다.
- 작업 히스토리는 README에서 제외하고 `.agents/histories`에서 관리하도록 구분했다.

---

# 콘텐츠 아키텍처

- 모든 글은 Jekyll `posts` 컬렉션으로 통합했다.
- `_posts/experiences` 글에는 `section: experience`와 `/experiences/:title/`을 적용한다.
- `_posts/knowledge` 글에는 `section: knowledge`와 `/knowledge/:title/`을 적용한다.
- `_layouts/section.html`이 각 섹션의 글을 연도별 목록으로 표시한다.
- Categories와 Tags는 두 섹션의 모든 글에서 공통으로 집계한다.
- `post.sh`는 `e`, `k` 옵션에 따라 각 섹션에 새 글을 생성한다.

---

# 사이트 구성

- `_tabs`에서 Experiences, Knowledge, Categories, Tags, Archives, About 순서를 관리한다.
- `_data/locales/ko-KR.yml`에서 한국어 UI를 유지하면서 탭 이름만 영어로 재정의한다.
- `_plugins/posts-lastmod-hook.rb`가 Git 이력을 이용해 글의 최종 수정일을 계산한다.
- GitHub Actions는 Ruby 3.3 환경에서 production 빌드와 `html-proofer` 검증 후 GitHub Pages에 배포한다.

---

# 로컬 실행 환경

- Ruby 3.3 slim 기반 `Dockerfile`을 추가했다.
- `.dockerignore`로 생성물, Git, IDE와 작업 히스토리를 build context에서 제외했다.
- `local.sh`에 `serve`, `build`, `test`, `clean` 명령을 구현했다.
- 모든 실행 컨테이너는 `--rm`으로 종료 시 자동 삭제된다.
- gem 의존성은 이미지에 포함하며 named volume은 사용하지 않는다.
- `clean`은 프로젝트 이미지와 Jekyll 생성물만 삭제하고 Docker 전체 build cache는 유지한다.
- Homebrew Ruby 4.0.6과 더 이상 필요하지 않은 `libyaml`을 제거했다.
- `~/.zshrc`의 Homebrew Ruby PATH 설정을 제거하고 macOS 기본 Ruby는 유지했다.

---

# 검증 결과

- production Jekyll 빌드 성공
- YAML front matter 164개 파싱 성공
- permalink 중복 0건
- 검색 인덱스 164개 생성 확인
- 생성 결과 345개 파일과 내부 링크 2,764개 `html-proofer` 검증 성공
- 데스크톱과 모바일에서 홈, 섹션, 글 상세와 사이드바 화면 확인
- 모든 주요 탭의 HTTP 200 응답 확인
- `post.sh`의 Experience와 Knowledge 글 생성 확인
- `local.sh`의 `serve`, `build`, `test`, `clean` 검증 성공
- serve 종료 후 프로젝트 컨테이너가 남지 않는 것을 확인
- clean 실행 후 프로젝트 이미지와 Jekyll 생성물이 남지 않는 것을 확인
- Homebrew Ruby 제거 후 Docker 기반 전체 test 재검증 성공
- `git diff --check` 통과

---

# 최종 사용 방법

로컬 미리보기를 실행한다.

```bash
./local.sh serve
```

production 사이트를 생성한다.

```bash
./local.sh build
```

production 빌드와 링크 검증을 실행한다.

```bash
./local.sh test
```

프로젝트 Docker 이미지와 로컬 생성물을 정리한다.

```bash
./local.sh clean
```
