---
title: "분산 추적 (Distributed Tracing)"
date: 2026-08-08T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Monitoring
---

# 분산 추적 (Distributed Tracing)

## 개요

분산 추적은 마이크로서비스나 분산 시스템에서 단일 요청이 여러 서비스를 거쳐 처리되는 전 과정을 시각적으로 추적하는 관찰 가능성(Observability) 기법입니다.

모놀리식 아키텍처에서는 하나의 프로세스 내에서 요청이 처리되므로 로그 하나로 흐름을 파악할 수 있었습니다. 그러나 마이크로서비스 환경에서는 요청 하나가 수십 개의 서비스를 경유하고, 각 서비스는 독립된 프로세스·컨테이너·노드에서 실행되므로 전용 메커니즘이 필요합니다.

---

## 핵심 개념

### Trace와 Span

#### Trace

하나의 요청이 시스템 전체를 통과하는 전체 여정입니다. 고유 식별자인 Trace ID로 구분되며, 여러 Span의 집합으로 구성됩니다.

#### Span

Trace 안에서 하나의 단위 작업을 의미합니다. DB 쿼리, HTTP 호출, 함수 실행 등 각각이 하나의 Span입니다.

| 속성 | 설명 |
| --- | --- |
| Span ID | Span 고유 식별자 |
| Trace ID | 소속된 Trace 식별자 |
| Parent Span ID | 부모 Span (없으면 Root Span) |
| Operation name | 작업 이름 |
| Start / End time | 시작·종료 시각 |
| Status | 성공 / 에러 |
| Tags / Attributes | key-value 메타데이터 |
| Events (Logs) | Span 내 특정 시점 이벤트 |

#### 계층 구조

Span들은 부모-자식 관계를 형성하며 트리 구조를 이룹니다. 시각화되면 Gantt 차트와 유사한 형태가 되며, 이를 Flame Graph 또는 Waterfall View라 부릅니다.

```
[Root Span: POST /orders          0ms ~ 320ms]
  ├─ [Span: validate user         0ms ~ 20ms ]
  ├─ [Span: create order         20ms ~ 150ms]
  │    └─ [Span: DB INSERT       30ms ~ 120ms]
  └─ [Span: charge payment      150ms ~ 300ms]
       └─ [Span: HTTP /charge   155ms ~ 295ms]
```

### Context Propagation (컨텍스트 전파)

Trace ID와 Span ID를 서비스 간 호출 시 함께 전달해야만 전체 흐름을 하나의 Trace로 연결할 수 있습니다.

#### W3C TraceContext 헤더 (표준)

```
traceparent: 00-{trace-id}-{span-id}-{flags}
tracestate:  vendor-specific data
```

gRPC나 메시지 큐(Kafka, RabbitMQ)에서도 동일하게 메타데이터나 헤더에 context를 심어 전파합니다.

### Sampling (샘플링)

| 전략 | 설명 | 특징 |
| --- | --- | --- |
| Head-based Sampling | 요청 시작 시 추적 여부 결정 | 단순, 에러 Trace를 놓칠 수 있음 |
| Tail-based Sampling | 요청 완료 후 결과를 보고 결정 | 에러·지연 Trace 보존 가능, 복잡 |
| Always-on | 100% 수집 | 개발/QA 환경 적합 |
| Rate-based | 초당 N건 고정 수집 | 예측 가능한 볼륨 |

프로덕션에서는 Head-based로 1~10% 샘플링하되, 에러 케이스는 Tail-based로 100% 보존하는 혼합 전략을 권장합니다.

---

## 주요 표준과 도구

### OpenTelemetry (OTel)

현재 업계 표준 관찰 가능성 프레임워크입니다. CNCF 프로젝트로, OpenTracing과 OpenCensus가 통합되어 탄생했습니다.

- SDK: 애플리케이션 코드에 계측(instrumentation) 삽입
- Collector: 텔레메트리 데이터를 수집·변환·내보내는 에이전트/게이트웨이
- OTLP (OpenTelemetry Protocol): 데이터 전송 표준 프로토콜

OTel 자체는 수집과 전송만 담당하며, 저장과 시각화는 백엔드 툴이 담당합니다.

#### Collector 아키텍처

```
[App + OTel SDK]
     ↓ OTLP
[OTel Collector]
  ├─ Receiver (OTLP, Jaeger, Zipkin...)
  ├─ Processor (batch, filter, sample...)
  └─ Exporter → Jaeger / Tempo / OTLP
```

### 백엔드 도구 비교

| 도구 | 특징 | 저장소 | 오픈소스 |
| --- | --- | --- | --- |
| Jaeger | CNCF 표준, 경량 | Cassandra / ES / Memory | ✅ |
| Zipkin | Twitter 출신, 역사 오래됨 | MySQL / ES / Cassandra | ✅ |
| Tempo (Grafana) | 오브젝트 스토리지 기반, 저비용 | S3 / GCS / Azure Blob | ✅ |
| Datadog APM | 통합 관찰 가능성 플랫폼 | SaaS | ❌ |

Kubernetes 환경에서는 Grafana Stack (Loki + Tempo + Prometheus + Grafana)이 통합 관찰 가능성을 구성하는 가장 일반적인 조합입니다.

---

## Kubernetes / Istio 환경에서의 분산 추적

### Istio와의 관계

Istio 서비스 메시를 사용하면 애플리케이션 코드 수정 없이 Envoy 사이드카 프록시 레벨에서 자동으로 Span을 생성하고 traceparent 헤더를 삽입합니다.

단, 서비스 내부에서 헤더를 수동으로 전달(forward)해야 두 Span이 연결됩니다. 애플리케이션이 `traceparent` 헤더를 다음 서비스 호출에 포함시키지 않으면 Trace가 끊깁니다.

```python
# FastAPI 예시: 수신한 traceparent를 다음 서비스 호출에 전달
@app.post("/order")
async def create_order(request: Request):
    headers = {
        "traceparent": request.headers.get("traceparent", ""),
        "tracestate": request.headers.get("tracestate", ""),
    }
    async with httpx.AsyncClient() as client:
        await client.post("http://payment-svc/charge", headers=headers)
```

### OTel Collector 배포 (Kubernetes)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      tail_sampling:
        decision_wait: 10s
        policies:
          - name: error-policy
            type: status_code
            status_code: { status_codes: [ERROR] }
          - name: slow-policy
            type: latency
            latency: { threshold_ms: 500 }
          - name: probabilistic
            type: probabilistic
            probabilistic: { sampling_percentage: 10 }

    exporters:
      otlp/jaeger:
        endpoint: jaeger-collector:4317
        tls:
          insecure: true

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch, tail_sampling]
          exporters: [otlp/jaeger]
```

### OTel Java Agent 주입 (Kubernetes Deployment)

```yaml
spec:
  containers:
  - name: order-service
    env:
    - name: JAVA_TOOL_OPTIONS
      value: "-javaagent:/otel/opentelemetry-javaagent.jar"
    - name: OTEL_EXPORTER_OTLP_ENDPOINT
      value: "http://otel-collector:4317"
    - name: OTEL_SERVICE_NAME
      value: "order-service"
    - name: OTEL_TRACES_SAMPLER
      value: "parentbased_traceidratio"
    - name: OTEL_TRACES_SAMPLER_ARG
      value: "0.1"
```

---

## 요약

분산 추적은 마이크로서비스 환경에서 요청의 전체 생애주기를 Trace와 Span이라는 단위로 표현하고, 서비스 간 Context Propagation으로 연결해 시각화하는 관찰 가능성 기법입니다.

현재 업계 표준은 OpenTelemetry이며, SDK로 계측 → Collector로 수집 및 변환 → Jaeger / Grafana Tempo 등 백엔드로 저장의 흐름을 따릅니다. Kubernetes 환경에서는 Istio 사이드카로 상당 부분 자동화되지만, 서비스 내 헤더 전달(header forwarding) 구현이 필수입니다. 샘플링 전략을 적절히 설계하지 않으면 프로덕션 오버헤드가 발생할 수 있으므로, Tail-based Sampling으로 에러·지연 Trace를 선별 보존하는 방식이 권장됩니다.

---

# Service Mesh (Istio)와 분산 추적

## Service Mesh란

Service Mesh는 마이크로서비스 간의 통신을 애플리케이션 코드 밖에서 제어하는 인프라 레이어입니다. 각 서비스 인스턴스 옆에 "사이드카(Sidecar) 프록시"를 배치해서, 서비스 간 모든 트래픽이 이 프록시를 거치도록 만듭니다.

핵심 아이디어는 "인프라가 알아서 처리한다"입니다. 개발자는 분산 추적 코드를 직접 작성하지 않아도, 사이드카 프록시가 자동으로 Span을 생성하고 Trace Header를 전파합니다.

## Istio 아키텍처

```
Control Plane
├── istiod
│   ├── Pilot      : 서비스 디스커버리, 트래픽 규칙 배포
│   ├── Citadel    : mTLS 인증서 관리
│   └── Galley     : 설정 검증

Data Plane
└── Envoy Sidecar (각 Pod 옆에 자동 주입)
    ├── 인바운드 트래픽 가로채기
    ├── 아웃바운드 트래픽 가로채기
    ├── Span 자동 생성
    └── Trace Header 자동 전파
```

Pod 안에서의 구조:

```
[Pod]
 ├── App Container (Spring Boot)
 └── Envoy Proxy (istio-proxy)
      ├── 포트 15001 : 아웃바운드 인터셉트
      └── 포트 15006 : 인바운드 인터셉트
```

---

## Istio의 자동 분산 추적 원리

### Envoy가 하는 일

Envoy 프록시는 모든 HTTP 요청에 대해 자동으로 아래 작업을 수행합니다.

```
요청 인입 시:
1. Trace Header 존재 확인
2. 없으면 → 새 Trace ID, Span ID 생성
3. 있으면 → 기존 Trace ID 유지, 새 Span ID 생성

요청 아웃바운드 시:
1. 기존 Trace Header에 현재 Span ID를 Parent로 설정
2. 다음 서비스로 Header 전달
3. 완료 후 Jaeger/Zipkin으로 Span 리포트
```

### 전파되는 Header

Istio(Envoy)는 아래 Header들을 자동으로 처리합니다.

```
x-request-id
x-b3-traceid
x-b3-spanid
x-b3-parentspanid
x-b3-sampled
x-b3-flags
b3  (단일 헤더 형식)
traceparent  (W3C TraceContext)
```

---

## 중요한 제약사항 - 앱 코드의 역할

### Header 포워딩 문제

Istio의 자동 추적에는 중요한 한계가 있습니다. Envoy는 인바운드와 아웃바운드 요청을 "각각 독립적으로" 인터셉트합니다. 두 요청을 "같은 Trace"로 묶으려면, 애플리케이션이 인바운드에서 받은 Trace Header를 아웃바운드 요청에 그대로 넘겨줘야 합니다.

```
[Service A] → (Trace Header 포함) → [Envoy A] → [Service B] → [Envoy B]

Envoy A가 생성한 Span과 Envoy B가 생성한 Span이
같은 Trace로 연결되려면:

Service B의 앱 코드가
인바운드 Header를 읽어서
아웃바운드 요청에 그대로 포워딩해야 함
```

### Spring Boot에서 Header 포워딩 구현

```kotlin
// 방법 1: Micrometer Tracing 사용 (자동 처리)
// 의존성만 추가하면 RestTemplate, WebClient가 자동으로 Header 포워딩

// 방법 2: 수동 포워딩 (Micrometer 없이 순수 Istio만 쓸 때)
@Component
class TraceHeaderForwardingInterceptor : ClientHttpRequestInterceptor {

    companion object {
        val TRACE_HEADERS = listOf(
            "x-request-id",
            "x-b3-traceid",
            "x-b3-spanid",
            "x-b3-parentspanid",
            "x-b3-sampled",
            "x-b3-flags",
            "traceparent",
            "tracestate"
        )
    }

    override fun intercept(
        request: HttpRequest,
        body: ByteArray,
        execution: ClientHttpRequestExecution
    ): ClientHttpResponse {
        val currentRequest = RequestContextHolder.getRequestAttributes()
            as? ServletRequestAttributes

        currentRequest?.request?.let { inbound ->
            TRACE_HEADERS.forEach { header ->
                inbound.getHeader(header)?.let { value ->
                    request.headers.set(header, value)
                }
            }
        }

        return execution.execute(request, body)
    }
}

@Configuration
class RestTemplateConfig {
    @Bean
    fun restTemplate(interceptor: TraceHeaderForwardingInterceptor): RestTemplate {
        return RestTemplate().apply {
            interceptors.add(interceptor)
        }
    }
}
```

---

## Istio + Jaeger 설정

### Istio 설치 및 Jaeger 연동

```bash
# Istio 설치 (demo 프로필 - Jaeger 포함)
istioctl install --set profile=demo

# addons으로 개별 설치
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

# Jaeger UI 접근
istioctl dashboard jaeger
```

### Istio MeshConfig로 추적 설정

```yaml
# istio-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10.0  # 10% 샘플링
        zipkin:
          address: jaeger-collector.istio-system:9411
```

### Namespace에 사이드카 자동 주입 활성화

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled  # 이 레이블 하나로 Pod 생성 시 자동 주입
```

### Spring Boot Deployment 예시

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: production
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
        proxy.istio.io/config: |
          tracing:
            sampling: 100.0  # 이 서비스만 100% 샘플링
    spec:
      containers:
        - name: order-service
          image: order-service:latest
          env:
            - name: SPRING_APPLICATION_NAME
              value: order-service
```

---

## Istio + Spring Boot Micrometer 함께 사용

### 두 레이어의 역할 분리

```
[Istio/Envoy 레이어]
 - 서비스 간 HTTP 통신 Span 자동 생성
 - 인프라 레벨 메타데이터 (응답코드, 지연시간, 바이트)
 - 별도 코드 불필요

[Micrometer Tracing 레이어]
 - 메서드/비즈니스 로직 레벨 Span 생성
 - DB 쿼리, 외부 API 호출 등 세부 추적
 - @Observed, Observation API 활용
```

두 레이어가 "같은 Trace ID"를 공유해야 Jaeger에서 하나의 완전한 Trace로 볼 수 있습니다.

### Trace ID 공유 동작 방식

```
1. 외부 요청 → Envoy(Sidecar) → Trace ID 생성, Header에 삽입
2. Envoy → App Container(Spring Boot) → Header 포함 요청 전달
3. Micrometer Tracing → Header에서 Trace ID 추출, Context로 설정
4. @Observed 메서드 → 같은 Trace ID의 Child Span으로 기록
5. 결과: Jaeger에서 Envoy Span + App Span이 하나의 Trace로 표시
```

---

## Kiali - Istio 전용 시각화

Jaeger가 "Trace 상세"를 보여준다면, Kiali는 "서비스 토폴로지"를 실시간으로 시각화합니다.

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
istioctl dashboard kiali
```

Kiali에서 확인 가능한 정보:

- 서비스 간 의존 관계 그래프
- 실시간 트래픽 흐름
- 오류율, 응답시간 per 서비스
- Jaeger Trace와 연동한 요청 드릴다운

---

## 요약

| 구분 | Istio/Envoy | Micrometer Tracing |
| --- | --- | --- |
| 추적 단위 | 서비스 간 네트워크 홉 | 메서드/비즈니스 로직 |
| 코드 필요 여부 | Header 포워딩만 필요 | @Observed, Observation API |
| 적합한 정보 | 응답코드, 레이턴시, 바이트 | DB쿼리, 비즈니스 이벤트 |
| 함께 사용 시 | 동일 Trace ID로 자동 연결 | 더 풍부한 Trace 완성 |

Istio의 핵심 가치는 "코드 변경 없이 인프라 수준의 가시성"을 얻는 것이고, Micrometer Tracing과 조합하면 인프라부터 비즈니스 로직까지 완전한 추적이 가능합니다. 단, "Header 포워딩"은 앱 코드의 책임임을 반드시 기억해야 합니다.