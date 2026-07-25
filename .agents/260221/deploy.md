# 2026-02-21 배포 설정 작업 내역

## 문제 상황

GitHub Pages 빌드 실패:
```
The minimal-mistakes-jekyll theme could not be found.
github-pages 232 | Error: The minimal-mistakes-jekyll theme could not be found.
```

## 원인 분석

`github-pages` 젬은 GitHub이 허용한 테마/플러그인만 사용 가능한데, `minimal-mistakes-jekyll`이 허용 목록에 없음.

## 시도한 우회 방법들 (실패)

### 1차: remote_theme으로 변경
- `_config.yml`: `theme` → `remote_theme: mmistakes/minimal-mistakes`
- 결과: 로컬에서 SSL 오류 발생
  ```
  certificate verify failed (unable to get certificate CRL)
  ```
  macOS에서 OpenSSL이 인증서 CRL(폐기 목록)을 확인하지 못하는 문제

### 2차: _config_dev.yml로 로컬/배포 환경 분리 시도
- `_config_dev.yml` 생성해서 로컬에서는 `theme`, 배포에서는 `remote_theme` 사용하도록 분리
- 결과: `jekyll-remote-theme` 플러그인이 config와 무관하게 항상 실행됨
  - `github-pages` 젬이 `:jekyll_plugins` Bundler 그룹에 있어서 `jekyll-remote-theme`을 자동 로드
  - `remote_theme: ""` → Ruby에서 `""[1..-1]` = nil → `match` 오류
  - `remote_theme: null` → Jekyll config 머지 시 null이 기존 값을 오버라이드하지 않음

## 최종 해결책: 커스텀 GitHub Actions 워크플로우

### 핵심 변경 사항

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 빌드 방식 | GitHub 기본 Pages 빌드 (`jekyll-build-pages`) | 커스텀 GitHub Actions 워크플로우 |
| Gemfile | `github-pages` 젬 사용 | `jekyll` + `minimal-mistakes-jekyll` 직접 명시 |
| _config.yml | `remote_theme: mmistakes/minimal-mistakes` | `theme: minimal-mistakes-jekyll` |
| 로컬 실행 | `bundle exec jekyll serve --config _config.yml,_config_dev.yml` | `bundle exec jekyll serve` |

### 변경된 파일

**Gemfile**
```ruby
source "https://rubygems.org"

gem "jekyll", "~> 3.10"
gem "minimal-mistakes-jekyll"
gem "kramdown-parser-gfm"

gem "tzinfo-data"
gem "wdm", "~> 0.1.0" if Gem.win_platform?

group :jekyll_plugins do
  gem "jekyll-paginate"
  gem "jekyll-sitemap"
  gem "jekyll-gist"
  gem "jekyll-feed"
  gem "jemoji"
  gem "jekyll-include-cache"
  gem "jekyll-algolia"
end
```

**_config.yml** (변경 부분)
```yaml
theme: minimal-mistakes-jekyll  # remote_theme에서 변경

plugins:
  - jekyll-paginate
  - jekyll-sitemap
  - jekyll-gist
  - jekyll-feed
  - jemoji
  - jekyll-include-cache
  # jekyll-remote-theme 제거
```

**.github/workflows/jekyll.yml** (신규 생성)
```yaml
name: Deploy Jekyll site to Pages

on:
  push:
    branches: ["master"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true
      - uses: actions/configure-pages@v5
        id: pages
      - run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production
      - uses: actions/upload-pages-artifact@v3

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/deploy-pages@v4
```

### GitHub 저장소 설정 변경 (1회성)

```
Settings → Pages → Build and deployment → Source
→ "Deploy from a branch" 에서 "GitHub Actions" 으로 변경
```

## 트러블슈팅 과정

1. `minimal-mistakes-jekyll` not found → `github-pages` 젬 제거, 직접 명시
2. `kramdown-parser-gfm` 누락 → Gemfile에 추가 (github-pages가 자동으로 포함해주던 의존성)
3. Ruby 3.1 gem 설치 오류 → 워크플로우 Ruby 버전을 3.3으로 변경

## 최종 상태

- 로컬: `bundle exec jekyll serve` → localhost:4000
- 배포: `master` 브랜치 push → GitHub Actions 자동 빌드 및 배포
