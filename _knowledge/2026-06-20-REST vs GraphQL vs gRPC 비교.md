---
title: "REST vs GraphQL vs gRPC 비교"
date: 2026-06-20T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - API
    - REST
    - GraphQL
    - gRPC
---

## 개요

REST, GraphQL, gRPC는 각각 다른 문제를 해결하기 위해 등장한 API 통신 방식입니다. "무엇이 더 좋다"가 아니라 "언제 어떤 것을 선택하는가"가 핵심입니다.

---

## 등장 배경과 철학

### REST (2000년)

"REST"는 Roy Fielding의 박사 논문에서 제안된 아키텍처 스타일입니다. "자원(Resource)을 URL로 표현하고, HTTP 메서드로 행위를 정의한다"는 철학입니다.

```
GET    /posts       → 게시글 목록
GET    /posts/1     → 게시글 단건
POST   /posts       → 게시글 생성
PUT    /posts/1     → 게시글 전체 수정
DELETE /posts/1     → 게시글 삭제
```

### GraphQL (2015년)

Facebook이 모바일 앱 개발 중 겪은 "Over-fetching"과 "Under-fetching"을 해결하기 위해 만들었습니다. "클라이언트가 필요한 데이터의 구조를 직접 선언한다"는 철학입니다.

### gRPC (2016년)

Google이 내부 MSA 서비스 간 통신을 위해 만든 RPC 프레임워크입니다. HTTP/2와 Protocol Buffers(이진 직렬화)를 기반으로 성능을 극대화합니다.

---

## 핵심 차이 한눈에 보기

![alt text](../assets/images/2026-06-20-REST%20vs%20GraphQL%20vs%20gRPC%20비교/rest_graphql_grpc_comparison.png)

| 특성       | REST          | GraphQL         | gRPC          |
| -------- | ------------- | --------------- | ------------- |
| 프로토콜     | HTTP/1.1      | HTTP/1.1 (POST) | HTTP/2        |
| 데이터 형식   | JSON / XML    | JSON            | Protobuf (이진) |
| 스키마/계약   | OpenAPI (선택)  | SDL (필수)        | .proto (필수)   |
| 응답 구조 결정 | 서버            | 클라이언트           | 서버 (.proto)   |
| 실시간 지원   | SSE / Polling | Subscription    | 양방향 스트리밍      |
| 성능       | 보통            | 보통              | 매우 빠름         |
| 브라우저 지원  | 완벽            | 완벽              | 제한적           |
| 주 사용처    | 퍼블릭 API       | 복잡한 클라이언트       | MSA 서비스 간     |

---

## 기술 심화 비교

### 프로토콜과 전송 방식

REST와 GraphQL은 모두 HTTP/1.1 위에서 동작하며 JSON을 주고받습니다. 브라우저가 기본적으로 이해할 수 있어 `curl`이나 Postman으로 바로 테스트할 수 있습니다.

gRPC는 HTTP/2를 기반으로 하며 데이터를 Protocol Buffers(이진 형식)로 직렬화합니다. JSON 대비 직렬화/역직렬화 속도가 5~10배 빠르고 페이로드 크기가 60~80% 작습니다.

### 통신 모델 비교

gRPC는 네 가지 통신 패턴을 모두 지원합니다.

```protobuf
service ChatService {
  // 1. 단방향 (Unary): 1요청 → 1응답
  rpc SendMessage (Message) returns (MessageResponse);

  // 2. 서버 스트리밍: 1요청 → N응답 (실시간 피드)
  rpc StreamMessages (StreamRequest) returns (stream Message);

  // 3. 클라이언트 스트리밍: N요청 → 1응답 (파일 업로드)
  rpc UploadChunks (stream Chunk) returns (UploadResponse);

  // 4. 양방향 스트리밍: N요청 → N응답 (실시간 채팅)
  rpc Chat (stream Message) returns (stream Message);
}
```

---

## Spring Boot 구현 비교

같은 "게시글 단건 조회"를 세 방식으로 구현했을 때의 차이입니다.

```kotlin
// REST
@GetMapping("/api/posts/{id}")
fun getPost(@PathVariable id: String): ResponseEntity<PostResponse> {
    val post = postService.findById(id) ?: return ResponseEntity.notFound().build()
    return ResponseEntity.ok(PostResponse.from(post))
}

// GraphQL
@QueryMapping
fun post(@Argument id: String): Post? = postService.findById(id)

// gRPC
override suspend fun getPost(request: GetPostRequest): PostProto {
    val post = postService.findById(request.id)
        ?: throw StatusException(Status.NOT_FOUND.withDescription("게시글 없음"))
    return PostProto.newBuilder().setId(post.id).setTitle(post.title).build()
}
```

---

## 언제 무엇을 선택하는가

### REST를 선택할 때

- 공개 API를 제공할 때 (외부 개발자가 `curl` 하나로 바로 사용)
- 캐싱이 중요한 경우 (GET 요청의 URL 기반 HTTP 캐싱)
- 팀의 GraphQL/gRPC 경험이 없을 때

### GraphQL을 선택할 때

- 프론트엔드가 다양한 화면에서 서로 다른 데이터 조합이 필요할 때
- BFF(Backend For Frontend) 패턴을 구현할 때
- React/Next.js 프론트엔드와 협업 시 Apollo Client와의 조합

### gRPC를 선택할 때

- MSA 서비스 간 내부 통신 (브라우저 개입 없음)
- 대용량 데이터를 고성능으로 처리할 때
- 실시간 양방향 스트리밍이 필요할 때

### 현실적인 조합 패턴

```
클라이언트 (React/모바일)
    ↓ GraphQL (클라이언트 친화적)
BFF / API Gateway
    ↓ gRPC (고성능 내부 통신)
Order Service ─ gRPC ─ Payment Service
    ↓ REST (외부 파트너사 연동)
외부 결제 PG API
```

---

## 요약

REST는 "범용성과 단순함", GraphQL은 "클라이언트 유연성", gRPC는 "성능과 타입 안전성"이 각각의 핵심 가치입니다. 퍼블릭 API나 단순 CRUD라면 REST, 다양한 클라이언트가 서로 다른 데이터를 필요로 한다면 GraphQL, MSA 서비스 간 고성능 내부 통신이라면 gRPC가 적합합니다. 세 방식은 상호 배타적이 아니며, 계층별로 혼합하는 것이 현실적인 프로덕션 아키텍처입니다.