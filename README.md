# install

- `brew install ruby` -> 이후 ./zshrc에 PATH 등록 필요
- `gem install bundler`
- `bundle install`

# run

- `bundle exec jekyll serve` -> localhost:4000

# 사용 테마 정보

## 사용 테마

- minimal-mistakes-jekyll
- https://mmistakes.github.io/minimal-mistakes/
- https://mmistakes.github.io/minimal-mistakes/docs/quick-start-guide

## 구조

- https://mmistakes.github.io/minimal-mistakes/docs/structure/
- _config.yml
    - 사이트의 전반적인 설정을 하는 가장 중요한 파일입니다. 
    - 사이트의 제목, 설명, 소유자 정보, 댓글 기능, 소셜 미디어 링크 등 거의 모든 것을 이곳에서 제어합니다.
- _data
    - 사이트 전체에서 사용할 데이터를 저장하는 폴더입니다. 
    - navigation.yml 파일은 사이트 상단에 표시되는 메인 메뉴의 링크와 구조를 정의하는 데 사용됩니다.
- _pages
    - '소개(About)', '태그 목록(Tag Archive)' 등 블로그 포스트가 아닌 독립적인 페이지들을 모아두는 곳입니다. 
    - Markdown(md) 파일로 작성됩니다.
- _posts
    - 블로그 게시물들이 저장되는 핵심 폴더입니다.
    - 파일 이름은 반드시 YYYY-MM-DD-제목.md 형식으로 만들어야 Jekyll이 포스트로 인식합니다.
- assets
    - 이미지, CSS, 폰트, 자바스크립트 등 웹사이트의 리소스(자산)를 보관하는 폴더입니다. 
    - 현재는 주로 각 포스트에 첨부된 이미지들이 들어있습니다.
- index.html
    - 사이트의 첫 화면, 즉 홈페이지의 레이아웃과 내용을 정의하는 파일입니다. 
    - 보통 최근 포스트 목록을 보여주는 코드가 포함되어 있습니다.
- Gemfile
    - 이 Jekyll 프로젝트가 사용하는 Ruby 라이브러리(Gem)들의 목록과 버전을 관리하는 파일입니다. 
    - bundle install 명령은 이 파일을 보고 필요한 라이브러리를 설치합니다.
- 요약
    - _posts에는 글을 작성하고
    - _assets에는 _posts 작성에 첨부한 이미지들을, _posts와 같은 폴더명으로 1:1로 매칭하여 보관하고
    - _pages에는 404 페이지, 자기소개 페이지, 태그 목록 같은 별개의 글들을 작성하고
    - _data와 _config.yml로 사이트의 형태와 기능을 조절함