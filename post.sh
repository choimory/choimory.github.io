#!/bin/bash

# 스크립트 사용법: ./post.sh [e|k] "포스트 제목"
# e: experiences (체험기)
# k: knowledge (지식)

# 1. 인자 확인
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "오류: 메뉴 타입과 포스트 제목을 입력해주세요."
  echo "사용법: $0 [e|k] \"포스트 제목\""
  echo "  e: experiences (체험기)"
  echo "  k: knowledge (지식)"
  exit 1
fi

# 2. 메뉴 타입 확인
MENU_TYPE="$1"
POST_TITLE="$2"

case "$MENU_TYPE" in
  e|E)
    FOLDER="_experiences"
    ;;
  k|K)
    FOLDER="_knowledge"
    ;;
  *)
    echo "오류: 올바른 메뉴 타입을 입력해주세요. (e: experiences, k: knowledge)"
    exit 1
    ;;
esac

# 3. 변수 설정
# 슬래시(/)를 대시(-)나 언더바(_)로 치환하여 파일명 오류 방지
SAFE_TITLE=$(echo "$POST_TITLE" | sed 's/\//-/g')
CURRENT_DATE=$(date +%Y-%m-%d)
FULL_DATETIME=$(date +%Y-%m-%dT00:00:00)
FILE_PATH="${FOLDER}/${CURRENT_DATE}-${SAFE_TITLE}.md"

# 4. Front Matter 내용 정의
FILE_CONTENT=$(cat <<EOF
---
title: "${POST_TITLE}"
date: ${FULL_DATETIME}
toc: true
toc_sticky: true
categories:
    -
tags:
    -
---

(본문)
EOF
)

# 5. 파일 생성
echo "$FILE_CONTENT" > "$FILE_PATH"

# 6. 완료 메시지 출력
echo "포스트가 성공적으로 생성되었습니다: ${FILE_PATH}"
