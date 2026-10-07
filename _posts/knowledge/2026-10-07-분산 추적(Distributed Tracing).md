---
title: "분산 추적(Distributed Tracing)"
date: 2026-10-07T00:00:00
toc: true
categories: ["DevOps"]
tags: ["Trace"]
---

## 개요

"분산 추적"은 MSA처럼 하나의 사용자 요청이 여러 서비스와 인프라를 거쳐 처리될 때, 그 요청의 전체 흐름을 하나의 연결된 기록으로 추적하는 관측성(Observability) 기술입니다.

예를 들어 다음과 같은 구조가 있다고 보겠습니다.

```
사용자
  ↓
Front
  ↓
API Gateway
  ↓
Order Service
  ↓
Redis
  ↓
Payment Service
  ↓
DB
```

일반 로그만 보면 각각의 서비스에 로그가 따로 남기 때문에 "이 로그들이 같은 사용자 요청에서 발생한 것인지" 연결하기 어렵습니다.

분산 추적은 요청에 "Trace ID"를 부여하고 각 서비스가 이를 전달함으로써 전체 요청을 하나로 연결합니다.

---

## 핵심 개념

### Trace

"Trace"는 하나의 요청이 시작해서 끝날 때까지의 전체 흐름입니다.

```
Trace
 ├─ API Gateway
 ├─ Order Service
 │   ├─ Redis
 │   └─ DB
 └─ Payment Service
     └─ DB
```

예를 들어

```
POST /orders
```

라는 하나의 요청이 여러 서비스를 거쳤다면 이 전체 과정이 하나의 Trace입니다.

Trace에는 일반적으로 고유한 "Trace ID"가 존재합니다.

```
Trace ID: a3f217...
```

---

### Span

"Span"은 Trace 내부의 하나의 작업 단위입니다.

```
Trace
│
├─ Span: API Gateway
│
├─ Span: Order Service
│
├─ Span: Redis 조회
│
├─ Span: Payment Service 호출
│
└─ Span: MySQL Query
```

각 Span에는 보통 다음과 같은 정보가 있습니다.

```
Span
- 시작 시간
- 종료 시간
- 실행 시간
- 서비스명
- HTTP Method
- URL
- HTTP Status
- DB Query
- Exception
- Parent Span
```

따라서 어느 구간에서 시간이 오래 걸렸는지를 확인할 수 있습니다.

---

## Trace와 Span의 관계

예를 들어 다음 요청이 있다고 가정합니다.

```
사용자
 ↓
API Gateway
 ↓
Order Service
 ↓
Payment Service
 ↓
DB
```

분산 추적 데이터는 다음처럼 구성됩니다.

```
Trace ID: abc123

Span A
API Gateway
100ms
│
└── Span B
    Order Service
    80ms
    │
    └── Span C
        Payment Service
        50ms
        │
        └── Span D
            MySQL
            30ms
```

모든 Span은 동일한 "Trace ID"를 공유합니다.

Span끼리는 Parent/Child 관계를 가집니다.

```
Trace ID
   │
   ├── Span ID
   │
   └── Parent Span ID
```

---

## Trace ID 전파

분산 추적에서 가장 중요한 부분 중 하나가 "Context Propagation"입니다.

서비스 간 요청이 이동할 때 Trace 정보를 같이 전달합니다.

예를 들어 HTTP 요청이라면 헤더에 포함됩니다.

```
API Gateway
   │
   │ Trace Context
   ▼
Order Service
   │
   │ Trace Context
   ▼
Payment Service
```

현재 가장 일반적인 표준은 W3C Trace Context입니다.

대표적인 헤더가 다음과 같습니다.

```
traceparent
```

형태는 대략 다음과 같습니다.

```
traceparent:
00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

여기에는

```
Trace ID
Span ID
Trace Flags
```

등의 정보가 포함됩니다.

---

## 로그와 분산 추적의 관계

분산 추적은 로그를 대체하는 기술이 아닙니다.

보통

```
Metrics
Logs
Traces
```

세 가지를 같이 사용합니다.

이를 Observability의 주요 요소라고 합니다.

### Metrics

시스템 전체 상태를 숫자로 봅니다.

```
CPU 80%
Memory 70%
RPS 300
Error Rate 2%
Response Time p95 1.2s
```

Prometheus 등이 대표적입니다.

### Logs

구체적으로 무슨 일이 발생했는지 확인합니다.

```
ERROR Payment failed
userId=100
orderId=500
```

Loki, Elasticsearch 등이 대표적입니다.

### Traces

어디에서 문제가 발생했는지를 확인합니다.

```
Gateway        20ms
   ↓
Order Service  50ms
   ↓
Payment       900ms  ← 문제
   ↓
DB             30ms
```

즉,

```
Metrics
→ 문제가 있다

Trace
→ 어디가 문제인지 찾는다

Logs
→ 왜 문제가 발생했는지 확인한다
```

라는 식으로 함께 사용하는 경우가 많습니다.

---

## MSA에서 분산 추적이 중요한 이유

Monolithic Application에서는 요청이 하나의 애플리케이션 안에서 처리되는 경우가 많습니다.

```
Application
 ├─ Controller
 ├─ Service
 ├─ Repository
 └─ DB
```

따라서 로그 추적이 상대적으로 쉽습니다.

반면 MSA에서는 다음처럼 됩니다.

```
Gateway
 ↓
User Service
 ↓
Order Service
 ↓
Payment Service
 ↓
Notification Service
```

각각 다른 Pod일 수도 있습니다.

```
gateway-pod-2

user-pod-1

order-pod-3

payment-pod-2

notification-pod-4
```

Kubernetes에서는 Pod가 재생성되기도 하므로 로그만으로 요청을 연결하기가 더욱 어렵습니다.

그래서 Trace ID를 기반으로 요청을 연결하는 것이 중요합니다.

---

## 실제 분산 추적 화면

분산 추적 도구에서는 흔히 "Waterfall" 형태로 표시합니다.

```
API Gateway      █████████████████████████████  1.2s

Order Service      ███████████████████████████  1.1s

Redis                ██                          30ms

Payment Service        ██████████████████████   900ms

MySQL                    ███████████████████    800ms
```

이 화면만 보면

```
전체 요청: 1.2초
Payment Service: 900ms
DB Query: 800ms
```

이므로 DB 구간이 병목이라는 것을 빠르게 찾을 수 있습니다.

---

## 대표적인 분산 추적 기술

현재 분산 추적을 구성할 때 중심이 되는 표준은 "OpenTelemetry"입니다.

구조를 단순화하면 다음과 같습니다.

```
Application
(Spring Boot / NestJS / Next.js)
        │
        │ Trace / Metric / Log
        ▼
OpenTelemetry
        │
        ▼
OpenTelemetry Collector
        │
        ├── Jaeger
        ├── Grafana Tempo
        ├── Zipkin
        └── 기타 Observability Backend
```

### OpenTelemetry

OpenTelemetry는 Observability 데이터를 생성하고 전송하기 위한 표준입니다.

보통 줄여서 "OTel"이라고 합니다.

지원하는 데이터는 크게

```
Trace
Metric
Log
```

입니다.

특히 분산 추적에서는 사실상 표준적인 선택지입니다.

---

## Jaeger와 Grafana Tempo

Trace를 저장하고 조회하는 Backend로 많이 사용하는 것이 다음과 같습니다.

### Jaeger

분산 추적에 특화된 대표적인 오픈소스 도구입니다.

```
Application
 ↓
OpenTelemetry
 ↓
Jaeger
```

Trace 검색과 요청 흐름 분석에 사용합니다.

### Grafana Tempo

Grafana 생태계를 사용하는 환경이라면 많이 사용합니다.

```
Prometheus → Metrics
Loki       → Logs
Tempo      → Traces
Grafana    → Visualization
```

이렇게 구성하면 Grafana 하나에서

```
Metric
 ↓
Trace
 ↓
Log
```

를 서로 연결해서 볼 수 있다는 장점이 있습니다.

---

## Kubernetes 환경 구성

Kubernetes에서는 흔히 다음처럼 구성합니다.

```
                    Kubernetes

API Gateway        ─┐
User Service       ─┤
Order Service      ─┤
Payment Service    ─┤── OTLP ──→ OpenTelemetry Collector
Notification Svc  ─┘                    │
                                       ▼
                                   Grafana Tempo
                                       │
                                       ▼
                                    Grafana
```

애플리케이션이 각각 Observability Backend로 직접 전송하게 만들기보다는 중간에 "OpenTelemetry Collector"를 두는 구조가 일반적입니다.

---

## 일반적인 MSA 구조에 적용한다면

예를 들어 다음 구조를 기준으로 볼 수 있습니다.

```
User
 ↓
Next.js
 ↓
API Gateway
 ↓
User Service
Order Service
Payment Service
Notification Service
 ↓
Redis / MySQL
```

여기에 OpenTelemetry를 적용하면 다음과 같은 요청을 하나의 Trace로 볼 수 있습니다.

```
Trace ID: ABC

API Gateway
 └─ Order Service
     ├─ Redis
     ├─ MySQL
     └─ Payment Service
         ├─ MySQL
         └─ External Payment API
```

특히 API Gateway에서 Trace가 시작되도록 구성하면 MSA 전체 요청 흐름을 보기 편합니다.

Spring Boot에서는 OpenTelemetry 또는 Micrometer Tracing을 이용할 수 있고, NestJS 역시 OpenTelemetry SDK를 사용할 수 있습니다.

---

## 로그에도 Trace ID 넣기

실무에서는 Trace만 보는 것보다 로그에 Trace ID를 같이 넣는 것이 매우 유용합니다.

예를 들어

```
2026-09-17 12:30:01
traceId=abc123
service=order-service
orderId=100
Order created
```

다른 서비스에서도

```
traceId=abc123
service=payment-service
Payment requested
```

처럼 남습니다.

그러면 Loki나 Elasticsearch에서

```
traceId=abc123
```

을 검색해 해당 요청과 관련된 모든 로그를 찾을 수 있습니다.

전체 흐름은 다음과 연결됩니다.

```
Grafana Metrics
      │
      ▼
Tempo Trace
      │
      │ Trace ID
      ▼
Loki Logs
```

이 구조가 Observability를 구축할 때 상당히 중요한 패턴입니다.

---

## 전체 요약

분산 추적은 "MSA 환경에서 하나의 요청이 여러 서비스와 인프라를 거치는 전체 과정을 Trace ID로 연결하여 추적하는 기술"입니다.

핵심 구조는 다음과 같습니다.

```
Trace
 └─ 하나의 전체 요청

Span
 └─ 요청 안의 개별 작업

Trace ID
 └─ 전체 Span을 하나의 요청으로 연결

Span ID
 └─ 개별 작업 식별

Context Propagation
 └─ 서비스 간 Trace ID 전달
```

그리고 Kubernetes + MSA 환경에서는 다음 구성이 많이 사용됩니다.

```
Spring Boot / NestJS
        │
        ▼
OpenTelemetry
        │
        ▼
OpenTelemetry Collector
        │
        ├── Prometheus → Metrics
        ├── Loki       → Logs
        └── Tempo      → Traces
                         │
                         ▼
                       Grafana
```

즉 첫 번째 답변의 구조와 설명은 그대로 두고, 전직장 관련 `im-*` 예시만 모두 일반적인 `User / Order / Payment / Notification Service` 예시로 바꿨습니다.