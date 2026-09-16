# 목차

- [개요](#개요)
- [Chirpy 테마 전환 구현](#chirpy-테마-전환-구현)

---

# 개요

- `plan2.md`의 단계별 계획에 따라 Minimal Mistakes에서 Chirpy로 전환한다.
- 구현 상태와 검증 결과를 이 문서에 기록한다.

---

# Chirpy 테마 전환 구현

> 구현 시작

## 작업 상태

- 구현 및 검증 완료
- 작업 완료

## 구현 내용

- `jekyll-theme-chirpy` 7.6.0 기반으로 테마 설정과 의존성을 교체했다.
- 기존 Experience 12개, Knowledge 152개 글을 각각 `_posts/experiences`, `_posts/knowledge`로 이동했다.
- 글의 `section` 기본값과 `/experiences/:title/`, `/knowledge/:title/` permalink를 디렉터리별로 적용했다.
- Experiences와 Knowledge를 독립 탭으로 유지하면서 categories와 tags는 전체 글에서 공통으로 집계하도록 구성했다.
- Experiences와 Knowledge 전용 연도별 목록 레이아웃을 추가했다.
- 기존 글의 URL과 분류 메타데이터를 정리하고, Chirpy와 충돌하는 Minimal Mistakes 전용 파일과 설정을 제거했다.
- 새 구조에 맞게 `post.sh`와 GitHub Pages 배포 workflow를 갱신했다.

## 검증 결과

- production Jekyll 빌드 성공
- YAML front matter 164개 파싱 성공
- permalink 중복 0건
- 검색 인덱스 164개 생성 확인
- `html-proofer`로 생성 결과 345개 파일, 내부 링크 2,764개 검증 성공
- `Back-end` 카테고리에서 Experience와 Knowledge 글의 교차 노출 확인
- Experience 및 Knowledge 글 생성 스크립트 실행 성공
- 데스크톱과 모바일에서 홈, 섹션 목록, 글 상세 화면의 레이아웃과 본문 표시 확인

## 참고

- 로컬 기본 Ruby 4.0.6은 Chirpy 지원 범위를 벗어나므로 Ruby 3.3 Docker 환경에서 검증했다.
- 실제 의존성 해석 결과 Jekyll 4.4.1과 Chirpy 7.6.0이 설치되었다.
