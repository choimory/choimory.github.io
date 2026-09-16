#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly IMAGE_NAME="choimory-blog:local"
readonly HOST_PORT="${PORT:-4000}"
readonly COMMAND="${1:-serve}"

usage() {
  cat <<'EOF'
사용법: ./local.sh [serve|build|test|clean]

  serve  로컬 Jekyll 서버 실행 (기본값)
  build  production 사이트를 _site에 생성
  test   production 빌드 후 html-proofer 실행
  clean  프로젝트 이미지와 로컬 생성물 삭제
EOF
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "오류: Docker가 설치되어 있지 않습니다." >&2
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "오류: Docker daemon이 실행 중이지 않습니다." >&2
    exit 1
  fi
}

build_image() {
  docker build --tag "$IMAGE_NAME" "$PROJECT_DIR"
}

run_container() {
  docker run --rm --init \
    --user "$(id -u):$(id -g)" \
    --env HOME=/tmp \
    --env GIT_CONFIG_COUNT=1 \
    --env GIT_CONFIG_KEY_0=safe.directory \
    --env GIT_CONFIG_VALUE_0=/site \
    --volume "$PROJECT_DIR:/site" \
    --workdir /site \
    "$@"
}

clean() {
  if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    docker image rm "$IMAGE_NAME"
  else
    echo "삭제할 프로젝트 이미지가 없습니다: $IMAGE_NAME"
  fi

  rm -rf -- \
    "$PROJECT_DIR/_site" \
    "$PROJECT_DIR/.jekyll-cache" \
    "$PROJECT_DIR/.sass-cache"

  echo "프로젝트 Docker 이미지와 로컬 생성물을 정리했습니다."
}

case "$COMMAND" in
  serve)
    check_docker
    build_image
    run_container \
      --publish "$HOST_PORT:4000" \
      --env JEKYLL_ENV=development \
      "$IMAGE_NAME" \
      bundle exec jekyll serve --host 0.0.0.0 --port 4000
    ;;
  build)
    check_docker
    build_image
    run_container \
      --env JEKYLL_ENV=production \
      "$IMAGE_NAME" \
      bundle exec jekyll build --destination /site/_site
    ;;
  test)
    check_docker
    build_image
    run_container \
      --env JEKYLL_ENV=production \
      "$IMAGE_NAME" \
      bash -lc 'bundle exec jekyll build --destination /site/_site && bundle exec htmlproofer /site/_site --disable-external --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"'
    ;;
  clean)
    check_docker
    clean
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "오류: 지원하지 않는 명령입니다: $COMMAND" >&2
    usage >&2
    exit 1
    ;;
esac
