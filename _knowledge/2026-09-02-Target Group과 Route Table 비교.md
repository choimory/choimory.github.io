---
title: "Target Group과 Route Table 비교"
date: 2026-09-02T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Network
    - Cloud
---

## 개요

AWS의 Target Group과 Route Table은 둘 다 "보낼 곳을 명세해놓는 테이블" 이라는 공통 본질을 가지고 있지만, 동작하는 OSI 레이어와 담당하는 방향(인바운드/아웃바운드)이 다릅니다. 이 문서는 두 개념을 비교하며, 패킷/요청이 흐르는 실제 경로와 k8s 클러스터와의 연동 구조까지 정리합니다.

---

## Target Group과 Route Table의 공통점과 차이점

### 공통 본질

둘 다 "목적지 판별 테이블" 입니다. 들어오는 무언가(패킷 or 요청)를 보고, 조건을 매칭해서, 어디로 보낼지 결정하는 구조 자체는 동일합니다.

### OSI 레이어 차이

레이어가 다르면 볼 수 있는 정보가 달라지고, 그래서 판별 기준도 달라집니다.

|  | Route Table | Target Group |
| --- | --- | --- |
| OSI 레이어 | L3 (Network) | L4~L7 (Transport~Application) |
| 판별 기준 | 목적지 IP(CIDR) | 포트, URL 경로, HTTP 헤더, 쿼리스트링 등 |
| 판별 단위 | 패킷 | 요청(Request/Connection) |
| 대상 | 게이트웨이, 인터페이스 | 서버 인스턴스, IP, Lambda |

L3 Route Table은 IP 헤더만 볼 수 있는 반면, L7 Target Group(ALB)은 IP/TCP/HTTP 헤더와 Body까지 볼 수 있습니다. 그래서 Target Group은 `/api/*` 같은 경로 기반 라우팅이 가능하지만, Route Table은 IP 대역 외에는 구분할 수 없습니다.

### 부가 기능의 차이

레이어가 높아질수록 "판별" 외에 부가 기능도 붙습니다.

- Route Table: 판별만 함, 상태 확인 없음
- Target Group: 판별 + 헬스 체크 + 로드밸런싱 알고리즘

이는 OSI 레이어 차이에서 파생된 것이지, 본질적으로 다른 개념이어서가 아닙니다.

### 구성 요소 (Target Group)

#### 멤버(Targets)

Target Group에 등록된 실제 목적지로, EC2 Instance, IP 주소(온프레미스 포함), Lambda 함수, 다른 ALB 등이 가능합니다.

#### 헬스 체크(Health Check)

각 멤버가 살아있는지 주기적으로 확인하며, 실패 시 해당 타겟으로는 트래픽을 보내지 않습니다. Route Table은 대상이 죽어도 그냥 보낸다는 점에서 큰 차이가 있습니다.

#### 로드밸런싱 알고리즘

Round Robin(기본), Least Outstanding Requests, Random, Weighted 등이 있습니다.

### 더 정확한 비유

| 개념 | 비유 |
| --- | --- |
| Route Table | 도로 표지판 (이 방향 → 저 도로) |
| Listener Rule | 콜센터 IVR (1번 누르면 기술팀, 2번 누르면 영업팀) |
| Target Group | 실제 팀원 목록 + 누가 지금 근무 중인지 |

---

## 인바운드/아웃바운드 담당 범위

### Route Table은 아웃바운드 전용이다

Route Table은 "나가는 패킷의 경로" 만 결정합니다. "인바운드/아웃바운드 둘 다" 처럼 느껴지는 이유는 서브넷마다 Route Table이 붙어있어서, 양쪽 서브넷 각각에서 아웃바운드를 정의하기 때문입니다.

```
클라이언트 (10.0.1.x)          서버 (10.0.2.x)
      │                              │
      │ 아웃바운드 → Route Table A   │
      │ ─────────────────────────►  │
      │                              │ 아웃바운드 → Route Table B
      │ ◄─────────────────────────  │
```

인바운드 트래픽 제어는 Route Table이 아니라 Security Group / NACL의 역할입니다.

### Target Group은 인바운드 전용이다

Target Group은 "로드밸런서가 수신한 요청을 어디로 넘길지" 만 정의합니다. 응답(Response)은 Target Group을 거치지 않고 서버에서 클라이언트로 직접 돌아갑니다.

```
외부 요청
   │
   ▼
[Load Balancer]  ←── 여기까지가 인바운드 수신
   │
   ▼
[Target Group]   ←── 어느 서버로 넘길지 결정
   │
   ▼
[EC2 / Lambda]
```

### 인바운드/아웃바운드 제어 주체 정리

| 역할 | AWS 구성요소 |
| --- | --- |
| 아웃바운드 경로 결정 | Route Table |
| 인바운드/아웃바운드 필터링 | Security Group, NACL |
| 인바운드 요청 분배 | Load Balancer + Target Group |
| 아웃바운드 트래픽 분산 | 별도 구성 필요 (NAT GW, Egress LB 등) |

### Target Group에는 백엔드 아웃바운드 명세가 없다

Route Table처럼 백엔드 서버에서 나가는 방향을 Target Group이 제어하는 개념은 존재하지 않습니다. Load Balancer + Target Group은 "요청을 받아서 분배하는 프록시" 이기 때문입니다.

```
클라이언트
   │  요청
   ▼
[ALB]  → Target Group → [EC2]
              
[EC2]  → 응답을 ALB로 직접 돌려줌
              
[ALB]  → 클라이언트로 응답 전달
```

백엔드(EC2)의 응답이 ALB로 돌아오는 것은 Target Group이 제어하는 게 아니라, TCP 커넥션이 유지되기 때문에 자동으로 되돌아오는 것입니다.

백엔드 서버가 외부로 무언가를 보내야 할 때는 완전히 별개의 구성요소가 담당합니다.

| 상황 | 담당 |
| --- | --- |
| EC2 → 인터넷 아웃바운드 | Route Table + NAT Gateway |
| EC2 → 다른 AWS 서비스 | Route Table + VPC Endpoint |
| EC2 → 다른 VPC | Route Table + VPC Peering / Transit Gateway |

Target Group은 이 흐름에 전혀 관여하지 않습니다.

---

## 인바운드 시 Route Table을 보지 않는 이유

### NAT의 정확한 의미

NAT(Network Address Translation)은 "주소를 변환한다" 는 뜻일 뿐, 방향(인바운드/아웃바운드)과는 무관한 개념입니다. "NAT = 아웃바운드" 라는 인식은 NAT Gateway라는 특정 제품 때문에 생긴 연상일 뿐입니다.

| 종류 | 방향 | 변환 내용 | 담당 |
| --- | --- | --- | --- |
| SNAT (Source NAT) | 아웃바운드 | 출발지 IP를 변환 | NAT Gateway |
| DNAT (Destination NAT) | 인바운드 | 목적지 IP를 변환 | IGW |

### IGW는 인바운드 시 DNAT을 수행한다

IGW는 인바운드 시 "목적지 Public IP를 목적지 Private IP로 바꿔치기" 합니다. 이것이 정확히 DNAT입니다.

```
[인바운드 - DNAT]
클라이언트 → 목적지: 1.2.3.4 (Public IP)
                  │
                  ▼ IGW가 DNAT 수행
                  │
            목적지: 10.0.1.5 (Private IP)로 변경
                  │
                  ▼
                 EC2
```

반대로 EC2가 응답을 내보낼 때는 IGW가 SNAT을 수행해서 출발지를 다시 Private → Public으로 바꿔줍니다. 이는 응답이라 새로운 라우팅 결정이 필요 없는 흐름이라 Route Table과는 무관합니다.

|  | NAT Gateway | IGW |
| --- | --- | --- |
| 인바운드 | 처리 안 함 (편도 전용) | DNAT (목적지 변환) |
| 아웃바운드 | SNAT (출발지 변환) | SNAT (출발지 변환) |

NAT Gateway는 프라이빗 서브넷의 "나가는 트래픽 전용" 이라 인바운드 자체가 불가능하고, IGW는 양방향 다 처리하되 방향에 따라 DNAT/SNAT을 다르게 수행합니다.

### 인바운드는 목적지가 이미 확정되어 들어온다

```
클라이언트가 EC2의 Public IP(1.2.3.4)로 요청을 보냄
   │
   ▼
[IGW]
   │  IGW는 1:1 NAT(DNAT) 매핑 테이블을 가지고 있음
   │  Public IP(1.2.3.4) ←→ Private IP(10.0.1.5)
   │  이 매핑으로 목적지를 Private IP로 변환
   │
   ▼
목적지가 10.0.1.5로 확정됨
   │
   ▼
VPC 내부 라우팅(자동, Local Route)으로 해당 서브넷의 ENI까지 직접 전달
```

"어디로 보낼지 결정하는" 단계가 이미 IGW의 DNAT 매핑에서 끝나기 때문에 Route Table이 끼어들 필요가 없습니다.

### Route Table의 Local 규칙

모든 Route Table에는 기본으로 다음 규칙이 자동으로 들어가 있습니다.

```
Destination       Target
10.0.0.0/16       local
```

이는 "VPC 내부 대역끼리는 무조건 직접 통신 가능" 이라는 뜻이며, IGW가 Private IP를 확정한 뒤에는 이 Local 규칙을 통해 VPC 내부망을 타고 서브넷까지 도달합니다.

### Route Table을 보느냐 마느냐의 핵심 기준

핵심 기준은 "인바운드/아웃바운드" 자체가 아니라 "목적지가 이미 확정되어 있는가" 입니다.

| 상황 | Route Table 확인 여부 |
| --- | --- |
| 인터넷 → IGW → EC2 (일반 인바운드) | 안 봄 (IGW DNAT으로 끝남) |
| EC2 → 인터넷 (일반 아웃바운드) | 봄 (목적지 선택 필요) |
| Ingress Routing (Gateway Load Balancer 등 특수 설정) | 봄 (의도적으로 우회시킴) |
| VPC Peering / Transit Gateway로 들어오는 트래픽 | 봄 (경로 자체가 Route Table에 정의됨) |

예외적으로 Gateway Load Balancer Endpoint를 타겟으로 지정해 인바운드 트래픽을 방화벽 어플라이언스로 우회시키는 Ingress Routing 패턴이나, VPC Peering/Transit Gateway처럼 다른 네트워크에서 들어오는 트래픽은 그 경로 자체가 Route Table에 명시되어 있어야 하므로 예외적으로 확인합니다.

### 정리된 흐름

```
[인바운드]
클라이언트 → IGW → (Route Table 대신 DNAT 매핑 확인) → Subnet (EC2)

[아웃바운드]
Subnet (EC2) → (Route Table에 적힌 규칙 확인) → NAT GW / 다른 Subnet / IGW / Peering 등
```

아웃바운드에서 Route Table에 적힌 목적지는 상황에 따라 다양하게 갈립니다.

```
Subnet의 Route Table 예시:

Destination         Target
10.0.0.0/16         local           → 같은 VPC 내 다른 Subnet
0.0.0.0/0           nat-xxxxxxxx    → 인터넷 (프라이빗 서브넷인 경우)
0.0.0.0/0           igw-xxxxxxxx    → 인터넷 (퍼블릭 서브넷인 경우, NAT 없이 직행)
172.16.0.0/16       pcx-xxxxxxxx    → Peering 연결된 다른 VPC
10.1.0.0/16         tgw-xxxxxxxx    → Transit Gateway 통해 다른 VPC/온프레미스
```

---

## Route Table은 Subnet에 종속되지 않고 참조된다

### Route Table은 독립적인 객체다

Route Table은 서브넷에 종속되어 생성되는 게 아니라, VPC 레벨에서 독립적으로 만들어지는 리소스입니다.

```
VPC
 ├─ Route Table A (rtb-aaaa)  ←── 독립적으로 존재
 ├─ Route Table B (rtb-bbbb)  ←── 독립적으로 존재
 │
 ├─ Subnet 1  ──── associate ───→ Route Table A
 ├─ Subnet 2  ──── associate ───→ Route Table A
 └─ Subnet 3  ──── associate ───→ Route Table B
```

서브넷은 Route Table을 "연결(Association)" 할 뿐이지, 자기 안에 내장하고 있는 게 아닙니다.

### 비유

| 비유 | 실제 |
| --- | --- |
| 여러 명이 같은 매뉴얼을 공유 | 여러 서브넷이 같은 Route Table 하나를 공유 가능 |
| 매뉴얼 자체는 한 곳에 보관 | Route Table은 VPC 안에 독립 리소스로 존재 |
| 사람마다 "어떤 매뉴얼 볼지" 표시만 함 | 서브넷은 "어떤 Route Table 쓸지" 연결 정보만 가짐 |

### 패킷이 나갈 때 실제로 일어나는 일

```
EC2 인스턴스가 패킷을 보냄
   │
   ▼
해당 EC2가 속한 Subnet 확인
   │
   ▼
그 Subnet에 연결(Association)된 Route Table을 조회
   │
   ▼
목적지 IP와 매칭되는 라우팅 규칙 찾음
   │
   ▼
다음 홉(Target)으로 전달
```

패킷이 나갈 때마다 "이 서브넷은 어떤 Route Table을 보고 있더라" 하고 참조해서 그 안의 규칙을 확인하는 방식입니다.

### 1:N 관계

하나의 Route Table을 여러 서브넷이 동시에 참조할 수 있습니다. 반대로 한 서브넷은 동시에 두 개의 Route Table을 가질 수 없고, 항상 정확히 1개와 연결됩니다.

```
Route Table A
   ├─ Subnet 1 (연결)
   ├─ Subnet 2 (연결)
   └─ Subnet 3 (연결)
```

### Target Group과 동일한 패턴

|  | 독립 리소스 | 연결(참조)하는 쪽 |
| --- | --- | --- |
| Route Table | Route Table (VPC 소속) | Subnet이 연결 |
| Target Group | Target Group (ELB 서비스 소속) | Listener Rule이 연결 |

둘 다 "테이블 자체는 독립적으로 존재하고, 사용하는 쪽에서 그걸 참조한다" 는 동일한 설계 패턴입니다.

---

## Target Group은 k8s 클러스터 외부 개념이다

### Target Group은 AWS 레벨 개념이다

Target Group은 AWS의 ELB(Elastic Load Balancer) 서비스에 속한 개념으로, k8s 클러스터 외부, AWS 인프라 레벨에 존재합니다.

```
[ AWS 인프라 레벨 ]
      │
   [ALB]  ←── AWS가 관리
      │
 [Target Group]  ←── AWS가 관리
      │
      ▼
[ k8s 클러스터 ]
   [Node1] [Node2] [Node3]  ←── Target Group의 멤버로 등록됨
```

### k8s 내부에서 대응되는 개념

| AWS | k8s 내부 대응 개념 |
| --- | --- |
| ALB / NLB | Ingress Controller, Service (LoadBalancer 타입) |
| Target Group | Endpoints / EndpointSlice |
| Listener Rule | Ingress 규칙 |

#### Endpoints / EndpointSlice

Target Group처럼 "실제 요청을 받을 Pod들의 IP:Port 목록" 을 관리합니다.

```
Service (my-service)
   └─ Endpoints
         ├─ 10.0.0.1:8080  (Pod1)
         ├─ 10.0.0.2:8080  (Pod2)
         └─ 10.0.0.3:8080  (Pod3)
```

### AWS + k8s 연동 시 전체 흐름

AWS EKS 환경에서 둘이 연결될 때의 구조는 다음과 같습니다.

```
클라이언트
   │
   ▼
[ALB]
   │  (ALB 내부에서 Listener Rule → Target Group 참조)
   │
   ▼
[Target Group]  ←── "어디로 보낼지 명세"만 하는 설정
   │
   ▼
[k8s Node : NodePort]  or  [Pod IP 직접]
   │
   ▼
[k8s 내부 라우팅 (kube-proxy / Service)]
   │
   ▼
[Pod]
```

Target Group은 독립 장비가 아니라 ALB에 붙어있는 설정이며, AWS Load Balancer Controller를 사용하면 k8s의 Ingress/Service 리소스를 감시해서 AWS Target Group을 자동으로 생성/갱신합니다.

```
라우터  +  Route Table  =  경로 결정
  ALB  +  Target Group  =  분배 대상 결정
```

물리적으로 별도 서버가 있는 게 아니라, ALB가 Target Group을 참조해서 어느 백엔드로 요청을 전달할지 결정하는 구조입니다. 따라서 전체 흐름은 `클라이언트 → ALB(+ Target Group) → k8s Node → kube-proxy → Pod` 로 정리하는 것이 정확합니다.

EKS에서는 ALB Target Type "ip"를 사용해 Pod IP를 직접 Target Group에 등록하는 패턴도 가능하며, 이는 AWS VPC CNI를 통해 구현됩니다.

---

## 전체 요약

Target Group과 Route Table은 둘 다 "목적지를 명세한 테이블" 이라는 공통 본질을 가지지만, Route Table은 L3에서 동작하며 서브넷에 연결(Association)되어 아웃바운드 경로만 결정하고, Target Group은 L4~L7에서 동작하며 ALB의 Listener Rule에 연결되어 인바운드 요청의 분배만 담당합니다.

인바운드 시에는 IGW가 DNAT으로 목적지를 이미 확정시키기 때문에 Route Table을 거치지 않으며, Route Table은 아웃바운드처럼 목적지가 여러 갈래일 때 실질적인 "선택" 역할을 합니다. 다만 Gateway Load Balancer를 이용한 Ingress Routing이나 VPC Peering/Transit Gateway를 통해 들어오는 트래픽처럼 경로 자체가 명시되어야 하는 예외 상황에서는 인바운드에도 Route Table을 참조합니다.

Target Group은 AWS 인프라 레벨 개념으로 k8s 클러스터 내부에는 존재하지 않으며, k8s 내부의 대응 개념은 Endpoints/EndpointSlice입니다. EKS 환경에서는 AWS Load Balancer Controller가 두 세계를 연결하는 브릿지 역할을 하며, 전체 트래픽 흐름은 `클라이언트 → ALB(+Target Group) → k8s Node → kube-proxy → Pod` 로 정리됩니다.