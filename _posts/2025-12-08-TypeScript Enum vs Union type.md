---
title: "TypeScript Enum vs Union type"
date: 2025-12-08T00:00:00
toc: true
toc_sticky: true
categories:
    - TypeScript
tags:
    - Enum
    - Union
---

# Enum

```tsx
// Enum 정의
enum UserRole {
  Admin = 'admin',
  User = 'user',
  Guest = 'guest',
}

// Enum 관련 함수 정의
function getRolePermissions(role: UserRole): string[] {
  switch (role) {
    case UserRole.Admin:
      return ['read', 'write', 'delete'];
    case UserRole.User:
      return ['read', 'write'];
    case UserRole.Guest:
      return ['read'];
    default:
      return [];
  }
}

// 사용 예시
const role: UserRole = UserRole.Admin; 
console.log(getRolePermissions(role)); // ['read', 'write', 'delete']

```

- Enum의 한계:
    - TypeScript `enum` 내부에 함수를 직접 정의할 수 없음.
    - 별도의 외부 함수로 처리해야 함.

---

# Union type

```tsx
// Union type as const 정의
const UserRole = {
  Admin: 'admin',
  User: 'user',
  Guest: 'guest',
} as const;

type UserRole = typeof UserRole[keyof typeof UserRole];

// Union type 관련 함수 정의
function getRolePermissions(role: UserRole): string[] {
  switch (role) {
    case UserRole.Admin:
      return ['read', 'write', 'delete'];
    case UserRole.User:
      return ['read', 'write'];
    case UserRole.Guest:
      return ['read'];
    default:
      return [];
  }
}

// 사용 예시
const role: UserRole = UserRole.Admin;
console.log(getRolePermissions(role)); // ['read', 'write', 'delete']

```

- 장점
    - `const` 객체로 키-값을 쉽게 정의 가능.
    - 객체로 사용하므로, 함수나 추가적인 메타데이터를 포함할 수 있음.

---

# Union type에 관련 행위 집약

```tsx
// 행위 집약 가능한 구조
const UserRole = {
  Admin: {
    name: 'Admin',
    permissions: ['read', 'write', 'delete'],
    description: () => 'Administrator role with full access',
  },
  User: {
    name: 'User',
    permissions: ['read', 'write'],
    description: () => 'Regular user role with limited access',
  },
  Guest: {
    name: 'Guest',
    permissions: ['read'],
    description: () => 'Guest role with read-only access',
  },
} as const;

type UserRole = keyof typeof UserRole;

// 함수 정의
function getRoleInfo(role: UserRole) {
  const roleData = UserRole[role];
  return {
    name: roleData.name,
    permissions: roleData.permissions,
    description: roleData.description(),
  };
}

// 사용 예시
const roleInfo = getRoleInfo('Admin');
console.log(roleInfo);
/*
{
  name: 'Admin',
  permissions: ['read', 'write', 'delete'],
  description: 'Administrator role with full access'
}
*/

```

---

# 비교

- **enum**
    - 간결한 정의가 가능.
    - 내부에 함수를 포함할 수 없음. 관련 함수는 외부에서 별도로 정의해야 함.
- **Union type as const**
    - 객체 형태로 유연하게 정의 가능.
    - 함수나 추가 데이터를 포함하여 행위를 집약할 수 있음.
    - 더 유연하고 실용적인 설계에 적합.

---

# Enum보다 Union type이 권장되는 이유

## **1. 런타임 동작과 타입 안전성**

### **`enum`:**

- TypeScript의 `enum`은 **런타임 객체**로 존재하며, 코드 내에서 잘못된 값을 할당할 가능성이 있음.

예시:

```tsx
enum UserRole {
  Admin = 'admin',
  User = 'user',
  Guest = 'guest',
}

// 의도하지 않은 값 할당 가능 (런타임 오류 유발 가능)
const role: UserRole = 'wrongValue' as UserRole; // 타입 시스템이 통과하나 잘못된 값
```

- 잘못된 문자열이나 숫자를 강제로 할당할 수 있기 때문에, 타입 시스템이 완벽하게 안전하지 않음.

### **`union type`:**

`union type as const`는 순수 타입 정의이며, TypeScript의 컴파일러가 더 엄격한 타입 검사를 제공함.

```tsx
const UserRole = {
  Admin: 'admin',
  User: 'user',
  Guest: 'guest',
} as const;

type UserRole = typeof UserRole[keyof typeof UserRole];

// 잘못된 값은 컴파일 단계에서 바로 오류 발생
const role: UserRole = 'wrongValue'; // Error: Type '"wrongValue"' is not assignable
```

---

## 2. **객체 지향 설계 가능**

### **`enum`:**

- `enum`은 단순한 값의 나열로 제한되며, 속성이나 동작(메서드)을 추가하기 어렵다.

### **`union type as const`:**

- `union type`은 객체로 정의 가능하므로 메타데이터와 메서드를 추가하여 더 유연하게 설계 가능하다.

```tsx
const UserRole = {
  Admin: {
    name: 'Admin',
    permissions: ['read', 'write', 'delete'],
  },
  User: {
    name: 'User',
    permissions: ['read', 'write'],
  },
  Guest: {
    name: 'Guest',
    permissions: ['read'],
  },
} as const;

type UserRole = keyof typeof UserRole;

function getPermissions(role: UserRole) {
  return UserRole[role].permissions;
}

console.log(getPermissions('Admin')); // ['read', 'write', 'delete']
```

---

## 3. **호환성과 유연성**

## **`enum`:**

- TypeScript의 `enum`은 JavaScript 런타임에서 추가적으로 번들링되는 코드가 생성됨.
- 다른 시스템(JavaScript, JSON 등)과 통합할 때, `enum`의 런타임 표현이 직관적이지 않을 수 있음.
- `enum` 값을 직렬화/역직렬화하거나 API 응답 처리 시 불필요한 변환이 필요할 수 있음.

```tsx
enum UserRole {
  Admin = 'admin',
  User = 'user',
  Guest = 'guest',
}
console.log(UserRole.Admin); // 'admin'
console.log(UserRole[UserRole.Admin]); // Undefined in some cases
```

## **`union type as const`:**

- 단순한 객체 리터럴 기반이라서 직렬화와 역직렬화가 간단하며, 다른 시스템과 호환성도 우수함.
- JSON, API 응답 처리에 더 적합함.

---

## 4. **타입 추론**

### **`enum`:**

- 값이 런타임에 존재하므로, TypeScript는 `enum`에 대한 타입 추론을 제한적으로 수행함.

### **`union type as const`:**

- TypeScript의 타입 시스템과 완벽히 호환되며, `as const` 키워드를 통해 모든 값을 리터럴 타입으로 추론 가능.

```tsx
const UserRole = {
  Admin: 'admin',
  User: 'user',
  Guest: 'guest',
} as const;

type UserRole = typeof UserRole[keyof typeof UserRole];
// 타입 안전하게 모든 값을 정확히 추론
```

---

## 5. **불필요한 런타임 코드 제거**

## **`enum`:**

- 런타임에서도 실제로 존재하는 객체로 번들되므로 불필요한 코드가 생성됨.

```jsx
// TypeScript enum의 컴파일 결과물
var UserRole;
(function (UserRole) {
  UserRole["Admin"] = "admin";
  UserRole["User"] = "user";
  UserRole["Guest"] = "guest";
})(UserRole || (UserRole = {}));
```

### **`union type as const`:**

- 순수한 타입 정의로, 런타임에 추가적인 코드가 생성되지 않음. 코드 크기와 성능에서 더 유리.

---

# 요약

- `union type as const`가 코드의 안정성과 확장성 면에서 더 견고한 선택이 될 수 있음.

## **타입 안전성:**

- `union type`은 강제된 값만 사용할 수 있어 더 안전함.

## **유연성:**

- `union type`은 객체 구조를 활용하여 추가적인 메타데이터나 메서드를 포함할 수 있음.

## **호환성:**

- `union type`은 JSON 및 API 응답 처리에 더 적합하며, 런타임에 추가 코드를 생성하지 않음.

## **타입 추론과 컴파일 단계 검증:**

- `union type`은 TypeScript의 타입 시스템과 자연스럽게 통합됨.