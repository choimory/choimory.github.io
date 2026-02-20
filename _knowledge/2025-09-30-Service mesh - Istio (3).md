---
title: "Service mesh - Istio (3)"
date: 2025-09-30T00:00:03
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
    - Mesh
    - Istio
---

# Kubernetes에서의 Istio 통합과 운영

## Istio와 Kubernetes의 관계

Istio는 Kubernetes 위에서 작동하는 서비스 메쉬 레이어로, Kubernetes의 네트워킹을 확장하고 강화한다. Kubernetes가 기본적인 Pod-to-Pod 통신과 Service 추상화를 제공한다면, Istio는 그 위에 고급 트래픽 관리, 보안, 관찰성을 추가한다.

- Kubernetes의 네이티브 리소스(Pod, Service, Deployment)를 그대로 활용한다
- 기존 Kubernetes 애플리케이션에 코드 변경 없이 추가할 수 있다
- Kubernetes API를 통해 모든 설정과 상태를 관리한다
- CRD(Custom Resource Definition)로 Istio 고유 리소스를 확장한다

## Istio가 Kubernetes 네트워킹을 확장하는 방식

### Kubernetes 기본 네트워킹의 한계

Kubernetes만으로는 부족한 부분들이 있다.

- **트래픽 제어**: 가중치 기반 라우팅, 카나리 배포를 네이티브로 지원하지 않는다
- **보안**: Service 간 통신이 기본적으로 암호화되지 않는다
- **관찰성**: 기본 메트릭만 제공하며 분산 추적이 없다
- **복원력**: 재시도, 타임아웃, 서킷 브레이커를 애플리케이션에서 구현해야 한다
- **정책**: L7 레벨의 세밀한 접근 제어가 어렵다

### Istio의 추가 가치

Kubernetes 위에 투명한 네트워크 레이어를 추가한다.

- Envoy 사이드카가 모든 네트워크 트래픽을 가로챈다
- Kubernetes Service를 그대로 사용하면서 고급 기능을 추가한다
- Network Policy보다 풍부한 L7 정책을 제공한다
- 애플리케이션 코드 수정 없이 mTLS를 적용한다

## Kubernetes 리소스와 Istio 리소스의 상호작용

### Pod와 Sidecar Injection

Istio는 Kubernetes의 Admission Controller를 활용한다.

### 자동 주입 메커니즘

- 네임스페이스에 `istio-injection=enabled` 레이블을 추가한다
- Mutating Webhook이 Pod 생성 요청을 가로챈다
- Pod 스펙에 Envoy 사이드카 컨테이너를 자동 삽입한다
- Init Container가 iptables 규칙을 설정하여 트래픽을 리다이렉트한다

### Injection 제어

```yaml
# 네임스페이스 레벨 활성화
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    istio-injection: enabled

# Pod 레벨 비활성화
apiVersion: v1
kind: Pod
metadata:
  annotations:
    sidecar.istio.io/inject: "false"
```

- 네임스페이스 레벨에서 기본 동작을 설정한다
- Pod 어노테이션으로 개별 Pod의 동작을 재정의한다
- 레거시 애플리케이션이나 호스트 네트워크 사용 Pod는 제외할 수 있다

### Service와 Virtual Service

Kubernetes Service는 유지하면서 Istio가 라우팅을 제어한다.

### 기본 통합

- Kubernetes Service는 여전히 서비스 디스커버리와 DNS를 제공한다
- Istio는 Service를 인식하고 Envoy 설정으로 변환한다
- Virtual Service가 없으면 기본적으로 라운드 로빈 로드 밸런싱을 수행한다

### Virtual Service로 확장

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
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 90
    - destination:
        host: reviews
        subset: v3
      weight: 10
```

- Kubernetes Service는 그대로 두고 라우팅 로직만 추가한다
- 헤더, 쿼리 파라미터, URI 기반 라우팅이 가능하다
- 가중치를 조정하여 카나리 배포를 구현한다
- 클라이언트 코드는 여전히 Service 이름만 사용한다

### Deployment와 Destination Rule

Kubernetes Deployment의 버전을 Istio subset으로 매핑한다.

### 버전 관리 패턴

```yaml
# Kubernetes Deployments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reviews
      version: v1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reviews
      version: v2
  template:
    metadata:
      labels:
        app: reviews
        version: v2
---
# Istio Destination Rule
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

- Deployment에서 `version` 레이블로 버전을 구분한다
- Destination Rule이 레이블을 subset으로 그룹화한다
- Virtual Service에서 subset 이름으로 트래픽을 제어한다
- Kubernetes는 여전히 모든 버전을 단일 Service로 관리한다

### Ingress vs Gateway

Kubernetes Ingress를 Istio Gateway로 대체할 수 있다.

### Kubernetes Ingress의 한계

- 기본 HTTP 라우팅만 지원한다
- 고급 트래픽 관리 기능이 부족하다
- TLS 설정이 제한적이다
- 각 Ingress Controller마다 어노테이션이 다르다

### Istio Gateway의 장점

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "bookinfo.example.com"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: bookinfo-credential
    hosts:
    - "bookinfo.example.com"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "bookinfo.example.com"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        prefix: "/productpage"
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

- Gateway는 L4-L6 설정을 담당한다(포트, 프로토콜, TLS)
- Virtual Service가 L7 라우팅을 처리한다
- 명확한 책임 분리로 설정이 더 깔끔하다
- 동일한 라우팅 규칙을 내부와 외부에서 재사용할 수 있다

## Istio 설치와 Kubernetes 통합

### 설치 방법

### istioctl을 이용한 설치

가장 일반적이고 권장되는 방법이다.

```bash
# 설치
istioctl install --set profile=demo

# 특정 네임스페이스 사이드카 자동 주입 활성화
kubectl label namespace default istio-injection=enabled

# 설치 검증
istioctl verify-install
```

- 프로파일별로 사전 구성된 설정을 제공한다
- 설치 전 검증을 수행한다
- 업그레이드와 제거가 간편하다

### Helm Chart 설치

GitOps 워크플로우에 적합하다.

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system
```

- 버전 관리가 용이하다
- ArgoCD, FluxCD와 쉽게 통합된다
- 선언적 방식으로 관리한다

### Operator 기반 설치

Kubernetes Operator 패턴을 활용한다.

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-controlplane
  namespace: istio-system
spec:
  profile: default
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          type: LoadBalancer
```

- IstioOperator CRD로 선언적 관리
- 자동 복구와 업그레이드를 지원한다
- 복잡한 설정을 코드로 관리한다

### 네임스페이스별 설정

Kubernetes 네임스페이스를 활용한 멀티테넌시를 지원한다.

### 선택적 메쉬 적용

```bash
# 프로덕션 네임스페이스만 메쉬 적용
kubectl label namespace production istio-injection=enabled

# 개발 네임스페이스는 메쉬 없이 운영
kubectl label namespace development istio-injection=disabled
```

- 점진적으로 메쉬를 도입할 수 있다
- 레거시 애플리케이션과 공존이 가능하다
- 테스트와 프로덕션을 분리 운영한다

### 네임스페이스별 정책

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: development
spec:
  mtls:
    mode: PERMISSIVE
```

- 네임스페이스마다 다른 보안 정책을 적용한다
- 환경별 요구사항에 맞게 설정한다

## 보안 통합

### ServiceAccount와 Identity

Kubernetes ServiceAccount를 Istio Identity로 사용한다.

### SPIFFE ID 생성

- Istio는 각 Pod의 ServiceAccount를 기반으로 SPIFFE ID를 생성한다
- 형식: `spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>`
- 예: `spiffe://cluster.local/ns/default/sa/bookinfo-productpage`

### 인증서 자동 발급

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  template:
    spec:
      serviceAccountName: httpbin  # 이 SA를 identity로 사용
```

- Citadel(Istiod)이 각 ServiceAccount에 대한 인증서를 발급한다
- 인증서는 자동으로 순환된다(기본 24시간마다 갱신)
- Envoy가 mTLS 통신에 이 인증서를 사용한다

### Network Policy와의 관계

Istio Authorization Policy는 Kubernetes Network Policy를 보완한다.

### 계층적 보안

- **Kubernetes Network Policy**: L3/L4 레벨 제어(IP, 포트)
- **Istio Authorization Policy**: L7 레벨 제어(HTTP 메서드, 경로, 헤더)

### 함께 사용하기

```yaml
# Kubernetes Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Istio Authorization Policy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-viewer
spec:
  selector:
    matchLabels:
      app: httpbin
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/sleep"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/status/*"]
```

- Network Policy로 기본 네트워크 격리를 구현한다
- Authorization Policy로 세밀한 애플리케이션 레벨 제어를 추가한다
- 심층 방어(Defense in Depth) 전략을 구현한다

### RBAC 통합

Kubernetes RBAC와 Istio Authorization을 구분한다.

- **Kubernetes RBAC**: Kubernetes API 접근 제어(누가 리소스를 관리할 수 있는가)
- **Istio Authorization**: 애플리케이션 트래픽 접근 제어(누가 서비스를 호출할 수 있는가)
- 두 시스템이 독립적으로 작동하며 각각의 영역을 보호한다

## 관찰성과 모니터링

### Prometheus 통합

Istio는 자동으로 메트릭을 생성하고 Prometheus로 전송한다.

### 메트릭 수집 아키텍처

- Envoy가 모든 요청에 대한 메트릭을 생성한다
- Prometheus가 각 Pod의 `/stats/prometheus` 엔드포인트를 스크랩한다
- ServiceMonitor CRD를 사용하여 자동 디스커버리를 설정한다

### 주요 메트릭

```promql
# 요청률
rate(istio_requests_total[5m])

# 에러율
rate(istio_requests_total{response_code=~"5.."}[5m])

# 레이턴시 (P99)
histogram_quantile(0.99, rate(istio_request_duration_milliseconds_bucket[5m]))

# 서비스별 트래픽
sum(rate(istio_requests_total[5m])) by (destination_service)
```

### Grafana 대시보드

사전 구성된 대시보드로 시각화한다.

- **Mesh Dashboard**: 전체 메쉬 상태 개요
- **Service Dashboard**: 서비스별 상세 메트릭
- **Workload Dashboard**: Deployment/Pod 레벨 메트릭
- **Performance Dashboard**: 레이턴시와 처리량 분석

### 분산 추적

### Jaeger/Zipkin 통합

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: JAEGER_AGENT_HOST
          value: jaeger-agent.istio-system
        - name: JAEGER_AGENT_PORT
          value: "6831"
```

- Istio가 추적 헤더(B3, W3C Trace Context)를 자동으로 전파한다
- 애플리케이션은 헤더를 downstream 호출에 전달하기만 하면 된다
- 전체 요청 경로를 시각적으로 추적한다

### 추적 데이터 활용

- 병목 지점 식별
- 에러 발생 위치 파악
- 의존성 그래프 생성
- 레이턴시 분석

### Kiali

서비스 메쉬 전용 관찰성 도구다.

### 주요 기능

- **그래프 뷰**: 서비스 간 실시간 트래픽 흐름 시각화
- **애플리케이션 뷰**: 논리적 애플리케이션 그룹화
- **워크로드 뷰**: Deployment/Pod 레벨 상세 정보
- **Istio Config**: Virtual Service, Destination Rule 등 검증
- **분산 추적**: Jaeger 통합
- **메트릭**: 실시간 성능 지표

### 설치

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# 접근
istioctl dashboard kiali
```

## 성능 최적화

### Resource 요구사항

Istio는 추가 리소스를 소비한다.

### Sidecar 리소스

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: istio-proxy
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 2000m
        memory: 1024Mi
```

- 기본 설정에서 사이드카당 약 50-100MB 메모리 사용
- CPU는 트래픽 양에 비례한다
- 대규모 클러스터에서는 전체적으로 상당한 오버헤드가 된다

### Control Plane 리소스

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 500m
            memory: 2Gi
          limits:
            cpu: 2000m
            memory: 4Gi
```

- Istiod는 클러스터 규모에 따라 리소스가 증가한다
- 수천 개의 서비스를 관리하려면 충분한 리소스가 필요하다

### 선택적 기능 비활성화

불필요한 기능을 끄면 성능이 향상된다.

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    # 접근 로그 비활성화
    accessLogFile: ""
    # 추적 샘플링 비율 조정
    defaultConfig:
      tracing:
        sampling: 1.0  # 1%만 추적
```

### Sidecar 리소스 범위 제한

각 사이드카가 알아야 하는 설정을 제한한다.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: production
spec:
  egress:
  - hosts:
    - "./*"  # 같은 네임스페이스만
    - "istio-system/*"  # istio-system 네임스페이스
```

- 기본적으로 사이드카는 전체 메쉬의 설정을 받는다
- Sidecar 리소스로 범위를 제한하면 메모리 사용량이 감소한다
- 대규모 클러스터에서 특히 효과적이다

## 고가용성과 확장성

### Control Plane HA

Istiod를 고가용성으로 배포한다.

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      k8s:
        replicaCount: 3
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: istiod
              topologyKey: kubernetes.io/hostname
```

- 최소 3개 레플리카로 실행한다
- Pod Anti-Affinity로 다른 노드에 분산 배치한다
- Istiod 장애 시에도 데이터 플레인은 계속 작동한다

### Gateway HA

Ingress/Egress Gateway를 확장한다.

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        replicaCount: 3
        hpaSpec:
          minReplicas: 3
          maxReplicas: 10
          metrics:
          - type: Resource
            resource:
              name: cpu
              targetAverageUtilization: 80
```

- HPA(Horizontal Pod Autoscaler)로 자동 확장한다
- LoadBalancer Service로 여러 레플리카에 트래픽을 분산한다

### 멀티 클러스터

여러 Kubernetes 클러스터에 걸친 메쉬를 구축한다.

### Primary-Remote 토폴로지

```bash
# Primary 클러스터에 설치
istioctl install --set profile=default \
  --set values.global.meshID=mesh1 \
  --set values.global.multiCluster.clusterName=cluster1 \
  --set values.global.network=network1

# Remote 클러스터 연결
istioctl x create-remote-secret \
  --context=cluster1 \
  --name=cluster1 | \
  kubectl apply -f - --context=cluster2
```

- Primary 클러스터의 Istiod가 Remote 클러스터를 관리한다
- Remote 클러스터의 API 서버 접근을 위한 시크릿을 공유한다
- 클러스터 간 서비스 디스커버리가 자동으로 작동한다

## 업그레이드 전략

### Canary 업그레이드

새 버전의 Istiod를 점진적으로 롤아웃한다.

```bash
# 기존 버전 유지하며 새 버전 설치
istioctl install --set revision=1-20 \
  --set profile=default

# 특정 네임스페이스를 새 버전으로 마이그레이션
kubectl label namespace test istio.io/rev=1-20 --overwrite

# 기존 Pod 재시작하여 새 사이드카 주입
kubectl rollout restart deployment -n test
```

- 여러 Istiod 버전을 동시에 실행한다
- 네임스페이스별로 점진적으로 마이그레이션한다
- 문제 발생 시 즉시 롤백할 수 있다

### In-Place 업그레이드

전체 메쉬를 한 번에 업그레이드한다.

```bash
istioctl upgrade

# 확인
istioctl version
```

- 다운타임 없이 Control Plane을 업그레이드한다
- 기존 사이드카는 계속 작동한다
- Pod를 재시작해야 새 사이드카가 적용된다

## 문제 해결

### 일반적인 이슈

### Sidecar가 주입되지 않음

```bash
# 네임스페이스 레이블 확인
kubectl get namespace -L istio-injection

# Webhook 설정 확인
kubectl get mutatingwebhookconfiguration

# Pod 어노테이션 확인
kubectl get pod <pod-name> -o yaml | grep sidecar.istio.io/inject
```

### mTLS 연결 실패

```bash
# PeerAuthentication 확인
kubectl get peerauthentication --all-namespaces

# DestinationRule의 TLS 모드 확인
kubectl get destinationrule --all-namespaces -o yaml | grep -A 5 tls

# Envoy 설정 확인
istioctl proxy-config cluster <pod-name> -n <namespace>
```

### 라우팅이 작동하지 않음

```bash
# VirtualService 검증
istioctl analyze

# Envoy 라우트 설정 확인
istioctl proxy-config route <pod-name> -n <namespace>

# 로그 확인
kubectl logs <pod-name> -n <namespace> -c istio-proxy
```

### 디버깅 도구

### istioctl 명령어

```bash
# 전체 메쉬 상태 분석
istioctl analyze

# 프록시 상태 확인
istioctl proxy-status

# 프록시 설정 조회
istioctl proxy-config cluster <pod> -n <namespace>
istioctl proxy-config listener <pod> -n <namespace>
istioctl proxy-config route <pod> -n <namespace>
istioctl proxy-config endpoint <pod> -n <namespace>

# 메트릭 확인
istioctl experimental metrics <pod> -n <namespace>
```

### 로그 레벨 조정

```bash
# Envoy 로그 레벨 변경
istioctl proxy-config log <pod> -n <namespace> --level debug

# 특정 컴포넌트만 디버그 모드
istioctl proxy-config log <pod> -n <namespace> --level connection:debug,router:debug
```

## 모범 사례

### 네임스페이스 구조

논리적으로 네임스페이스를 구성한다.

- **환경별 분리**: dev, staging, production
- **팀별 분리**: team-a, team-b
- **애플리케이션별 분리**: app1, app2
- 네임스페이스마다 독립적인 정책 적용

### 리소스 명명 규칙

일관된 네이밍으로 관리를 용이하게 한다.

```yaml
# VirtualService 이름: <service>-vs
# DestinationRule 이름: <service>-dr
# Gateway 이름: <purpose>-gateway

apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews-vs
  namespace: bookinfo
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
```

### 점진적 도입

단계적으로 Istio를 적용한다.

1. **1단계**: 메트릭 수집과 관찰성만 활성화
2. **2단계**: mTLS를 Permissive 모드로 활성화
3. **3단계**: mTLS를 Strict 모드로 전환
4. **4단계**: Authorization Policy 적용
5. **5단계**: 고급 트래픽 관리 기능 활용

### GitOps 통합

Istio 설정을 코드로 관리한다.

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: istio-config
spec:
  source:
    repoURL: https://github.com/myorg/istio-config
    path: production
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

- VirtualService, DestinationRule을 Git으로 버전 관리
- Pull Request로 변경 사항 리뷰
- 자동 배포와 롤백

## 전체 요약

Kubernetes에서 Istio는 기존 네이티브 리소스(Pod, Service, Deployment)를 그대로 활용하면서 사이드카 패턴으로 고급 네트워킹 기능을 투명하게 추가한다. Mutating Webhook으로 자동 사이드카 주입을 수행하고, ServiceAccount를 identity로 사용하여 mTLS를 자동화한다. Kubernetes Service 위에 Virtual Service와 Destination Rule로 세밀한 트래픽 제어를 구현하며, Gateway로 Ingress를 대체할 수 있다. Prometheus, Grafana, Jaeger, Kiali와 통합하여 전체 메쉬를 관찰하고, HPA와 멀티 클러스터로 확장한다. 선택적 기능 비활성화와 Sidecar 리소스로 성능을 최적화하며, Canary 업그레이드로 안전하게 버전을 관리한다. istioctl 도구로 디버깅하고 GitOps로 선언적 관리를 구현한다.
