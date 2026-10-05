---
title: "Jest vs Vitest"
date: 2026-10-05T00:00:00
toc: true
categories: ["Front-end"]
tags: ["TDD", "Jest", "Vitest"]
---

## 개요

둘 다 JavaScript/TypeScript 테스트 프레임워크입니다.

문법도 상당히 비슷합니다.

```tsx
describe('Calculator', () => {
  it('1 + 2 = 3', () => {
    expect(1 + 2).toBe(3);
  });
});
```

가장 큰 차이는 기반입니다.

- Jest → 독립적인 범용 테스트 프레임워크
- Vitest → Vite 생태계에 맞춰 만들어진 테스트 프레임워크

Vitest는 Vite의 설정, transformer, resolver, plugin을 그대로 활용할 수 있고 Jest 호환 API를 상당 부분 제공합니다. (vitest.dev)

---

## 핵심 비교

| 항목 | Jest | Vitest |
| --- | --- | --- |
| 기반 | 독립적 | Vite 기반 |
| React 테스트 | O | O |
| TypeScript | 별도 설정이 필요한 경우 있음 | 기본 지원이 매우 편함 |
| JSX/TSX | 설정 필요할 수 있음 | 기본 지원 |
| ESM | 지원하지만 설정 이슈가 생길 수 있음 | ESM 중심 |
| 실행 속도 | 보통 | 일반적으로 빠름 |
| Watch Mode | O | O, Vite 모듈 그래프 활용 |
| Mock | `jest.fn()` | `vi.fn()` |
| Snapshot | O | O |
| Coverage | O | O |
| 생태계/역사 | 매우 큼 | 비교적 신생 |
| Vite 프로젝트 궁합 | 보통 | 매우 좋음 |

Vitest는 TypeScript, JSX, ESM을 기본 지원하고 Vite의 모듈 그래프를 이용해 변경과 관련된 테스트만 다시 실행하는 watch mode를 제공합니다. (main.vitest.dev)

---

## Jest

Jest는 오랫동안 React/Node.js 생태계에서 사실상 표준처럼 사용되어 온 테스트 프레임워크입니다.

현재 Jest 공식 문서의 안정 버전은 30.5입니다. (jestjs.io)

### 장점

가장 큰 장점은 "성숙한 생태계"입니다.

라이브러리나 예제에서 Jest를 기준으로 설명하는 경우가 많고, 기존 프로젝트에서도 매우 흔합니다.

```tsx
const mockFn = jest.fn();

expect(mockFn).toHaveBeenCalled();
```

특히 이런 상황에서 좋습니다.

- 기존 프로젝트가 Jest 기반
- 오래된 React 프로젝트
- Vite를 사용하지 않음
- Jest용 라이브러리나 설정이 이미 많이 존재함

### 단점

현대적인 TypeScript + ESM 프로젝트에서는 Babel, ts-jest 등의 추가 설정을 신경 써야 하는 경우가 있습니다.

Jest 공식 TypeScript 예제도 Jest API를 명시적으로 import하는 형태를 안내하고 있습니다. (jestjs.io)

---

## Vitest

Vitest는 쉽게 말하면

> "Vite 시대에 맞게 만든 Jest 스타일 테스트 프레임워크"
> 

에 가깝습니다.

```tsx
import { describe, expect, it, vi } from 'vitest';

const mockFn = vi.fn();

describe('test', () => {
  it('works', () => {
    expect(true).toBe(true);
  });
});
```

### 가장 큰 특징

Vite 프로젝트라면 기존 `vite.config.ts` 및 Vite 플러그인 환경을 그대로 사용할 수 있습니다. (vitest.dev)

예를 들어 프로젝트에서 이미

```tsx
import { defineConfig } from 'vite';

export default defineConfig({
  resolve: {
    alias: {
      '@': '/src',
    },
  },
});
```

처럼 설정했다면 테스트에서도 같은 모듈 해석 환경을 사용할 수 있습니다.

이게 꽤 큰 장점입니다.

---

## 속도 차이

Vitest가 등장한 가장 큰 이유 중 하나가 개발 경험과 실행 속도입니다.

Vitest는 Vite의 모듈 그래프를 활용해서 변경된 코드와 연관된 테스트만 선택적으로 다시 실행할 수 있습니다. (main.vitest.dev)

그래서

```
코드 수정
 ↓
Vitest가 변경 감지
 ↓
관련 테스트만 재실행
```

하는 개발 사이클이 상당히 빠릅니다.

다만 "항상 Vitest가 Jest보다 N배 빠르다"처럼 고정된 수치로 볼 수는 없습니다. 프로젝트 규모와 transform 설정 등에 따라 달라집니다.

---

## 문법 차이

둘의 API는 거의 비슷합니다.

### Jest

```tsx
const fn = jest.fn();

jest.mock('./api');
jest.spyOn(service, 'find');
```

### Vitest

```tsx
const fn = vi.fn();

vi.mock('./api');
vi.spyOn(service, 'find');
```

즉 가장 눈에 띄는 차이는

```
jest.xxx
```

가

```
vi.xxx
```

로 바뀐다는 것입니다.

Vitest 자체가 Jest 호환 API를 목표로 설계되어 있기 때문에 Jest → Vitest 마이그레이션도 비교적 쉽습니다. (main.vitest.dev)

다만 완전히 동일한 것은 아닙니다. 예를 들어 `mockReset` 동작이나 globals 기본 활성화 여부 등에 차이가 있습니다. (main.vitest.dev)

---

## React 테스트에서는

React 프로젝트라면 둘 다 보통 React Testing Library와 함께 사용합니다.

### Jest

```
Jest
+
React Testing Library
+
jsdom
```

### Vitest

```
Vitest
+
React Testing Library
+
jsdom
```

컴포넌트 테스트 자체의 작성 방식은 거의 똑같습니다.

```tsx
render(<Button />);

expect(
  screen.getByRole('button')
).toBeInTheDocument();
```

즉 React Testing Library를 사용하는 입장에서는 Jest냐 Vitest냐보다 "테스트 러너를 무엇으로 사용할 것인가"에 가깝습니다.

---

## 어떤 것을 사용하면 좋은가

새로운 프론트엔드 프로젝트라면 프로젝트 빌드 환경을 기준으로 보면 됩니다.

```
Vite + React + TypeScript
        ↓
      Vitest
```

궁합이 매우 좋습니다.

반대로

```
기존 Jest 프로젝트
      ↓
굳이 Vitest로 변경할 이유가 없음
```

입니다.

Next.js처럼 특정 프레임워크와 Jest 설정이 이미 잘 정립되어 있는 경우에는 Jest를 그대로 사용하는 것도 자연스럽습니다.

---

## 전체 요약

핵심만 정리하면 다음과 같습니다.

```
Jest
 ├─ 오래됨
 ├─ 생태계 큼
 ├─ 범용적
 └─ 기존 프로젝트에서 많이 사용

Vitest
 ├─ Vite 기반
 ├─ 빠른 개발 피드백
 ├─ TypeScript / JSX / ESM 편리
 ├─ Jest API와 매우 유사
 └─ 신규 Vite 프로젝트에 특히 적합
```

따라서 "React + TypeScript + Vite 신규 프로젝트"라면 Vitest를 먼저 고려하는 것이 자연스럽고, 기존 Jest 프로젝트라면 그대로 Jest를 유지해도 충분합니다.