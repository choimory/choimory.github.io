---
title: "node, nvm, npm"
date: 2025-10-14T00:00:00
toc: true
toc_sticky: true
categories:
    - Node.js
tags:
    - nvm
    - npm
---

# node, nvm, npm

- Node.js, NVM, NPM의 차이와 관계
- **NVM을 설치한 뒤 NVM을 통해 원하는 Node.js 버전을 설치하고 관리**하는 방식이다.
- **Express.js**나 **NestJS** 같은 프레임워크는 보통 **NPM(Node Package Manager)**을 통해 설치하고 관리한다. 이는 Node.js 프로젝트의 일반적인 패키지 설치 방식이다

# Node.js

- **정의**: JavaScript 런타임 환경으로, 서버 사이드 애플리케이션 개발을 위해 사용됨.브라우저 밖에서 JavaScript를 실행할 수 있도록 구글의 V8 엔진을 기반으로 만들어짐.
- **주요 역할**:
    - 서버에서 JavaScript 코드를 실행.
    - 비동기 I/O 처리와 이벤트 기반 아키텍처 제공.
    - 서버 개발에 필요한 모듈과 API 제공 (예: `http`, `fs`, `os` 등).
- **설치 결과**:
    - Node.js 실행 파일이 설치됨.
    - 함께 설치되는 도구: `npm` (Node Package Manager).

---

# NVM (Node Version Manager)

- **정의**: Node.js 버전을 관리하는 도구.
- **주요 역할**:
    - 여러 Node.js 버전을 동시에 설치하고, 원하는 버전으로 쉽게 전환.
    - 프로젝트별로 다른 Node.js 버전을 사용할 수 있도록 지원.
    - Node.js 버전 간의 호환성 문제 해결.
- **사용 방식**:
    - NVM으로 특정 Node.js 버전 설치: `nvm install <버전>`
    - 현재 버전 확인: `nvm current`
    - 버전 전환: `nvm use <버전>`

---

# NPM (Node Package Manager)

- **정의**: Node.js의 기본 패키지 관리 도구.
- **주요 역할**:
    - JavaScript 패키지(라이브러리) 설치 및 관리.
    - 프로젝트 의존성을 손쉽게 관리 (`package.json` 기반).
    - CLI(Command Line Interface) 도구 제공.
- **핵심 명령어**:
    - 패키지 설치: `npm install <패키지>`
    - 글로벌 설치: `npm install -g <패키지>`
    - 패키지 제거: `npm uninstall <패키지>`
    - 스크립트 실행: `npm run <스크립트>`
- **Node.js 설치 시 자동으로 포함됨**.

---

# 관계

1. **Node.js ↔ NPM**:
    - NPM은 Node.js와 함께 설치되며, Node.js에서 패키지를 관리하기 위한 기본 도구로 사용됨.
2. **NVM ↔ Node.js**:
    - NVM은 Node.js 버전을 관리하기 위한 도구로, Node.js의 설치 및 버전 전환을 도와줌.
    - Node.js 설치와 버전 관리만 담당하며 NPM이나 다른 도구와는 직접적으로 연관되지 않음.
3. **NVM ↔ NPM**:
    - NVM으로 설치한 Node.js 버전에 따라 자동으로 해당 버전의 NPM도 포함됨.
    - NVM은 NPM의 버전을 직접 관리하지 않지만, Node.js 버전에 따라 NPM 버전이 따라감.

---

# **왜 NVM을 사용하는가?**

- Node.js는 버전에 따라 **새로운 기능**이나 **API 변경**이 있을 수 있음.
- 프로젝트마다 요구하는 Node.js 버전이 다를 수 있음.
- 시스템에 여러 버전의 Node.js를 설치하고, 필요할 때마다 전환할 수 있도록 도와줌.
- NVM을 설치한 뒤, 원하는 Node.js 버전을 NVM으로 가져와 사용하는 것이 효율적.
- NVM은 Node.js 버전 간의 전환 및 관리 문제를 손쉽게 해결함.

---

# **NVM 설치와 Node.js 버전 관리 흐름**

1. **NVM 설치**:
    - NVM 설치는 Node.js를 설치하기 전에 진행함.
    - 설치 방법(예시):

        ```bash
        # Linux/MacOS
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        
        # Windows
        winget install CoreyButler.NVMforWindows
        ```

2. **NVM으로 Node.js 설치**:
    - 특정 버전 설치:

        ```bash
        nvm install <버전>
        ```

      예: Node.js 18 설치

        ```bash
        nvm install 18
        ```

    - 설치된 Node.js 버전 확인:

        ```bash
        nvm list
        ```

    - 원하는 버전 사용 설정:

        ```bash
        nvm use <버전>
        ```

      예: Node.js 16 사용

        ```bash
        nvm use 16
        ```

3. **NPM 사용**:
    - NVM으로 Node.js를 설치하면, 해당 Node.js에 맞는 NPM도 자동으로 설치됨.
    - 이후 NPM을 통해 패키지 관리 가능:

        ```bash
        npm install <패키지>
        ```


---

# **NVM 사용의 장점**

- **버전 관리 용이**:
  여러 Node.js 버전을 설치하고, 필요할 때마다 빠르게 전환 가능.
- **개발 환경 독립성 보장**:
  프로젝트별로 다른 Node.js 버전을 사용할 때 충돌 없이 관리 가능.
- **Node.js 업데이트 간소화**:
  기존 버전을 유지하면서 새 버전을 쉽게 설치하고 테스트 가능.

---

# npm과 express.js, nest.js

- **Express.js**나 **NestJS** 같은 프레임워크는 보통 **NPM(Node Package Manager)**을 통해 설치하고 관리한다.
- 이는 Node.js 프로젝트의 일반적인 패키지 설치 방식이다.
- **Express.js**와 **NestJS**는 NPM을 통해 설치하고 관리함.
- Express.js는 가볍고 빠른 웹 프레임워크, NestJS는 더 구조적이고 확장 가능한 프레임워크.
- NPM은 라이브러리 다운로드, 의존성 관리, 버전 제어를 담당.

# Express.js와 NestJS 설치 및 관리 흐름

### 1. **Express.js**

Express.js는 경량화된 Node.js 웹 프레임워크로, 간단한 API 서버나 웹 애플리케이션을 구축할 때 많이 사용됨.

- 설치 방법:

    ```bash
    # 프로젝트 디렉터리 생성
    mkdir my-express-app && cd my-express-app
    
    # Node.js 초기화 및 package.json 생성
    npm init -y
    
    # Express.js 설치
    npm install express
    ```

- 설치 후 `node_modules` 폴더에 Express.js 코드가 다운로드되고, `package.json`에 의존성으로 기록됨:

    ```json
    "dependencies": {
      "express": "^4.18.2"
    }
    ```


---

### 2. **NestJS**

NestJS는 더 구조적이고 모듈화된 백엔드 프레임워크로, 대규모 애플리케이션에 적합함.

- Nest CLI를 통한 프로젝트 생성:

    ```bash
    # NestJS CLI 글로벌 설치
    npm install -g @nestjs/cli
    
    # 새 프로젝트 생성
    nest new my-nest-app
    ```

- Nest CLI는 프로젝트를 초기화하고 기본 의존성을 설치함. 이 과정에서 다음과 같은 명령이 내부적으로 실행됨:

    ```bash
    npm install @nestjs/core @nestjs/common rxjs
    ```

- 이미 초기화된 프로젝트에 추가적인 패키지 설치:

    ```bash
    npm install @nestjs/mongoose mongoose
    ```


---

# NPM이 이 과정에서 하는 역할

1. **패키지 다운로드**:
    - Express.js, NestJS 또는 기타 라이브러리를 중앙 NPM 레지스트리에서 다운로드.
2. **의존성 관리**:
    - `package.json` 파일에 기록되어 프로젝트 의존성을 관리.
3. **버전 제어**:
    - 특정 버전의 패키지를 설치하거나, 최신 안정 버전을 가져올 수 있음.
    - 예: 특정 버전 설치

        ```bash
        npm install express@4.17.1
        ```

4. **글로벌 도구 관리**:
    - NestJS CLI 같은 도구를 글로벌로 설치하여 시스템 어디서나 사용 가능.

---

# 요약

- **Node.js**: JavaScript 런타임 환경.
- **NVM**: Node.js 버전 관리 도구.
- **NPM**: Node.js에서 패키지를 관리하는 기본 도구.
- NVM은 Node.js 버전을 관리하며, Node.js와 함께 설치된 NPM도 영향을 받음.
- NPM은 Node.js 환경에서 패키지 설치와 프로젝트 의존성 관리를 담당.