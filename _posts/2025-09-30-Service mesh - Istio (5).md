---
title: "Service mesh - Istio (5)"
date: 2025-09-30T00:00:05
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
    - Mesh
    - Istio
---

# Ingress vs Service Mesh(Istio)의 차이

## 핵심 개념: 경계 vs 내부

### Ingress: 클러스터의 출입구

```
Internet
   ↓
┌──────────────────────────────────────┐
│  Kubernetes Cluster                  │
│                                      │
│  ┌────────────────┐                 │
│  │ Ingress        │ ← 여기가 Ingress │
│  │ (출입구)       │                  │
│  └────────┬───────┘                 │
│           │                          │
│           ↓                          │
│     Service A → Service B            │
│           ↓                          │
│     Service C                        │
│                                      │
└──────────────────────────────────────┘

역할: 외부 → 내부 (진입만 담당)
```

### Service Mesh: 내부의 모든 통신

```
Internet
   ↓
┌──────────────────────────────────────┐
│  Kubernetes Cluster                  │
│                                      │
│  ┌────────────────┐                 │
│  │ Ingress        │                  │
│  └────────┬───────┘                 │
│           │                          │
│  ┌────────▼───────┐                 │
│  │ [Envoy]        │                  │
│  │ Service A      │                  │
│  └────────┬───────┘                 │
│           │ ← 여기부터 Service Mesh │
│  ┌────────▼───────┐                 │
│  │ [Envoy]        │                  │
│  │ Service B      │                  │
│  └────────┬───────┘                 │
│           │                          │
│  ┌────────▼───────┐                 │
│  │ [Envoy]        │                  │
│  │ Service C      │                  │
│  └────────────────┘                 │
│                                      │
└──────────────────────────────────────┘

역할: 내부 ↔ 내부 (모든 서비스 간 통신)
```

## 계층별 역할 분담

```
┌─────────────────────────────────────────────────┐
│ Internet (외부 사용자)                          │
└────────────────┬────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────┐
│ Layer 1: Ingress (진입 제어)                    │
│ - 도메인 라우팅 (api.example.com → Service)    │
│ - TLS 종료                                      │
│ - 외부 → 내부 첫 진입점                        │
└────────────────┬────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────┐
│ Layer 2: Service Mesh (내부 통신 제어)         │
│ - Service A ↔ Service B                        │
│ - Service B ↔ Service C                        │
│ - mTLS, 라우팅, 관찰성                          │
└─────────────────────────────────────────────────┘
```

## Ingress 상세

### 기본 구조

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-service
            port:
              number: 8080
```

### 실제 동작

```
1. 사용자가 api.example.com/users 호출
   
2. DNS가 Ingress Controller의 LoadBalancer IP로 해석
   
3. Ingress Controller (Nginx/Traefik)가 요청 수신
   
4. Host 헤더 확인: api.example.com
   
5. Path 확인: /users
   
6. Ingress 규칙 매칭: user-service:8080으로 전달
   
7. user-service로 요청 전달
   
8. 끝! (내부 통신은 관여 안 함)
```

### Ingress가 하는 일

### 1. 도메인 기반 라우팅

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: domain-routing
spec:
  rules:
  - host: api.example.com      # API 트래픽
    http:
      paths:
      - path: /
        backend:
          service:
            name: api-service
  - host: web.example.com      # 웹 트래픽
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
```

```
api.example.com → api-service
web.example.com → web-service
```

### 2. 경로 기반 라우팅

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api        # /api/* → api-service
        backend:
          service:
            name: api-service
      - path: /admin      # /admin/* → admin-service
        backend:
          service:
            name: admin-service
      - path: /           # /* → frontend-service
        backend:
          service:
            name: frontend-service
```

### 3. TLS 종료

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret  # TLS 인증서
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
```

```
HTTPS (암호화) → Ingress → HTTP (평문) → Service
                  ↑
             TLS 종료 지점
```

### Ingress가 못하는 일

```
❌ Service A → Service B 통신 제어
❌ 내부 트래픽 암호화
❌ 서비스 간 인증/인가
❌ 카나리 배포 (가중치 기반 라우팅)
❌ 재시도, 타임아웃 (제한적)
❌ 서킷 브레이커
❌ 분산 추적
❌ 세밀한 메트릭 수집
```

## Service Mesh(Istio) 상세

### 기본 구조

```
모든 Pod에 사이드카 배치:

┌─────────────────┐
│ Frontend Pod    │
│ ┌──────┐        │
│ │ App  │        │
│ └──┬───┘        │
│    ↓            │
│ ┌──────┐        │     ┌─────────────────┐
│ │Envoy │────────┼─────→│ Backend Pod     │
│ └──────┘        │     │ ┌──────┐        │
└─────────────────┘     │ │Envoy │        │
                        │ └──┬───┘        │
                        │    ↓            │
                        │ ┌──────┐        │
                        │ │ App  │        │
                        │ └──────┘        │
                        └─────────────────┘

모든 통신이 Envoy를 거침
```

### Service Mesh가 하는 일

### 1. 내부 트래픽 제어

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews  # Kubernetes Service 이름
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2    # 특정 사용자는 v2로
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 90      # 90%는 v1
    - destination:
        host: reviews
        subset: v3
      weight: 10      # 10%는 v3
```

```
내부 통신 흐름:
Product Service 
    → (Envoy)
    → VirtualService 규칙 적용
    → 헤더가 jason이면 v2로
    → 아니면 90% v1, 10% v3로
    → (Envoy)
    → Reviews Service
```

### 2. 자동 mTLS

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # 모든 통신 암호화 강제
```

```
Service A → Service B 통신:

Without Istio:
A ─(평문)─→ B
누구나 스니핑 가능

With Istio:
A → [Envoy A] ═══(mTLS)═══ [Envoy B] → B
    자동 암호화              자동 복호화
    
애플리케이션 코드는 변경 없음!
```

### 3. 세밀한 접근 제어

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: database-policy
spec:
  selector:
    matchLabels:
      app: database
  action: ALLOW
  rules:
  - from:
    - source:
        principals: 
        - "cluster.local/ns/default/sa/backend"  # backend만
    to:
    - operation:
        methods: ["GET", "POST"]  # GET, POST만
        paths: ["/api/query"]     # 이 경로만
```

```
실제 동작:
1. Frontend → Database 시도
   → Envoy: "너는 frontend SA야, backend만 허용됨"
   → ❌ 403 Forbidden

2. Backend → Database GET /api/query
   → Envoy: "backend SA, GET 메서드, /api/query 경로"
   → ✅ 허용

3. Backend → Database DELETE /api/data
   → Envoy: "DELETE는 허용 안 됨"
   → ❌ 403 Forbidden
```

### 4. 복원력 (Resilience)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
    timeout: 5s           # 5초 타임아웃
    retries:
      attempts: 3         # 3번 재시도
      perTryTimeout: 2s   # 각 시도당 2초
      retryOn: 5xx        # 5xx 에러 시 재시도
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  trafficPolicy:
    outlierDetection:
      consecutiveErrors: 5      # 5번 연속 실패하면
      interval: 30s
      baseEjectionTime: 30s     # 30초 동안 격리
```

```
장애 시나리오:
1. Reviews → Ratings 호출
2. Ratings 응답 없음 (2초 대기)
3. Envoy: 재시도 1회
4. Ratings 응답 없음 (2초 대기)
5. Envoy: 재시도 2회
6. Ratings 응답 없음 (2초 대기)
7. Envoy: 재시도 3회 실패
8. 5초 전체 타임아웃
9. Reviews에 에러 응답

5번 연속 실패 감지:
→ 해당 Ratings 인스턴스를 30초간 격리
→ 다른 정상 인스턴스로만 라우팅
```

### 5. 관찰성

```
모든 통신을 관찰:

Frontend → Backend 호출 시
Envoy가 자동 기록:
- 요청 시간: 2025-01-15 10:30:45
- 메서드: GET
- 경로: /api/users
- 응답 코드: 200
- 레이턴시: 45ms
- 요청 크기: 120 bytes
- 응답 크기: 2.3 KB
- Trace ID: abc-123-xyz
- Source: frontend.default.svc
- Destination: backend.default.svc

→ Prometheus 메트릭으로 수집
→ Jaeger로 분산 추적
→ Kiali로 시각화
```

## 실제 비교: 같은 기능 구현

### 시나리오: 카나리 배포

### Ingress로 시도 (불가능/제한적)

```yaml
# NGINX Ingress로는 가중치 라우팅이 어려움
# 어노테이션으로 일부 가능하지만 복잡

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app-v2  # 10% 트래픽
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app-v1  # 90% 트래픽
```

문제점:

- 외부 진입 트래픽에만 적용
- 내부 서비스 간 통신은 여전히 직접
- 복잡하고 Ingress Controller 의존적

### Istio로 구현 (완벽)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: app
spec:
  hosts:
  - app
  http:
  - route:
    - destination:
        host: app
        subset: v1
      weight: 90  # 90%
    - destination:
        host: app
        subset: v2
      weight: 10  # 10%
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app
spec:
  host: app
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

장점:

- 외부 + 내부 모든 트래픽에 적용
- 선언적이고 명확함
- 실시간 가중치 조정 가능

## 함께 사용하기 (일반적인 패턴)

### 전체 아키텍처

```
Internet
   ↓
┌──────────────────────────────────────────────────┐
│ [NGINX Ingress Controller]                       │
│ - TLS 종료                                        │
│ - 도메인 라우팅                                   │
│ - Rate Limiting (외부 공격 방어)                  │
└──────────────────┬───────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────┐
│ [Istio Ingress Gateway]                          │
│ - L7 라우팅                                       │
│ - 클러스터 경계 제어                              │
└──────────────────┬───────────────────────────────┘
                   │
     ┌─────────────┼─────────────┐
     ↓             ↓             ↓
┌─────────┐  ┌─────────┐  ┌─────────┐
│[Envoy]  │  │[Envoy]  │  │[Envoy]  │
│Service A│→→│Service B│→→│Service C│
└─────────┘  └─────────┘  └─────────┘
     ↑             ↑             ↑
     └─────────────┴─────────────┘
       Service Mesh (내부 제어)
```

### 역할 분담

```yaml
# 1. NGINX Ingress (외부 진입)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: external-ingress
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"  # Rate limit
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: tls-cert
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: istio-ingressgateway  # Istio Gateway로 전달
            port:
              number: 80
---
# 2. Istio Gateway (클러스터 경계)
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: api-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.example.com"
---
# 3. Istio VirtualService (내부 라우팅)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-routes
spec:
  hosts:
  - "api.example.com"
  gateways:
  - api-gateway
  http:
  - match:
    - uri:
        prefix: "/users"
    route:
    - destination:
        host: user-service
  - match:
    - uri:
        prefix: "/orders"
    route:
    - destination:
        host: order-service
        subset: v1
      weight: 90
    - destination:
        host: order-service
        subset: v2
      weight: 10  # 내부 카나리 배포
```

## 구체적 시나리오: 마이크로서비스 아키텍처

### Ingress만 사용

```
Internet
   ↓
[Ingress]
   ↓
Frontend ─(직접)─→ Product ─(직접)─→ Reviews
                              ↓
                          Ratings

문제점:
1. Frontend → Product 통신 제어 불가
2. Product → Reviews 카나리 배포 불가
3. 내부 통신 암호화 안 됨
4. Reviews 장애 시 재시도 로직을 코드로 구현
5. Product → Reviews 메트릭 수집 어려움
```

### Ingress + Istio 사용

```
Internet
   ↓
[Ingress]
   ↓
[Istio Gateway]
   ↓
[Envoy] Frontend → [Envoy] Product → [Envoy] Reviews v1 (90%)
                                   → [Envoy] Reviews v2 (10%)
                                   → [Envoy] Ratings

해결됨:
1. ✅ 모든 통신 제어 가능
2. ✅ 내부 카나리 배포
3. ✅ 자동 mTLS
4. ✅ 자동 재시도
5. ✅ 전체 경로 추적
```

## 선택 기준

### Ingress만으로 충분한 경우

```
- 단순한 애플리케이션 (5개 미만 서비스)
- 외부 진입 제어만 필요
- 내부 통신이 단순
- 리소스가 제한적
- 학습 비용을 최소화하고 싶을 때
```

### Service Mesh가 필요한 경우

```
- 복잡한 마이크로서비스 (10개 이상)
- 서비스 간 통신이 복잡
- 카나리 배포, A/B 테스트 필요
- 강력한 보안 요구사항 (mTLS, 인가)
- 상세한 관찰성 필요
- 분산 추적 필요
- 복원력 패턴 (재시도, 서킷 브레이커) 필요
```

### 둘 다 사용하는 경우 (가장 일반적)

```
- 엔터프라이즈 애플리케이션
- 프로덕션 환경
- 외부 진입 + 내부 제어 모두 필요
- 계층별 책임 분리
```

## 리소스 비교

### Ingress만

```
NGINX Ingress Controller: 3 레플리카
- CPU: 0.5 core * 3 = 1.5 cores
- Memory: 200MB * 3 = 600MB

총: 1.5 cores, 600MB
```

### Istio 추가

```
Ingress: 600MB
Istio Control Plane (Istiod): 2GB, 1 core
Istio Ingress Gateway: 500MB, 0.5 core
Sidecar (50개 Pod 가정): 5GB, 5 cores

총: 8.1GB, 7 cores

약 13배 증가
하지만 그만큼 기능도 훨씬 많음
```

---

# 그것은 즉

- ingress는 쿠버네티스 클러스터 전체에 대한 리버스 프록시 엔진엑스
- istio는 각각의 서비스 팟에 대한 리버스 프록시 엔진엑스

### Ingress = 클러스터 전체의 단일 리버스 프록시

```
                    ┌─────────────┐
외부 트래픽  ─────→ │   Ingress   │ ← 클러스터 전체에 하나 (또는 몇 개)
                    │   (Nginx)   │    중앙 집중식 리버스 프록시
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            ↓              ↓              ↓
       Service A      Service B      Service C
       
하나의 Nginx가 전체 클러스터 진입점 담당
```

### Istio = 각 Pod마다 전용 리버스 프록시

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Pod A       │    │  Pod B       │    │  Pod C       │
│  ┌────────┐  │    │  ┌────────┐  │    │  ┌────────┐  │
│  │App     │  │    │  │App     │  │    │  │App     │  │
│  └───┬────┘  │    │  └───▲────┘  │    │  └───▲────┘  │
│      │       │    │      │       │    │      │       │
│  ┌───▼────┐  │    │  ┌───┴────┐  │    │  ┌───┴────┐  │
│  │Envoy   │──┼────┼─→│Envoy   │──┼────┼─→│Envoy   │  │
│  │(Nginx  │  │    │  │(Nginx  │  │    │  │(Nginx  │  │
│  │ 같은)  │  │    │  │ 같은)  │  │    │  │ 같은)  │  │
│  └────────┘  │    │  └────────┘  │    │  └────────┘  │
└──────────────┘    └──────────────┘    └──────────────┘

각 Pod마다 전용 Nginx(Envoy) 프록시가 붙음
```

## 시각적 비교

### 전통적인 아키텍처 (Nginx만)

```
┌────────────────────────────────────────┐
│  외부                                  │
└────────┬───────────────────────────────┘
         │
    ┌────▼─────┐
    │  Nginx   │ ← 하나의 중앙 프록시
    │ (Ingress)│
    └────┬─────┘
         │
    ┌────┼────┐
    ↓    ↓    ↓
  ┌───┐┌───┐┌───┐
  │A  ││B  ││C  │ ← 서비스들 (프록시 없음)
  └───┘└───┘└───┘
    │    │    │
    └────┼────┘
         ↓
      (직접 통신)
```

역할:

- Nginx: 외부 → 내부 진입만
- 서비스 간 통신: 직접 (제어 불가)

### Istio 아키텍처

```
┌────────────────────────────────────────┐
│  외부                                  │
└────────┬───────────────────────────────┘
         │
    ┌────▼─────┐
    │  Nginx   │ ← 여전히 진입점
    │ (Ingress)│
    └────┬─────┘
         │
    ┌────┼────┐
    ↓    ↓    ↓
  ┌───┐┌───┐┌───┐
  │[P]││[P]││[P]│ ← 각 서비스마다 프록시 추가
  │ A ││ B ││ C │
  └─┬─┘└─▲─┘└─▲─┘
    │    │    │
    └────┼────┘
         ↑
  [P] = Envoy 프록시
  (모든 통신이 프록시 경유)
```

역할:

- Ingress Nginx: 외부 → 내부 진입
- Envoy (각 Pod): 모든 내부 통신 제어

## 완전한 비교표

```
┌─────────────────────────────────────────────────────────┐
│ Ingress (Nginx)                                         │
├─────────────────────────────────────────────────────────┤
│ 배치: 클러스터당 1개 (또는 HA를 위해 2-3개)             │
│ 위치: 클러스터 경계 (진입점)                            │
│ 역할: 외부 → 내부                                       │
│ 비유: 건물의 정문 경비                                  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Istio (Envoy)                                           │
├─────────────────────────────────────────────────────────┤
│ 배치: Pod마다 1개 (100개 Pod = 100개 프록시)            │
│ 위치: 각 서비스 옆 (사이드카)                           │
│ 역할: 내부 ↔ 내부 (모든 통신)                          │
│ 비유: 각 방마다 배치된 개인 비서                        │
└─────────────────────────────────────────────────────────┘
```

## 전체 요약

Ingress는 **클러스터의 출입구** 역할로 외부에서 내부로 들어오는 트래픽만 제어한다(도메인/경로 라우팅, TLS 종료). Service Mesh(Istio)는 **클러스터 내부의 모든 서비스 간 통신**을 제어한다(트래픽 제어, mTLS, 접근 제어, 복원력, 관찰성). Ingress는 첫 진입점에서 한 번만 작동하고, Istio는 모든 Pod마다 사이드카를 배치하여 모든 통신을 가로챈다. 실제로는 Ingress(외부 진입) + Istio(내부 메쉬)를 함께 사용하는 것이 일반적이다. Ingress는 가볍고 단순하지만 기능이 제한적이고, Istio는 강력하지만 복잡하고 리소스를 많이 사용한다. 서비스가 10개 미만이면 Ingress만으로 충분하고, 복잡한 마이크로서비스 환경에서는 둘 다 필요하다.

Ingress(Nginx)는 **클러스터 전체의 단일 리버스 프록시**로 외부 진입점을 담당하고, Istio(Envoy)는 **각 Pod마다 붙는 전용 리버스 프록시**로 모든 내부 통신을 제어한다. Ingress는 중앙 집중식으로 1개(또는 HA를 위해 2-3개)만 배치되어 외부→내부 진입만 처리하고, Istio는 분산 방식으로 100개 Pod면 100개 프록시가 배치되어 모든 서비스 간 통신을 가로챈다. Ingress는 고정 비용(약 600MB)이지만 기능이 제한적이고, Istio는 변동 비용(Pod당 100MB)이지만 mTLS, 재시도, 서킷 브레이커, 분산 추적 등 강력한 기능을 제공한다. 작은 프로젝트는 Ingress만으로 충분하고, 복잡한 마이크로서비스는 둘 다 필요하다. 완벽한 비유: Ingress는 건물의 정문 경비, Istio는 각 방마다 배치된 개인 비서다.