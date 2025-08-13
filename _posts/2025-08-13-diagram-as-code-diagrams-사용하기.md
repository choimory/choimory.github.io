---
title: "Diagram as code, Diagrams 사용하기"
date: 2025-08-13T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Tool
    - Architecture
---

# Introduce

- https://diagrams.mingrammer.com/
- 서비스 구조 등 다이어그램을 그리는 작업을 파이썬 코드로 작성하여 이미지를 생성할 수 있음

# Installation

```bash
# 파이썬 설치 및 확인
brew install python
python3 --version
pip3 --version

# VSC 설치
brew install --cask visual-studio-code

# 실행
open /Applications/Visual\ Studio\ Code.app

# graphviz (그림 생성에 사용)
brew install graphviz
dot -V

# 가상환경 생성
mkdir ~/hello-diagrams
cd ~/hello-diagrams
python3 -m venv venv
source venv/bin/activate

# diagrams 설치
pip install diagrams
pip show diagrams

# vsc로 실행
code .
```

# code

```python
from diagrams import Diagram
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB
from diagrams.aws.database import RDS

with Diagram("Simple Web Service", show=True):
    ELB("lb") >> EC2("web") >> RDS("db")

```

- vsc에서 새 파일 만들고 이름은 web_diagram.py

# run

```bash
# py 가상환경 활성화 된 상태에서 터미널에
python web_diagram.py
```

- `Simple Web Service.png`라는 이미지 파일이 생성되고 자동으로 미리보기 앱에서 열리게 됨

# code 상세

- 크게 다섯가지로 나눌수 있음
    1. **노드(Node):** EC2, RDS, S3, Redis, Kubernetes Pod 등 리소스를 뜻하는 아이콘
    2. **엣지(Edge):** >> 또는 << 로 노드를 연결 (→ 또는 ←)
    3. **그룹(Cluster):** 리소스들을 박스로 묶어서 계층 표현
    4. **방향(Direction):** → ↓ 등으로 배치 방향 설정
    5. **아이콘 카테고리:** AWS, Azure, GCP, Kubernetes, On-Prem 등

## 1. 기본 문법

```python
from diagrams import Diagram
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS

with Diagram("Simple Diagram", direction="LR"):
    EC2("web") >> RDS("db")
```

- `EC2("이름")`: 노드 생성
- `>>`: 화살표 연결
- `direction="LR"`: Left → Right

---

## 2. 방향 옵션 (배치)

| 옵션 | 의미 |
| --- | --- |
| `TB` | 위 → 아래 (Top → Bottom) |
| `LR` | 왼쪽 → 오른쪽 (Left → Right) |
| `BT` | 아래 → 위 (Bottom → Top) |
| `RL` | 오른쪽 → 왼쪽 (Right → Left) |

---

## 3. 클러스터 (그룹)

```python
from diagrams import Cluster

with Cluster("Web Servers"):
    web1 = EC2("web1")
    web2 = EC2("web2")
```

- 클러스터는 시각적으로 박스 그룹으로 묶임
- `[]`나 `list`로 연결 가능:
    
    ```python
    python
    복사편집
    lb >> [web1, web2]
    
    ```
    

---

## 4. 리소스 종류별 import 경로

### AWS 예시

```python
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.network import ELB, Route53
from diagrams.aws.database import RDS, Dynamodb
from diagrams.aws.storage import S3
```

### GCP 예시

```python
from diagrams.gcp.compute import GCE
from diagrams.gcp.database import SQL
from diagrams.gcp.storage import GCS

```

### Azure 예시

```python
from diagrams.azure.compute import VirtualMachines
from diagrams.azure.network import LoadBalancers
```

### Kubernetes

```python
from diagrams.k8s.compute import Pod, Deployment
from diagrams.k8s.network import Service
from diagrams.k8s.ecosystem import Helm

```

### 🧱 On-Prem / 기타

```python
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.compute import Server
from diagrams.onprem.client import Users
from diagrams.programming.language import Python
from diagrams.generic.device import Mobile
```

---

## 5. 예시: 클러스터 + 여러 노드 + 연결

```python
from diagrams import Diagram, Cluster
from diagrams.aws.network import ELB
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS

with Diagram("Web Service", direction="LR"):
    lb = ELB("load balancer")

    with Cluster("Web Tier"):
        web_nodes = [EC2("web1"), EC2("web2"), EC2("web3")]

    db = RDS("database")

    lb >> web_nodes >> db
```

---

## 6. 조건/루프도 표현 가능?

diagrams는 논리구조를 그리기 위한 도구는 아니라서 **조건문, 루프 같은 알고리즘 흐름도**에는 안 맞아. 하지만 복잡한 병렬 처리 구조, 데이터 흐름은 충분히 표현 가능함.

---

## 7. 커스텀 노드 (이미지로 직접 만들기)

```python
from diagrams import Node

class CustomNode(Node):
    _provider = "custom"
    _icon_dir = "path/to/your/icons"
    fontcolor = "#000000"

    def __init__(self, label: str, icon: str):
        super().__init__(label, icon)
```

- 직접 아이콘을 넣고 싶을 때 사용함.

---

## 8. 유용한 아이콘 종류 빠른 참조

- `diagrams.aws.compute.EC2`, `Lambda`, `AutoScaling`
- `diagrams.aws.network.ELB`, `Route53`, `VPC`, `CloudFront`
- `diagrams.aws.database.RDS`, `DynamoDB`, `Aurora`
- `diagrams.aws.storage.S3`, `EFS`
- `diagrams.onprem.client.Users`, `Laptop`
- `diagrams.generic.device.Mobile`, `Tablet`
- 그 외 전체 목록:
    - https://diagrams.mingrammer.com/docs/nodes/aws

# 그 외

- python 실행할때의 venv는 프로젝트별 라이브러리 및 환경 저장하는곳
- `source vent/bin/active`한거 신경쓰면 그냥 `deactive`해주면 되지만 어차피 큰 의미없고 안쓰면 프로젝트 디렉토리 지우면 끝

# ref

- https://diagrams.mingrammer.com/