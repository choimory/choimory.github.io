---
title: "ES에서의 null check, optional, falsy"
date: 2025-12-12T00:00:00
toc: true
toc_sticky: true
categories:
    - TypeScript
tags:
    - ECMAScript
---

# ?:

```tsx
export class Abc {
	// O
	data?: any;
	
	// X
	const data?: any;
}
```

- Optional Property
- 필드 속성이 선택적이다 (Optional, 있을수도 없을수도 있다)
- const는 필드의 초기화가 요구되므로 ?:를 사용할 수 없다

# ??

```tsx
constructor(id:number){
	// ?
	this.id ? id : 0;
	
	// ??
	this.id ?? 0;
}
```

- Nullish Coalescing Operator
- 판단할 값이 null 혹은 undefined일시 오른쪽 반환

# ||

```tsx
constructor(id:number){
	// ??
	this.id ?? 0;
	
	// ||
	this.id = id || 42;
}
```

- falsy
- null, undefined 뿐만아니라 “”, 0같은 값도 falsy 처리되어 우항이 선택됨