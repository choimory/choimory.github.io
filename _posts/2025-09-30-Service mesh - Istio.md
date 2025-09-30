---
title: "Service mesh - Istio"
date: 2025-09-30T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
    - Mesh
    - Istio
---

# 선요약

- Ingress
    - 쿠버네티스 전체에 대한 리버스 프록시
    - 외부에서 내부 통신시에 대한 리버스 프록시
    - Kubernetes 차원에서 Ingress를 지원하며 Nginx ingress controller가 대표적인 Ingress 구현체
- Service mesh
    - 각각의 서비스 팟에 대한 리버스 프록시
    - 내부에서 내부 통신시에 대한 리버스 프록시
    - Kubernetes 차원에서 mesh를 지원하며 Istio가 대표적인 구현체
    - Istio의 각각의 프록시를 사이드카로 호칭하며 Envoy가 대표적인 사이드카 구현체

---

# 서비스 메쉬의 개념과 구조

## 서비스 메쉬의 정의

서비스 메쉬는 마이크로서비스 아키텍처에서 서비스 간 통신을 관리하는 전용 인프라 계층이다. 애플리케이션 코드와 분리되어 네트워크 통신을 투명하게 처리하며, 각 서비스 인스턴스 옆에 프록시(사이드카)를 배치하여 모든 네트워크 트래픽을 중개한다.

- 애플리케이션 로직과 네트워크 로직의 분리를 통해 개발자가 비즈니스 로직에만 집중할 수 있게 한다
- 서비스 간 통신의 복잡성을 인프라 레벨에서 해결한다
- 분산 시스템에서 발생하는 통신 문제를 일관되게 처리한다

## 핵심 구성 요소

### 데이터 플레인 (Data Plane)

실제 네트워크 트래픽을 처리하는 계층이다.

- 각 서비스 인스턴스마다 사이드카 프록시가 배치된다
- 모든 인바운드/아웃바운드 트래픽이 이 프록시를 거친다
- Envoy, Linkerd-proxy 등이 대표적인 프록시다
- 요청 라우팅, 로드 밸런싱, 암호화, 인증을 실시간으로 수행한다

### 컨트롤 플레인 (Control Plane)

데이터 플레인을 관리하고 설정하는 중앙 제어 계층이다.

- 모든 프록시의 설정과 정책을 중앙에서 관리한다
- 서비스 디스커버리 정보를 프록시에 배포한다
- 텔레메트리 데이터를 수집하고 집계한다
- 보안 정책과 트래픽 규칙을 배포한다

## 주요 기능

### 트래픽 관리

- **로드 밸런싱**: 라운드 로빈, 최소 연결, 해시 기반 등 다양한 알고리즘을 지원한다
- **서비스 디스커버리**: 동적으로 변하는 서비스 인스턴스를 자동으로 감지한다
- **라우팅 규칙**: URL 경로, 헤더, 가중치 기반으로 트래픽을 분배한다
- **트래픽 분할**: 카나리 배포, A/B 테스트를 위한 점진적 롤아웃을 지원한다
- **서킷 브레이커**: 장애가 있는 서비스로의 요청을 차단하여 연쇄 장애를 방지한다

### 보안

- **mTLS (Mutual TLS)**: 서비스 간 통신을 자동으로 암호화하고 양방향 인증을 수행한다
- **인증/인가**: 서비스 수준의 접근 제어를 구현한다
- **인증서 관리**: 인증서의 자동 발급, 갱신, 순환을 처리한다
- **정책 기반 제어**: 세밀한 접근 정책을 정의하고 강제한다

### 관찰성 (Observability)

- **분산 추적**: 요청이 여러 서비스를 거치는 전체 경로를 추적한다
- **메트릭 수집**: 지연 시간, 에러율, 트래픽 양 등을 자동으로 수집한다
- **로깅**: 모든 요청/응답을 상세히 기록한다
- **시각화**: Grafana, Kiali 등과 연동하여 서비스 간 관계를 시각적으로 보여준다

## 대표적인 서비스 메쉬 구현체

### Istio

가장 널리 사용되는 오픈소스 서비스 메쉬다.

- Envoy를 데이터 플레인 프록시로 사용한다
- 풍부한 기능과 강력한 트래픽 관리 능력을 제공한다
- Kubernetes와의 깊은 통합을 지원한다
- 상대적으로 복잡한 아키텍처와 높은 리소스 사용량이 단점이다

### Linkerd

경량화와 단순성에 초점을 맞춘 서비스 메쉬다.

- Rust로 작성된 자체 프록시를 사용한다
- 낮은 리소스 오버헤드와 빠른 성능을 자랑한다
- 설치와 운영이 상대적으로 간단하다
- CNCF에서 졸업한 프로젝트다

### Consul Connect

HashiCorp의 Consul에 포함된 서비스 메쉬 기능이다.

- 멀티 클라우드와 멀티 플랫폼을 지원한다
- Kubernetes뿐만 아니라 VM 환경도 지원한다
- Consul의 서비스 디스커버리와 자연스럽게 통합된다

## 서비스 메쉬가 필요한 이유

### 마이크로서비스의 복잡성

- 수십, 수백 개의 서비스가 서로 통신하는 환경에서 통신 로직을 각 서비스에 구현하면 중복과 불일치가 발생한다
- 서비스마다 다른 언어와 프레임워크를 사용할 때 일관된 통신 패턴을 구현하기 어렵다
- 네트워크 관련 문제(재시도, 타임아웃, 서킷 브레이킹)를 각 팀이 개별적으로 해결하면 비효율적이다

### 운영상의 이점

- 애플리케이션 코드 수정 없이 트래픽 정책을 변경할 수 있다
- 중앙 집중식 관리로 보안 정책을 일관되게 적용한다
- 전체 시스템의 동작을 실시간으로 관찰하고 문제를 빠르게 진단한다
- 새로운 서비스를 배포할 때 네트워크 관련 인프라를 자동으로 제공받는다

## 도입 시 고려사항

### 복잡성과 학습 곡선

- 새로운 컴포넌트 도입으로 시스템 전체가 복잡해진다
- 팀원들이 서비스 메쉬의 개념과 운영 방법을 학습해야 한다
- 문제 발생 시 디버깅 범위가 넓어진다

### 성능 오버헤드

- 모든 요청이 프록시를 거치면서 약간의 지연이 추가된다
- 사이드카 프록시가 추가 CPU와 메모리를 소비한다
- 소규모 서비스에서는 오버헤드가 이점을 상쇄할 수 있다

### 적용 시점

- 서비스가 10개 미만일 때는 필요하지 않을 수 있다
- 서비스 간 통신 패턴이 단순하다면 더 간단한 솔루션으로 충분하다
- 마이크로서비스 아키텍처가 성숙하고 복잡도가 증가할 때 도입을 고려한다

## 구현 패턴

### 사이드카 패턴

가장 일반적인 구현 방식이다.

- 각 애플리케이션 컨테이너 옆에 프록시 컨테이너를 배치한다
- Kubernetes에서는 같은 Pod 내에 두 컨테이너가 공존한다
- 애플리케이션은 localhost로 통신하면 프록시가 중개한다
- 애플리케이션 코드의 변경이 필요 없다

### Ambient 메쉬

최근 Istio에서 제안한 새로운 방식이다.

- 사이드카 없이 노드 레벨에서 트래픽을 처리한다
- 리소스 오버헤드를 크게 줄인다
- 기본 기능은 ambient 모드로, 고급 기능이 필요할 때만 사이드카를 추가한다

## 전체 요약

서비스 메쉬는 마이크로서비스 간 통신을 관리하는 전용 인프라 계층으로, 애플리케이션 코드와 분리하여 네트워크 로직을 처리한다. 데이터 플레인의 사이드카 프록시가 실제 트래픽을 중개하고, 컨트롤 플레인이 이를 중앙에서 관리한다. 트래픽 관리, 보안(mTLS), 관찰성 등의 기능을 제공하여 복잡한 마이크로서비스 환경에서 일관된 통신 패턴을 구현한다. Istio, Linkerd, Consul Connect 같은 구현체가 있으며, 각각 특성이 다르다. 도입 시 복잡성과 오버헤드를 고려해야 하며, 서비스 규모와 복잡도가 충분히 클 때 그 가치가 드러난다.

---

# Istio의 개념과 아키텍처

## Istio란 무엇인가

Istio는 Google, IBM, Lyft가 공동 개발한 오픈소스 서비스 메쉬 플랫폼이다. 마이크로서비스 간 통신을 연결, 보호, 제어, 관찰하는 기능을 제공하며, 현재 가장 널리 사용되는 서비스 메쉬 구현체다.

- 애플리케이션 코드 수정 없이 서비스 메쉬 기능을 투명하게 추가한다
- Kubernetes 환경에서 가장 잘 작동하지만 VM 환경도 지원한다
- Envoy 프록시를 데이터 플레인으로 사용하여 검증된 성능과 안정성을 보장한다
- CNCF(Cloud Native Computing Foundation) 프로젝트로 활발히 발전하고 있다

## 핵심 아키텍처

### Istiod (Control Plane)

Istio 1.5 버전부터 여러 컴포넌트가 단일 바이너리로 통합되었다.

- **Pilot**: 서비스 디스커버리와 트래픽 관리를 담당한다
- **Citadel**: 인증서 발급과 순환을 자동화한다
- **Galley**: 설정 검증과 배포를 처리한다
- Kubernetes API 서버와 통신하여 서비스와 엔드포인트 정보를 수집한다
- 모든 Envoy 프록시에 설정을 배포하고 동기화한다
- 단일 컨트롤 플레인으로 통합되어 배포와 운영이 간소화되었다

### Envoy Proxy (Data Plane)

각 서비스의 사이드카로 배치되는 고성능 프록시다.

- C++로 작성되어 뛰어난 성능과 낮은 메모리 사용량을 자랑한다
- 동적 설정을 지원하여 재시작 없이 설정을 변경할 수 있다
- HTTP/1.1, HTTP/2, gRPC, TCP 등 다양한 프로토콜을 지원한다
- 풍부한 메트릭과 로그를 자동으로 생성한다
- xDS API를 통해 Istiod로부터 동적으로 설정을 받는다

### Ingress/Egress Gateway

클러스터 경계에서 트래픽을 제어하는 특수한 Envoy 프록시다.

- **Ingress Gateway**: 외부에서 들어오는 트래픽의 진입점이다
- **Egress Gateway**: 클러스터 내부에서 외부로 나가는 트래픽을 제어한다
- 로드 밸런싱, TLS 종료, 라우팅 규칙 적용을 담당한다
- 단일 진입/이탈점을 제공하여 보안 정책을 집중 관리한다

## 트래픽 관리 기능

### Virtual Service

서비스로 향하는 트래픽의 라우팅 규칙을 정의한다.

- HTTP 헤더, URI, 쿠키 등을 기반으로 요청을 라우팅한다
- 가중치 기반 트래픽 분배로 카나리 배포를 구현한다
- 재시도, 타임아웃, 장애 주입 등의 정책을 설정한다
- 여러 버전의 서비스 간 트래픽 비율을 세밀하게 조정한다
- 예를 들어 v1에 90%, v2에 10%의 트래픽을 보낼 수 있다

### Destination Rule

서비스의 하위 집합(subset)과 정책을 정의한다.

- 서비스의 여러 버전을 subset으로 그룹화한다
- 로드 밸런싱 알고리즘을 지정한다(라운드 로빈, 랜덤, 최소 요청)
- 연결 풀 크기와 아웃라이어 감지 설정을 구성한다
- TLS 설정과 서킷 브레이커 정책을 적용한다

### Gateway

클러스터 경계에서의 트래픽을 관리한다.

- 어떤 포트와 프로토콜을 노출할지 정의한다
- TLS 인증서와 SNI 설정을 구성한다
- Virtual Service와 결합하여 외부 트래픽 라우팅을 완성한다
- Kubernetes Ingress보다 더 풍부한 기능을 제공한다

### Service Entry

메쉬 외부 서비스를 메쉬에 등록한다.

- 외부 API나 레거시 시스템을 서비스 메쉬에 통합한다
- 외부 서비스에 대한 트래픽도 동일한 정책으로 관리한다
- DNS 해상도 설정과 엔드포인트를 명시적으로 지정한다

## 보안 기능

### 자동 mTLS

서비스 간 통신을 자동으로 암호화하고 인증한다.

- 각 서비스에 고유한 SPIFFE ID를 부여한다
- X.509 인증서를 자동으로 발급하고 순환한다(기본 90일)
- 애플리케이션 코드 수정 없이 전송 계층 보안을 제공한다
- Permissive 모드로 점진적 마이그레이션을 지원한다(평문과 mTLS 동시 허용)
- Strict 모드에서는 mTLS만 허용하여 높은 보안을 보장한다

### Authorization Policy

세밀한 접근 제어를 구현한다.

- 서비스, 네임스페이스, 메서드 수준의 접근 제어를 정의한다
- ALLOW, DENY, CUSTOM 액션을 지원한다
- 요청의 소스(서비스 계정, IP), 작업(HTTP 메서드, 경로), 조건을 기준으로 평가한다
- JWT 토큰 검증과 클레임 기반 인가를 수행한다

### Peer Authentication

mTLS 모드를 설정한다.

- STRICT: mTLS만 허용
- PERMISSIVE: mTLS와 평문 모두 허용
- DISABLE: mTLS 비활성화
- 워크로드 수준, 네임스페이스 수준, 메쉬 수준에서 설정 가능하다

### Request Authentication

JWT 기반 인증을 구성한다.

- OIDC 제공자(Auth0, Keycloak 등)와 통합한다
- JWT 발급자와 공개 키를 검증한다
- 유효하지 않은 토큰을 가진 요청을 거부한다

## 관찰성 기능

### 메트릭 수집

모든 트래픽에 대한 상세한 메트릭을 자동 생성한다.

- 요청 수, 지연 시간, 에러율을 측정한다
- RED 메트릭(Rate, Errors, Duration)을 기본 제공한다
- Prometheus 형식으로 메트릭을 노출한다
- Golden Signals(지연, 트래픽, 에러, 포화도)를 추적한다

### 분산 추적

요청이 여러 서비스를 거치는 경로를 추적한다.

- Jaeger, Zipkin, Lightstep과 통합된다
- B3 전파 헤더를 자동으로 추가한다
- 애플리케이션은 헤더만 전파하면 나머지는 Istio가 처리한다
- 병목 지점과 장애 발생 위치를 시각적으로 파악한다

### 접근 로그

모든 요청/응답을 상세히 기록한다.

- 요청 메서드, 경로, 상태 코드, 지연 시간을 로깅한다
- 표준 출력이나 파일로 로그를 출력한다
- 커스텀 로그 포맷을 정의할 수 있다

### Kiali 대시보드

서비스 메쉬를 시각화하는 웹 UI다.

- 서비스 간 의존성을 그래프로 표현한다
- 실시간 트래픽 흐름과 에러를 시각화한다
- Istio 설정을 검증하고 문제를 진단한다
- Virtual Service, Destination Rule 등을 GUI로 관리한다

## 고급 트래픽 관리 패턴

### 카나리 배포

새 버전을 점진적으로 롤아웃한다.

- Virtual Service에서 가중치를 조절하여 트래픽 비율을 변경한다
- 10% → 50% → 100%로 단계적으로 증가시킨다
- 문제 발생 시 즉시 이전 버전으로 롤백한다
- Flagger 같은 도구와 연동하여 자동화한다

### A/B 테스팅

특정 사용자 그룹에게 다른 버전을 제공한다.

- HTTP 헤더(사용자 ID, 쿠키)를 기반으로 라우팅한다
- 특정 조건을 만족하는 요청만 새 버전으로 보낸다
- 두 버전의 성능을 비교 분석한다

### 미러링

프로덕션 트래픽을 복제하여 테스트한다.

- 실제 요청을 라이브 버전과 테스트 버전에 동시에 전송한다
- 테스트 버전의 응답은 무시하고 라이브 버전의 응답만 사용자에게 반환한다
- 실제 트래픽 패턴으로 새 버전을 검증한다

### 서킷 브레이킹

장애가 있는 서비스로의 요청을 차단한다.

- 연속된 오류가 임계값을 초과하면 회로를 차단한다
- 일정 시간 후 일부 요청을 허용하여 회복 여부를 확인한다
- 연쇄 장애 전파를 방지하고 시스템 안정성을 높인다

### 재시도와 타임아웃

일시적 장애를 자동으로 처리한다.

- 실패한 요청을 자동으로 재시도한다
- 지수 백오프와 지터를 적용하여 부하를 분산한다
- 요청당 최대 대기 시간을 설정하여 무한 대기를 방지한다

### 장애 주입

시스템의 복원력을 테스트한다.

- 특정 비율의 요청에 지연을 주입한다
- 일부 요청을 강제로 실패시킨다
- 카오스 엔지니어링을 실천하여 시스템 취약점을 발견한다

## 설치와 구성

### 설치 프로파일

사용 사례에 맞는 프리셋 구성이다.

- **default**: 프로덕션 배포용 기본 구성
- **demo**: 학습과 테스트용으로 모든 기능 포함
- **minimal**: 최소한의 컴포넌트만 설치
- **preview**: 실험적 기능 포함
- **empty**: 커스텀 구성을 위한 빈 프로파일

### Sidecar 주입

서비스에 Envoy 프록시를 추가하는 방법이다.

- **자동 주입**: 네임스페이스에 `istio-injection=enabled` 레이블 추가
- **수동 주입**: `istioctl kube-inject` 명령으로 명시적 주입
- Pod 생성 시 Mutating Admission Webhook이 사이드카를 자동 삽입한다
- 기존 애플리케이션 YAML 수정이 불필요하다

### IstioOperator

선언적 방식으로 Istio를 설치하고 관리한다.

- YAML로 원하는 구성을 정의한다
- 컴포넌트별 활성화/비활성화와 리소스 할당을 설정한다
- `istioctl` 또는 Operator를 통해 적용한다

## 멀티 클러스터 구성

여러 Kubernetes 클러스터에 걸친 서비스 메쉬를 구축한다.

### Primary-Remote

하나의 컨트롤 플레인이 여러 클러스터를 관리한다.

- Primary 클러스터에만 Istiod가 설치된다
- Remote 클러스터는 Primary의 컨트롤 플레인을 사용한다
- 관리가 간단하지만 Primary가 단일 장애점이 된다

### Multi-Primary

각 클러스터에 독립적인 컨트롤 플레인이 있다.

- 높은 가용성과 지역 복원력을 제공한다
- 클러스터 간 서비스 디스커버리가 필요하다
- 더 복잡한 네트워크 구성이 필요하다

### 네트워크 구성

- **단일 네트워크**: 모든 Pod가 직접 통신 가능
- **다중 네트워크**: East-West Gateway를 통한 통신

## 성능과 최적화

### 리소스 사용

Istio는 상당한 오버헤드를 발생시킨다.

- Envoy 사이드카당 약 50-100MB 메모리 사용
- 요청당 1-3ms의 추가 지연 발생
- CPU 사용량은 트래픽 양에 비례하여 증가한다
- 대규모 클러스터에서는 Istiod도 상당한 리소스를 소비한다

### 최적화 전략

- **선택적 배포**: 필요한 서비스에만 사이드카를 주입한다
- **리소스 튜닝**: 사이드카의 CPU/메모리 요청과 제한을 조정한다
- **프로토콜 선택**: HTTP/2와 gRPC 사용으로 오버헤드를 줄인다
- **메트릭 필터링**: 불필요한 메트릭 수집을 비활성화한다
- **Ambient 메쉬**: 사이드카 없는 경량 모드를 사용한다

## Ambient 메쉬 (신규 아키텍처)

Istio 1.18에서 도입된 사이드카 없는 구조다.

### Ztunnel (Zero-Trust Tunnel)

노드 레벨에서 작동하는 경량 프록시다.

- 각 노드에 하나의 ztunnel만 배치된다
- mTLS, 텔레메트리, L4 인가를 처리한다
- 사이드카 대비 리소스 사용량이 크게 감소한다

### Waypoint Proxy

L7 기능이 필요할 때만 선택적으로 배치한다.

- Virtual Service, 장애 주입 등 고급 기능을 제공한다
- 서비스나 네임스페이스 수준에서 배포한다
- 세밀한 제어가 필요한 곳에만 추가 오버헤드를 부담한다

### 장점

- 애플리케이션 Pod 재시작 없이 Istio를 도입/제거할 수 있다
- 전체 리소스 사용량이 50% 이상 감소한다
- 점진적 도입이 더욱 쉬워진다

## 문제 해결과 디버깅

### istioctl 도구

명령줄에서 Istio를 관리하고 진단한다.

- `istioctl analyze`: 구성 오류를 검출한다
- `istioctl proxy-status`: 모든 프록시의 상태를 확인한다
- `istioctl proxy-config`: Envoy 설정을 조회한다
- `istioctl dashboard`: Kiali, Grafana 등을 실행한다

### 일반적인 문제

- **사이드카 미주입**: 네임스페이스 레이블 확인
- **mTLS 실패**: PeerAuthentication 정책 충돌 검사
- **라우팅 불일치**: Virtual Service와 Destination Rule의 subset 이름 일치 확인
- **Gateway 연결 실패**: Gateway와 Virtual Service의 hosts 매칭 확인

### 로깅 레벨 조정

더 상세한 디버깅 정보를 수집한다.

- Envoy 로그 레벨을 동적으로 변경한다
- 특정 컴포넌트만 debug 레벨로 설정한다
- 문제 해결 후 다시 info 레벨로 복원한다

## 전체 요약

Istio는 Envoy 프록시 기반의 강력한 서비스 메쉬 플랫폼으로, Istiod 컨트롤 플레인이 모든 사이드카를 중앙 관리한다. Virtual Service, Destination Rule, Gateway 등의 리소스로 트래픽을 세밀하게 제어하며, 자동 mTLS과 Authorization Policy로 보안을 강화한다. 메트릭, 추적, 로깅을 자동 생성하여 전체 시스템을 관찰할 수 있고, Kiali로 시각화한다. 카나리 배포, A/B 테스트, 서킷 브레이킹 같은 고급 패턴을 코드 변경 없이 구현한다. 리소스 오버헤드가 있지만 새로운 Ambient 메쉬로 이를 크게 줄일 수 있다. istioctl 도구와 다양한 진단 기능으로 문제를 해결하며, 멀티 클러스터 구성으로 확장 가능하다.

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

yaml

```kotlin
*# 네임스페이스 레벨 활성화*
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    istio-injection: enabled

*# Pod 레벨 비활성화*
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

yaml

```kotlin
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews  *# Kubernetes Service 이름*
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

yaml

```kotlin
*# Kubernetes Deployments*
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
*# Istio Destination Rule*
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

yaml

```kotlin
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

bash

```kotlin
*# 설치*
istioctl install --set profile=demo

*# 특정 네임스페이스 사이드카 자동 주입 활성화*
kubectl label namespace default istio-injection=enabled

*# 설치 검증*
istioctl verify-install
```

- 프로파일별로 사전 구성된 설정을 제공한다
- 설치 전 검증을 수행한다
- 업그레이드와 제거가 간편하다

### Helm Chart 설치

GitOps 워크플로우에 적합하다.

bash

```kotlin
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system
```

- 버전 관리가 용이하다
- ArgoCD, FluxCD와 쉽게 통합된다
- 선언적 방식으로 관리한다

### Operator 기반 설치

Kubernetes Operator 패턴을 활용한다.

yaml

```kotlin
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

bash

```kotlin
*# 프로덕션 네임스페이스만 메쉬 적용*
kubectl label namespace production istio-injection=enabled

*# 개발 네임스페이스는 메쉬 없이 운영*
kubectl label namespace development istio-injection=disabled
```

- 점진적으로 메쉬를 도입할 수 있다
- 레거시 애플리케이션과 공존이 가능하다
- 테스트와 프로덕션을 분리 운영한다

### 네임스페이스별 정책

yaml

```kotlin
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

yaml

```kotlin
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
      serviceAccountName: httpbin  *# 이 SA를 identity로 사용*
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

yaml

```kotlin
*# Kubernetes Network Policy*
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
*# Istio Authorization Policy*
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

promql

```kotlin
*# 요청률*
rate(istio_requests_total[5m])

*# 에러율*
rate(istio_requests_total{response_code=~"5.."}[5m])

*# 레이턴시 (P99)*
histogram_quantile(0.99, rate(istio_request_duration_milliseconds_bucket[5m]))

*# 서비스별 트래픽*
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

yaml

```kotlin
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

bash

```kotlin
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

*# 접근*
istioctl dashboard kiali
```

## 성능 최적화

### Resource 요구사항

Istio는 추가 리소스를 소비한다.

### Sidecar 리소스

yaml

```kotlin
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

yaml

```kotlin
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

yaml

```kotlin
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    *# 접근 로그 비활성화*
    accessLogFile: ""
    *# 추적 샘플링 비율 조정*
    defaultConfig:
      tracing:
        sampling: 1.0  *# 1%만 추적*
```

### Sidecar 리소스 범위 제한

각 사이드카가 알아야 하는 설정을 제한한다.

yaml

```kotlin
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
  namespace: production
spec:
  egress:
  - hosts:
    - "./*"  *# 같은 네임스페이스만*
    - "istio-system/*"  *# istio-system 네임스페이스*
```

- 기본적으로 사이드카는 전체 메쉬의 설정을 받는다
- Sidecar 리소스로 범위를 제한하면 메모리 사용량이 감소한다
- 대규모 클러스터에서 특히 효과적이다

## 고가용성과 확장성

### Control Plane HA

Istiod를 고가용성으로 배포한다.

yaml

```kotlin
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

yaml

```kotlin
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

bash

```kotlin
*# Primary 클러스터에 설치*
istioctl install --set profile=default \
  --set values.global.meshID=mesh1 \
  --set values.global.multiCluster.clusterName=cluster1 \
  --set values.global.network=network1

*# Remote 클러스터 연결*
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

bash

```kotlin
*# 기존 버전 유지하며 새 버전 설치*
istioctl install --set revision=1-20 \
  --set profile=default

*# 특정 네임스페이스를 새 버전으로 마이그레이션*
kubectl label namespace test istio.io/rev=1-20 --overwrite

*# 기존 Pod 재시작하여 새 사이드카 주입*
kubectl rollout restart deployment -n test
```

- 여러 Istiod 버전을 동시에 실행한다
- 네임스페이스별로 점진적으로 마이그레이션한다
- 문제 발생 시 즉시 롤백할 수 있다

### In-Place 업그레이드

전체 메쉬를 한 번에 업그레이드한다.

bash

```kotlin
istioctl upgrade

*# 확인*
istioctl version
```

- 다운타임 없이 Control Plane을 업그레이드한다
- 기존 사이드카는 계속 작동한다
- Pod를 재시작해야 새 사이드카가 적용된다

## 문제 해결

### 일반적인 이슈

### Sidecar가 주입되지 않음

bash

```kotlin
*# 네임스페이스 레이블 확인*
kubectl get namespace -L istio-injection

*# Webhook 설정 확인*
kubectl get mutatingwebhookconfiguration

*# Pod 어노테이션 확인*
kubectl get pod <pod-name> -o yaml | grep sidecar.istio.io/inject
```

### mTLS 연결 실패

bash

```kotlin
*# PeerAuthentication 확인*
kubectl get peerauthentication --all-namespaces

*# DestinationRule의 TLS 모드 확인*
kubectl get destinationrule --all-namespaces -o yaml | grep -A 5 tls

*# Envoy 설정 확인*
istioctl proxy-config cluster <pod-name> -n <namespace>
```

### 라우팅이 작동하지 않음

bash

```kotlin
*# VirtualService 검증*
istioctl analyze

*# Envoy 라우트 설정 확인*
istioctl proxy-config route <pod-name> -n <namespace>

*# 로그 확인*
kubectl logs <pod-name> -n <namespace> -c istio-proxy
```

### 디버깅 도구

### istioctl 명령어

bash

```kotlin
*# 전체 메쉬 상태 분석*
istioctl analyze

*# 프록시 상태 확인*
istioctl proxy-status

*# 프록시 설정 조회*
istioctl proxy-config cluster <pod> -n <namespace>
istioctl proxy-config listener <pod> -n <namespace>
istioctl proxy-config route <pod> -n <namespace>
istioctl proxy-config endpoint <pod> -n <namespace>

*# 메트릭 확인*
istioctl experimental metrics <pod> -n <namespace>
```

### 로그 레벨 조정

bash

```kotlin
*# Envoy 로그 레벨 변경*
istioctl proxy-config log <pod> -n <namespace> --level debug

*# 특정 컴포넌트만 디버그 모드*
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

yaml

```kotlin
*# VirtualService 이름: <service>-vs# DestinationRule 이름: <service>-dr# Gateway 이름: <purpose>-gateway*

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

yaml

```kotlin
*# ArgoCD Application*
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

bash

```kotlin
*# 이 명령 하나로 끝*
kubectl label namespace default istio-injection=enabled
```

이게 전부다. 이제 `default` 네임스페이스에서 생성되는 모든 Pod에 자동으로 Envoy 사이드카가 추가된다.

### 2단계: 기존 Deployment 그대로 사용

yaml

```kotlin
*# 개발자가 작성하는 YAML - Istio 관련 내용 전혀 없음*
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default  *# istio-injection=enabled된 네임스페이스*
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

yaml

```kotlin
*# Kubernetes가 실제로 생성하는 Pod - 자동으로 변환됨*
apiVersion: v1
kind: Pod
metadata:
  name: my-app-xxxxx
  namespace: default
  annotations:
    sidecar.istio.io/status: '{"version":"...","initContainers":[...],"containers":[...]}'
spec:
  *# Init Container가 자동 추가됨*
  initContainers:
  - name: istio-init
    image: istio/proxyv2:1.20.0
    command: ['istio-iptables', ...]  *# iptables 규칙 설정*
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
  
  *# 원래의 애플리케이션 컨테이너*
  containers:
  - name: my-app
    image: my-app:v1
    ports:
    - containerPort: 8080
  
  *# Envoy 사이드카가 자동 추가됨*
  - name: istio-proxy
    image: istio/proxyv2:1.20.0
    args: ['proxy', 'sidecar', ...]
    ports:
    - containerPort: 15090  *# Prometheus 메트릭*
    - containerPort: 15021  *# Health check*
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

```kotlin
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

bash

```kotlin
*# Istio가 설치한 Webhook 확인*
kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml
```

yaml

```kotlin
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector
webhooks:
- name: sidecar-injector.istio.io
  namespaceSelector:
    matchLabels:
      istio-injection: enabled  *# 이 레이블 있는 네임스페이스만 처리*
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

bash

```kotlin
*# 프로덕션: Istio 활성화*
kubectl label namespace production istio-injection=enabled

*# 스테이징: Istio 활성화*
kubectl label namespace staging istio-injection=enabled

*# 개발: Istio 비활성화 (레거시 테스트)*
kubectl label namespace development istio-injection=disabled

*# 레이블 확인*
kubectl get namespace -L istio-injection
```

```kotlin
NAME          STATUS   AGE   ISTIO-INJECTION
default       Active   10d   
production    Active   5d    enabled
staging       Active   5d    enabled
development   Active   5d    disabled
```

### 점진적 마이그레이션

기존 운영 중인 서비스에 Istio를 도입할 때의 전략이다.

bash

```kotlin
*# 1단계: 테스트 네임스페이스에만 적용*
kubectl label namespace test istio-injection=enabled
kubectl rollout restart deployment -n test

*# 2단계: 스테이징 확인*
kubectl label namespace staging istio-injection=enabled
kubectl rollout restart deployment -n staging

*# 3단계: 프로덕션 서비스별로 점진적 적용*
kubectl label namespace production istio-injection=enabled
kubectl rollout restart deployment my-app-1 -n production
*# 모니터링...*
kubectl rollout restart deployment my-app-2 -n production
*# 모니터링...*
```

## Pod 레벨 제어

특정 Pod만 예외 처리하고 싶을 때 사용한다.

### 네임스페이스는 활성화, 특정 Pod만 비활성화

yaml

```kotlin
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: production  *# istio-injection=enabled*
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"  *# 이 Pod만 사이드카 제외*
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

yaml

```kotlin
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-app
  namespace: development  *# istio-injection=disabled*
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"  *# 이 Pod만 사이드카 추가*
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

bash

```kotlin
*# YAML 파일에 사이드카를 추가한 버전 생성*
istioctl kube-inject -f deployment.yaml > deployment-injected.yaml

*# 확인*
cat deployment-injected.yaml  *# istio-proxy 컨테이너가 포함됨# 배포*
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

bash

```kotlin
*# 1. 네임스페이스 생성 및 Istio 활성화*
kubectl create namespace my-service
kubectl label namespace my-service istio-injection=enabled

*# 2. 기존 Deployment YAML 그대로 배포*
kubectl apply -f deployment.yaml -n my-service

*# 3. Pod 확인 - 자동으로 2개 컨테이너 실행*
kubectl get pods -n my-service
```

```kotlin
NAME                         READY   STATUS    RESTARTS   AGE
my-service-5d8f6c9b7-abcde   2/2     Running   0          30s
```

`2/2`가 핵심이다:

- 첫 번째 2: 실행 중인 컨테이너 수
- 두 번째 2: 전체 컨테이너 수 (my-app + istio-proxy)

### 사이드카 확인

bash

```kotlin
*# Pod 상세 정보 확인*
kubectl describe pod my-service-5d8f6c9b7-abcde -n my-service
```

```kotlin
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

bash

```kotlin
*# Istio 1.19 설치 (기존)*
istioctl install --set revision=1-19

*# Istio 1.20 설치 (신규)*
istioctl install --set revision=1-20
```

### 네임스페이스별 버전 선택

bash

```kotlin
*# 프로덕션: 안정적인 1.19 사용*
kubectl label namespace production istio.io/rev=1-19

*# 스테이징: 새로운 1.20 테스트*
kubectl label namespace staging istio.io/rev=1-20

*# 기존 istio-injection 레이블 제거*
kubectl label namespace production istio-injection-
kubectl label namespace staging istio-injection-
```

### 서비스별 점진적 업그레이드

bash

```kotlin
*# Service A를 1.20으로 업그레이드*
kubectl label namespace service-a istio.io/rev=1-20 --overwrite
kubectl rollout restart deployment -n service-a

*# 모니터링 후 문제없으면 Service B도 업그레이드*
kubectl label namespace service-b istio.io/rev=1-20 --overwrite
kubectl rollout restart deployment -n service-b
```

## 리소스 사용량 커스터마이징

사이드카의 리소스를 조정하고 싶을 때는 어떻게 할까?

### 글로벌 설정 변경

yaml

```kotlin
*# IstioOperator로 전역 사이드카 리소스 설정*
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
            cpu: 50m      *# 기본 100m에서 감소*
            memory: 64Mi  *# 기본 128Mi에서 감소*
          limits:
            cpu: 500m
            memory: 512Mi
```

### Pod별 리소스 오버라이드

yaml

```kotlin
apiVersion: apps/v1
kind: Deployment
metadata:
  name: high-traffic-app
spec:
  template:
    metadata:
      annotations:
        *# 이 Pod의 사이드카만 더 많은 리소스 할당*
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

yaml

```kotlin
*# 개발자가 작성하는 YAML*
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

yaml

```kotlin
*# 개발자가 작성하는 YAML - 완전히 동일!*
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

bash

```kotlin
*# 플랫폼 팀이 한 번만 실행*
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

```kotlin
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

```kotlin
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

```kotlin
Before Istio:
Service A → Service B
(직접 연결)

After Istio:
Service A → [Envoy A] → [Envoy B] → Service B
            ↑                    ↑
         사이드카            사이드카
```

### 구체적으로 하는 일

yaml

```kotlin
*# 트래픽 분배 (카나리 배포)*
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
      weight: 90  *# 구버전 90%*
    - destination:
        host: reviews
        subset: v2
      weight: 10  *# 신버전 10%*
```

```kotlin
100개 요청 중:
→ 90개는 v1으로
→ 10개는 v2로
→ 사이드카가 자동으로 분배
→ 애플리케이션 코드는 모름
```

### 재시도 및 타임아웃

yaml

```kotlin
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
      attempts: 3         *# 3번 재시도*
      perTryTimeout: 2s   *# 각 시도당 2초*
    timeout: 10s          *# 전체 10초*
```

애플리케이션에서 재시도 로직을 구현할 필요 없다. 사이드카가 자동 처리한다.

### 서킷 브레이커

yaml

```kotlin
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
      consecutiveErrors: 5       *# 5번 연속 실패하면*
      interval: 30s
      baseEjectionTime: 30s      *# 30초 동안 격리*
      maxEjectionPercent: 50
```

```kotlin
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

```kotlin
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

```kotlin
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

yaml

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
사이드카가 자동 생성:
[2025-01-15T10:30:45.123Z] "GET /api/products HTTP/1.1" 200 
- "-" "-" 0 1234 5 4 "-" "curl/7.68.0" 
"abc-123-xyz" "productpage.default.svc.cluster.local" 
"10.244.1.5:9080" inbound|9080|| 127.0.0.1:9080 
10.244.1.3:34567 10.244.1.5:9080
```

### 5. 트래픽 가시성

### Kiali 대시보드

```kotlin
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

```kotlin
프로메테우스 = 메트릭 저장소 + 쿼리 엔진

- 메트릭을 수집해서 저장
- PromQL로 쿼리
- 알람 설정
- Grafana로 시각화
```

### Istio의 역할

```kotlin
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

python

```kotlin
*# 애플리케이션 코드 - 변경 없음*
import requests

response = requests.get('http://reviews:9080/api/reviews')
```

```kotlin
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

```kotlin
Pod 100개 클러스터:
- 사이드카 없음: 10GB
- 사이드카 있음: 10GB + (100 * 100MB) = 20GB

메모리가 2배로 증가
```

### CPU

```kotlin
요청당 처리 시간:
- 직접 통신: 1ms
- Istio 경유: 1ms + 0.5ms (사이드카) + 0.5ms (사이드카) = 2ms

약 2배의 레이턴시 증가
```

### 복잡성

```kotlin
디버깅 경로:
Before: App A → App B (1 hop)
After:  App A → Proxy A → Proxy B → App B (3 hops)

문제 발생 시 어디가 원인인지 찾기 어려움
```

## 실제 사용 예시: 전체 흐름

### 시나리오: 온라인 쇼핑몰

yaml

```kotlin
*# 서비스 구조*
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

```kotlin
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

yaml

```kotlin
*# 1. 카나리 배포*
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
      weight: 95  *# 95%는 안전한 v1*
    - destination:
        host: reviews
        subset: v2
      weight: 5   *# 5%만 v2로 테스트*
```

yaml

```kotlin
*# 2. 복원력*
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
    timeout: 5s       *# 5초 초과하면 실패*
    retries:
      attempts: 3     *# 자동 재시도*
      perTryTimeout: 2s
```

yaml

```kotlin
*# 3. 보안 - Ratings는 Reviews만 호출 가능*
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

```kotlin
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

```kotlin
                  ┌─────────┐
외부 요청  ───→  │ Nginx   │  ───→  Backend Servers
                  │(리버스  │         - Server 1
                  │ 프록시) │         - Server 2
                  └─────────┘         - Server 3
                  
하나의 Nginx가 여러 백엔드로 트래픽 분배
```

### Istio 패턴 (분산 리버스 프록시)

```kotlin
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

nginx

```kotlin
*# nginx.conf*
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

yaml

```kotlin
*# 동적 설정 - Istiod가 자동 전송*
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

nginx

```kotlin
upstream backend {
    least_conn;  *# 최소 연결 방식*
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}
```

### Envoy (Istio)

yaml

```kotlin
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN  *# 최소 연결 방식*
```

둘 다 동일한 로드 밸런싱 기능을 제공한다.

### 2. 타임아웃

### Nginx

nginx

```kotlin
location /api {
    proxy_pass http://backend;
    proxy_connect_timeout 5s;
    proxy_read_timeout 10s;
}
```

### Envoy (Istio)

yaml

```kotlin
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

nginx

```kotlin
location / {
    proxy_pass http://backend;
    proxy_next_upstream error timeout;
    proxy_next_upstream_tries 3;
}
```

### Envoy (Istio)

yaml

```kotlin
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

nginx

```kotlin
location / {
    proxy_pass http://backend;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### Envoy (Istio)

yaml

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
1. 외부 요청
   User → Nginx → Service A

2. 내부 서비스 간 통신 (프록시 거치지 않음)
   Service A → Service B (직접 연결)
   
3. 문제점
   - 내부 통신은 제어 불가
   - Service A와 B 사이는 "블랙박스"
```

### Istio 방식

```kotlin
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

nginx

```kotlin
*# nginx.conf*
upstream backend {
    *# 90% 트래픽*
    server backend-v1-1:8080 weight=9;
    server backend-v1-2:8080 weight=9;
    server backend-v1-3:8080 weight=9;
    
    *# 10% 트래픽*
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

yaml

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

nginx

```kotlin
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

yaml

```kotlin
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

```kotlin
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

```kotlin
Nginx 인스턴스: 3개 (HA)
메모리: 3 * 200MB = 600MB
CPU: 3 * 0.5 core = 1.5 cores

총 리소스: 600MB, 1.5 cores
```

### Istio (분산)

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

yaml

```kotlin
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

```kotlin
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

yaml

```kotlin
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: domain-routing
spec:
  rules:
  - host: api.example.com      *# API 트래픽*
    http:
      paths:
      - path: /
        backend:
          service:
            name: api-service
  - host: web.example.com      *# 웹 트래픽*
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
```

```kotlin
api.example.com → api-service
web.example.com → web-service
```

### 2. 경로 기반 라우팅

yaml

```kotlin
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api        *# /api/* → api-service*
        backend:
          service:
            name: api-service
      - path: /admin      *# /admin/* → admin-service*
        backend:
          service:
            name: admin-service
      - path: /           *# /* → frontend-service*
        backend:
          service:
            name: frontend-service
```

### 3. TLS 종료

yaml

```kotlin
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret  *# TLS 인증서*
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
```

```kotlin
HTTPS (암호화) → Ingress → HTTP (평문) → Service
                  ↑
            TLS 종료 지점
```

### Ingress가 못하는 일

```kotlin
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

```kotlin
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

yaml

```kotlin
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews  *# Kubernetes Service 이름*
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2    *# 특정 사용자는 v2로*
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 90      *# 90%는 v1*
    - destination:
        host: reviews
        subset: v3
      weight: 10      *# 10%는 v3*
```

```kotlin
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

yaml

```kotlin
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  *# 모든 통신 암호화 강제*
```

```kotlin
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

yaml

```kotlin
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
        - "cluster.local/ns/default/sa/backend"  *# backend만*
    to:
    - operation:
        methods: ["GET", "POST"]  *# GET, POST만*
        paths: ["/api/query"]     *# 이 경로만*
```

```kotlin
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

yaml

```kotlin
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
    timeout: 5s           *# 5초 타임아웃*
    retries:
      attempts: 3         *# 3번 재시도*
      perTryTimeout: 2s   *# 각 시도당 2초*
      retryOn: 5xx        *# 5xx 에러 시 재시도*
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  trafficPolicy:
    outlierDetection:
      consecutiveErrors: 5      *# 5번 연속 실패하면*
      interval: 30s
      baseEjectionTime: 30s     *# 30초 동안 격리*
```

```kotlin
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

```kotlin
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

yaml

```kotlin
*# NGINX Ingress로는 가중치 라우팅이 어려움# 어노테이션으로 일부 가능하지만 복잡*

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
            name: app-v2  *# 10% 트래픽*
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
            name: app-v1  *# 90% 트래픽*
```

문제점:

- 외부 진입 트래픽에만 적용
- 내부 서비스 간 통신은 여전히 직접
- 복잡하고 Ingress Controller 의존적

### Istio로 구현 (완벽)

yaml

```kotlin
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
      weight: 90  *# 90%*
    - destination:
        host: app
        subset: v2
      weight: 10  *# 10%*
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

```kotlin
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

yaml

```kotlin
*# 1. NGINX Ingress (외부 진입)*
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: external-ingress
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"  *# Rate limit*
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
            name: istio-ingressgateway  *# Istio Gateway로 전달*
            port:
              number: 80
---
*# 2. Istio Gateway (클러스터 경계)*
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
*# 3. Istio VirtualService (내부 라우팅)*
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
      weight: 10  *# 내부 카나리 배포*
```

## 구체적 시나리오: 마이크로서비스 아키텍처

### Ingress만 사용

```kotlin
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

```kotlin
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

```kotlin
- 단순한 애플리케이션 (5개 미만 서비스)
- 외부 진입 제어만 필요
- 내부 통신이 단순
- 리소스가 제한적
- 학습 비용을 최소화하고 싶을 때
```

### Service Mesh가 필요한 경우

```kotlin
- 복잡한 마이크로서비스 (10개 이상)
- 서비스 간 통신이 복잡
- 카나리 배포, A/B 테스트 필요
- 강력한 보안 요구사항 (mTLS, 인가)
- 상세한 관찰성 필요
- 분산 추적 필요
- 복원력 패턴 (재시도, 서킷 브레이커) 필요
```

### 둘 다 사용하는 경우 (가장 일반적)

```kotlin
- 엔터프라이즈 애플리케이션
- 프로덕션 환경
- 외부 진입 + 내부 제어 모두 필요
- 계층별 책임 분리
```

## 리소스 비교

### Ingress만

```kotlin
NGINX Ingress Controller: 3 레플리카
- CPU: 0.5 core * 3 = 1.5 cores
- Memory: 200MB * 3 = 600MB

총: 1.5 cores, 600MB
```

### Istio 추가

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
1. 사용자 → Nginx → Web (Nginx 역할 끝)
2. Web → API (직접, 암호화 없음, 재시도 없음)
3. API → DB (직접, 접근 제어 없음)
```

### Istio 추가했을 때

```kotlin
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

```kotlin
1. 사용자 → Nginx → [Envoy] → Web
2. Web → [Envoy] → [Envoy] → API (mTLS, 재시도, 메트릭)
3. API → [Envoy] → [Envoy] → DB (인증, 인가, 추적)
```

## 리소스 관점에서 비교

### Ingress (Nginx)

```kotlin
┌──────────────────────────┐
│ Nginx Ingress Controller │
│ - Replicas: 3            │
│ - 각 200MB               │
│ = 총 600MB               │
└──────────────────────────┘

고정 비용: 서비스 개수와 무관
```

### Istio (Envoy)

```kotlin
서비스 Pod 개수: 50개
각 사이드카: 100MB
= 50 * 100MB = 5GB

Istiod (컨트롤 플레인): 2GB
= 총 7GB

변동 비용: 서비스 개수에 비례
```

## 네트워크 홉(Hop) 비교

### Ingress만

```kotlin
외부 요청:
User → Nginx (1홉) → Service A (1홉) = 총 2홉

내부 통신:
Service A → Service B (1홉) = 총 1홉
```

### Istio 추가

```kotlin
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

yaml

```kotlin
*# 하나의 설정으로 전체 라우팅 정의*
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

yaml

```kotlin
*# Service별로 세밀한 설정*
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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

```kotlin
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