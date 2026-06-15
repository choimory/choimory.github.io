---
title: "Istio Service-entry와 Sidecar"
date: 2026-06-15T00:00:00
toc: true
toc_sticky: true
categories:
    - Devops
tags:
    - Istio
---

# ServiceEntry & Sidecar 트래픽 제어

## 개념 정리

Istio의 외부 트래픽 제어는 "메시 전체 정책"과 "파드 단위 정책" 두 레이어로 나뉩니다.

"메시 전체 정책"은 `MeshConfig.outboundTrafficPolicy`로 설정하며, 모든 사이드카(Envoy 프록시)의 기본 동작을 결정합니다. "파드 단위 정책"은 `Sidecar` 리소스로 설정하며, 특정 파드의 Envoy가 어떤 호스트 정보를 가질지를 제어합니다.

이 두 레이어와 `ServiceEntry`가 조합되어 최종 트래픽 허용 여부가 결정됩니다.

## 핵심 리소스 개념

### outboundTrafficPolicy (MeshConfig)

메시 전체에 적용되는 외부 트래픽 기본 정책입니다.

| 값 | 동작 |
| --- | --- |
| `ALLOW_ANY` | 등록 여부와 무관하게 모든 외부 트래픽 허용 |
| `REGISTRY_ONLY` | ServiceEntry에 등록된 호스트만 허용, 나머지 차단 |

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
```

### ServiceEntry

Istio의 서비스 레지스트리에 외부 서비스를 등록하는 리소스입니다. 등록된 호스트는 Istio가 인식하는 "알려진 서비스"가 됩니다. namespace에 생성되지만, 기본적으로 `exportTo: "*"` 이므로 메시 전체에 적용됩니다.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-api
  namespace: default
spec:
  hosts:
    - api.example.com
  ports:
    - number: 443
      name: https
      protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
```

### Sidecar 리소스

특정 파드(workload)의 Envoy 프록시가 수신할 서비스 레지스트리 정보를 제한하는 리소스입니다. `egress.hosts`에 명시된 호스트만 해당 파드의 Envoy 설정에 포함됩니다.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: restricted-sidecar
  namespace: app-ns
spec:
  workloadSelector:
    labels:
      app: my-app
  egress:
    - hosts:
        - "./*"               # 같은 namespace 내부 서비스
        - "istio-system/*"    # istio 시스템 서비스
        - "*/api.example.com" # 특정 외부 서비스 (SE 등록 필요)
```

## 경우의 수별 동작 분석

### ALLOW_ANY 모드

#### ALLOW_ANY + SE 없음 + Sidecar 없음

모든 외부 트래픽이 허용됩니다. Envoy가 모든 호스트로의 패스스루(passthrough)를 허용합니다.

#### ALLOW_ANY + SE 있음 + Sidecar 없음

외부 트래픽이 여전히 전체 허용됩니다. SE는 해당 호스트에 대한 "세부 라우팅 제어(VirtualService, DestinationRule)"를 가능하게 할 뿐, 트래픽 자체를 차단하지는 않습니다.

#### ALLOW_ANY + SE 있음 + Sidecar 있음

Sidecar의 `egress.hosts`에 명시된 호스트만 해당 파드에서 허용됩니다.

- `egress.hosts`가 `*/*` 이면 → SE 미등록 도메인 포함 전체 허용
- `egress.hosts`가 `*/api.example.com` 이면 → 해당 호스트만 허용

여기서 중요한 점은 Sidecar 리소스가 ALLOW_ANY 모드를 "오버라이드"한다는 것입니다. 파드 단위 제어가 메시 전체 정책보다 우선합니다.

### REGISTRY_ONLY 모드

#### REGISTRY_ONLY + SE 없음 + Sidecar 없음

외부 트래픽이 전부 차단됩니다. 내부 서비스 간 통신(클러스터 내부)은 레지스트리에 자동 등록되므로 영향 없습니다.

#### REGISTRY_ONLY + SE 있음 + Sidecar 없음

SE에 등록된 호스트만 허용됩니다. 등록되지 않은 외부 호스트는 Envoy에서 `502 Bad Gateway` 또는 연결 거부가 발생합니다.

#### REGISTRY_ONLY + SE 있음 + Sidecar 있음

SE에 등록된 호스트 중에서 Sidecar `egress.hosts`에 포함된 것만 허용됩니다.

- `egress.hosts`가 `*/*` (와일드카드)이면 → SE에 등록된 모든 호스트 허용 (SE 미등록 호스트는 REGISTRY_ONLY에 의해 여전히 차단)
- `egress.hosts`가 특정 호스트이면 → SE 등록 + egress.hosts 교집합만 허용

REGISTRY_ONLY에서 와일드카드 Sidecar는 "SE 전체 허용"을 의미하며, ALLOW_ANY에서의 와일드카드처럼 SE 미등록까지 허용하지는 않습니다.

## 전체 요약

| 모드 | SE | Sidecar | 결과 |
| --- | --- | --- | --- |
| ALLOW_ANY | ✗ | ✗ | 전체 허용 |
| ALLOW_ANY | ✓ | ✗ | 전체 허용 (SE는 라우팅 제어용) |
| ALLOW_ANY | ✓ | ✓ (`*/*`) | SE 포함 전체 허용 |
| ALLOW_ANY | ✓ | ✓ (특정 호스트) | egress.hosts만 허용 |
| REGISTRY_ONLY | ✗ | ✗ | 외부 전체 차단 |
| REGISTRY_ONLY | ✓ | ✗ | SE 등록 호스트만 허용 |
| REGISTRY_ONLY | ✓ | ✓ (`*/*`) | SE 등록 전체 허용 |
| REGISTRY_ONLY | ✓ | ✓ (특정 호스트) | SE ∩ egress.hosts 교집합만 허용 |

핵심 원칙을 정리하면 다음과 같습니다.

- "outboundTrafficPolicy"는 메시 전체의 기본값, Sidecar 리소스는 파드 단위 오버라이드
- "ALLOW_ANY"에서 Sidecar 와일드카드는 SE 밖까지 허용, "REGISTRY_ONLY"에서 Sidecar 와일드카드는 SE 범위 내에서만 허용
- SE는 트래픽 허용/차단보다 "레지스트리 등록"과 "세부 라우팅 정책 부여"가 주목적