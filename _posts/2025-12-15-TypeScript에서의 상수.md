---
title: "TypeScript에서의 상수"
date: 2025-12-15T00:00:00
toc: true
toc_sticky: true
categories:
    - Typescript
tags:
    - export
    - const
---

# TypeScript에서의 상수

- Java의 `static final` 변수는 TypeScript에서 다음과 같은 방식으로 구현할 수 있다:

# TypeScript에서 구현 방식

## **`const`와 `export` 조합** (Java의 `public static final`과 유사한 방식):

- TypeScript에서는 모듈 수준에서 `const`를 사용하여 값을 정의하면 이를 불변 상수로 사용할 수 있다.
- `export` 키워드를 추가하면 다른 모듈에서 접근 가능하다.

```tsx
// Java 코드
public class Constants {
    public static final String MY_CONSTANT = "Hello, World!";
}

// TypeScript 코드
export const MY_CONSTANT = "Hello, World!";
```

## **클래스 내부의 `static` 변수** (Java 클래스 내부의 `static final`):

- TypeScript에서는 클래스 내부에 `static readonly` 키워드를 사용하여 `static final` 상수를 구현할 수 있다.

```tsx
// Java 코드
public class Constants {
    public static final String MY_CONSTANT = "Hello, World!";
}

// TypeScript 코드
export class Constants {
    static readonly MY_CONSTANT = "Hello, World!";
}
```

## **네임스페이스를 사용한 상수 정의** (Java의 `static final` 필드를 그룹화한 방식):

- TypeScript에서 `namespace`를 사용하여 상수를 그룹화할 수 있다.

```tsx
// Java 코드
public class Constants {
    public static final String MY_CONSTANT = "Hello, World!";
    public static final int MAX_COUNT = 100;
}

// TypeScript 코드
export namespace Constants {
    export const MY_CONSTANT = "Hello, World!";
    export const MAX_COUNT = 100;
}
```

# 요약

- 모듈 단위의 상수: `export const`
- 클래스 내부 상수: `static readonly`
- 상수 그룹화: `namespace`