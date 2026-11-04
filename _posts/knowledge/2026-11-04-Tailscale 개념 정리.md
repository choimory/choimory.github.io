---
title: "Tailscale 개념 정리"
date: 2026-11-04T00:00:00
toc: true
categories: ["DevOps"]
tags: ["Tailscale"]
---

## 개요

Tailscale은 "WireGuard 기반의 Mesh VPN"을 이용하여 서로 다른 네트워크에 위치한 장치들을 하나의 사설 네트워크로 연결하는 서비스입니다.

일반적인 VPN과 달리 중앙 VPN 서버를 직접 구축하거나 관리하지 않아도 인터넷에 연결된 서버와 PC, 스마트폰 등을 안전하게 연결할 수 있습니다.

Tailscale의 핵심은 단순한 VPN 연결을 넘어 "네트워크 구성, 내부 서비스 접근, 외부 서비스 공개, 접근 제어"까지 제공한다는 점입니다.

대표적인 개념은 다음과 같습니다.

| 개념 | 역할 |
| --- | --- |
| Tailnet | Tailscale로 구성된 사설 네트워크 |
| Node / Peer | Tailnet에 연결된 장치 및 통신 상대 |
| MagicDNS | 장치 이름을 이용한 DNS 접근 |
| Serve | Tailnet 내부에 로컬 서비스를 공개 |
| Funnel | 로컬 서비스를 퍼블릭 인터넷에 공개 |
| Subnet Router | Tailscale 미설치 사설망에 접근 |
| Exit Node | 외부 인터넷 트래픽을 특정 장치로 경유 |
| ACL / Grants | 사용자·장치·서비스 접근 권한 제어 |
| DERP | 직접 연결이 어려울 때 사용하는 중계 서버 |
| Tailscale SSH | Tailnet 기반 SSH 접근 및 인증 관리 |

이 중 `Tailnet`, `Serve`, `Funnel`은 Tailscale을 이해하는 데 특히 중요한 개념입니다.

---

## 1. Tailscale의 네트워크 구조

### 1.1 일반적인 VPN과의 차이

전통적인 VPN은 일반적으로 중앙 VPN 서버를 경유하여 장치 간 통신을 수행합니다.

반면 Tailscale은 가능한 경우 장치들이 서로 직접 통신하는 P2P Mesh 구조를 사용합니다.

일반적인 중앙 집중형 VPN:

```
Client A → VPN Server → Client B
          (중앙 경유)
```

Tailscale Mesh VPN:

```
           Control Plane
          (인증·연결 조정)
             /       \
          Node A ←→ Node B
              직접 P2P
```

개념도: Tailscale의 Control Plane은 인증과 네트워크 정보를 조정하지만, 직접 연결이 가능한 경우 실제 데이터는 이를 경유하지 않습니다.

### 1.2 Control Plane

장치들의 연결과 인증을 관리하는 영역입니다.

- 사용자 및 장치 인증
- 장치의 네트워크 정보 관리
- 장치 간 연결 정보 교환
- ACL 및 Grants 정책 배포
- 장치 등록과 제거

일반적으로 Tailscale이 제공하는 관리 서비스를 사용합니다.

### 1.3 Data Plane

실제 장치 간 네트워크 트래픽이 전달되는 영역입니다.

- WireGuard를 통한 트래픽 암호화
- NAT Traversal을 통한 직접 연결
- 직접 연결이 불가능하면 DERP 중계
- 장치 간 VPN 통신 수행

중요한 특징은 "Control Plane과 Data Plane이 분리되어 있다"는 것입니다.

즉, Tailscale의 중앙 관리 서버가 모든 VPN 트래픽을 직접 처리하는 것은 아닙니다.

---

## 2. Tailnet

Tailnet은 "Tailscale을 통해 구성되는 논리적인 사설 네트워크"입니다.

사용자가 Tailscale에 로그인하고 장치를 등록하면 해당 장치는 Tailnet의 구성원이 됩니다.

예를 들어 다음과 같이 구성할 수 있습니다.

```
Tailnet: example.ts.net
  ├── Laptop      100.101.1.1
  ├── Dev Server  100.101.1.2
  └── Home NAS    100.101.1.3

암호화된 Tailnet 내부 통신
```

물리적으로 서로 다른 네트워크에 존재하더라도 같은 Tailnet에 속한 장치들은 접근 정책이 허용하는 범위에서 통신할 수 있습니다.

### 2.1 Tailscale IP

각 장치에는 별도의 Tailscale IP가 할당됩니다.

일반적으로 IPv4는 `100.64.0.0/10` 범위의 주소를 사용하며, IPv6 주소도 제공됩니다.

예를 들어 개발 서버가 `100.101.1.2`라는 Tailscale IP를 가지고 있다면 다음과 같이 접근할 수 있습니다.

```bash
ssh ubuntu@100.101.1.2
curl http://100.101.1.2:8080
```

이 IP는 일반적인 퍼블릭 IP와 달리 인터넷에서 직접 라우팅되는 주소가 아닙니다.

### 2.2 Node와 Peer

Node는 Tailnet에 등록된 장치이며, Peer는 특정 장치의 관점에서 통신하는 다른 장치를 의미합니다.

예를 들어 Laptop과 Dev Server가 연결되어 있다면, Laptop 입장에서는 Dev Server가 Peer입니다.

### 2.3 Tailnet의 특징

- 물리적 네트워크와 무관한 논리적 네트워크
- 장치별 고유 Tailscale IP 제공
- WireGuard 기반 암호화
- 장치별 접근 권한 설정 가능
- NAT 및 방화벽 환경에서도 연결 시도
- 여러 클라우드와 온프레미스 환경 연결 가능

Tailnet은 단순한 주소 대역이 아니라 "장치의 신원과 접근 정책까지 포함하는 사설 네트워크"라고 이해할 수 있습니다.

---

## 3. MagicDNS

MagicDNS는 "Tailnet 내부에서 장치의 이름을 이용해 접근할 수 있도록 하는 DNS 기능"입니다.

Tailscale은 각 장치에 IP 주소를 할당하지만 IP를 매번 기억해서 접근하는 것은 불편합니다.

MagicDNS를 활성화하면 IP 대신 장치 이름을 사용할 수 있습니다.

| 구분 | 접근 방식 |
| --- | --- |
| Tailscale IP | `100.101.1.2` |
| 장치 이름 | `dev-server` |
| FQDN | `dev-server.example.ts.net` |

예를 들어 다음과 같이 사용할 수 있습니다.

```bash
ssh ubuntu@dev-server
curl http://dev-server:8080
```

MagicDNS는 일반적인 DNS와 유사하지만, Tailnet의 장치 정보를 자동으로 관리한다는 특징이 있습니다.

또한 Serve 및 Funnel에서 HTTPS 도메인을 구성하는 기반으로 사용됩니다.

다만 MagicDNS가 제공하는 것은 기본적으로 "장치 이름의 DNS 해석"입니다. 특정 장치의 포트나 웹 애플리케이션을 자동으로 공개하는 기능은 아닙니다.

---

## 4. Tailscale Serve

Serve는 "특정 장치에서 실행 중인 서비스를 Tailnet 내부에 공개하는 기능"입니다.

예를 들어 개발 서버에서 다음과 같은 웹 애플리케이션이 실행 중이라고 가정하겠습니다.

```
http://127.0.0.1:3000
```

이 서비스는 기본적으로 해당 장치의 로컬 환경에서만 접근할 수 있습니다.

Serve를 이용하면 이 로컬 서비스를 Tailnet 내부 장치들이 사용할 수 있도록 HTTPS 프록시 형태로 제공할 수 있습니다.

```
Tailnet 내부 Laptop
        |
        | HTTPS / WireGuard 기반 내부 접근
        v
  Tailscale Serve
  dev-server.example.ts.net
        |
        | Reverse Proxy
        v
      Local App
    127.0.0.1:3000
```

### 4.1 주요 특징

- Tailnet 내부에서만 접근 가능
- HTTPS 인증서 사용 가능
- 로컬 애플리케이션에 대한 Reverse Proxy 제공
- 별도의 Nginx 구성 없이 서비스 공유 가능
- Tailnet의 접근 정책 적용

Serve는 웹 서비스뿐 아니라 TCP 포워딩 등도 지원합니다.

### 4.2 활용 사례

개발 환경에서 특히 유용합니다.

예를 들어 다음과 같은 서비스들을 내부 구성원에게만 제공할 수 있습니다.

- Grafana 모니터링 대시보드
- Jenkins 웹 UI
- 내부 개발용 API
- 사설 Kubernetes 관리 도구
- 로컬 테스트 애플리케이션

중요한 점은 Serve를 사용하더라도 해당 서비스가 퍼블릭 인터넷에 공개되지는 않는다는 것입니다.

---

## 5. Tailscale Funnel

Funnel은 "Tailnet 내부 장치에서 실행되는 서비스를 퍼블릭 인터넷에 공개하는 기능"입니다.

Serve와 가장 큰 차이는 서비스를 사용할 수 있는 대상입니다.

- Serve: Tailnet 접근 권한이 있는 장치
- Funnel: Tailscale을 설치하지 않은 일반 인터넷 사용자도 접근 가능

```
일반 인터넷 사용자      Tailnet 사용자
          \               /
            Tailscale Funnel
           Public HTTPS Endpoint
                   |
                   v
                Local App
             127.0.0.1:3000
```

### 5.1 주요 특징

- 퍼블릭 인터넷에 서비스 공개
- 별도의 공유기 포트포워딩 없이 접근 가능
- HTTPS를 통한 암호화된 연결
- Tailscale이 제공하는 공개 중계 인프라 이용
- 로컬 개발 서버 또는 테스트 서비스 외부 공개 가능

일반적인 Funnel 구성에서는 `*.ts.net` 도메인을 사용합니다.

다만 Funnel은 2026년 11월 기준 베타 기능이며, 공개 리스닝 포트, 대역폭 및 도메인 등에 제한이 있습니다.

특히 Funnel로 공개한 서비스는 Tailnet의 사설 접근 제어만으로 보호되는 서비스가 아닙니다. 공개 서비스를 보호하려면 애플리케이션 자체 인증이나 별도의 보안 통제가 필요합니다.

### 5.2 활용 사례

Funnel은 외부에서 접근해야 하는 임시 서비스에 적합합니다.

예를 들어 다음과 같은 용도로 활용할 수 있습니다.

- 외부 Webhook 수신
- GitHub Webhook 테스트
- OAuth Callback 테스트
- 외부 고객에게 개발 결과물 시연
- 로컬 개발 서버 임시 공개
- 외부 API 연동 테스트

개발 서버에서 특정 서비스를 외부에 공개해야 할 때, 별도의 ALB나 Reverse Proxy를 구성하지 않고도 테스트 환경을 만들 수 있습니다.

---

## 6. Serve와 Funnel의 차이

두 기능은 모두 로컬 서비스를 다른 사용자에게 제공한다는 공통점이 있지만, 서비스가 노출되는 네트워크 범위가 다릅니다.

| 구분 | Serve | Funnel |
| --- | --- | --- |
| 목적 | 내부 서비스 공유 | 외부 서비스 공개 |
| 접근 범위 | Tailnet 내부 | 퍼블릭 인터넷 |
| Tailscale 클라이언트 | 접근 장치에 필요 | 외부 방문자에게 불필요 |
| HTTPS | 지원 | 필수 |
| 접근 제어 | Tailnet 정책 적용 | 별도 공개 서비스 보안 필요 |
| 대표 용도 | Grafana, Jenkins | Webhook, 데모 |
| 공개 중계 | 필요 없음 | Funnel 인프라 경유 |
| 인터넷 공개 위험 | 낮음 | 상대적으로 높음 |

### 6.1 선택 기준

Serve가 적합한 경우:

회사 내부 구성원이나 개발자만 접근해야 하는 서비스입니다. 예를 들어 사내 관리자 페이지, 모니터링 시스템, 개발용 API에 적합합니다.

Funnel이 적합한 경우:

Tailscale을 설치하지 않은 외부 사용자나 외부 시스템에서도 접근해야 하는 서비스입니다. 예를 들어 외부 Webhook 수신이나 데모용 웹 애플리케이션에 적합합니다.

결국 두 기능은 "동일한 로컬 애플리케이션을 어느 네트워크 범위까지 공개할 것인가"를 기준으로 구분하면 됩니다.

---

## 7. Subnet Router

Subnet Router는 "Tailscale이 설치되지 않은 장치가 속한 사설 네트워크에 접근할 수 있도록 하는 라우터 기능"입니다.

일반적으로 Tailnet에 참여하려면 각 장치에 Tailscale을 설치해야 합니다.

하지만 데이터베이스, NAS, 내부 네트워크 장비 등 모든 장치에 Tailscale을 설치하기 어려운 경우가 있습니다.

이때 Subnet Router를 사용합니다.

```
Tailnet
  |
  +-- Laptop (100.101.1.1)
  |
  +-- Subnet Router (100.101.1.2)
          |
          +-- 192.168.10.0/24
                |
                +-- DB Server (192.168.10.10)
                +-- NAS       (192.168.10.20)
                +-- VM        (192.168.10.30)
```

Subnet Router가 `192.168.10.0/24` 네트워크의 경로를 Tailnet에 광고하면, 접근 권한과 라우팅 설정이 허용된 다른 장치에서 해당 네트워크에 접근할 수 있습니다.

### 주요 특징

- 사설망 전체를 Tailnet에 연결
- 모든 장치에 Tailscale을 설치할 필요 없음
- 온프레미스 네트워크 및 클라우드 VPC 연결 가능
- 특정 CIDR 대역에 대한 라우팅 제공
- ACL / Grants를 통한 접근 제어 가능

특히 AWS VPC의 Private Subnet이나 온프레미스 Kubernetes 네트워크를 외부 개발 장치와 연결할 때 유용합니다.

다만 Subnet Router만 설정한다고 양방향 통신이 자동으로 보장되는 것은 아닙니다. IP Forwarding, 경로 승인, 클라이언트의 경로 수락, 방화벽 및 반환 경로 등을 고려해야 합니다.

---

## 8. Exit Node

Exit Node는 "Tailnet 장치의 외부 인터넷 트래픽을 특정 장치를 통해 전달하는 기능"입니다.

Subnet Router가 특정 사설 네트워크에 접근하기 위한 기능이라면, Exit Node는 일반적인 인터넷 트래픽의 출구를 변경하는 기능입니다.

예를 들어 다음과 같은 구조입니다.

```
Laptop
  |
  | WireGuard VPN
  v
Exit Node (Home Server)
  |
  | Internet
  v
google.com / github.com / ...
```

Laptop에서 Exit Node를 활성화하면 일반적인 인터넷 트래픽도 Home Server를 경유할 수 있습니다.

### 활용 사례

- 외부 네트워크에서 집 또는 회사의 인터넷 회선 사용
- 공용 Wi-Fi 이용 시 인터넷 트래픽을 신뢰할 수 있는 장치로 전달
- 특정 네트워크의 공인 IP를 이용해야 하는 서비스 접근
- 사내 고정 IP 기반의 외부 서비스 접근

### Subnet Router와 Exit Node 비교

| 구분 | Subnet Router | Exit Node |
| --- | --- | --- |
| 목적 | 특정 사설망 접근 | 인터넷 트래픽 경유 |
| 대상 | 특정 CIDR | 일반적인 외부 트래픽 |
| 예시 | `192.168.10.0/24` | 인터넷 기본 경로 |
| 대표 용도 | VPC, LAN 연결 | VPN 인터넷 게이트웨이 |
| 기본 인터넷 경로 변경 | 일반적으로 없음 | 있음 |

Tailscale은 기본적으로 Split Tunnel 방식으로 동작하므로, Exit Node를 선택하지 않았다면 일반 인터넷 트래픽은 대체로 기존 인터넷 연결을 이용합니다.

---

## 9. DERP와 NAT Traversal

Tailscale은 가능한 경우 장치 간 직접적인 P2P 연결을 사용합니다.

하지만 모든 네트워크 환경에서 직접 연결이 가능한 것은 아닙니다.

예를 들어 다음과 같은 환경에서는 직접 연결이 어려울 수 있습니다.

- 엄격한 방화벽이 설치된 기업 네트워크
- UDP 통신이 제한된 네트워크
- NAT Traversal이 어려운 NAT 환경
- 장치 간 직접 통신이 차단된 환경

### 9.1 NAT Traversal

NAT Traversal은 NAT 뒤에 위치한 두 장치가 직접 통신할 수 있도록 연결 경로를 찾는 기술입니다.

Tailscale은 NAT 유형과 네트워크 연결 정보를 확인하고, 가능한 경우 UDP 기반 직접 연결을 구성합니다.

### 9.2 DERP

DERP(Designated Encrypted Relay for Packets)는 직접 연결이 어려울 때 사용하는 중계 시스템입니다.

```
직접 연결 가능한 경우
Node A <------ P2P ------> Node B

직접 연결이 불가능한 경우
Node A <----> DERP <----> Node B
```

DERP는 WireGuard로 암호화된 트래픽을 중계하며, 일반적으로 해당 트래픽을 복호화하지 않습니다.

다만 직접 연결에 비해 중계 경로가 추가되므로 지연 시간이나 처리 성능에 영향을 줄 수 있습니다.

여기서 중요한 점은 DERP와 Funnel의 차이입니다.

DERP는 "Tailnet 장치 간 연결을 위한 중계"이고, Funnel은 "외부 인터넷 사용자가 서비스에 접근하도록 공개하는 기능"입니다.

---

## 10. ACL과 Grants

Tailscale은 동일한 Tailnet에 연결되어 있다고 해서 모든 장치가 무조건 통신할 수 있도록 설계된 것은 아닙니다.

접근 제어 정책을 통해 누가 어떤 장치와 서비스에 접근할 수 있는지 관리할 수 있습니다.

### 10.1 ACL

ACL(Access Control List)은 장치 사이의 네트워크 접근 권한을 정의합니다.

예를 들어 다음과 같은 정책을 구성할 수 있습니다.

- 개발자 그룹은 개발 서버에 접근 가능
- 운영자 그룹만 운영 서버 SSH 접근 가능
- 일반 사용자는 데이터베이스 접근 불가

### 10.2 Grants

Grants는 Tailscale에서 권장하는 접근 제어 방식으로, 기존 ACL의 네트워크 접근 제어를 포괄하면서 애플리케이션 수준의 권한 모델도 지원합니다.

사용자, 그룹, 장치 태그와 목적지, 포트 등을 기준으로 권한을 구성할 수 있습니다.

### 10.3 Tags

Tags는 장치를 사용자 개인 계정이 아닌 역할이나 서비스 단위로 식별하기 위한 기능입니다.

예를 들어 다음과 같은 태그를 지정할 수 있습니다.

```
tag:dev
tag:prod
tag:database
tag:monitoring
```

이를 통해 사람에게 소유된 장치와 서버 인프라를 분리하여 관리하기 쉬워집니다.

특히 DevOps 환경에서 서버 접근 권한을 관리할 때 유용합니다.

---

## 11. Tailscale SSH

Tailscale SSH는 "Tailscale의 장치 인증과 접근 정책을 활용하여 SSH 접근을 관리하는 기능"입니다.

일반적인 SSH를 Tailnet IP로 사용하는 것과 Tailscale SSH를 사용하는 것은 서로 다릅니다.

일반 SSH는 기존 SSH 서버와 SSH 키 인증을 그대로 사용하면서 네트워크 연결만 Tailscale로 전달합니다.

반면 Tailscale SSH는 Tailscale이 SSH 연결의 인증과 인가를 관리합니다.

| 구분 | 일반 SSH over Tailscale | Tailscale SSH |
| --- | --- | --- |
| 네트워크 | Tailnet | Tailnet |
| SSH 인증 | 기존 SSH 인증 | Tailscale 인증 기반 |
| SSH 키 관리 | 일반적으로 필요 | 별도 사용자 키 관리 부담 감소 |
| 접근 정책 | 네트워크 정책 + SSH 설정 | 네트워크 정책 + SSH 정책 |
| 재인증 | SSH 구성에 따름 | Check Mode 지원 |

Tailscale SSH는 필요에 따라 재인증을 요구하거나 SSH 세션을 기록하도록 구성할 수 있습니다.

운영 서버의 SSH 포트를 퍼블릭 인터넷에 공개하지 않고 관리하고 싶을 때 유용합니다.

---

## 12. 주요 CLI 명령어

Tailscale의 개념을 실제로 활용하기 위해 자주 사용하는 명령어를 정리하면 다음과 같습니다.

참고로 질문의 `tailscale net`이 사설 네트워크를 의미한 것이라면 정확한 용어는 "Tailnet"입니다. 네트워크 상태 진단용 명령어는 `tailscale netcheck`입니다.

### 12.1 기본 연결 및 상태 관리

```bash
# Tailscale 네트워크 연결
sudo tailscale up

# 현재 상태 확인
tailscale status

# 내 Tailscale IPv4 확인
tailscale ip -4

# 네트워크 연결 진단
tailscale netcheck

# 다른 장치와 연결 확인
tailscale ping dev-server

# Tailscale 연결 해제
sudo tailscale down
```

### 12.2 Serve

```bash
# 로컬 3000 포트를 Tailnet 내부에 공개
tailscale serve 3000

# 백그라운드 실행
tailscale serve --bg 3000

# 현재 설정 확인
tailscale serve status

# Serve 설정 초기화
tailscale serve reset
```

`--bg` 옵션을 사용하면 명령을 종료해도 Serve 설정이 유지되며, 재부팅 이후에도 자동으로 다시 적용될 수 있습니다.

### 12.3 Funnel

```bash
# 로컬 3000 포트를 인터넷에 공개
tailscale funnel 3000

# 백그라운드 실행
tailscale funnel --bg 3000

# 공개 상태 확인
tailscale funnel status

# Funnel 설정 초기화
tailscale funnel reset
```

Serve와 Funnel의 활성화 과정에서 HTTPS 인증서 설정이나 관리자 승인이 필요할 수 있습니다.

### 12.4 Subnet Router

Linux 서버를 Subnet Router로 사용할 때의 간단한 예시입니다.

```bash
# IP Forwarding 활성화
sudo sysctl -w net.ipv4.ip_forward=1

# 사설망 경로 광고
sudo tailscale set \
  --advertise-routes=192.168.10.0/24
```

광고한 경로는 관리자 콘솔에서 승인해야 할 수 있으며, 클라이언트 측 경로 수락 설정과 라우팅 구성이 추가로 필요합니다.

### 12.5 Exit Node

```bash
# 현재 장치를 Exit Node로 광고
sudo tailscale set --advertise-exit-node

# 다른 장치에서 Exit Node 사용
sudo tailscale set \
  --exit-node=100.101.1.2

# Exit Node 사용 해제
sudo tailscale set --exit-node=
```

Exit Node로 사용하는 서버에는 IP Forwarding 설정과 관리자 승인 등의 사전 구성이 필요합니다.

### 12.6 Tailscale SSH

```bash
# 서버에서 Tailscale SSH 활성화
sudo tailscale set --ssh

# 클라이언트에서 SSH 연결
tailscale ssh ubuntu@dev-server
```

Tailscale SSH를 이용하려면 해당 장치에 대한 네트워크 접근 권한과 SSH 접근 정책이 모두 허용되어야 합니다.

명령어는 현재 공식 CLI 문서 기준이며, 구버전에서는 Serve 및 Funnel 명령의 문법이 다를 수 있습니다.

---

## 13. DevOps 인프라에서의 활용

Tailscale을 DevOps 인프라에 적용하면 외부에 직접 노출하지 않아도 되는 관리 서비스를 Tailnet 내부에 배치할 수 있습니다.

예를 들어 다음과 같은 구성이 가능합니다.

```
Developer Laptop
       |
       | Tailscale VPN
       |
       v
     Tailnet
       |
       +-- Dev Server
       |      |
       |      +-- SSH
       |      +-- Docker
       |      +-- Kubernetes
       |
       +-- Monitoring Server
       |      |
       |      +-- Serve
       |            |
       |            +-- Grafana
       |            +-- Prometheus UI
       |
       +-- Network Gateway
       |      |
       |      +-- Subnet Router
       |            |
       |            +-- Private Subnet
       |            +-- Database
       |
       +-- Webhook Server
              |
              +-- Funnel
                    |
                    +-- External Webhook
```

이러한 구성을 적용하면 기능별로 네트워크 접근 방식을 구분할 수 있습니다.

| 서비스 | 권장 구성 | 이유 |
| --- | --- | --- |
| 서버 SSH | Tailnet / Tailscale SSH | 사설 원격 접속 |
| Grafana | Serve | 내부 모니터링 |
| Jenkins | Serve | 내부 관리 UI |
| Kubernetes API | Tailnet / Subnet Router | 클러스터 사설 접근 |
| Private DB | Tailnet / Subnet Router | 데이터베이스 접근 제한 |
| 외부 Webhook | Funnel | 외부 요청 수신 |
| 일반 사용자 서비스 | ALB / Ingress 등 | 정식 공개 서비스 운영 |

Funnel은 테스트나 소규모 공개 서비스에 특히 편리하지만, 운영 서비스에서는 대역폭, 가용성, 인증, 보안, 트래픽 제어 등의 요구사항에 따라 일반적인 Load Balancer나 Ingress를 사용하는 것이 더 적합할 수 있습니다.

---

## 전체 요약

Tailscale은 단순히 장치 사이에 VPN을 연결하는 도구가 아니라 "사설 네트워크 구축부터 서비스 공개, 라우팅, 접근 제어까지 관리하는 네트워크 플랫폼"입니다.

핵심 구성 요소의 역할은 다음과 같습니다.

| 기능 | 핵심 개념 |
| --- | --- |
| Tailnet | Tailscale 사설 네트워크 |
| MagicDNS | 장치 이름으로 접근 |
| Serve | 내부 서비스 공유 |
| Funnel | 외부 서비스 공개 |
| Subnet Router | 특정 사설망 연결 |
| Exit Node | 인터넷 트래픽 경유 |
| DERP | P2P 연결 실패 시 중계 |
| ACL / Grants | 네트워크 접근 권한 관리 |
| Tailscale SSH | SSH 인증 및 접근 제어 |

전체 구조는 크게 세 가지 관점으로 이해하면 좋습니다.

1. "네트워크 연결": Tailnet, WireGuard, MagicDNS, DERP
2. "네트워크 확장 및 서비스 공개": Serve, Funnel, Subnet Router, Exit Node
3. "보안 및 접근 관리": ACL, Grants, Tags, Tailscale SSH

이처럼 Tailscale은 VPN으로 장치들을 연결하고, Serve 및 Funnel로 서비스 노출 범위를 결정하며, 라우팅과 접근 정책을 통해 인프라 전체의 네트워크를 관리할 수 있도록 해줍니다.

공식 문서는 Tailscale Documentation에서 확인할 수 있습니다.