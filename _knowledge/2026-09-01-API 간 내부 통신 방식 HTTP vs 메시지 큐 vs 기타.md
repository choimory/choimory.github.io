---
title: "API 간 내부 통신 방식: HTTP vs 메시지 큐 vs 기타"
date: 2026-09-01T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - HTTP API
    - Queue
    - gRPC
---

## 개요

MSA에서 API 간 내부 통신은 크게 "동기 통신"과 "비동기 통신"으로 나눌 수 있습니다.

핵심은 기술 자체보다 "호출한 서비스가 상대 서비스의 결과를 지금 당장 필요로 하는가?"입니다.

```
결과가 지금 필요함
→ HTTP / gRPC

결과를 지금 기다릴 필요 없음
→ Message Queue / Event

실시간 데이터 스트림
→ Kafka 같은 Streaming
```

따라서 HTTP와 Queue는 서로 대체재라기보다 용도가 다릅니다.

---

## HTTP 통신

가장 일반적인 API 간 동기 통신 방식입니다.

```
회원 API
   │
   │ GET /members/123
   ▼
예약 API
   │
   ▼
회원 정보 응답
```

호출자는 요청을 보내고 상대방의 응답을 기다립니다.

### 적합한 경우

예를 들어 예약을 생성하는 과정에서 회원 상태를 확인해야 한다면:

```
Reservation API
      │
      ├── HTTP → Member API
      │             │
      │             └── 회원 조회
      │
      ← 응답
      │
      └── 예약 생성
```

회원 조회 결과가 없으면 다음 로직을 실행할 수 없으므로 HTTP가 자연스럽습니다.

### 장점

- 구조가 단순합니다.
- 요청 → 응답 흐름이 명확합니다.
- 디버깅이 쉽습니다.
- REST API를 그대로 활용할 수 있습니다.

### 단점

서비스 간 결합이 생깁니다.

```
A → B → C
```

이 구조에서 C가 느려지면:

```
C 지연
↓
B 지연
↓
A 지연
```

으로 전파될 수 있습니다.

그래서 timeout, retry, circuit breaker 같은 장애 대응이 중요합니다.

---

## 메시지 큐

RabbitMQ, Kafka, SQS 같은 메시징 시스템을 이용하는 방식입니다.

```
Order API
    │
    │ 주문완료 이벤트
    ▼
Message Broker
    │
    ├── Notification API
    ├── Point API
    └── Analytics API
```

Order API는 다른 API의 처리가 끝날 때까지 기다리지 않습니다.

### 적합한 경우

대표적으로:

```
회원가입 완료
```

후 다음 작업들이 있다고 가정합니다.

```
Member API
     │
     └── MemberCreated
              │
              ▼
           Broker
          /   |   \
         /    |    \
      Mail   Point  Analytics
```

메일 발송이나 통계 저장이 끝나야 회원가입 성공을 반환할 필요는 없습니다.

따라서 이벤트 방식이 적합합니다.

### 장점

서비스 간 결합도가 낮아집니다.

```
Member API

"회원 생성됨"
     ↓
Broker
```

Member API는 누가 이 이벤트를 사용하는지 몰라도 됩니다.

### 단점

HTTP보다 운영 복잡도가 크게 증가합니다.

고려해야 할 것이 많습니다.

```
중복 메시지
재처리
순서 보장
DLQ
Consumer 장애
Eventual Consistency
Idempotency
메시지 유실
```

따라서 "MSA니까 Kafka" 같은 식으로 사용하는 것은 좋지 않습니다.

---

## HTTP와 Queue의 가장 중요한 차이

회원 API와 문자 API가 있다고 해보겠습니다.

### Case 1. 문자 전송 결과가 즉시 필요한 경우

```
Member API
   │
   └── HTTP → Notification API
                   │
                   └── SMS Provider
```

예:

```
POST /sms
```

응답:

```json
{
  "success": true,
  "messageId": "123"
}
```

이 결과를 바로 사용자에게 보여줘야 한다면 HTTP가 적합합니다.

### Case 2. 문자만 보내면 되는 경우

```
Member API
    │
    └── SMS_REQUESTED
             │
             ▼
           Queue
             │
             ▼
     Notification API
```

Member API는:

```
"문자 보내주세요"
```

만 전달하고 끝냅니다.

실제 SMS 발송이 1초 뒤에 되든 10초 뒤에 되든 문제가 없다면 Queue가 더 적합합니다.

---

## gRPC

HTTP REST 대신 내부 API 통신에 gRPC를 사용하는 방법도 있습니다.

```
Service A
   │
   │ gRPC
   ▼
Service B
```

Protocol Buffers를 사용합니다.

```protobuf
service MemberService {
    rpc GetMember(GetMemberRequest)
        returns (MemberResponse);
}
```

REST:

```
GET /members/123
```

와 역할 자체는 비슷합니다.

### HTTP REST와 비교

| 항목 | REST | gRPC |
| --- | --- | --- |
| 프로토콜 | HTTP + JSON | HTTP/2 + Protobuf |
| 데이터 | JSON | Binary |
| 성능 | 보통 | 높음 |
| 사람이 보기 | 쉬움 | 어려움 |
| 타입 계약 | 상대적으로 약함 | 강함 |
| 브라우저 | 편리 | 제한적 |
| 내부 API | 좋음 | 매우 좋음 |

MSA 내부 통신 전용이라면 gRPC도 좋은 선택입니다.

다만 일반적인 규모에서는 REST도 충분한 경우가 많습니다.

---

## Kafka

Kafka는 단순히 "Queue의 빠른 버전"으로 이해하면 약간 다릅니다.

Kafka는 Event Streaming 플랫폼에 가깝습니다.

```
Order API
    │
    └── OrderCreated
            │
            ▼
         Kafka
       ┌────┼────┐
       ▼    ▼    ▼
     Pay   Point Analytics
```

그리고 이벤트를 일정 기간 저장합니다.

```
Kafka Topic

offset 100 → OrderCreated
offset 101 → OrderPaid
offset 102 → OrderCanceled
offset 103 → OrderCreated
...
```

Consumer가 자신의 offset을 관리하며 읽습니다.

따라서 다음과 같은 환경에 특히 좋습니다.

```
대량 이벤트
로그
통계
CDC
이벤트 기반 MSA
데이터 파이프라인
```

---

## RabbitMQ / SQS

단순한 작업 큐라면 Kafka보다 RabbitMQ나 SQS가 더 자연스러운 경우도 많습니다.

예:

```
Notification API

Email Job
SMS Job
Push Job
```

```
API
 │
 └── Queue
       │
       └── Worker
             │
             └── SMS Provider
```

즉,

```
Kafka
→ Event Stream

RabbitMQ / SQS
→ Task Queue
```

정도로 구분하면 이해하기 쉽습니다.

---

## Redis도 사용할 수 있음

Redis에는 Pub/Sub과 Streams가 있습니다.

### Redis Pub/Sub

```
Publisher
    │
    ▼
Redis
   ├── Consumer A
   └── Consumer B
```

매우 간단하지만 메시지 내구성이 약합니다.

Consumer가 없으면 메시지를 놓칠 수 있습니다.

그래서 중요한 비즈니스 이벤트에는 일반적으로 Redis Pub/Sub만 사용하는 것을 권장하지 않습니다.

### Redis Streams

Kafka와 비슷한 구조를 어느 정도 제공합니다.

```
Producer
   │
   ▼
Redis Stream
   │
   ├── Consumer Group A
   └── Consumer Group B
```

작은 시스템이라면 Kafka를 도입하기 전에 선택할 수도 있습니다.

---

## 내부 통신 설계 기준

가장 실전적인 판단 기준은 다음입니다.

| 상황 | 추천 |
| --- | --- |
| 상대 API의 결과가 지금 필요 | HTTP |
| 내부 API 성능이 매우 중요 | gRPC |
| 처리 결과를 기다릴 필요 없음 | Queue |
| 작업 큐 | RabbitMQ / SQS |
| 대규모 이벤트 스트림 | Kafka |
| 간단한 이벤트 처리 | Redis Streams |
| 실시간 Push | WebSocket / SSE |
| 파일/대용량 데이터 | Object Storage + 이벤트 |

---

## MSA에서는 보통 혼합해서 사용

실제로는 하나만 선택하지 않습니다.

예를 들어:

```
                   ┌──── HTTP ──── Member API
                   │
Reservation API ───┼──── HTTP ──── Facility API
                   │
                   └──── Event ───▶ Kafka
                                      │
                         ┌────────────┼────────────┐
                         ▼            ▼            ▼
                    Notification   Analytics    Logging
```

예약 생성 과정에서 회원 정보와 시설 정보는 "지금 필요"하므로 HTTP입니다.

예약 생성 이후:

```
문자 발송
통계
로그
후처리
```

등은 비동기로 넘길 수 있습니다.

이 구조가 상당히 일반적입니다.

---

## 중요한 설계 원칙

"조회"는 대부분 HTTP/gRPC가 자연스럽습니다.

```
Member 조회
Facility 조회
Tenant 조회
Product 조회
```

반면 어떤 "사건이 발생했다"는 것을 다른 서비스에 전달하는 것은 Event가 자연스럽습니다.

```
MemberCreated
ReservationCreated
PaymentCompleted
PaymentCanceled
ContractExpired
```

즉 아주 단순화하면:

```
Query
→ HTTP / gRPC

Event
→ Kafka / RabbitMQ / SQS
```

그리고 Command는 상황에 따라 나뉩니다.

```
Command
├── 결과 필요 → HTTP / gRPC
└── 결과 불필요 → Queue
```

---

## 전체 요약

API 간 통신 방식을 결정할 때는 다음 기준으로 보면 됩니다.

```
          API 간 통신
              │
   결과를 지금 기다려야 하는가?
        /              \
      YES              NO
       │                │
HTTP / gRPC        Queue / Event
       │                │
   조회/명령        비동기 후처리
                    │
       ┌────────────┼────────────┐
    RabbitMQ       SQS          Kafka
    작업 Queue    관리형 Queue   Event Stream
```

가장 추천하는 기본 원칙은 다음입니다.

"동기 호출은 HTTP/gRPC, 비동기 후처리는 Queue/Event"입니다.

특히 MSA에서 "서비스 A가 서비스 B 데이터를 조회해야 한다" 정도의 상황이라면 굳이 Queue를 사용하지 않고 HTTP가 가장 자연스럽습니다. 반대로 "A에서 일이 발생했으니 B, C, D도 알아서 처리해라"라면 이벤트 방식이 훨씬 자연스럽습니다.