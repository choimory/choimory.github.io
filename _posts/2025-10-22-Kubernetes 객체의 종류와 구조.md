---
title: "Kubernetes 객체의 종류와 구조"
date: 2025-10-22T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
---

# **Kubernetes 객체의 종류와 전체 구조**

Kubernetes 객체는 클러스터의 상태를 표현하는 영속적인 엔티티다. 각 객체는 desired state(원하는 상태)를 선언하면 Kubernetes가 현재 상태를 지속적으로 desired state와 일치시킨다. 모든 객체는 YAML 또는 JSON 형식으로 정의되며, `apiVersion`, `kind`, `metadata`, `spec` 필드를 포함한다.

## 기본 워크로드 객체

컨테이너화된 애플리케이션을 실행하기 위한 핵심 객체들이다.

- **Pod**: 가장 작은 배포 단위로, 하나 이상의 컨테이너를 포함한다
    - 같은 Pod 내 컨테이너들은 네트워크와 스토리지를 공유한다
    - IP 주소를 Pod 단위로 할당받는다
    - 일반적으로 직접 생성하지 않고 컨트롤러를 통해 관리한다
- **ReplicaSet**: 지정된 수의 Pod 복제본을 유지한다
    - Pod의 가용성을 보장한다
    - 셀렉터를 통해 Pod를 식별한다
    - 직접 사용보다는 Deployment를 통해 간접 관리한다
- **Deployment**: 애플리케이션의 선언적 업데이트를 제공한다
    - ReplicaSet을 관리하며 롤링 업데이트, 롤백을 지원한다
    - 무중단 배포가 가능하다
    - 가장 일반적으로 사용되는 워크로드 객체다
- **StatefulSet**: 상태를 가진 애플리케이션을 관리한다
    - Pod에 고유한 식별자와 안정적인 네트워크 ID를 제공한다
    - 순차적인 배포와 스케일링을 보장한다
    - 데이터베이스 같은 stateful 애플리케이션에 적합하다
- **DaemonSet**: 모든 노드(또는 특정 노드)에 Pod를 실행한다
    - 로그 수집, 모니터링 에이전트 배포에 사용된다
    - 노드가 추가되면 자동으로 Pod가 생성된다
- **Job**: 한 번 실행되고 완료되는 작업을 관리한다
    - 배치 처리, 데이터 마이그레이션 등에 사용된다
    - 성공적으로 완료될 때까지 재시도한다
- **CronJob**: 스케줄에 따라 Job을 생성한다
    - cron 형식으로 주기적인 작업을 정의한다
    - 백업, 리포트 생성 등에 활용된다

## 서비스 및 네트워킹 객체

Pod 간 또는 외부와의 통신을 관리하는 객체들이다.

- **Service**: Pod 집합에 대한 안정적인 네트워크 엔드포인트를 제공한다
    - ClusterIP: 클러스터 내부에서만 접근 가능한 기본 타입이다
    - NodePort: 각 노드의 특정 포트로 외부 접근을 허용한다
    - LoadBalancer: 클라우드 제공자의 로드밸런서를 생성한다
    - ExternalName: DNS CNAME 레코드를 반환한다
- **Ingress**: HTTP/HTTPS 라우팅 규칙을 정의한다
    - 도메인 기반, 경로 기반 라우팅을 지원한다
    - TLS/SSL 종료를 처리한다
    - Ingress Controller가 실제 동작을 구현한다
- **NetworkPolicy**: Pod 간 네트워크 트래픽을 제어한다
    - 방화벽 규칙처럼 동작한다
    - Ingress(들어오는)와 Egress(나가는) 트래픽을 제어한다
- **Endpoints**: Service가 트래픽을 전달할 Pod IP 목록이다
    - Service가 자동으로 생성/관리한다
    - 수동으로 생성하여 외부 서비스를 연결할 수도 있다

## 스토리지 객체

데이터를 영속적으로 저장하고 관리하는 객체들이다.

- **PersistentVolume (PV)**: 클러스터의 스토리지 리소스다
    - 관리자가 프로비저닝하거나 StorageClass를 통해 동적 생성된다
    - 생명주기가 Pod와 독립적이다
    - NFS, iSCSI, 클라우드 스토리지 등을 추상화한다
- **PersistentVolumeClaim (PVC)**: 사용자의 스토리지 요청이다
    - 용량, 접근 모드를 지정하여 PV를 요청한다
    - Pod에서 볼륨으로 마운트하여 사용한다
    - PV와 1:1로 바인딩된다
- **StorageClass**: 동적 프로비저닝을 위한 스토리지 유형을 정의한다
    - 프로비저너(provisioner)와 파라미터를 지정한다
    - PVC가 StorageClass를 참조하면 자동으로 PV를 생성한다
    - SSD, HDD 등 다양한 스토리지 타입을 정의할 수 있다
- **Volume**: Pod 내에서 사용되는 디렉토리다
    - emptyDir: 임시 스토리지로 Pod 삭제 시 데이터도 삭제된다
    - hostPath: 호스트 노드의 파일시스템을 마운트한다
    - configMap, secret: 설정 데이터를 볼륨으로 마운트한다

## 설정 및 시크릿 객체

애플리케이션 설정과 민감한 정보를 관리한다.

- **ConfigMap**: 키-값 쌍으로 설정 데이터를 저장한다
    - 환경변수, 커맨드 라인 인자, 설정 파일로 주입 가능하다
    - 애플리케이션 코드와 설정을 분리한다
    - 평문으로 저장되므로 민감한 정보는 부적합하다
- **Secret**: 민감한 정보를 인코딩하여 저장한다
    - 비밀번호, 토큰, SSH 키 등을 관리한다
    - base64로 인코딩되지만 암호화는 아니다
    - RBAC으로 접근을 제한해야 한다
    - Opaque, TLS, Docker registry 등 여러 타입이 있다

## 권한 및 보안 객체

클러스터 접근 제어와 보안 정책을 관리한다.

- **ServiceAccount**: Pod가 API 서버와 통신할 때 사용하는 계정이다
    - 각 네임스페이스에 default ServiceAccount가 자동 생성된다
    - Pod에 자동으로 마운트되는 토큰을 제공한다
- **Role / ClusterRole**: 권한 집합을 정의한다
    - Role은 네임스페이스 수준, ClusterRole은 클러스터 전체 수준이다
    - 어떤 리소스에 어떤 동작(get, list, create 등)을 허용할지 명시한다
- **RoleBinding / ClusterRoleBinding**: 사용자/그룹/ServiceAccount에 Role을 부여한다
    - 주체(subject)와 역할(role)을 연결한다
    - 네임스페이스별 또는 클러스터 전체에 적용된다
- **PodSecurityPolicy (PSP)**: Pod의 보안 관련 사양을 제어한다 (deprecated)
    - privileged 모드 실행, 호스트 네트워크 사용 등을 제한한다
    - Kubernetes 1.25부터 제거되고 Pod Security Standards로 대체되었다

## 네임스페이스 및 리소스 관리 객체

클러스터 리소스를 조직화하고 제한한다.

- **Namespace**: 클러스터 내 가상 클러스터를 생성한다
    - 리소스를 논리적으로 분리한다
    - 개발/스테이징/프로덕션 환경 분리에 사용된다
    - ResourceQuota, LimitRange를 적용하는 단위다
- **ResourceQuota**: 네임스페이스의 총 리소스 사용량을 제한한다
    - CPU, 메모리, 스토리지 용량을 제한한다
    - Pod, Service 등 객체 개수를 제한할 수 있다
- **LimitRange**: 개별 Pod/Container의 리소스 범위를 제한한다
    - 최소/최대 CPU, 메모리를 설정한다
    - 기본 request/limit 값을 정의한다

## 고급 워크로드 및 관리 객체

특수한 목적을 위한 고급 객체들이다.

- **HorizontalPodAutoscaler (HPA)**: CPU/메모리 사용량에 따라 Pod 수를 자동 조절한다
    - Metrics Server가 필요하다
    - 최소/최대 복제본 수를 설정한다
    - 커스텀 메트릭 기반 스케일링도 가능하다
- **VerticalPodAutoscaler (VPA)**: Pod의 리소스 request/limit을 자동 조절한다
    - 과거 사용량을 분석하여 적정 값을 추천한다
    - HPA와 함께 사용할 때 주의가 필요하다
- **PodDisruptionBudget (PDB)**: 유지보수 중에도 최소 가용 Pod 수를 보장한다
    - 노드 드레인, 클러스터 업그레이드 시 중단을 제어한다
    - minAvailable 또는 maxUnavailable로 정의한다
- **CustomResourceDefinition (CRD)**: 사용자 정의 리소스 타입을 생성한다
    - Kubernetes API를 확장한다
    - Operator 패턴 구현의 기반이 된다
    - 도메인 특화 객체를 정의할 수 있다

## Kubernetes 객체의 공통 구조

모든 객체는 일관된 구조를 따른다.

- **apiVersion**: 사용할 API 버전을 지정한다
    - `v1`, `apps/v1`, `batch/v1` 등 그룹과 버전을 명시한다
    - 안정성 수준(alpha, beta, stable)을 나타낸다
- **kind**: 생성할 객체의 타입을 정의한다
    - `Pod`, `Deployment`, `Service` 등 객체 종류를 명시한다
- **metadata**: 객체를 식별하는 메타정보다
    - name: 객체의 고유 이름이다
    - namespace: 객체가 속한 네임스페이스다
    - labels: 키-값 쌍으로 객체를 분류한다 (셀렉터에 사용)
    - annotations: 임의의 메타데이터를 저장한다 (도구, 라이브러리용)
    - uid, resourceVersion 등은 시스템이 자동 생성한다
- **spec**: 객체의 원하는 상태를 정의한다
    - 객체 타입마다 다른 필드를 가진다
    - 선언적 방식으로 desired state를 명시한다
- **status**: 객체의 현재 상태를 나타낸다 (읽기 전용)
    - Kubernetes가 자동으로 업데이트한다
    - 관찰된 상태(observed state)를 표현한다
    - `kubectl get` 명령으로 조회할 수 있다

## 객체 간 관계와 계층 구조

Kubernetes 객체들은 서로 참조하고 의존한다.

- **Owner Reference**: 부모-자식 관계를 형성한다
    - Deployment → ReplicaSet → Pod의 계층 구조다
    - 부모가 삭제되면 자식도 cascade 삭제된다
    - `ownerReferences` 필드에 부모 정보가 기록된다
- **Label Selector**: 객체를 동적으로 선택한다
    - Service는 label selector로 Pod를 찾는다
    - Deployment는 label selector로 관리할 Pod를 식별한다
    - matchLabels, matchExpressions 방식이 있다
- **Volume Mount**: Pod와 스토리지를 연결한다
    - Pod spec에서 volume을 정의하고 container에 마운트한다
    - PVC를 volume으로 참조하여 영속 스토리지를 사용한다
- **Environment Variables**: 객체 간 정보를 전달한다
    - ConfigMap, Secret의 데이터를 환경변수로 주입한다
    - Downward API로 Pod 메타데이터를 환경변수로 노출한다

## 전체 요약

- **핵심 개념**: Kubernetes 객체는 클러스터 상태를 표현하는 영속적 엔티티로, desired state를 선언하면 컨트롤러가 현재 상태를 일치시킨다
- **워크로드 객체**: Pod(최소 단위), Deployment(무중단 배포), StatefulSet(상태 관리), DaemonSet(전체 노드 실행), Job/CronJob(배치 작업) 등이 애플리케이션을 실행한다
- **네트워킹**: Service가 안정적인 엔드포인트를 제공하고, Ingress가 HTTP 라우팅을 담당하며, NetworkPolicy가 트래픽을 제어한다
- **스토리지**: PV/PVC로 영속 스토리지를 관리하고, StorageClass로 동적 프로비저닝을 구현하며, 다양한 Volume 타입으로 데이터를 저장한다
- **설정 관리**: ConfigMap이 일반 설정을, Secret이 민감 정보를 저장하여 애플리케이션과 설정을 분리한다
- **보안 및 권한**: ServiceAccount, Role/RoleBinding으로 RBAC를 구현하여 접근을 제어한다
- **리소스 관리**: Namespace로 논리적 분리를, ResourceQuota/LimitRange로 리소스 제한을, HPA/VPA로 자동 스케일링을 제공한다
- **객체 구조**: 모든 객체는 apiVersion, kind, metadata, spec 필드를 가지며 status로 현재 상태를 추적한다
- **관계성**: Label selector로 객체를 선택하고, owner reference로 계층을 형성하며, volume mount와 환경변수로 데이터를 공유한다