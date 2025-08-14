#!/bin/bash

# 스크립트 사용법: ./create_post.sh "여기에 포스트 제목 입력"

# 1. 제목이 입력되었는지 확인
if [ -z "$1" ]; then
  echo "오류: 포스트 제목을 입력해주세요."
  echo "사용법: $0 \"포스트 제목\""
  exit 1
fi

# 2. 변수 설정
POST_TITLE="$1"
# 파일 이름에 사용될 제목 (소문자 변환, 공백을 하이픈으로 변경)
FILENAME_TITLE=$1 #치환내용 가독성이 별로라서 그냥 주석 -> $(echo "$POST_TITLE" | tr '[:upper:]' '[:lower:]' | perl -pe 's/^\s+|\s+$//g; s/\s+/-/g; s/[^a-z0-9-가-힣]//g; s/-$//;')
CURRENT_DATE=$(date +%Y-%m-%d)
FULL_DATETIME=$(date +%Y-%m-%dT00:00:00)
FILE_PATH="_posts/${CURRENT_DATE}-${FILENAME_TITLE}.md"

# 3. Front Matter 내용 정의
# heredoc을 사용하여 여러 줄의 문자열을 변수에 할당
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

# 4. 파일 생성
echo "$FILE_CONTENT" > "$FILE_PATH"

# 5. 완료 메시지 출력
echo "포스트가 성공적으로 생성되었습니다: ${FILE_PATH}"
