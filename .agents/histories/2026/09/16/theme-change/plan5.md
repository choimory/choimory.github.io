# 개요

- 지금 보니까 로컬 호스트 세팅을 건드리지 않기 위해, 도커에 루비같은거 추가로 깔아서 그걸 이용해서 도커 런으로 컨테이너 올려서 로컬 테스트 하는거 같은데
- 그럴거면 그냥 프로젝트 자체를 dockerfile로 도커라이징해서 docker run하는 스크립트 하나 놓고 해당 스크립트로 로컬테스트 편하게 할 수 있도록 하는게 낫겠는데?
- 왜냐면 나도 로컬에서 테스트해야하는데 로컬 실행방법이 복잡해지잖아

---

# 요구사항 정리

- 호스트에 Ruby와 Bundler를 설치하지 않는다.
- 프로젝트 전용 Docker 이미지에 Ruby 3.3과 gem 의존성을 구성한다.
- 사용자가 긴 `docker run` 명령과 세부 옵션을 직접 입력하지 않도록 한다.
- 실행 스크립트 하나로 컨테이너를 실행하고 로컬 블로그를 확인할 수 있게 한다.
- 포트, volume, `JEKYLL_ENV`와 Jekyll host 설정은 스크립트 내부에서 관리한다.
- README의 로컬 실행 방법을 실행 스크립트 중심으로 단순화한다.

---

# 구현 방향

## Dockerfile

- Ruby 3.3 기반 이미지를 사용한다.
- Bundler가 `Gemfile`과 `Gemfile.lock`을 기준으로 의존성을 설치하도록 구성한다.
- Jekyll 서버 실행에 필요한 기본 설정을 이미지에 포함한다.
- 의존성 파일을 소스보다 먼저 복사해 gem 설치 layer cache를 활용한다.

## .dockerignore

- Docker build context에 불필요한 생성물과 로컬 설정이 포함되지 않게 한다.
- 다음 항목을 우선 제외한다.
  - `_site`
  - `.jekyll-cache`
  - `.sass-cache`
  - `.git`
  - `.idea`
  - `.agents`

## 실행 스크립트

- 로컬 실행 진입점을 하나의 스크립트로 제공한다.
- 기본 동작은 Jekyll 개발 서버 실행으로 구성한다.
- 필요하면 같은 스크립트에서 다음 명령을 제공한다.
  - `serve`: 이미지 빌드 후 로컬 개발 서버 실행
  - `build`: production Jekyll 빌드
  - `test`: production 빌드 후 `html-proofer` 실행
- `serve`는 컨테이너의 4000번 포트를 호스트에 연결한다.
- 소스 디렉터리를 bind mount해 글과 설정 변경이 컨테이너에 반영되도록 한다.
- `bundle` 캐시 volume 또는 이미지 layer cache를 사용해 반복 실행 시간을 줄인다.
- 종료된 일회성 컨테이너가 남지 않도록 `--rm`을 사용한다.

## README

- 호스트 Ruby 설치 안내를 제거한다.
- 로컬 실행의 기본 방법을 실행 스크립트 한 줄로 안내한다.
- 이미지 최초 빌드와 이후 재사용 방식이 다르면 그 차이를 간단히 설명한다.
- build와 test 명령을 제공할 경우 각각의 사용 예시를 작성한다.
- 직접 사용하는 `docker build`와 `docker run` 명령은 문제 해결용 참고 수준으로 제한한다.

---

# 권장 사용 방법

```bash
./local.sh serve
```

필요한 경우 다음 명령도 지원한다.

```bash
./local.sh build
./local.sh test
```

---

# 기대 효과

- 개발자의 호스트 Ruby 버전과 무관하게 동일한 환경에서 실행할 수 있다.
- 긴 Docker 명령과 volume, port 옵션을 기억할 필요가 없다.
- 로컬 실행과 GitHub Actions 검증 환경의 Ruby 버전을 맞출 수 있다.
- 새 환경에서도 Docker만 설치되어 있으면 빠르게 로컬 테스트를 시작할 수 있다.

---

# 방향설정

- docker 컨테이너로 로컬 실행 vs 루비 명령어로 로컬 실행

## ruby

```shell
  - `brew install ruby` -> 이후 ~/.zshrc에 PATH 등록 필요
  - `gem install bundler`
  - `bundle install`
```

## docker

- 프로젝트의 `Dockerfile`로 Ruby 3.3과 gem 의존성이 포함된 이미지를 빌드한다.
- `local.sh`가 이미지 빌드, port 연결, volume 설정과 Jekyll 명령을 대신 처리한다.

```shell
./local.sh serve

# 필요할 때 사용
./local.sh build
./local.sh test
```

## 최종결정

- 공식 로컬 실행 방식은 `Dockerfile + local.sh` 기반의 Docker 실행으로 결정한다.
- Chirpy 7.6.0은 Ruby 4를 지원하지 않으므로 호스트 Ruby 버전에 따른 실행 실패를 방지할 수 있다.
- 개발자마다 Ruby와 Bundler 버전을 별도로 설치하고 맞출 필요가 없다.
- 로컬과 GitHub Actions에서 동일한 Ruby 3.3 환경을 사용할 수 있다.
- 긴 `docker build`와 `docker run` 옵션을 스크립트 내부에 숨겨 `./local.sh serve` 한 줄로 실행할 수 있다.
- 이 프로젝트는 Jekyll 단일 서비스이므로 Docker Compose는 도입하지 않는다.
- Ruby 직접 실행 방식은 공식 실행 방법에서 제외하고 필요할 때 참고할 수 있는 비교 대상으로만 남긴다.
