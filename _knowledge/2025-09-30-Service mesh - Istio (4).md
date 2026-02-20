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