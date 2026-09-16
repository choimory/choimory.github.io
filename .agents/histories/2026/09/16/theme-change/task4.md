# 목차

- [개요](#개요)
- [Docker 로컬 실행 환경](#docker-로컬-실행-환경)

---

# 개요

- `plan5.md`에 따라 호스트 Ruby에 의존하지 않는 Docker 로컬 실행 환경을 구성한다.
- 실행, 빌드, 검증과 정리를 하나의 스크립트로 제공한다.

---

# Docker 로컬 실행 환경

## 작업 상태

- 구현 및 검증 완료
- 작업 완료

## 구현 내용

- Ruby 3.3 slim 기반 `Dockerfile`을 추가했다.
- gem native extension 빌드 도구, Git과 `html-proofer` 실행에 필요한 libcurl을 이미지에 포함했다.
- `Gemfile`과 `Gemfile.lock`을 소스보다 먼저 복사해 gem 설치 layer cache를 사용하도록 구성했다.
- `_site`, Jekyll cache, Git, IDE와 작업 히스토리를 build context에서 제외하는 `.dockerignore`를 추가했다.
- `local.sh`에 `serve`, `build`, `test`, `clean` 명령을 구현했다.
- 모든 실행 컨테이너에 `--rm`을 적용하고 별도 named volume을 만들지 않도록 구성했다.
- 호스트 UID와 GID로 컨테이너를 실행해 생성물의 파일 소유권을 유지하도록 구성했다.
- README의 공식 로컬 실행 방법을 `local.sh` 기반으로 변경하고 호스트 Ruby 실행 안내를 제거했다.

## 검증 결과

- `bash -n local.sh` 문법 검사 성공
- `./local.sh --help` 출력과 실행 권한 확인
- `./local.sh build` production 빌드 성공
- `./local.sh test` production 빌드 및 `html-proofer` 성공
- 생성 결과 345개 파일과 내부 링크 2,764개 검증 성공
- `PORT=4002 ./local.sh serve` 실행 후 모든 주요 탭 HTTP 200 확인
- serve 종료 후 프로젝트 컨테이너가 남지 않는 것을 확인
- 프로젝트 이미지 크기 약 258MB 확인
- `./local.sh clean` 실행 후 프로젝트 이미지, `_site`, `.jekyll-cache`, `.sass-cache`가 남지 않는 것을 확인
- Docker 전체 build cache와 다른 프로젝트 리소스를 삭제하지 않는 것을 확인

## 구현 중 보완

- 최초 slim 이미지에서는 `html-proofer`가 `libcurl.so.4`를 찾지 못해 test가 실패했다.
- Dockerfile에 `libcurl4-openssl-dev`를 추가한 뒤 전체 test가 통과하는 것을 확인했다.
