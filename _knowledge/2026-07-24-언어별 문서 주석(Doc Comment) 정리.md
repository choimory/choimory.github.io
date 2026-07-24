---
title: "언어별 문서 주석(Doc Comment) 정리"
date: 2026-07-24T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Comment
---

## Java 주석

Java는 크게 "한 줄 주석", "여러 줄 주석", "Javadoc 주석" 3가지를 사용합니다.

### 한 줄 주석

```java
// 한 줄 주석

int age = 20; // 코드 뒤에도 작성 가능
```

### 여러 줄 주석

```java
/*
여러 줄에 걸친
주석을 작성할 때 사용
*/
```

### Javadoc 주석

API 문서 생성에 사용되는 특수 주석입니다.

```java
/**
 * 회원을 조회합니다.
 *
 * @param id 회원 ID
 * @return 회원 정보
 */
public Member findMember(Long id) {
    ...
}
```

대표 태그는 `@param`, `@return`, `@throws`, `@author`, `@since`, `@see`, `@deprecated` 등이 있습니다.

```java
/**
 * 회원을 등록합니다.
 *
 * @param request 회원 생성 요청
 * @return 생성된 회원
 * @throws DuplicateEmailException 이메일이 중복된 경우
 * @since 1.0
 */
public Member createMember(CreateMemberRequest request) {
    ...
}
```

---

## JavaScript / TypeScript 주석

JavaScript와 TypeScript도 Java와 거의 동일한 문법을 사용합니다.

### 한 줄 주석

```jsx
// 한 줄 주석

const name = "Mory";
```

### 여러 줄 주석

```jsx
/*
여러 줄 주석
*/
```

### JSDoc 주석

JavaScript와 TypeScript에서는 "JSDoc"을 사용합니다.

```tsx
/**
 * 회원을 조회합니다.
 *
 * @param id 회원 ID
 * @returns 회원 정보
 */
function findMember(id: number): Member {
    ...
}
```

화살표 함수에서도 사용할 수 있습니다.

```tsx
/**
 * 두 수를 더합니다.
 *
 * @param a 첫 번째 숫자
 * @param b 두 번째 숫자
 * @returns 합계
 */
const add = (a: number, b: number): number => {
    return a + b;
};
```

TypeScript에서 자주 사용하는 JSDoc 태그는 `@param`, `@returns`, `@throws`, `@deprecated`, `@example`, `@see`, `@default`, `@type` 등이 있습니다.

```tsx
/**
 * 사용자 정보를 저장합니다.
 *
 * @param user 저장할 사용자
 * @returns 저장된 사용자
 * @throws Error 저장에 실패한 경우
 * @example
 * const user = await saveUser(member);
 */
async function saveUser(user: User): Promise<User> {
    ...
}
```

TypeScript는 일반적으로 "JSDoc + TypeDoc" 조합으로 문서화합니다. JSDoc은 주석 작성 형식이고, TypeDoc은 TypeScript 코드와 JSDoc을 읽어 API 문서를 생성하는 도구입니다.

---

## Python

Python은 `/** */` 같은 문법이 없습니다.

대신 함수, 클래스, 모듈의 첫 번째 문자열을 "Docstring"으로 인식합니다.

```python
def find_member(member_id: int):
    """
    회원을 조회합니다.

    Args:
        member_id: 회원 ID

    Returns:
        Member 객체
    """
    ...
```

이 문자열은 실제 객체의 `__doc__` 속성으로 저장됩니다.

```python
print(find_member.__doc__)
```

### Google Style

가장 많이 사용하는 스타일입니다.

```python
def add(a: int, b: int) -> int:
    """두 수를 더합니다.

    Args:
        a: 첫 번째 숫자
        b: 두 번째 숫자

    Returns:
        두 수의 합
    """
    return a + b
```

### NumPy Style

데이터 분석 분야에서 많이 사용합니다.

```python
def add(a, b):
    """
    Parameters
    ----------
    a : int
    b : int

    Returns
    -------
    int
    """
```

### reStructuredText 스타일

Sphinx에서 많이 사용합니다.

```python
def add(a, b):
    """
    :param a: 첫 번째 숫자
    :param b: 두 번째 숫자
    :return: 합계
    """
```

Python의 대표 문서 생성 도구에는 Sphinx, pdoc, MkDocs 등이 있습니다.

---

## Go

Go는 별도의 Javadoc 문법이 없습니다.

대신 `//` 주석을 사용하며, 문서화 대상의 이름으로 주석을 시작하는 규칙을 따릅니다.

```go
// Add returns the sum of a and b.
func Add(a, b int) int {
    return a + b
}
```

구조체 예시입니다.

```go
// User represents a system user.
type User struct {
    ID   int
    Name string
}
```

인터페이스 예시입니다.

```go
// Repository provides member persistence.
type Repository interface {
    Save(User)
}
```

패키지 예시입니다.

```go
// Package member provides member services.
package member
```

Go는 이러한 주석을 읽어 `go doc`이나 `pkg.go.dev`에서 문서를 생성합니다.

```go
// Client represents an HTTP client.
type Client struct{}

// Do sends an HTTP request.
func (c *Client) Do() {}
```

Go는 `@param`, `@return` 같은 태그보다는 자연어 문장과 함수 시그니처를 조합해 간결하게 문서화하는 방식을 권장합니다.

---

## Doc Comment의 공통 명칭

Javadoc, JSDoc, Docstring, GoDoc처럼 코드 요소를 설명하고 문서 생성에 활용하는 주석은 일반적으로 "Documentation Comment"라고 부릅니다.

실무에서는 이를 줄여서 "Doc Comment"라고 가장 많이 부릅니다. 한국어로는 "문서 주석"이라고 표현합니다.

### 언어별 명칭

| 언어 | 명칭 |
| --- | --- |
| Java | Javadoc |
| JavaScript | JSDoc |
| TypeScript | JSDoc, TypeDoc |
| Python | Docstring |
| Go | GoDoc 스타일 주석 |
| Kotlin | KDoc |
| C# | XML Documentation Comment |
| Rust | Rustdoc Comment |

공통적으로 표현할 때는 다음과 같이 말하는 것이 자연스럽습니다.

```
Public API에는 반드시 Doc Comment를 작성한다.
클래스와 인터페이스에는 Documentation Comment를 작성한다.
내부 구현에는 일반 주석(//)을 사용한다.
```

Javadoc, JSDoc, Docstring, GoDoc은 언어별 구현 방식은 다르지만, 상위 개념으로는 모두 "Doc Comment" 또는 "문서 주석"에 해당합니다.

---

## 언어별 비교

| 언어 | 문서화 방식 | 문서 생성 도구 |
| --- | --- | --- |
| Java | Javadoc (`/** */`) | Javadoc |
| JavaScript | JSDoc (`/** */`) | JSDoc |
| TypeScript | JSDoc (`/** */`) | TypeDoc |
| Python | Docstring (`""" """`) | Sphinx, pdoc, MkDocs |
| Go | `// 이름 ...` | GoDoc, pkg.go.dev |

---

## 전체 요약

- Java는 `//`, `/* */`, `/** */`을 사용하며, `/** */` 형태의 문서 주석을 Javadoc이라고 합니다.
- JavaScript와 TypeScript는 JSDoc 형식을 사용하고, TypeScript 문서 생성에는 TypeDoc을 함께 사용하는 경우가 많습니다.
- Python은 주석 문법 대신 함수·클래스·모듈의 첫 문자열인 Docstring을 사용합니다.
- Go는 일반 `//` 주석을 사용하지만 문서화 대상의 이름으로 시작하는 GoDoc 스타일을 따릅니다.
- 이들을 공통적으로 부를 때는 "Documentation Comment", 줄여서 "Doc Comment", 한국어로는 "문서 주석"이라고 합니다.