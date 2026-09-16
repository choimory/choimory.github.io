---
title: "Kubernetes에서 민감한 환경변수 관리 방법"
date: 2026-09-10T00:00:00
toc: true
categories:
    - DevOps
tags:
    - Kubernetes
    - k8s
    - env
---

## 개요

프로젝트에서 DB 비밀번호, JWT Secret, API Key 같은 값을 제거하려는 목적이라면 단순히 `.env` → Kubernetes Secret으로 옮기는 것보다 한 단계 더 나아가 다음 구조를 만드는 것이 좋습니다.

```
Git / Source Code
        │
        │ 비밀값 없음
        ▼
Kubernetes Manifest
        │
        │ "어떤 Secret을 사용할지"만 정의
        ▼
Secret Management System
        │
        ├─ DB_PASSWORD
        ├─ JWT_SECRET
        ├─ API_KEY
        └─ ...
        │
        ▼
      Pod
```

현재처럼 Kubernetes + Argo CD + GitOps 환경이라면 크게 다음 방법들을 고려할 수 있습니다.

---

## 1. HashiCorp Vault

가장 제대로 된 Secret 관리 시스템 중 하나입니다.

```
Git
 │
 │ secret path만 기록
 ▼
Argo CD
 │
 ▼
Kubernetes
 │
 │ ServiceAccount 인증
 ▼
Vault
 │
 ├─ DB_PASSWORD
 ├─ JWT_SECRET
 └─ API_KEY
 │
 ▼
Pod
```

Vault는 Kubernetes ServiceAccount를 이용하여 Pod를 인증할 수 있고, Vault Agent Injector를 이용하면 애플리케이션이 Vault API를 직접 호출하지 않아도 Secret을 파일 형태로 전달할 수 있습니다. (developer.hashicorp.com)

예를 들어 Deployment에는 실제 비밀번호가 없습니다.

```yaml
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "im-cms"
    vault.hashicorp.com/agent-inject-secret-db: "secret/data/im-cms/db"
```

Pod에는 다음처럼 들어옵니다.

```
/vault/secrets/db
```

그리고 내용은 예를 들어:

```
DB_USERNAME=imcms
DB_PASSWORD=xxxxxxxx
```

입니다.

### 장점

- Git에 Secret이 존재하지 않음
- Kubernetes manifest에도 Secret이 없음
- 애플리케이션별 권한 분리 가능
- Secret Rotation 가능
- 접근 감사 로그 관리 가능
- TTL 기반 Secret 가능
- DB 계정을 동적으로 생성하는 "Dynamic Secret"도 가능
- Kubernetes ServiceAccount 기반 인증 가능

특히 Vault Agent Injector는 Secret을 shared memory volume에 렌더링하기 때문에 애플리케이션 자체가 Vault를 알 필요도 없습니다. (developer.hashicorp.com)

### 단점

Vault 자체를 운영해야 합니다.

```
Vault HA
Vault Storage
Unseal
Backup
RBAC
Policy
TLS
Monitoring
```

등을 관리해야 하기 때문에 소규모 시스템에는 약간 무거울 수 있습니다.

---

## 2. Vault + Secrets Store CSI Driver

개인적으로 "Kubernetes Secret 자체를 정말 사용하고 싶지 않다"면 상당히 좋은 방식입니다.

```
Vault
  │
  ▼
Secrets Store CSI Driver
  │
  ▼
Pod Volume

/run/secrets/
 ├─ DB_PASSWORD
 ├─ JWT_SECRET
 └─ API_KEY
```

Secret을 Kubernetes Secret으로 생성하지 않고 Pod의 ephemeral volume으로 직접 Mount할 수 있습니다. Vault 공식 문서에서도 CSI Provider가 Pod ServiceAccount로 Vault에 인증하고 Secret을 volume으로 제공하는 방식을 지원합니다. (developer.hashicorp.com)

즉:

```
Vault
 ↓
CSI
 ↓
Pod
```

이고 중간에

```
Kubernetes Secret
```

이 없어도 됩니다.

### 보안적으로 좋은 이유

일반 Kubernetes Secret은 결국 etcd에 저장됩니다.

반면 CSI 방식은:

```
Vault
 ↓
Pod ephemeral volume
```

으로 가져올 수 있습니다. Vault의 Kubernetes 통합 비교에서도 CSI Provider는 Secret을 ephemeral volume으로 제공하는 방식으로 구분됩니다. (developer.hashicorp.com)

### 제가 Vault를 쓴다면

오히려 이 방식을 꽤 선호합니다.

```
Vault
    ↓
Secrets Store CSI
    ↓
Pod File
```

---

## 3. External Secrets Operator + 외부 Secret Manager

Kubernetes에서는 굉장히 많이 사용하는 구조입니다.

```
AWS Secrets Manager
Google Secret Manager
Azure Key Vault
Vault
1Password
etc...
        │
        ▼
External Secrets Operator
        │
        ▼
Kubernetes Secret
        │
        ▼
Pod
```

External Secrets Operator는 `ExternalSecret`, `SecretStore`, `ClusterSecretStore` 같은 CRD를 제공하고 외부 Secret Store의 값을 Kubernetes로 동기화합니다. (external-secrets.io)

예를 들면 Git에는:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: im-cms-secret
spec:
  secretStoreRef:
    name: vault
    kind: ClusterSecretStore

  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: im-cms/database
        property: password
```

만 올라갑니다.

실제 값:

```
password = X@!#adfaf...
```

은 외부 Secret Manager에만 존재합니다.

### GitOps하고 궁합이 매우 좋음

현재 사용하는 구조가:

```
Helm
 ↓
Argo CD
 ↓
Application
```

이라면 다음처럼 만들 수 있습니다.

```
Helm
 ↓
Argo CD
 ├─ External Secrets Operator
 └─ Application
       │
       ▼
 ExternalSecret
       │
       ▼
     Vault
```

Argo CD에서는 "Secret 값"이 아니라:

```
어떤 Secret을 어디서 가져올지
```

만 관리합니다.

### 중요한 점

다만 External Secrets Operator는 기본적으로 외부 Secret을 가져와 "Kubernetes Secret을 생성"합니다. 공식 문서에서도 외부 API에서 값을 읽어 Kubernetes Secret으로 동기화하는 구조라고 설명합니다. (external-secrets.io)

그래서 질문하신 의미가:

> Kubernetes Secret 리소스 자체도 사용하고 싶지 않다
> 

라면 ESO보다는 Vault + CSI 쪽이 더 적합합니다.

---

## 4. Cloud Secret Manager

AWS 같은 클라우드를 사용한다면 이것이 가장 편한 경우도 많습니다.

예를 들어 AWS:

```
AWS Secrets Manager

/prod/im-cms/db
  username
  password

/prod/api-gateway/jwt
  secret
```

AWS IAM으로:

```
im-cms Pod
   │
   └── /prod/im-cms/* 만 접근

api-gateway Pod
   │
   └── /prod/api-gateway/* 만 접근
```

처럼 권한을 분리할 수 있습니다.

그리고:

```
AWS Secrets Manager
        ↓
CSI Driver
        ↓
Pod
```

또는

```
AWS Secrets Manager
        ↓
External Secrets Operator
        ↓
Kubernetes Secret
        ↓
Pod
```

구조로 사용합니다.

### 장점

Vault와 달리 Secret Manager 자체를 운영할 필요가 없습니다.

그래서 AWS/EKS 환경이라면 저는 대체로

```
AWS Secrets Manager
+
Secrets Store CSI Driver
```

또는

```
AWS Secrets Manager
+
External Secrets Operator
```

를 먼저 검토합니다.

---

## 5. SOPS + age

GitOps에서 굉장히 많이 사용하는 다른 접근입니다.

SOPS는 Secret 자체를 암호화해서 Git에 저장합니다.

```yaml
DB_USERNAME: ENC[AES256_GCM,data:...]
DB_PASSWORD: ENC[AES256_GCM,data:...]
JWT_SECRET: ENC[AES256_GCM,data:...]
```

Git:

```
GitOps Repo
 └─ secrets.enc.yaml
```

Argo CD 배포 시:

```
Git
 ↓
SOPS decrypt
 ↓
Argo CD
 ↓
Kubernetes
```

형태가 됩니다.

### 장점

아주 단순합니다.

```
Vault 서버
Secret Manager
Operator
```

같은 별도 인프라가 없어도 됩니다.

### 단점

Secret이 "암호화되어 있기는 하지만 Git에 존재한다"는 점입니다.

또 최종적으로 Kubernetes Secret을 생성하는 패턴이 일반적입니다.

따라서:

```
보안성
Vault > SOPS

운영 편의성
SOPS > Vault
```

정도로 생각하면 편합니다.

---

## 6. Sealed Secrets

SOPS와 비슷한 GitOps용 Secret 관리 방식입니다.

```
Secret

DB_PASSWORD=1234
        │
        ▼
kubeseal
        │
        ▼
SealedSecret

AgBy8....
        │
        ▼
Git
        │
        ▼
Kubernetes
        │
        ▼
Sealed Secrets Controller
        │
        ▼
Secret
```

Git에는 암호화된 값만 존재합니다.

다만 결국 Kubernetes Secret으로 복호화됩니다.

그래서 요즘 시스템을 새로 설계한다면 저는 Vault/Cloud Secret Manager 쪽을 더 우선적으로 검토합니다.

---

## 7. Jenkins Credentials / GitHub Actions Secrets

CI/CD Secret으로 사용할 수도 있습니다.

예를 들어:

```
Jenkins Credentials

NCR_USERNAME
NCR_PASSWORD
SONAR_TOKEN
GIT_TOKEN
```

이런 값은 매우 적절합니다.

하지만:

```
DB_PASSWORD
JWT_SECRET
REDIS_PASSWORD
PAYMENT_API_KEY
```

같은 "런타임 애플리케이션 Secret"까지 Jenkins가 관리하게 만드는 것은 추천하지 않습니다.

역할을 나누는 것이 좋습니다.

```
Jenkins Credentials
 ├─ Git Credential
 ├─ Registry Credential
 └─ CI Token

Vault
 ├─ DB Credential
 ├─ Redis Credential
 ├─ JWT Secret
 └─ External API Key
```

---

# 환경변수보다 파일 Mount도 고려

또 하나 중요한 부분입니다.

보통 Spring Boot에서 이렇게 사용합니다.

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

그러면:

```
DB_PASSWORD=xxxx
```

라는 Environment Variable이 됩니다.

Vault/CSI를 사용한다면 굳이 Environment Variable로 변환할 필요가 없습니다.

예를 들어:

```
/run/secrets/db-password
/run/secrets/jwt-secret
```

으로 Mount할 수 있습니다.

Spring Boot는 `configtree:`를 지원하기 때문에 이런 형태로 사용할 수도 있습니다.

```
spring.config.import=optional:configtree:/run/secrets/
```

그러면:

```
/run/secrets/
├── DB_PASSWORD
├── DB_USERNAME
└── JWT_SECRET
```

같은 파일 기반 Secret 구성이 가능합니다.

Vault Agent가 Secret을 파일로 주입하는 구조도 공식적으로 지원됩니다. (developer.hashicorp.com)

---

# 방법별 비교

| 방법 | Git에 평문 Secret | K8s Secret | 별도 시스템 | GitOps 궁합 | 추천 |
| --- | --- | --- | --- | --- | --- |
| `.env` | 경우에 따라 존재 | X | X | 낮음 | X |
| K8s Secret | X | O | X | 보통 | △ |
| Sealed Secret | 암호화 | O | Controller | 좋음 | ○ |
| SOPS + age | 암호화 | 보통 O | 거의 없음 | 매우 좋음 | ○ |
| External Secrets | X | O | Secret Store | 매우 좋음 | ◎ |
| Vault Agent | X | X 가능 | Vault | 매우 좋음 | ◎ |
| Vault + CSI | X | X 가능 | Vault + CSI | 매우 좋음 | ◎ |
| Cloud Secret Manager + CSI | X | X 가능 | Managed | 매우 좋음 | ◎ |

---

# Kubernetes + Argo CD + GitOps 환경에서는 어떤 Secret 관리 구조가 적합할까?

Kubernetes와 Argo CD를 이용해 GitOps 방식으로 인프라와 애플리케이션을 관리하고 있다면, Secret 역시 Git에 실제 값을 저장하지 않고 외부 Secret Store에서 런타임에 주입하는 구조가 적합합니다.

### 1순위: 보안성과 완성도를 우선할 경우

```
       GitOps Repository
              │
     Secret 값은 없음
              │
              ▼
           Argo CD
              │
              ▼
         Kubernetes
              │
      ServiceAccount
              │
              ▼
       HashiCorp Vault
        /             \
im-cms/db         api-gateway/jwt
    │                    │
    └──────┬─────────────┘
           ▼
  Secrets Store CSI
           │
           ▼
          Pod
           │
   /run/secrets/*
```

이 구조가 가장 깔끔합니다.

특히:

```
Git에 Secret 없음
Kubernetes Secret 없음
etcd에 Secret 없음
애플리케이션 코드에 Secret 없음
```

이라는 구성을 만들 수 있다는 장점이 있습니다.

그리고 Pod마다 ServiceAccount를 따로 두고 최소 권한을 부여하는 것이 좋습니다. Vault도 Pod별 전용 ServiceAccount 사용을 권장하고 있습니다. (developer.hashicorp.com)

---

### 2순위: 운영 복잡도를 낮추고 싶다면

클라우드에서 적절한 Managed Secret Manager를 제공한다면:

```
Managed Secret Manager
        ↓
External Secrets Operator
        ↓
Kubernetes Secret
        ↓
Pod
```

입니다.

Kubernetes Secret이 생성되는 것은 괜찮지만 "Git이나 프로젝트에서 Secret을 완전히 제거하는 것"이 주목적이라면 가장 운영하기 편한 구조 중 하나입니다.

---

# 전체 요약

프로젝트에서 민감한 환경변수를 걷어내는 목적이라면 단순히 `.env → Kubernetes Secret`으로 바꾸는 것보다 "외부 Secret Store + Kubernetes 연동" 구조를 추천합니다.

현재 환경 기준 추천 우선순위는:

```
보안성과 완성도 최우선

1. Vault + Secrets Store CSI
   ↓
2. Managed Secret Manager + CSI
   ↓
3. Vault/Secret Manager + External Secrets Operator
   ↓
4. SOPS + age
   ↓
5. Sealed Secrets
   ↓
6. Kubernetes Secret 직접 관리
```

특히 "Kubernetes Secret마저 사용하지 않겠다"면:

```
Vault
 ↓
Kubernetes ServiceAccount 인증
 ↓
Secrets Store CSI
 ↓
Pod ephemeral volume
 ↓
Spring Boot configtree
```

구조를 가장 먼저 검토할 만합니다.

반대로 "Kubernetes Secret 자체는 괜찮고 Git/소스에서만 비밀값을 없애고 싶다"면:

```
Vault / Cloud Secret Manager
 ↓
External Secrets Operator
 ↓
Kubernetes Secret
```

이 방식이 GitOps와 운영 편의성 사이의 균형이 좋습니다. (external-secrets.io)