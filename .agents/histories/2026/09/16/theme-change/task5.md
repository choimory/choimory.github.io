# 목차

- [개요](#개요)
- [호스트 Ruby 정리](#호스트-ruby-정리)

---

# 개요

- `plan6.md`에 따라 Docker 전환 검증 후 이 프로젝트를 위해 설치한 Homebrew Ruby를 호스트에서 제거한다.
- macOS 기본 Ruby와 다른 프로젝트의 Docker 리소스는 유지한다.

---

# 호스트 Ruby 정리

## 작업 상태

- 구현 및 검증 완료
- 작업 완료

## 작업 내용

- 현재 선택된 Ruby가 `/opt/homebrew/opt/ruby/bin/ruby`의 Homebrew Ruby 4.0.6임을 확인했다.
- `brew uses --installed ruby` 결과 Homebrew Ruby에 의존하는 설치 패키지가 없음을 확인했다.
- Homebrew Ruby 4.0.6을 제거했다.
- Homebrew가 더 이상 필요하지 않은 `libyaml`을 함께 자동 제거했다.
- `~/.zshrc`에서 Homebrew Ruby 전용 주석과 PATH 설정만 제거했다.
- macOS 기본 `/usr/bin/ruby`는 제거하거나 변경하지 않았다.

## 검증 결과

- 새 interactive shell에서 Ruby 경로가 `/usr/bin/ruby`로 확인됐다.
- Homebrew Ruby 설치 목록이 비어 있는 것을 확인했다.
- `~/.zshrc`와 `~/.zprofile`에 Homebrew Ruby PATH가 남지 않은 것을 확인했다.
- Homebrew Ruby 제거 후 `./local.sh test`를 다시 실행해 Docker 기반 전체 검증이 성공했다.
- 최종 `./local.sh clean` 실행 후 프로젝트 이미지, 컨테이너와 Jekyll 생성물이 남지 않은 것을 확인했다.
