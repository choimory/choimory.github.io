---
title: "Service mesh - Istio (4)"
date: 2025-09-30T00:00:04
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
    - Mesh
    - Istio
---

# Istio는 k8s yaml로 명세해서 각각의 서비스 팟에 붙여주는 개념인가?

YAML에 일일이 명시하지 않는다. Istio의 가장 큰 장점 중 하나가 바로 **기존 애플리케이션 YAML을 전혀 수정하지 않고도** 사이드카를 자동으로 추가할 수 있다는 점이다.

# Istio 사이드카 주입 방식의 이해

### 작동 방식

- 네임스페이스에 단 하나의 레이블만 추가하면 된다
- 그 네임스페이스에서 생성되는 모든 Pod에 자동으로 사이드카가 주입된다
- Kubernetes의 Admission Controller(Mutating Webhook)가 Pod 생성 요청을 가로채서 사이드카 컨테이너를 추가한다
- 개발자는 원래 작성하던 Deployment YAML을 그대로 사용한다

## 실제 사용 예시

### 1단계: 네임스페이스에 레이블 추가

```bash
# 이 명령 하나로 끝
kubectl label namespace default istio-injection=enabled
```

이게 전부다. 이제 `default` 네임스페이스에서 생성되는 모든 Pod에 자동으로 Envoy 사이드카가 추가된다.

### 2단계: 기존 Deployment 그대로 사용

```yaml
# 개발자가 작성하는 YAML - Istio 관련 내용 전혀 없음
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default  # istio-injection=enabled된 네임스페이스
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:v1
        ports:
        - containerPort: 8080
```

이 YAML을 배포하면 자동으로 다음과 같이 변환된다.

### 3단계: 실제 생성되는 Pod (자동 변환)

```yaml
# Kubernetes가 실제로 생성하는 Pod - 자동으로 변환됨
apiVersion: v1
kind: Pod
metadata:
  name: my-app-xxxxx
  namespace: default
  annotations:
    sidecar.istio.io/status: '{"version":"...","initContainers":[...],"containers":[...]}'
spec:
  # Init Container가 자동 추가됨
  initContainers:
  - name: istio-init
    image: istio/proxyv2:1.20.0
    command: ['istio-iptables', ...]  # iptables 규칙 설정
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
  
  # 원래의 애플리케이션 컨테이너
  containers:
  - name: my-app
    image: my-app:v1
    ports:
    - containerPort: 8080
  
  # Envoy 사이드카가 자동 추가됨
  - name: istio-proxy
    image: istio/proxyv2:1.20.0
    args: ['proxy', 'sidecar', ...]
    ports:
    - containerPort: 15090  # Prometheus 메트릭
    - containerPort: 15021  # Health check
    env:
    - name: ISTIO_META_MESH_ID
      value: "cluster.local"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
```

개발자는 위 변환 과정을 전혀 신경 쓰지 않는다. Kubernetes가 알아서 처리한다.

## 자동 주입의 동작 원리

### Mutating Admission Webhook

Kubernetes의 확장 메커니즘이다.

```
1. 개발자가 Pod 생성 요청
   kubectl apply -f deployment.yaml
   
2. API Server가 요청 수신
   
3. Mutating Webhook 호출
   "이 Pod를 수정할 사람?"
   
4. Istio Webhook 응답
   "나! 사이드카 추가할게"
   
5. Pod 스펙 변경
   istio-init + istio-proxy 컨테이너 추가
   
6. 변경된 Pod 생성
```

### Webhook 설정 확인

```bash
# Istio가 설치한 Webhook 확인
kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml
```

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector
webhooks:
- name: sidecar-injector.istio.io
  namespaceSelector:
    matchLabels:
      istio-injection: enabled  # 이 레이블 있는 네임스페이스만 처리
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  clientConfig:
    service:
      name: istiod
      namespace: istio-system
      path: "/inject"
```

이 설정이 "istio-injection=enabled 레이블이 있는 네임스페이스의 Pod 생성 시 istiod에게 물어보라"는 의미다.

## 네임스페이스별 제어

### 여러 네임스페이스 관리

```bash
# 프로덕션: Istio 활성화
kubectl label namespace production istio-injection=enabled

# 스테이징: Istio 활성화
kubectl label namespace staging istio-injection=enabled

# 개발: Istio 비활성화 (레거시 테스트)
kubectl label namespace development istio-injection=disabled

# 레이블 확인
kubectl get namespace -L istio-injection
```

```
NAME          STATUS   AGE   ISTIO-INJECTION
default       Active   10d   
production    Active   5d    enabled
staging       Active   5d    enabled
development   Active   5d    disabled
```

### 점진적 마이그레이션

기존 운영 중인 서비스에 Istio를 도입할 때의 전략이다.

```bash
# 1단계: 테스트 네임스페이스에만 적용
kubectl label namespace test istio-injection=enabled
kubectl rollout restart deployment -n test

# 2단계: 스테이징 확인
kubectl label namespace staging istio-injection=enabled
kubectl rollout restart deployment -n staging

# 3단계: 프로덕션 서비스별로 점진적 적용
kubectl label namespace production istio-injection=enabled
kubectl rollout restart deployment my-app-1 -n production
# 모니터링...
kubectl rollout restart deployment my-app-2 -n production
# 모니터링...
```

## Pod 레벨 제어

특정 Pod만 예외 처리하고 싶을 때 사용한다.

### 네임스페이스는 활성화, 특정 Pod만 비활성화

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: production  # istio-injection=enabled
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"  # 이 Pod만 사이드카 제외
      labels:
        app: legacy-app
    spec:
      containers:
      - name: legacy-app
        image: legacy-app:old-version
```

사용 시나리오:

- 레거시 애플리케이션이 Istio와 호환되지 않을 때
- 특정 시스템 컴포넌트(모니터링 에이전트 등)
- hostNetwork를 사용하는 Pod

### 네임스페이스는 비활성화, 특정 Pod만 활성화

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-app
  namespace: development  # istio-injection=disabled
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"  # 이 Pod만 사이드카 추가
      labels:
        app: new-app
    spec:
      containers:
      - name: new-app
        image: new-app:latest
```

## 수동 주입 방식

자동 주입을 사용하지 않고 명시적으로 주입하는 방법도 있다.

### istioctl을 이용한 수동 주입

```bash
# YAML 파일에 사이드카를 추가한 버전 생성
istioctl kube-inject -f deployment.yaml > deployment-injected.yaml

# 확인
cat deployment-injected.yaml  # istio-proxy 컨테이너가 포함됨

# 배포
kubectl apply -f deployment-injected.yaml
```

### 수동 주입이 필요한 경우

- CI/CD 파이프라인에서 명시적으로 제어하고 싶을 때
- Webhook이 작동하지 않는 환경
- 배포 전에 정확히 무엇이 배포되는지 확인하고 싶을 때
- GitOps 리포지토리에 완전한 YAML을 커밋하고 싶을 때

단점:

- YAML 파일이 매우 길어진다
- Istio 버전 업그레이드 시 모든 파일을 다시 주입해야 한다
- 자동화가 번거롭다

## 실제 워크플로우 예시

### 새로운 마이크로서비스 배포

```bash
# 1. 네임스페이스 생성 및 Istio 활성화
kubectl create namespace my-service
kubectl label namespace my-service istio-injection=enabled

# 2. 기존 Deployment YAML 그대로 배포
kubectl apply -f deployment.yaml -n my-service

# 3. Pod 확인 - 자동으로 2개 컨테이너 실행
kubectl get pods -n my-service
```

```
NAME                         READY   STATUS    RESTARTS   AGE
my-service-5d8f6c9b7-abcde   2/2     Running   0          30s
```

`2/2`가 핵심이다:

- 첫 번째 2: 실행 중인 컨테이너 수
- 두 번째 2: 전체 컨테이너 수 (my-app + istio-proxy)

### 사이드카 확인

```bash
# Pod 상세 정보 확인
kubectl describe pod my-service-5d8f6c9b7-abcde -n my-service
```

```
Containers:
  my-app:
    Container ID:   containerd://...
    Image:          my-app:v1
    Port:           8080/TCP
    
  istio-proxy:
    Container ID:   containerd://...
    Image:          istio/proxyv2:1.20.0
    Port:           15090/TCP
    Requests:
      cpu:     100m
      memory:  128Mi
```

## 버전별 사이드카 관리

Istio 버전을 여러 개 동시에 운영할 수 있다.

### Revision 기반 주입

```bash
# Istio 1.19 설치 (기존)
istioctl install --set revision=1-19

# Istio 1.20 설치 (신규)
istioctl install --set revision=1-20
```

### 네임스페이스별 버전 선택

```bash
# 프로덕션: 안정적인 1.19 사용
kubectl label namespace production istio.io/rev=1-19

# 스테이징: 새로운 1.20 테스트
kubectl label namespace staging istio.io/rev=1-20

# 기존 istio-injection 레이블 제거
kubectl label namespace production istio-injection-
kubectl label namespace staging istio-injection-
```

### 서비스별 점진적 업그레이드

```bash
# Service A를 1.20으로 업그레이드
kubectl label namespace service-a istio.io/rev=1-20 --overwrite
kubectl rollout restart deployment -n service-a

# 모니터링 후 문제없으면 Service B도 업그레이드
kubectl label namespace service-b istio.io/rev=1-20 --overwrite
kubectl rollout restart deployment -n service-b
```

## 리소스 사용량 커스터마이징

사이드카의 리소스를 조정하고 싶을 때는 어떻게 할까?

### 글로벌 설정 변경

```yaml
# IstioOperator로 전역 사이드카 리소스 설정
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_DNS_CAPTURE: "true"
  values:
    global:
      proxy:
        resources:
          requests:
            cpu: 50m      # 기본 100m에서 감소
            memory: 64Mi  # 기본 128Mi에서 감소
          limits:
            cpu: 500m
            memory: 512Mi
```

### Pod별 리소스 오버라이드

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: high-traffic-app
spec:
  template:
    metadata:
      annotations:
        # 이 Pod의 사이드카만 더 많은 리소스 할당
        sidecar.istio.io/proxyCPU: "200m"
        sidecar.istio.io/proxyMemory: "256Mi"
        sidecar.istio.io/proxyCPULimit: "1000m"
        sidecar.istio.io/proxyMemoryLimit: "1024Mi"
    spec:
      containers:
      - name: high-traffic-app
        image: high-traffic-app:v1
```

## 정리: 개발자 관점에서의 Istio

### 기존 방식 (Istio 없음)

```yaml
# 개발자가 작성하는 YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:v1
```

### Istio 방식

```yaml
# 개발자가 작성하는 YAML - 완전히 동일!
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:v1
```

```bash
# 플랫폼 팀이 한 번만 실행
kubectl label namespace production istio-injection=enabled
```

이게 전부다. 개발자는 아무것도 바꿀 필요가 없다.

## 전체 요약

Istio는 각 Pod에 사이드카를 추가하지만, 개발자가 YAML에 명시할 필요가 전혀 없다. 네임스페이스에 `istio-injection=enabled` 레이블 하나만 추가하면 Mutating Admission Webhook이 자동으로 모든 Pod에 istio-proxy 컨테이너를 주입한다. 기존 Deployment YAML은 단 한 글자도 수정하지 않고 그대로 사용한다. 네임스페이스별로 Istio를 활성화/비활성화할 수 있고, 특정 Pod만 어노테이션으로 예외 처리할 수 있다. Revision을 사용하면 여러 Istio 버전을 동시에 운영하며 점진적으로 업그레이드할 수 있다. 수동 주입 방식(istioctl kube-inject)도 있지만 거의 사용하지 않는다. 핵심은 **투명성**이다. 애플리케이션은 Istio의 존재를 전혀 모르고, 플랫폼 레벨에서 모든 것이 자동으로 처리된다.

---

# 정리하자면

- 명시는 한번만 하지만 어쨌든 istio라는 서비스 메쉬는 모든 서비스 팟에 각각 붙게되는것
- istio가 하는 역할은 각 서비스별 프로메테우스랑 사이드카 지원 등

## Istio의 실제 역할과 배치 방식

## 배치 구조: 모든 Pod마다 붙는다

네임스페이스에 레이블 하나만 추가하면, 그 이후 생성되는 **모든 Pod마다** Envoy 프록시(istio-proxy) 컨테이너가 사이드카로 붙는다.

### 실제 배치 예시

```
Before Istio:
┌─────────────────┐
│   Node 1        │
│  ┌──────────┐   │
│  │ Pod A    │   │
│  │ my-app   │   │
│  └──────────┘   │
│  ┌──────────┐   │
│  │ Pod B    │   │
│  │ my-app   │   │
│  └──────────┘   │
└─────────────────┘

After Istio:
┌─────────────────────────────────┐
│   Node 1                        │
│  ┌─────────────────────────┐   │
│  │ Pod A                   │   │
│  │ ┌────────┐ ┌─────────┐ │   │
│  │ │my-app  │ │istio-   │ │   │
│  │ │        │ │proxy    │ │   │
│  │ └────────┘ └─────────┘ │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ Pod B                   │   │
│  │ ┌────────┐ ┌─────────┐ │   │
│  │ │my-app  │ │istio-   │ │   │
│  │ │        │ │proxy    │ │   │
│  │ └────────┘ └─────────┘ │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### 규모에 따른 리소스 증가

```
서비스 수: 10개
레플리카: 각 3개
= 총 30개 Pod
= 30개의 istio-proxy 사이드카

각 사이드카가 100MB 메모리 사용
= 30 * 100MB = 3GB 추가 메모리

이게 Istio의 오버헤드다.
```

## Istio가 하는 역할: 프로메테우스보다 훨씬 많다

프로메테우스는 Istio가 하는 일 중 극히 일부다. Istio의 핵심 역할을 정확히 정리하면:

### 1. 트래픽 중개 및 제어 (가장 핵심)

모든 네트워크 트래픽이 사이드카를 거친다.

```
Before Istio:
Service A → Service B
(직접 연결)

After Istio:
Service A → [Envoy A] → [Envoy B] → Service B
            ↑                    ↑
         사이드카            사이드카
```

### 구체적으로 하는 일

```yaml
# 트래픽 분배 (카나리 배포)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 90  # 구버전 90%
    - destination:
        host: reviews
        subset: v2
      weight: 10  # 신버전 10%
```

```
100개 요청 중:
→ 90개는 v1으로
→ 10개는 v2로
→ 사이드카가 자동으로 분배
→ 애플리케이션 코드는 모름
```

### 재시도 및 타임아웃

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
    retries:
      attempts: 3         # 3번 재시도
      perTryTimeout: 2s   # 각 시도당 2초
    timeout: 10s          # 전체 10초
```

애플리케이션에서 재시도 로직을 구현할 필요 없다. 사이드카가 자동 처리한다.

### 서킷 브레이커

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5       # 5번 연속 실패하면
      interval: 30s
      baseEjectionTime: 30s      # 30초 동안 격리
      maxEjectionPercent: 50
```

```
장애 발생 시:
Service A → [Envoy] → Service B (응답 없음)
                ↓
          5번 연속 실패 감지
                ↓
          Service B 격리
                ↓
          다른 인스턴스로 라우팅
```

### 2. 자동 mTLS (보안)

모든 서비스 간 통신을 자동으로 암호화한다.

```
Before Istio:
Service A ─(평문)─→ Service B
누구나 스니핑 가능

After Istio:
Service A → [Envoy A] ═(암호화)═ [Envoy B] → Service B
            ↑                              ↑
        자동 암호화                    자동 복호화
        
애플리케이션은 여전히 평문으로 통신
사이드카가 투명하게 암호화/복호화
```

### 인증서 자동 관리

```
Istiod (Control Plane)
    ↓
각 사이드카에 인증서 자동 발급
    ↓
24시간마다 자동 갱신
    ↓
애플리케이션은 전혀 모름
```

### 3. 접근 제어 (Authorization)

누가 누구에게 접근할 수 있는지 제어한다.

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend-policy
  namespace: default
spec:
  selector:
    matchLabels:
      app: frontend
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/web"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/*"]
```

```
실제 동작:
1. Web 서비스가 Frontend의 /api/users 호출
   → Envoy: "너는 web SA야? GET 요청이야?"
   → ✅ 허용

2. Unknown 서비스가 Frontend 호출
   → Envoy: "너 누구야?"
   → ❌ 차단 (403 Forbidden)

3. Web 서비스가 POST 요청
   → Envoy: "GET만 허용됨"
   → ❌ 차단
```

### 4. 관찰성 (메트릭, 로그, 추적)

이 부분이 프로메테우스와 관련된 부분이다.

### 자동 메트릭 생성

```
사이드카가 모든 요청/응답을 관찰하면서 자동 생성:

istio_requests_total{
  source_app="productpage",
  destination_app="reviews",
  response_code="200"
} = 1523

istio_request_duration_milliseconds{
  source_app="productpage",
  destination_app="reviews",
  percentile="99"
} = 245
```

프로메테우스는 단지 이 메트릭을 수집하는 도구일 뿐이다. **메트릭을 만드는 건 Envoy 사이드카**다.

### 분산 추적

```
User 요청 → Gateway → Product → Reviews → Ratings
                        ↓           ↓          ↓
                    Trace ID: abc123
                    
각 사이드카가 Trace ID를 전파하고
모든 구간의 시간을 측정

Jaeger에서 전체 경로 확인 가능:
- Gateway: 5ms
- Product: 10ms
- Reviews: 100ms ← 병목 발견!
- Ratings: 15ms
```

### 접근 로그

```
사이드카가 자동 생성:
[2025-01-15T10:30:45.123Z] "GET /api/products HTTP/1.1" 200 
- "-" "-" 0 1234 5 4 "-" "curl/7.68.0" 
"abc-123-xyz" "productpage.default.svc.cluster.local" 
"10.244.1.5:9080" inbound|9080|| 127.0.0.1:9080 
10.244.1.3:34567 10.244.1.5:9080
```

### 5. 트래픽 가시성

### Kiali 대시보드

```
실시간으로 보여줌:
┌─────────┐
│ Gateway │
└────┬────┘
     │ 100 req/s
     ↓
┌──────────┐
│ Product  │
└────┬─────┘
     │ 95% → Reviews v1 (5ms)
     │ 5%  → Reviews v2 (100ms) ← 느림!
     ↓
┌─────────┐
│ Ratings │
└─────────┘
```

사이드카가 모든 트래픽을 보기 때문에 이런 시각화가 가능하다.

## Istio vs 프로메테우스: 역할 구분

### 프로메테우스의 역할

```
프로메테우스 = 메트릭 저장소 + 쿼리 엔진

- 메트릭을 수집해서 저장
- PromQL로 쿼리
- 알람 설정
- Grafana로 시각화
```

### Istio의 역할

```
Istio = 서비스 메쉬 플랫폼

1. 트래픽 제어
   - 라우팅
   - 로드 밸런싱
   - 재시도
   - 타임아웃
   - 서킷 브레이커

2. 보안
   - mTLS 암호화
   - 인증
   - 인가

3. 관찰성
   - 메트릭 생성 ← 프로메테우스에 제공
   - 로그 생성
   - 추적 데이터 생성

4. 정책 집행
   - Rate Limiting
   - 장애 주입 (카오스 테스트)
```

## 사이드카 패턴의 장단점

### 장점: 투명성

```python
# 애플리케이션 코드 - 변경 없음
import requests

response = requests.get('http://reviews:9080/api/reviews')
```

```
실제로는:
1. my-app이 localhost:9080 호출
2. iptables가 트래픽을 istio-proxy로 리다이렉트
3. istio-proxy가 실제 reviews 서비스 찾기
4. mTLS로 암호화
5. 로드 밸런싱
6. 재시도 로직
7. 메트릭 수집
8. 추적 정보 추가
9. reviews의 istio-proxy에 전달
10. reviews의 istio-proxy가 복호화
11. 실제 reviews 앱에 전달

모든 게 투명하게 일어남
```

### 단점: 리소스 오버헤드

### 메모리

```
Pod 100개 클러스터:
- 사이드카 없음: 10GB
- 사이드카 있음: 10GB + (100 * 100MB) = 20GB

메모리가 2배로 증가
```

### CPU

```
요청당 처리 시간:
- 직접 통신: 1ms
- Istio 경유: 1ms + 0.5ms (사이드카) + 0.5ms (사이드카) = 2ms

약 2배의 레이턴시 증가
```

### 복잡성

```
디버깅 경로:
Before: App A → App B (1 hop)
After:  App A → Proxy A → Proxy B → App B (3 hops)

문제 발생 시 어디가 원인인지 찾기 어려움
```

## 실제 사용 예시: 전체 흐름

### 시나리오: 온라인 쇼핑몰

```yaml
# 서비스 구조
Frontend (웹 UI)
    ↓
Product Service (상품 조회)
    ↓
Reviews Service v1 (리뷰 - 구버전)
Reviews Service v2 (리뷰 - 신버전)
    ↓
Ratings Service (평점)
```

### Istio 없이

```
문제점:
1. Frontend가 직접 Product 호출
   - Product 장애 시 Frontend도 다운
   - 재시도 로직을 Frontend에 구현

2. Reviews v2 배포
   - 모든 트래픽이 한번에 v2로
   - 문제 있으면 롤백 필요

3. 보안
   - 평문 통신
   - 누구나 Ratings 직접 호출 가능

4. 모니터링
   - 각 서비스마다 로깅 코드 작성
   - 전체 흐름 파악 어려움
```

### Istio 있으면

```yaml
# 1. 카나리 배포
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 95  # 95%는 안전한 v1
    - destination:
        host: reviews
        subset: v2
      weight: 5   # 5%만 v2로 테스트
```

```yaml
# 2. 복원력
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
    timeout: 5s       # 5초 초과하면 실패
    retries:
      attempts: 3     # 자동 재시도
      perTryTimeout: 2s
```

```yaml
# 3. 보안 - Ratings는 Reviews만 호출 가능
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ratings-policy
spec:
  selector:
    matchLabels:
      app: ratings
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/reviews"]
```

```
결과:
✅ Product 느려도 Frontend는 5초 후 타임아웃
✅ v2에 문제 있으면 5% 피해만
✅ 모든 통신 자동 암호화
✅ Frontend가 직접 Ratings 호출 시도 → 차단
✅ 전체 요청 경로를 Jaeger에서 시각화
✅ 코드 한 줄 안 바꿈
```

## 전체 요약

Istio는 메쉬가 활성화된 네임스페이스의 **모든 Pod마다** istio-proxy(Envoy) 사이드카를 붙인다. 네임스페이스 레이블 하나로 명시하면 이후 생성되는 모든 Pod에 자동 적용된다. Istio의 역할은 프로메테우스 메트릭 생성보다 훨씬 광범위하다. 핵심은 **모든 네트워크 트래픽을 중개**하면서 트래픽 제어(라우팅, 재시도, 타임아웃, 서킷 브레이커), 보안(자동 mTLS, 인증, 인가), 관찰성(메트릭 생성, 로그, 분산 추적)을 제공하는 것이다. 프로메테우스는 Istio가 생성한 메트릭을 수집하는 도구일 뿐이다. 사이드카 패턴으로 애플리케이션 코드를 전혀 수정하지 않고 이 모든 기능을 투명하게 추가하지만, Pod당 약 100MB 메모리와 약간의 레이턴시가 오버헤드로 발생한다.

---

# Istio와 리버스 프록시의 관계

Istio의 사이드카(Envoy)는 **각 서비스마다 붙는 전용 리버스 프록시**다. Nginx를 생각하면 개념이 정확히 맞다.

### 전통적인 Nginx 패턴

```
                  ┌─────────┐
외부 요청  ───→  │ Nginx   │  ───→  Backend Servers
                  │(리버스  │         - Server 1
                  │ 프록시) │         - Server 2
                  └─────────┘         - Server 3
                  
하나의 Nginx가 여러 백엔드로 트래픽 분배
```

### Istio 패턴 (분산 리버스 프록시)

```
┌──────────────────────┐      ┌──────────────────────┐
│   Service A Pod      │      │   Service B Pod      │
│  ┌────────┐          │      │  ┌────────┐          │
│  │Service │          │      │  │Service │          │
│  │  A     │          │      │  │  B     │          │
│  └───┬────┘          │      │  └───▲────┘          │
│      │               │      │      │               │
│  ┌───▼────────┐      │      │  ┌───┴────────┐     │
│  │  Envoy     │ ─────┼──────┼─→│  Envoy     │     │
│  │(리버스     │      │      │  │(리버스     │     │
│  │ 프록시)    │      │      │  │ 프록시)    │     │
│  └────────────┘      │      │  └────────────┘     │
└──────────────────────┘      └──────────────────────┘

각 서비스마다 전용 Envoy(Nginx 같은) 프록시가 붙음
```

## Envoy vs Nginx: 핵심 차이

### Nginx의 역할 (전통적)

```nginx
# nginx.conf
upstream backend {
    server backend1.example.com:8080;
    server backend2.example.com:8080;
    server backend3.example.com:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }
}
```

- 정적 설정 파일
- 변경 시 reload 필요
- 중앙 집중식 배치
- 수동 설정

### Envoy의 역할 (Istio)

```yaml
# 동적 설정 - Istiod가 자동 전송
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend
  http:
  - route:
    - destination:
        host: backend
        subset: v1
      weight: 90
    - destination:
        host: backend
        subset: v2
      weight: 10
    timeout: 5s
    retries:
      attempts: 3
```

- 동적 설정 (xDS API)
- 재시작 없이 실시간 변경
- 분산 배치 (각 Pod마다)
- 자동 설정 (Istiod가 관리)

## 구체적인 비교: 같은 점

### 1. 로드 밸런싱

### Nginx

```nginx
upstream backend {
    least_conn;  # 최소 연결 방식
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}
```

### Envoy (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN  # 최소 연결 방식
```

둘 다 동일한 로드 밸런싱 기능을 제공한다.

### 2. 타임아웃

### Nginx

```nginx
location /api {
    proxy_pass http://backend;
    proxy_connect_timeout 5s;
    proxy_read_timeout 10s;
}
```

### Envoy (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  http:
  - route:
    - destination:
        host: backend
    timeout: 10s
```

### 3. 재시도

### Nginx

```nginx
location / {
    proxy_pass http://backend;
    proxy_next_upstream error timeout;
    proxy_next_upstream_tries 3;
}
```

### Envoy (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  http:
  - route:
    - destination:
        host: backend
    retries:
      attempts: 3
      retryOn: 5xx,reset,connect-failure
```

### 4. 헤더 조작

### Nginx

```nginx
location / {
    proxy_pass http://backend;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### Envoy (Istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  http:
  - route:
    - destination:
        host: backend
    headers:
      request:
        add:
          x-custom-header: "my-value"
```

## 핵심 차이점: 아키텍처 패턴

### Nginx 패턴: 중앙 집중식

```
                    ┌─────────────┐
                    │   Nginx     │
외부 ──────────────→│  (단일 or   │
                    │   클러스터) │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            ↓              ↓              ↓
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │Service A│    │Service B│    │Service C│
      └─────────┘    └─────────┘    └─────────┘

장점:
- 단순한 아키텍처
- 설정이 한 곳에 집중
- 리소스 효율적

단점:
- Nginx가 SPOF (단일 장애점)
- Nginx가 병목이 될 수 있음
- 내부 서비스 간 통신은 여전히 직접
```

### Istio 패턴: 분산 사이드카

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Service A Pod   │    │ Service B Pod   │    │ Service C Pod   │
│ ┌─────┐         │    │ ┌─────┐         │    │ ┌─────┐         │
│ │App A│         │    │ │App B│         │    │ │App C│         │
│ └──┬──┘         │    │ └──▲──┘         │    │ └──▲──┘         │
│    │            │    │    │            │    │    │            │
│ ┌──▼──────┐     │    │ ┌──┴──────┐     │    │ ┌──┴──────┐     │
│ │Envoy A  │────────────→│Envoy B  │────────────→│Envoy C  │     │
│ │(프록시) │     │    │ │(프록시) │     │    │ │(프록시) │     │
│ └─────────┘     │    │ └─────────┘     │    │ └─────────┘     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        ↑                      ↑                      ↑
        └──────────────────────┴──────────────────────┘
                    Istiod (설정 배포)

장점:
- SPOF 없음 (한 프록시 장애는 해당 Pod만 영향)
- 모든 통신을 가로챌 수 있음 (내부 통신 포함)
- 세밀한 제어 (Pod별, 서비스별)

단점:
- 리소스 오버헤드 (Pod마다 프록시)
- 복잡한 아키텍처
```

## 실제 트래픽 흐름 비교

### Nginx 방식

```
1. 외부 요청
   User → Nginx → Service A

2. 내부 서비스 간 통신 (프록시 거치지 않음)
   Service A → Service B (직접 연결)
   
3. 문제점
   - 내부 통신은 제어 불가
   - Service A와 B 사이는 "블랙박스"
```

### Istio 방식

```
1. 외부 요청
   User → Ingress Gateway (Envoy) → Envoy A → Service A

2. 내부 서비스 간 통신 (모두 프록시 거침)
   Service A → Envoy A → Envoy B → Service B
   
3. 장점
   - 모든 통신을 관찰/제어
   - A→B 트래픽도 정책 적용 가능
   - 전체 경로 추적 가능
```

## 구체적 시나리오: 카나리 배포

### Nginx로 구현

```nginx
# nginx.conf
upstream backend {
    # 90% 트래픽
    server backend-v1-1:8080 weight=9;
    server backend-v1-2:8080 weight=9;
    server backend-v1-3:8080 weight=9;
    
    # 10% 트래픽
    server backend-v2-1:8080 weight=1;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
    }
}
```

문제점:

- 설정 변경 시 reload 필요
- 내부 서비스 간에는 적용 불가
- 백엔드 IP가 바뀌면 수동 수정

### Istio로 구현

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend
  http:
  - route:
    - destination:
        host: backend
        subset: v1
      weight: 90
    - destination:
        host: backend
        subset: v2
      weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

장점:

- 설정 변경 시 재시작 불필요
- 모든 서비스 간 통신에 적용
- Kubernetes Service Discovery 자동 연동
- 가중치를 `kubectl edit`으로 즉시 변경 가능

## Envoy의 고급 기능 (Nginx에는 없는)

### 1. 동적 설정 (xDS API)

```
Nginx:
1. 설정 파일 수정
2. nginx -s reload
3. 기존 연결 유지하며 재시작

Envoy:
1. Istiod가 새 설정 푸시
2. Envoy가 즉시 적용
3. 재시작 전혀 없음

실시간 변경 가능!
```

### 2. 서비스 디스커버리 통합

```
Nginx:
upstream backend {
    server 10.244.1.5:8080;  # 고정 IP
    server 10.244.1.6:8080;
}
→ Pod IP가 바뀌면 수동 업데이트

Envoy:
# Kubernetes Service 이름만 지정
destination:
  host: backend  # Kubernetes Service
→ Pod 생성/삭제 자동 감지
→ IP 변경 자동 반영
```

### 3. mTLS 자동 처리

```
Nginx:
# 수동으로 인증서 설정 필요
ssl_certificate /path/to/cert.pem;
ssl_certificate_key /path/to/key.pem;
ssl_client_certificate /path/to/ca.pem;
ssl_verify_client on;

Envoy (Istio):
# 자동으로 처리됨
- Istiod가 인증서 발급
- Envoy가 자동으로 사용
- 24시간마다 자동 갱신
→ 설정 필요 없음
```

### 4. 분산 추적

```
Nginx:
# 기본 지원 안 함
# 애플리케이션에서 구현 필요

Envoy:
# 자동으로 trace ID 생성 및 전파
X-B3-TraceId: 80f198ee56343ba864fe8b2a57d3eff7
X-B3-SpanId: e457b5a2e4d86bd1
X-B3-Sampled: 1
→ 전체 요청 경로 자동 추적
```

## 실제 설정 비교: A/B 테스팅

### Nginx 구현

```nginx
map $http_user_agent $backend_pool {
    ~*iPhone backend-mobile;
    ~*Android backend-mobile;
    default backend-desktop;
}

upstream backend-mobile {
    server mobile-v1:8080;
}

upstream backend-desktop {
    server desktop-v1:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://$backend_pool;
    }
}
```

### Istio 구현

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*(iPhone|Android).*"
    route:
    - destination:
        host: backend
        subset: mobile
  - route:
    - destination:
        host: backend
        subset: desktop
```

비슷한 기능이지만 Istio는:

- YAML로 선언적 관리
- GitOps 통합 용이
- 모든 내부 통신에도 적용

## 혼합 사용: Istio + Nginx

실제로는 둘 다 사용하는 경우가 많다.

```
Internet
   ↓
[Nginx Ingress Controller]  ← 외부 진입점
   ↓
[Istio Gateway (Envoy)]      ← 클러스터 경계
   ↓
[Service A + Envoy Sidecar]  ← 내부 서비스
   ↓
[Service B + Envoy Sidecar]
```

역할 분담:

- **Nginx**: WAF, Rate Limiting, TLS 종료 (외부 진입)
- **Istio Gateway**: L7 라우팅, 클러스터 진입점
- **Envoy Sidecar**: 내부 서비스 간 모든 통신 제어

## 리소스 비교

### Nginx (중앙 집중)

```
Nginx 인스턴스: 3개 (HA)
메모리: 3 * 200MB = 600MB
CPU: 3 * 0.5 core = 1.5 cores

총 리소스: 600MB, 1.5 cores
```

### Istio (분산)

```
서비스 Pod: 50개
사이드카: 50개
메모리: 50 * 100MB = 5GB
CPU: 50 * 0.1 core = 5 cores

Istiod (Control Plane)
메모리: 2GB
CPU: 1 core

총 리소스: 7GB, 6 cores
```

훨씬 많은 리소스를 사용하지만, 그만큼 세밀한 제어가 가능하다.

## 전체 요약

Istio의 Envoy는 각 서비스마다 붙는 **전용 리버스 프록시**로, Nginx가 하는 일(로드 밸런싱, 타임아웃, 재시도, 헤더 조작)을 동일하게 수행한다. 하지만 근본적인 차이는 아키텍처 패턴이다. Nginx는 중앙 집중식으로 외부 트래픽만 처리하지만, Istio는 **모든 Pod마다 프록시를 배치**하여 내부 서비스 간 통신까지 모두 제어한다. Envoy는 동적 설정(xDS), 자동 서비스 디스커버리, mTLS 자동 처리, 분산 추적 등 Nginx보다 진보된 기능을 제공한다. 리소스는 더 많이 사용하지만(Pod당 약 100MB), 모든 트래픽을 관찰하고 제어할 수 있다는 강력한 장점이 있다. 실제로는 Nginx(외부 진입)와 Istio(내부 메쉬)를 함께 사용하는 경우가 많다.

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

## 전체 요약

Ingress는 **클러스터의 출입구** 역할로 외부에서 내부로 들어오는 트래픽만 제어한다(도메인/경로 라우팅, TLS 종료). Service Mesh(Istio)는 **클러스터 내부의 모든 서비스 간 통신**을 제어한다(트래픽 제어, mTLS, 접근 제어, 복원력, 관찰성). Ingress는 첫 진입점에서 한 번만 작동하고, Istio는 모든 Pod마다 사이드카를 배치하여 모든 통신을 가로챈다. 실제로는 Ingress(외부 진입) + Istio(내부 메쉬)를 함께 사용하는 것이 일반적이다. Ingress는 가볍고 단순하지만 기능이 제한적이고, Istio는 강력하지만 복잡하고 리소스를 많이 사용한다. 서비스가 10개 미만이면 Ingress만으로 충분하고, 복잡한 마이크로서비스 환경에서는 둘 다 필요하다.

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

## 실제 예시: 온라인 쇼핑몰

### Ingress만 있을 때

```
Internet
   ↓
┌──────────────────────────────────────────┐
│ Kubernetes Cluster                       │
│                                          │
│     ┌─────────────┐                     │
│     │   Nginx     │ ← 1개               │
│     │  (Ingress)  │                     │
│     └──────┬──────┘                     │
│            │                             │
│      ┌─────┼─────┐                      │
│      ↓     ↓     ↓                      │
│   ┌────┐┌────┐┌────┐                   │
│   │Web ││API ││DB  │ ← 프록시 없음     │
│   └────┘└────┘└────┘                   │
│      │     │     │                      │
│      └─────┼─────┘                      │
│    (직접 통신, 제어 불가)               │
│                                          │
└──────────────────────────────────────────┘
```

트래픽 흐름:

```
1. 사용자 → Nginx → Web (Nginx 역할 끝)
2. Web → API (직접, 암호화 없음, 재시도 없음)
3. API → DB (직접, 접근 제어 없음)
```

### Istio 추가했을 때

```
Internet
   ↓
┌──────────────────────────────────────────┐
│ Kubernetes Cluster                       │
│                                          │
│     ┌─────────────┐                     │
│     │   Nginx     │ ← 1개               │
│     │  (Ingress)  │                     │
│     └──────┬──────┘                     │
│            │                             │
│      ┌─────┼─────┐                      │
│      ↓     ↓     ↓                      │
│   ┌────┐┌────┐┌────┐                   │
│   │[E] ││[E] ││[E] │ ← 각각 Envoy 추가 │
│   │Web ││API ││DB  │                    │
│   └─┬──┘└─▲──┘└─▲──┘                   │
│     │     │     │                        │
│     └─────┼─────┘                        │
│    (모든 통신이 Envoy 경유)             │
│                                          │
└──────────────────────────────────────────┘
```

트래픽 흐름:

```
1. 사용자 → Nginx → [Envoy] → Web
2. Web → [Envoy] → [Envoy] → API (mTLS, 재시도, 메트릭)
3. API → [Envoy] → [Envoy] → DB (인증, 인가, 추적)
```

## 리소스 관점에서 비교

### Ingress (Nginx)

```
┌──────────────────────────┐
│ Nginx Ingress Controller │
│ - Replicas: 3            │
│ - 각 200MB               │
│ = 총 600MB               │
└──────────────────────────┘

고정 비용: 서비스 개수와 무관
```

### Istio (Envoy)

```
서비스 Pod 개수: 50개
각 사이드카: 100MB
= 50 * 100MB = 5GB

Istiod (컨트롤 플레인): 2GB
= 총 7GB

변동 비용: 서비스 개수에 비례
```

## 네트워크 홉(Hop) 비교

### Ingress만

```
외부 요청:
User → Nginx (1홉) → Service A (1홉) = 총 2홉

내부 통신:
Service A → Service B (1홉) = 총 1홉
```

### Istio 추가

```
외부 요청:
User → Nginx (1홉) → Envoy (1홉) → Service A (1홉) = 총 3홉

내부 통신:
Service A → Envoy A (1홉) → Envoy B (1홉) → Service B (1홉) = 총 3홉
```

레이턴시 증가:

- 각 Envoy 통과: +0.5ms
- 외부 요청: +0.5ms
- 내부 통신: +1ms (양쪽 Envoy)

## 설정 방식 비교

### Ingress 설정 (중앙 집중)

```yaml
# 하나의 설정으로 전체 라우팅 정의
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        backend:
          service:
            name: api-service
      - path: /web
        backend:
          service:
            name: web-service
```

특징:

- 한 곳에서 모든 외부 라우팅 관리
- 변경 시 하나의 리소스만 수정
- 내부 통신은 제어 불가

### Istio 설정 (분산)

```yaml
# Service별로 세밀한 설정
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-service
spec:
  hosts:
  - api-service
  http:
  - route:
    - destination:
        host: api-service
    timeout: 5s
    retries:
      attempts: 3
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-service
spec:
  hosts:
  - web-service
  http:
  - route:
    - destination:
        host: web-service
    timeout: 10s
```

특징:

- Service별로 독립적인 설정
- 세밀한 제어 가능
- 모든 통신(외부+내부) 제어

## 장애 격리 비교

### Ingress만

```
Nginx 장애 시:
┌─────────┐
│ Nginx X │ ← 전체 클러스터 접근 불가
└─────────┘

서비스 장애 시:
┌────┐  ┌────┐  ┌────┐
│ A  │→│ B X│→│ C  │
└────┘  └────┘  └────┘
         ↑
    B 장애가 A, C로 전파 가능
    (재시도, 타임아웃 없으면)
```

### Istio 추가

```
Nginx 장애 시:
┌─────────┐
│ Nginx X │ ← 외부 진입만 불가
└─────────┘
   내부 통신은 계속 작동

서비스 장애 시:
┌────┐  ┌────┐  ┌────┐
│[E] │ │[E] │ │[E] │
│ A  │→│ B X│→│ C  │
└────┘  └────┘  └────┘
         ↑
    Envoy가 자동 재시도
    서킷 브레이커로 격리
    다른 인스턴스로 우회
```

## 관찰성 비교

### Ingress만

```
볼 수 있는 것:
✅ 외부 → 서비스 (Nginx 로그)
   - 어떤 URL이 호출됐는지
   - 어떤 서비스로 갔는지

볼 수 없는 것:
❌ 서비스 A → 서비스 B
❌ 서비스 B → 서비스 C
❌ 전체 요청 경로
```

### Istio 추가

```
볼 수 있는 것:
✅ 외부 → 서비스
✅ 서비스 A → 서비스 B
✅ 서비스 B → 서비스 C
✅ 전체 요청 경로 추적
✅ 각 구간별 레이턴시
✅ 에러 발생 위치

Kiali 대시보드:
User → Nginx → A(5ms) → B(100ms) → C(10ms)
                          ↑
                    여기가 병목!
```

## 보안 관점

### Ingress만

```
외부 → 내부:
Internet ──(HTTPS)──→ [Nginx] ──(HTTP)──→ Services
                        ↑
                   TLS 종료 여기까지

내부 통신:
Service A ──(HTTP 평문)──→ Service B
            ↑
        암호화 없음
        누구나 스니핑 가능 (같은 네트워크에서)
```

### Istio 추가

```
외부 → 내부:
Internet ──(HTTPS)──→ [Nginx] ──(HTTP)──→ [Envoy] → Service

내부 통신:
Service A → [Envoy] ══(mTLS)══ [Envoy] → Service B
            자동 암호화          자동 복호화
            
✅ 모든 구간 암호화
✅ 서비스 간 상호 인증
✅ 코드 수정 없음
```

## 현실적인 선택

### 작은 팀/프로젝트

```
추천: Ingress만

이유:
- 5-10개 이하 서비스
- 간단한 구조
- 리소스 제약
- 빠른 시작

예시:
┌─────────┐
│ Nginx   │
└────┬────┘
     │
┌────┼────┐
│    │    │
Web API  DB

충분함!
```

### 중대형 조직

```
추천: Ingress + Istio

이유:
- 20개 이상 서비스
- 복잡한 통신
- 보안 요구사항
- 관찰성 필요

예시:
┌─────────┐
│ Nginx   │
└────┬────┘
     │
  ┌──┴───────────────┐
  │   Istio Mesh     │
  │ ┌──┐┌──┐┌──┐┌──┐│
  │ │E ││E ││E ││E ││
  │ │A ││B ││C ││D ││
  │ └┬─┘└┬─┘└┬─┘└──┘│
  │  └───┴───┘       │
  └──────────────────┘

필수!
```

## 전체 요약

Ingress(Nginx)는 **클러스터 전체의 단일 리버스 프록시**로 외부 진입점을 담당하고, Istio(Envoy)는 **각 Pod마다 붙는 전용 리버스 프록시**로 모든 내부 통신을 제어한다. Ingress는 중앙 집중식으로 1개(또는 HA를 위해 2-3개)만 배치되어 외부→내부 진입만 처리하고, Istio는 분산 방식으로 100개 Pod면 100개 프록시가 배치되어 모든 서비스 간 통신을 가로챈다. Ingress는 고정 비용(약 600MB)이지만 기능이 제한적이고, Istio는 변동 비용(Pod당 100MB)이지만 mTLS, 재시도, 서킷 브레이커, 분산 추적 등 강력한 기능을 제공한다. 작은 프로젝트는 Ingress만으로 충분하고, 복잡한 마이크로서비스는 둘 다 필요하다. 완벽한 비유: Ingress는 건물의 정문 경비, Istio는 각 방마다 배치된 개인 비서다.
