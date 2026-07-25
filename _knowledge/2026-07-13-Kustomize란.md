---
title: "Kustomize란"
date: 2026-07-13T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kustomize
---

## 개요

Kustomize는 Kubernetes YAML 매니페스트를 "템플릿 문법 없이" 환경별로 다르게 조합하고 수정할 수 있게 해주는 도구입니다.

예를 들어 운영환경과 개발환경에서 같은 Deployment를 쓰되, 이미지 태그, replica 수, ConfigMap, Ingress host, namespace만 다르게 쓰고 싶을 때 Kustomize를 사용합니다.

Helm이 "템플릿 기반 패키징 도구"에 가깝다면, Kustomize는 "기존 YAML을 계층적으로 덮어쓰기 하는 구성 관리 도구"에 가깝습니다.

---

## Kustomize가 필요한 이유

Kubernetes를 운영하다 보면 같은 애플리케이션이라도 환경별로 설정이 달라집니다.

예를 들면 다음과 같습니다.

```
개발환경
- replica: 1
- image: app:dev
- host: dev.example.com
- namespace: dev

운영환경
- replica: 3
- image: app:prod
- host: example.com
- namespace: prod
```

이걸 환경별로 YAML을 전부 복사해서 관리하면 문제가 생깁니다.

```
deployment-dev.yaml
deployment-prod.yaml
service-dev.yaml
service-prod.yaml
ingress-dev.yaml
ingress-prod.yaml
```

처음에는 편하지만, 시간이 지나면 공통 설정을 수정할 때 여러 파일을 동시에 바꿔야 합니다. 결국 설정 누락, 환경 차이, 운영 장애가 생기기 쉽습니다.

Kustomize는 이 문제를 해결하기 위해 "공통 base"와 "환경별 overlay" 구조를 사용합니다.

---

## 핵심 개념

## Base

Base는 모든 환경에서 공통으로 사용하는 Kubernetes 리소스입니다.

예를 들어 Deployment, Service, ConfigMap, Ingress의 기본 형태를 여기에 둡니다.

```
base/
  deployment.yaml
  service.yaml
  ingress.yaml
  kustomization.yaml
```

Base는 "원본 YAML"이라고 보면 됩니다.

---

## Overlay

Overlay는 base를 가져와서 특정 환경에 맞게 수정하는 계층입니다.

예를 들어 개발환경, 운영환경을 다음처럼 나눌 수 있습니다.

```
overlays/
  dev/
    kustomization.yaml
    patch-deployment.yaml

  prod/
    kustomization.yaml
    patch-deployment.yaml
```

Overlay는 base를 복사하지 않고, 필요한 부분만 덮어씁니다.

---

## kustomization.yaml

Kustomize의 핵심 파일입니다.

어떤 리소스를 포함할지, 어떤 patch를 적용할지, 이미지 태그를 어떻게 바꿀지 등을 정의합니다.

예시는 다음과 같습니다.

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

또는 overlay에서는 다음처럼 base를 가져올 수 있습니다.

```yaml
resources:
  - ../../base
```

---

## 기본 디렉토리 구조

일반적으로 다음 구조를 많이 사용합니다.

```
k8s/
  base/
    deployment.yaml
    service.yaml
    ingress.yaml
    kustomization.yaml

  overlays/
    dev/
      kustomization.yaml
      patch-deployment.yaml

    prod/
      kustomization.yaml
      patch-deployment.yaml
```

이 구조의 의미는 다음과 같습니다.

```
base      = 공통 Kubernetes 리소스
dev       = 개발환경에서만 다른 설정
prod      = 운영환경에서만 다른 설정
```

---

## 예시

## Base Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-api
  template:
    metadata:
      labels:
        app: my-api
    spec:
      containers:
        - name: my-api
          image: my-api:latest
          ports:
            - containerPort: 8080
```

---

## Base kustomization.yaml

```yaml
resources:
  - deployment.yaml
```

---

## 개발환경 Overlay

```yaml
resources:
  - ../../base

namespace: dev

images:
  - name: my-api
    newTag: dev
```

이렇게 하면 개발환경에서는 다음처럼 적용됩니다.

```
namespace: dev
image: my-api:dev
replicas: 1
```

---

## 운영환경 Overlay

```yaml
resources:
  - ../../base

namespace: prod

images:
  - name: my-api
    newTag: prod

patches:
  - path: patch-deployment.yaml
```

그리고 `patch-deployment.yaml`은 다음처럼 작성할 수 있습니다.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
spec:
  replicas: 3
```

결과적으로 운영환경에서는 다음처럼 됩니다.

```
namespace: prod
image: my-api:prod
replicas: 3
```

---

## 적용 방법

Kustomize는 kubectl에 내장되어 있어서 별도 설치 없이 사용할 수 있습니다.

개발환경 적용은 다음과 같습니다.

```bash
kubectl apply -k overlays/dev
```

운영환경 적용은 다음과 같습니다.

```bash
kubectl apply -k overlays/prod
```

실제로 어떤 YAML이 만들어지는지 확인하려면 다음 명령어를 사용합니다.

```bash
kubectl kustomize overlays/prod
```

또는 Kustomize CLI를 따로 설치했다면 다음도 가능합니다.

```bash
kustomize build overlays/prod
```

---

## Helm과 Kustomize 차이

| 구분 | Helm | Kustomize |
| --- | --- | --- |
| 방식 | 템플릿 기반 | YAML 덮어쓰기 기반 |
| 설정 파일 | values.yaml | kustomization.yaml |
| 문법 | Go template 사용 | Kubernetes YAML 그대로 사용 |
| 장점 | 패키징, 재사용, 배포 관리에 강함 | 환경별 YAML 관리가 단순함 |
| 단점 | 템플릿이 복잡해질 수 있음 | 복잡한 조건 분기에는 약함 |
| 적합한 경우 | 외부 앱 설치, Chart 배포, 복잡한 배포 패키지 | dev/prod 환경별 매니페스트 관리 |

쉽게 말하면 다음과 같습니다.

```
Helm      = Kubernetes 앱을 패키지처럼 배포
Kustomize = Kubernetes YAML을 환경별로 커스터마이징
```

---

## GitOps에서의 Kustomize

Kustomize는 GitOps와 잘 맞습니다.

예를 들어 Argo CD나 Flux에서 다음처럼 환경별 경로를 바라보게 만들 수 있습니다.

```
GitOps Repository
  apps/
    my-api/
      base/
      overlays/
        dev/
        prod/
```

Argo CD에서는 개발환경 애플리케이션이 `overlays/dev`를 바라보고, 운영환경 애플리케이션이 `overlays/prod`를 바라보게 구성할 수 있습니다.

```
Argo CD App - dev  → apps/my-api/overlays/dev
Argo CD App - prod → apps/my-api/overlays/prod
```

이렇게 하면 Git에 반영된 매니페스트가 자동으로 클러스터에 동기화됩니다.

---

## 언제 Kustomize를 쓰면 좋은가

Kustomize는 다음 상황에 적합합니다.

```
- Kubernetes YAML을 직접 관리하고 싶을 때
- 개발/운영 환경별 설정 차이가 있을 때
- Helm 템플릿까지는 과하다고 느껴질 때
- GitOps Repository에서 환경별 매니페스트를 관리할 때
- 같은 앱을 여러 namespace나 cluster에 다르게 배포할 때
```

반대로 다음 상황에서는 Helm이 더 적합할 수 있습니다.

```
- 외부 오픈소스 앱을 설치할 때
- 배포 단위를 Chart로 패키징해야 할 때
- values.yaml로 많은 옵션을 관리해야 할 때
- 조건문, 반복문, 동적 생성이 많이 필요할 때
```

---

## 실무에서 추천하는 구조

실무에서는 보통 다음처럼 구성하는 것이 좋습니다.

```
manifests/
  apps/
    api/
      base/
        deployment.yaml
        service.yaml
        ingress.yaml
        kustomization.yaml

      overlays/
        dev/
          kustomization.yaml
          patch-deployment.yaml
          patch-ingress.yaml

        prod/
          kustomization.yaml
          patch-deployment.yaml
          patch-ingress.yaml

    frontend/
      base/
      overlays/
        dev/
        prod/
```

환경별 차이는 overlay에만 둡니다.

```
공통 설정      → base
환경별 설정    → overlays/dev, overlays/prod
민감 정보      → Secret, External Secret, Sealed Secret 등으로 별도 관리
이미지 태그    → CI/CD 또는 GitOps 단계에서 변경
```

---

## Kustomize를 한 문장으로 정리

Kustomize는 Kubernetes YAML을 복사하지 않고, 공통 base를 기준으로 개발/운영 같은 환경별 차이만 overlay로 덮어씌워 관리하는 도구입니다.

---

## 전체 요약

Kustomize는 Kubernetes 매니페스트를 환경별로 깔끔하게 관리하기 위한 도구입니다. 핵심 구조는 `base`와 `overlay`입니다. `base`에는 공통 YAML을 두고, `overlay`에는 개발환경, 운영환경처럼 환경별로 다른 설정만 작성합니다.

Helm은 패키징과 템플릿에 강하고, Kustomize는 순수 YAML 기반 환경 분리에 강합니다. GitOps에서는 Argo CD나 Flux가 `overlays/dev`, `overlays/prod` 같은 경로를 바라보게 구성하면 환경별 배포를 깔끔하게 관리할 수 있습니다.