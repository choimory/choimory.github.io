# 개요

- 좌측메뉴의 카테고리, 태그, 아카이브, 정보도 영어로 변경해줘
- 좌측메뉴의 이름은 choimory.devlog -> choimory로 변경, 좌측메뉴의 소개는 Back-end Engineer's dev log -> Back-end, Dev-ops Engineer로 변경
- 프로필 사진 4ECBB2E6-D78C-48B4-BCB7-E807EA548927_1_105_c.jpeg 21-24-21-394.jpeg로 변경

---

# 분석 결과

## 좌측 메뉴 영문화

- Chirpy는 `_tabs`의 `title`보다 현재 언어의 로케일 값을 우선 사용한다.
- `_tabs/categories.md` 등에 영문 `title`만 추가하는 방식으로는 메뉴명이 변경되지 않는다.
- 사이트 언어 `ko-KR`은 유지하고 `_data/locales/ko-KR.yml`에서 필요한 메뉴명만 덮어쓴다.
- 다음 항목을 영문으로 변경한다.
  - 카테고리 -> Categories
  - 태그 -> Tags
  - 아카이브 -> Archives
  - 정보 -> About
- 검색 문구, 날짜와 같은 나머지 UI는 계속 한국어로 표시한다.

## 사이트 정보 변경

- `_config.yml`의 `title`을 `choimory.devlog`에서 `choimory`로 변경한다.
- `_config.yml`의 `tagline`을 `Back-end Engineer's dev log`에서 `Back-end, Dev-ops Engineer`로 변경한다.

## 프로필 이미지 변경

- 현재 설정된 프로필 이미지:
  - `0B354A31-CE69-44EF-B2FD-3B469BC71C41_1_105_c.jpeg 21-24-21-387.jpeg`
- 새 프로필 이미지:
  - `4ECBB2E6-D78C-48B4-BCB7-E807EA548927_1_105_c.jpeg 21-24-21-394.jpeg`
- 두 이미지 경로의 각 표기는 공백을 포함한 하나의 실제 파일명이다.
- 새 이미지는 886x886 정사각형이므로 Chirpy의 원형 아바타에 적합하다.
- 기존 이미지 파일은 삭제하지 않고 `_config.yml`의 `avatar` 경로만 변경한다.

## 연관 문제 보완

- Experiences와 Knowledge는 좌측 메뉴에서 정상 표시되지만 해당 페이지의 HTML 제목은 현재 사이트 이름 앞이 비어 있다.
- 생성 결과:
  - `<title> | choimory.devlog</title>`
- 로케일 덮어쓰기에 `experiences: Experiences`, `knowledge: Knowledge`를 함께 추가한다.
- 화면의 기존 메뉴명은 유지하면서 브라우저 탭과 문서 제목을 정상화한다.

---

# 구현 계획

1. `_data/locales/ko-KR.yml`을 추가하고 필요한 여섯 개 탭 이름만 정의한다.
2. `_config.yml`의 `title`, `tagline`, `avatar`를 변경한다.
3. production Jekyll 빌드를 수행한다.
4. Categories, Tags, Archives, About 메뉴와 페이지 제목이 영어로 표시되는지 확인한다.
5. Experiences와 Knowledge의 HTML 제목이 정상적으로 생성되는지 확인한다.
6. 사이트 이름, 소개와 새 프로필 이미지가 데스크톱 및 모바일에서 정상 표시되는지 확인한다.
7. 내부 링크와 변경사항 무결성을 검증한다.

---

# 변경 예정 파일

- `_config.yml`
- `_data/locales/ko-KR.yml`
