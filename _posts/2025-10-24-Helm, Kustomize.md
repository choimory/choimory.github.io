---
title: "Helm, Kustomize"
date: 2025-10-24T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
    - Helm
    - Kustomize
---

# Helm과 Kustomize 개념

Helm과 Kustomize는 Kubernetes 애플리케이션 배포를 관리하는 두 가지 주요 도구다. 두 도구 모두 Kubernetes 매니페스트의 복잡성을 관리하고 재사용성을 높이지만, 근본적으로 다른 철학과 접근 방식을 가지고 있다.

## Helm의 핵심 개념

Helm은 Kubernetes의 "패키지 매니저"로, 템플릿 기반 접근 방식을 사용한다.

- **Chart**: Kubernetes 리소스를 정의하는 패키지 단위. 템플릿 파일, values 파일, 메타데이터로 구성됨
- **Template Engine**: Go 템플릿 언어를 사용해 동적으로 매니페스트 생성
- **Values 파일**: 환경별 설정을 분리하여 관리. `values.yaml`, `values-prod.yaml` 등으로 구성
- **Release**: Chart를 클러스터에 설치한 인스턴스. 버전 관리와 롤백 기능 제공
- **Repository**: Chart를 저장하고 공유하는 중앙 저장소 (예: ArtifactHub)

**장점**

- 복잡한 애플리케이션을 하나의 패키지로 관리 가능
- 커뮤니티에서 제공하는 수천 개의 검증된 Chart 활용 가능 (nginx-ingress, prometheus 등)
- 릴리스 이력 관리 및 롤백 기능 내장
- 조건문, 반복문 등 강력한 템플릿 기능

**단점**

- Go 템플릿 문법 학습 필요
- 템플릿이 복잡해지면 디버깅 어려움
- 원본 YAML이 템플릿으로 변환되어 가독성 저하

## Kustomize의 핵심 개념

Kustomize는 "템플릿 없는" 방식으로 YAML 오버레이를 통해 커스터마이징한다.

- **Base**: 공통 리소스를 정의하는 기본 YAML 파일들
- **Overlay**: 환경별 차이점만 정의. base 위에 패치를 적용하는 방식
- **kustomization.yaml**: 어떤 리소스를 포함하고 어떻게 변환할지 선언하는 파일
- **Patch 전략**: Strategic Merge Patch, JSON Patch 등을 사용해 선택적 수정
- **Native Integration**: kubectl에 기본 내장 (`kubectl apply -k`)

**장점**

- 순수 YAML 사용으로 별도 템플릿 언어 학습 불필요
- 원본 매니페스트를 그대로 유지하면서 환경별 차이만 오버레이
- kubectl에 내장되어 추가 도구 설치 불필요
- Git 친화적이고 코드 리뷰가 용이

**단점**

- 복잡한 조건부 로직 구현 어려움
- 패키지 버전 관리 및 배포 기능 없음
- 커뮤니티 공유 생태계가 Helm보다 작음

## 주요 차이점

### 철학적 접근

- **Helm**: "템플릿 + 변수 치환" 방식. 하나의 템플릿에서 모든 환경 생성
- **Kustomize**: "베이스 + 패치" 방식. 공통 부분을 유지하고 차이점만 오버레이

### 사용 예시

**Helm 구조**

```kotlin
mychart/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── deployment.yaml  # {{ .Values.replicas }} 같은 템플릿 사용
    └── service.yaml
```

**Kustomize 구조**
```
myapp/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml  # 순수 YAML
│   └── service.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml  # replicas: 1
    └── prod/
        └── kustomization.yaml  # replicas: 3
```

### 적합한 사용 사례

**Helm을 선택해야 할 때**

- 서드파티 애플리케이션 설치 (데이터베이스, 모니터링 도구 등)
- 릴리스 버전 관리 및 롤백 기능이 중요한 경우
- 복잡한 조건부 로직이 필요한 경우
- 팀 내 패키지 재사용 및 공유가 중요한 경우

**Kustomize를 선택해야 할 때**

- 자체 개발 애플리케이션의 환경별 배포
- GitOps 워크플로우 구축 (ArgoCD, Flux와 함께)
- 단순하고 명확한 환경별 차이 관리
- Kubernetes 네이티브 도구만 사용하고 싶을 때

## 함께 사용하기

두 도구는 상호 배타적이지 않으며 함께 사용할 수 있다.

- Helm Chart를 Base로 사용하고 Kustomize로 후처리 (Helm template | kustomize)
- Helm으로 서드파티 패키지 관리, Kustomize로 자체 앱 관리
- ArgoCD 같은 GitOps 도구는 Helm과 Kustomize 모두 지원

## 전체 요약

- **Helm**은 템플릿 엔진 기반의 패키지 매니저로, 복잡한 애플리케이션을 재사용 가능한 Chart로 패키징하고 버전 관리 및 롤백 기능을 제공한다
- **Kustomize**는 템플릿 없이 순수 YAML을 base와 overlay 구조로 관리하며, kubectl에 내장되어 있어 Kubernetes 네이티브한 접근 방식을 제공한다
- Helm은 동적 템플릿 생성과 조건부 로직이 강력하지만 복잡도가 증가하며, Kustomize는 단순하고 Git 친화적이지만 복잡한 로직 표현에 한계가 있다
- 서드파티 패키지 설치와 릴리스 관리가 중요하면 Helm을, 자체 앱의 환경별 배포와 GitOps 워크플로우가 중요하면 Kustomize를 선택하는 것이 일반적이다
- 두 도구는 함께 사용할 수 있으며, 각각의 강점을 활용하는 하이브리드 접근도 가능하다

---

# helm은 k8s의 패키지매니저, kustomize는 환경별 관리?

정확하게 정리하면 조금 다르다. 두 도구 모두 Kubernetes 배포에 사용되며, 환경별 관리도 둘 다 가능하다. 하지만 **사용 목적과 강점이 다르다**.

## 일반적인 사용 패턴

### Helm의 주요 용도

**외부 패키지 설치용**

- Kubernetes 클러스터에 서드파티 소프트웨어를 설치할 때 주로 사용
- nginx-ingress, prometheus, grafana, postgresql, redis 등
- 커뮤니티에서 검증된 Chart를 가져와 values만 수정해서 설치
- 예: `helm install my-nginx nginx/nginx-ingress -f custom-values.yaml`

**복잡한 애플리케이션 패키징**

- 여러 마이크로서비스로 구성된 자체 애플리케이션을 하나의 Chart로 패키징
- 서비스 간 의존성, 조건부 리소스 생성 등 복잡한 로직 필요할 때
- 릴리스 버전 관리, 롤백 기능이 필요할 때

**환경별 배포도 가능**

- `values-dev.yaml`, `values-prod.yaml`로 환경별 구분
- `helm install myapp ./mychart -f values-prod.yaml`
- 하지만 이 방식보다는 Kustomize가 더 적합한 경우가 많음

### Kustomize의 주요 용도

**환경별 구성 관리 특화**

- 동일한 애플리케이션을 dev, staging, prod 환경에 배포할 때
- base에 공통 설정, overlay에 환경별 차이만 정의
- GitOps 워크플로우에서 각 환경별 Git 브랜치/디렉토리로 관리

**자체 개발 애플리케이션 배포**

- 내부에서 개발한 마이크로서비스들의 배포 관리
- CI/CD 파이프라인에서 이미지 태그 자동 업데이트
- `kustomize edit set image myapp=myapp:v1.2.3`

**순수 YAML 유지**

- 템플릿 없이 원본 Kubernetes 매니페스트 그대로 유지
- 코드 리뷰와 변경 이력 추적이 명확함

## 실무 조합 패턴

### 패턴 1: 역할 분리 (가장 일반적)

```kotlin
프로젝트 구조:
├── infrastructure/          # Helm으로 관리
│   ├── nginx-ingress/
│   ├── cert-manager/
│   └── monitoring/
│       └── values-prod.yaml
│
└── applications/           # Kustomize로 관리
    └── myapp/
        ├── base/
        └── overlays/
            ├── dev/
            ├── staging/
            └── prod/
```

**사용 방식**

- **Helm**: 인프라 컴포넌트(Ingress, 모니터링, DB) 설치
- **Kustomize**: 자체 개발 애플리케이션 환경별 배포

### 패턴 2: Helm + Kustomize 후처리

Helm으로 기본 구조를 생성하고 Kustomize로 환경별 커스터마이징을 추가한다.

bash

```kotlin
*# Helm으로 템플릿 렌더링*
helm template myapp ./mychart > base/rendered.yaml

*# Kustomize로 환경별 패치 적용*
kubectl apply -k overlays/prod/
```

**사용 예시**
- Helm Chart의 복잡한 로직은 활용하되
- 환경별 세밀한 조정은 Kustomize overlay로 처리
- Helm의 릴리스 관리 기능 없이 순수 GitOps 방식 사용

*### 패턴 3: 모든 것을 Kustomize로*

일부 팀은 Helm을 완전히 배제하고 Kustomize만 사용한다.
```
모든 리소스:
└── k8s/
    ├── components/        *# 재사용 가능한 컴포넌트*
    │   ├── ingress/
    │   └── monitoring/
    └── apps/
        └── myapp/
            ├── base/
            └── overlays/
```

**장점**

- 도구 스택 단순화
- 모든 것이 순수 YAML로 관리
- kubectl만으로 모든 작업 가능

**단점**

- 서드파티 패키지 수동 관리 필요
- 버전 업그레이드 추적 어려움

## 환경별 관리 비교

### Helm의 환경별 관리

yaml

```kotlin
*# values-dev.yaml*
replicas: 1
resources:
  requests:
    memory: "128Mi"
ingress:
  host: dev.myapp.com

*# values-prod.yaml*  
replicas: 5
resources:
  requests:
    memory: "512Mi"
ingress:
  host: myapp.com
```

bash

```kotlin
helm install myapp-dev ./mychart -f values-dev.yaml
helm install myapp-prod ./mychart -f values-prod.yaml
```

**특징**

- 하나의 템플릿에서 모든 환경 생성
- values 파일만 변경하면 되므로 간단
- 하지만 환경별 차이가 values에 모두 표현 가능해야 함

### Kustomize의 환경별 관리

yaml

```kotlin
*# base/kustomization.yaml*
resources:
  - deployment.yaml
  - service.yaml

*# overlays/prod/kustomization.yaml*
bases:
  - ../../base
replicas:
  - name: myapp
    count: 5
patches:
  - path: resources-patch.yaml
```

**특징**

- base는 그대로 두고 overlay에서 필요한 부분만 패치
- Git에서 환경별 변경사항 추적 명확
- 각 환경의 최종 상태를 쉽게 파악 가능

## 실무 선택 가이드

### Helm을 사용해야 하는 경우

- Bitnami, Prometheus 등 **외부 Chart 설치**
- **복잡한 조건부 로직** 필요 (특정 조건에서만 리소스 생성 등)
- **릴리스 히스토리와 롤백** 기능이 중요
- **멀티 테넌트 환경**에서 동일 Chart를 여러 번 설치

### Kustomize를 사용해야 하는 경우

- **자체 개발 앱**의 환경별 배포
- **GitOps 워크플로우** (ArgoCD, Flux)
- **순수 YAML 유지**가 중요
- **kubectl만으로** 모든 관리를 하고 싶을 때

### 둘 다 사용하는 경우

- 인프라는 Helm, 애플리케이션은 Kustomize
- 대부분의 중대형 프로젝트가 이 방식 채택
- 각 도구의 강점을 살릴 수 있음

## 전체 요약

- Helm과 Kustomize 둘 다 Kubernetes 배포와 환경별 관리에 사용할 수 있지만, **사용 목적에 따라 강점이 다르다**
- **Helm은 주로 서드파티 패키지 설치, 복잡한 애플리케이션 패키징, 릴리스 관리**에 강점이 있다
- **Kustomize는 자체 개발 앱의 환경별 배포, GitOps 워크플로우, 순수 YAML 관리**에 특화되어 있다
- 실무에서는 **인프라 컴포넌트는 Helm, 자체 애플리케이션은 Kustomize**로 분리하는 하이브리드 패턴이 가장 일반적이다
- 환경별 관리는 Helm도 가능하지만, Kustomize의 base/overlay 구조가 **Git 기반 변경 추적과 코드 리뷰에 더 적합**하다
- 도구 선택은 팀의 워크플로우, GitOps 도입 여부, 관리할 애플리케이션의 특성에 따라 결정해야 한다