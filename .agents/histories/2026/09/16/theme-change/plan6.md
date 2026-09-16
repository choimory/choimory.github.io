# 개요

- 이 프로젝트를 위해 Homebrew로 설치한 Ruby를 Docker 전환 완료 후 호스트에서 제거한다.
- macOS가 관리하는 기본 Ruby는 제거하지 않는다.
- Homebrew Ruby를 다른 도구가 사용하지 않는지 먼저 확인하고 안전하게 정리한다.

---

# 전제 조건

- `plan5.md`의 `Dockerfile`과 `local.sh` 구현을 완료한다.
- 다음 Docker 기반 명령의 동작을 모두 검증한다.

```bash
./local.sh serve
./local.sh build
./local.sh test
```

- Docker 전환 검증이 끝나기 전에는 호스트 Ruby를 제거하지 않는다.

---

# Ruby 설치 경로 확인

다음 명령으로 현재 사용되는 Ruby와 설치 경로를 확인한다.

```bash
type -a ruby
which ruby
ruby -v
```

- `/usr/bin/ruby`는 macOS가 관리하므로 제거하지 않는다.
- `/opt/homebrew/...` 또는 `/usr/local/...` 경로는 Homebrew로 설치한 Ruby인지 확인한다.
- `~/.rbenv`, `~/.asdf`, `~/.local/share/mise` 경로가 있으면 별도 버전 관리자가 설치한 Ruby인지 확인한다.

---

# Homebrew 의존성 확인

설치된 Homebrew Ruby 버전과 이를 사용하는 다른 패키지가 있는지 확인한다.

```bash
brew list --versions ruby
brew uses --installed ruby
```

- 다른 패키지가 Ruby에 의존하면 제거하기 전에 해당 패키지의 용도를 확인한다.
- 의존성 문제가 있을 때 `--force`로 강제 제거하지 않는다.

---

# Homebrew Ruby 제거

다른 도구가 사용하지 않는 것이 확인된 경우에만 제거한다.

```bash
brew uninstall ruby
```

- 제거 후 Homebrew Ruby에 설치했던 Bundler와 gem도 더 이상 사용하지 않는다.
- 프로젝트의 Ruby와 gem 의존성은 Docker 이미지 내부에서 관리한다.

---

# 셸 설정 정리

- `~/.zshrc`에서 이 프로젝트를 위해 추가한 Homebrew Ruby PATH 설정을 찾는다.
- 다른 용도로 사용하지 않는 설정인지 확인한 뒤 해당 줄만 제거한다.
- `~/.zshrc`는 프로젝트 외부의 개인 설정 파일이므로 실제 수정 전에 별도 확인과 허락을 받는다.
- 새 터미널을 열거나 셸 설정을 다시 불러온 뒤 Ruby 경로를 재확인한다.

```bash
type -a ruby
which ruby
ruby -v
```

---

# README 반영 범위

- README에는 Docker만 있으면 프로젝트를 실행할 수 있다는 내용을 작성한다.
- 호스트 Ruby가 필요하지 않다는 점을 명시한다.
- 개인 Mac에 설치된 Homebrew Ruby 제거 과정은 프로젝트 사용자가 공통으로 수행해야 하는 절차가 아니므로 README에 포함하지 않는다.
- 호스트 정리 과정과 결과는 작업 히스토리에만 기록한다.

---

# Docker 리소스 정리

## 리소스 구분

- 컨테이너는 `docker run --rm`으로 실행해 프로세스 종료 시 자동 삭제한다.
- 이미지는 컨테이너가 아니므로 `--rm`으로 삭제되지 않는다.
- named volume을 사용하면 컨테이너 종료 후에도 별도로 남는다.
- 이미지를 삭제해도 Docker build cache 일부는 남을 수 있다.

## 권장 정책

- 모든 일회성 컨테이너에 `--rm`을 적용한다.
- gem 의존성은 Docker 이미지에 포함해 별도 named volume을 만들지 않는다.
- 프로젝트 이미지는 반복 실행 속도를 위해 기본적으로 하나만 유지하고 재사용한다.
- `local.sh`에 `clean` 명령을 제공해 필요할 때 프로젝트 이미지와 프로젝트 생성물만 제거한다.
- 다른 프로젝트에도 영향을 줄 수 있는 Docker 전체 build cache 정리는 자동으로 실행하지 않는다.

## 실행 인터페이스

```bash
./local.sh serve
./local.sh build
./local.sh test
./local.sh clean
```

- `serve` 컨테이너는 사용자가 서버를 종료하면 자동 삭제된다.
- `build`와 `test`도 일회성 컨테이너를 사용하고 종료 후 자동 삭제한다.
- `clean`은 이 프로젝트의 로컬 이미지와 `_site` 같은 생성물만 제거한다.

## 완전 자동 삭제 방식

스크립트 종료 시 프로젝트 이미지까지 삭제하려면 다음과 같은 `trap`을 사용할 수 있다.

```bash
trap 'docker image rm choimory-blog:local >/dev/null 2>&1 || true' EXIT
```

- 이 방식은 실행 후 프로젝트 이미지가 남지 않는다.
- 다음 실행마다 gem 설치와 이미지 빌드가 다시 필요해 실행 시간이 길어진다.
- 따라서 기본 동작으로 사용하지 않고, 컨테이너 자동 삭제와 명시적인 `clean` 명령 조합을 채택한다.

---

# 작업 순서

1. Docker 기반 `serve`, `build`, `test`를 모두 검증한다.
2. `clean`이 프로젝트 컨테이너, 이미지와 생성물만 정리하는지 검증한다.
3. 현재 Ruby 실행 경로와 버전을 확인한다.
4. Homebrew Ruby를 사용하는 다른 패키지가 있는지 확인한다.
5. 의존성이 없을 때 Homebrew Ruby를 제거한다.
6. 사용자 확인 후 `~/.zshrc`의 Homebrew Ruby PATH 설정을 정리한다.
7. 새 셸에서 Homebrew Ruby가 경로에서 제거됐는지 확인한다.
8. Docker 기반 프로젝트 실행이 계속 정상인지 최종 확인한다.

---

# 주의사항

- macOS 기본 Ruby는 삭제하거나 변경하지 않는다.
- Homebrew가 의존성 오류를 표시하면 강제 제거하지 않는다.
- Docker 검증 완료 전에 호스트 Ruby를 먼저 제거하지 않는다.
- 프로젝트 디렉터리 밖의 셸 설정은 사용자 허락 없이 수정하지 않는다.
