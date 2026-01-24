---
title: "TypeScript typeof, key of"
date: 2025-12-04T00:00:00
toc: true
toc_sticky: true
categories:
    - TypeScript
tags:
    - typeof
    - key of
---

# typeof, key of

- TypeScript에서 `typeof`와 `[keyof]`는 타입 추론 및 변환을 위한 강력한 기능이다. 각각의 역할과 사용하는 방법은 아래와 같다.

---

# 1. **`typeof`: 값으로부터 타입 추출**

- `typeof`는 **값(value)**에서 해당 값의 타입을 추출하는 데 사용된다. 주로 런타임 객체나 변수에서 타입을 생성할 때 사용된다.

## 기본 사용법

```tsx
const user = {
  name: 'Alice',
  age: 25,
};

// typeof를 사용해 객체의 타입 추출
type UserType = typeof user;

// UserType은 아래와 같은 타입으로 추출됨:
type UserType = {
  name: string;
  age: number;
};
```

---

# 2. **`keyof`: 객체의 키(key)를 유니온 타입으로 추출**

- `keyof`는 **객체 타입의 키(key)들**을 유니온 타입으로 반환한다.

## 기본 사용법

```tsx
type User = {
  name: string;
  age: number;
};

// keyof를 사용하여 User의 키 추출
type UserKeys = keyof User;

// UserKeys는 'name' | 'age'로 추출됨
```

- `keyof`는 객체의 모든 키를 동적으로 다뤄야 할 때 유용하다.

---

# 3. **`typeof`와 `keyof`의 조합**

- `typeof`와 `keyof`를 함께 사용하면 **런타임 객체에서 키를 동적으로 추출**하여 타입을 정의할 수 있다.

### 조합 예제

```tsx
const user = {
  name: 'Alice',
  age: 25,
};

// 객체의 타입 추출
type UserType = typeof user;

// 키만 추출
type UserKeys = keyof UserType;

// UserKeys는 'name' | 'age'
```

---

# 4. **활용 예제**

## 객체에서 동적 키를 타입으로 사용할 때

```tsx
const config = {
  host: 'localhost',
  port: 8080,
  secure: false,
} as const;

// 동적 키 타입 추출
type ConfigKeys = keyof typeof config;

// ConfigKeys는 'host' | 'port' | 'secure'

// 특정 키를 사용한 함수
function getConfigValue(key: ConfigKeys) {
  return config[key];
}

const value = getConfigValue('host'); // 'localhost'
```

## 객체의 값(value)을 유니온 타입으로 추출

```tsx
const roles = {
  Admin: 'admin',
  User: 'user',
  Guest: 'guest',
} as const;

// 값 타입 추출
type RoleValues = typeof roles[keyof typeof roles];

// RoleValues는 'admin' | 'user' | 'guest'
```

---

# 5. `typeof`와 `[keyof]`의 조합 패턴

## 패턴 1: 타입 안전한 객체 키 접근

```tsx
const colors = {
  red: '#ff0000',
  green: '#00ff00',
  blue: '#0000ff',
};

type ColorKeys = keyof typeof colors;

// 타입 안전하게 키 접근
function getColorHex(key: ColorKeys): string {
  return colors[key];
}

const hex = getColorHex('red'); // '#ff0000'
```

## 패턴 2: 유니온 타입 기반 동적 값 접근

```tsx
const settings = {
  theme: 'dark',
  language: 'en',
  notifications: true,
} as const;

type SettingKeys = keyof typeof settings;
type SettingValues = typeof settings[SettingKeys];

// SettingValues는 'dark' | 'en' | true
```

---

# 6. 요약

## **`typeof`:**

- 값(value)에서 타입을 추출함.
- 주로 객체, 변수, 리터럴 타입을 기반으로 새로운 타입 생성 시 사용.

## **`keyof`:**

- 객체 타입의 키(key)를 유니온 타입으로 추출.
- 동적 키 기반 로직을 설계할 때 유용.

## **`typeof` + `keyof`:**

- 런타임 객체에서 키와 값을 조합하여 타입을 추출하고 동적 접근 및 타입 안전성을 보장.

이 조합을 통해 런타임 데이터를 기반으로 타입을 추출하고 타입 안전한 코드를 작성할 수 있음.