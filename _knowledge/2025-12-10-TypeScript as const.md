---
title: "TypeScript as const"
date: 2025-12-10T00:00:00
toc: true
toc_sticky: true
categories:
    - TypeScript
tags:
    - as const
---

# as const

- `as const`는 TypeScript에서 **객체, 배열, 또는 값**을 **리터럴 타입**으로 고정하는 데 사용하는 키워드이다.
- 이를 통해 해당 값들이 변경되지 않고, TypeScript 컴파일러가 더 좁은 타입으로 추론할 수 있게 한다.

---

# 주요 특징

## **리터럴 타입으로 고정**

- 기본적으로 TypeScript는 객체나 배열의 값을 더 일반적인 타입으로 추론함.
- `as const`를 사용하면 **값을 상수(literal)**로 취급하여 더 좁은 타입으로 추론하도록 만듦.

## **읽기 전용(Read-only)**

- `as const`를 적용한 값은 자동으로 `readonly` 속성을 가지게 됨. 변경이 불가능함.

---

# 사용 사례

## 1. **객체에서의 활용**

- `as const`를 사용하지 않은 경우:
    
    ```tsx
    const UserRole = {
      Admin: 'admin',
      User: 'user',
      Guest: 'guest',
    };
    
    // TypeScript는 각 값을 string으로 추론
    type UserRole = typeof UserRole[keyof typeof UserRole];
    // UserRole은 string
    ```
    
- `as const`를 사용한 경우:
    
    ```tsx
    const UserRole = {
      Admin: 'admin',
      User: 'user',
      Guest: 'guest',
    } as const;
    
    // TypeScript는 각 값을 리터럴 타입으로 추론
    type UserRole = typeof UserRole[keyof typeof UserRole];
    // UserRole은 'admin' | 'user' | 'guest'
    
    ```
    

## 2. **배열에서의 활용**

- `as const`를 사용하지 않은 경우:
    
    ```tsx
    const colors = ['red', 'green', 'blue'];
    
    // TypeScript는 배열을 string[]으로 추론
    type Colors = typeof colors[number];
    // Colors는 string
    ```
    
- `as const`를 사용한 경우:
    
    ```tsx
    const colors = ['red', 'green', 'blue'] as const;
    
    // TypeScript는 배열을 ['red', 'green', 'blue'] 리터럴 타입으로 추론
    type Colors = typeof colors[number];
    // Colors는 'red' | 'green' | 'blue'
    ```
    

## 3. **함수 반환값의 활용**

- `as const`를 사용하지 않은 경우:
    
    ```tsx
    function getStatus() {
      return {
        success: true,
        message: 'Operation completed',
      };
    }
    
    const status = getStatus();
    // status.success의 타입은 boolean
    
    ```
    
- `as const`를 사용한 경우:
    
    ```tsx
    function getStatus() {
      return {
        success: true,
        message: 'Operation completed',
      } as const;
    }
    
    const status = getStatus();
    // status.success의 타입은 true
    ```
    

---

# 주요 효과

## **리터럴 타입 유지**

- 객체나 배열 내부의 값이 **리터럴 타입**으로 고정됨.
- 타입 추론에서 더 좁은 범위를 제공하여 더 안전한 코드 작성 가능.

## **읽기 전용 속성 추가**

- `as const`를 적용하면 객체나 배열의 모든 속성이 자동으로 `readonly`가 됨.

```tsx
const example = { value: 42 } as const;
example.value = 50; // Error: Cannot assign to 'value' because it is a read-only property.
```

## **더 안전한 타입 정의**

- API 응답처럼 고정된 데이터의 경우 `as const`를 사용해 값이 변하지 않도록 보장 가능.

---

# 요약

- `as const`는 TypeScript에서 **값을 리터럴 타입으로 고정**하고, **읽기 전용**으로 만들어 타입 안정성을 강화하는 도구이다.
- 이로 인해 더 좁은 타입 추론과 불변성을 제공하여 안전한 코드 작성을 지원함.