---
title: "Terraform vs Pulumi"
date: 2026-06-09T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Terraform
    - Pulumi
    - IaC
---

# Terraform vs Pulumi

## 개요

IaC(Infrastructure as Code) 도구는 인프라를 코드로 선언하여 버전 관리, 자동화, 반복 가능한 배포를 가능하게 합니다. Terraform과 Pulumi는 현재 가장 널리 쓰이는 두 가지 대표적인 IaC 도구로, 철학과 접근 방식에서 근본적인 차이를 가집니다.

핵심 차이를 한 줄로 요약하면 이렇습니다.

- Terraform: 선언형 DSL(HCL)로 인프라를 정의한다
- Pulumi: 범용 프로그래밍 언어로 인프라를 코드처럼 작성한다

## 비교표

| 항목 | Terraform | Pulumi |
| --- | --- | --- |
| 언어 | HCL (HashiCorp Configuration Language) | Python, TypeScript, Go, C#, Java, YAML |
| 패러다임 | 선언형 DSL | 범용 프로그래밍 언어 (명령형 + 선언형) |
| 상태 관리 | tfstate 파일 (로컬 or 원격 backend) | Pulumi Cloud / Self-hosted / 로컬 |
| 조건 / 반복 | count, for_each, conditional expression (제한적) | 언어 기본 문법 (if, for, loop 등) |
| 테스트 | 별도 프레임워크 필요 (Terratest 등) | 언어 기본 테스트 프레임워크 사용 가능 |
| 추상화 / 재사용 | Module 단위 | 클래스, 함수, 라이브러리 등 언어 수준 추상화 |
| 학습 곡선 | 낮음 (HCL 단순) | 보통~높음 (언어별 상이) |
| 프로바이더 생태계 | 매우 넓음 (3,000+) | Terraform 프로바이더 연동 가능 (bridged) |
| 엔터프라이즈 기능 | Terraform Cloud / Enterprise | Pulumi Cloud (무료 티어 있음) |
| 라이선스 | BSL 1.1 (2023년 변경, 비 OSI) | Apache 2.0 |
| NCP 지원 | ✓ 공식 NCP Terraform Provider 존재 | △ 공식 지원 없음, Terraform bridge 통해 사용 가능 |

# Terraform

## 선언형 DSL, HCL

Terraform은 HashiCorp가 만든 HCL(HashiCorp Configuration Language)을 사용합니다. HCL은 JSON과 유사하지만 사람이 읽기 쉽게 설계된 DSL(Domain Specific Language)입니다. 인프라의 최종 상태를 선언하면, Terraform이 현재 상태와 비교해 필요한 변경만 수행합니다.

```hcl
resource "ncloud_server" "web" {
  name                      = "web-server"
  server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0703.B050"
  server_product_code       = "SVR.VSVR.STAND.C002.M008.NET.HDD.B050.G002"
}
```

## State 관리

Terraform은 `terraform.tfstate` 파일에 현재 인프라 상태를 기록합니다. 이 파일이 Terraform 작동의 핵심입니다.

- 로컬 state: 개인 프로젝트나 테스트 환경
- 원격 backend: S3, NCP Object Storage, GCS 등 — 팀 협업 필수
- State locking: 동시 apply 방지를 위해 DynamoDB나 NCP에서는 별도 구성 필요

## 장단점

장점

- 생태계가 압도적으로 넓습니다 (프로바이더 3,000개 이상)
- HCL 문법이 단순해 인프라 전담이 아닌 인원도 쉽게 읽고 리뷰 가능합니다
- NCP 공식 Provider가 존재합니다
- 커뮤니티, 레퍼런스, 문서가 풍부합니다

단점

- 복잡한 조건 로직이나 반복 처리가 불편합니다 (count, for_each의 한계)
- 함수 추상화나 재사용이 Module 단위로만 가능합니다
- 2023년 라이선스가 BSL 1.1로 변경되어 일부 상업적 사용에 제약이 생겼습니다 (OpenTofu가 fork로 등장한 배경)

# Pulumi

## 범용 언어로 인프라 작성

Pulumi는 Python, TypeScript, Go 등 이미 알고 있는 프로그래밍 언어로 인프라를 정의합니다. 단순한 선언을 넘어서, 언어의 모든 기능(조건문, 반복문, 클래스, 테스트 프레임워크)을 그대로 활용할 수 있습니다.

```python
import pulumi_ncloud as ncloud  # 공식 지원 없어 bridge 필요

server = ncloud.Server("web-server",
    name="web-server",
    server_image_product_code="SW.VSVR.OS.LNX64.CNTOS.0703.B050",
)

pulumi.export("server_id", server.id)
```

## Pulumi의 핵심 개념

### Stack

Pulumi에서 환경(dev/stage/prod)은 Stack으로 구분됩니다. Terraform의 workspace나 디렉터리 구조 분리와 유사한 개념입니다.

### 상태 저장소

상태는 기본적으로 Pulumi Cloud에 저장됩니다. 자체 호스팅(Self-managed)도 가능하며, 이 경우 S3나 NCP Object Storage 같은 오브젝트 스토리지를 backend로 사용할 수 있습니다.

### Terraform Provider 연동 (Bridged Provider)

Pulumi는 자체 프로바이더가 부족한 경우, Terraform Provider를 Pulumi용으로 변환해주는 `pulumi-terraform-bridge`를 제공합니다. NCP Provider도 이론적으로 이 방법으로 사용 가능하지만 공식 지원은 아닙니다.

## 장단점

장점

- 복잡한 조건/반복 로직을 언어 기본 문법으로 처리 가능합니다
- 기존 앱 코드와 동일한 언어, 동일한 테스트 방법론 사용 가능합니다
- 추상화와 재사용이 클래스/함수 수준으로 강력합니다
- Apache 2.0 라이선스로 Terraform BSL 이슈 없습니다

단점

- NCP 공식 지원이 없습니다
- 프로바이더 생태계가 Terraform보다 좁습니다
- 팀원 모두가 해당 언어를 알아야 합니다
- 학습 곡선이 언어와 Pulumi 개념 두 가지를 동시에 요구합니다

# 어떤 상황에서 무엇을 선택할까

## Terraform이 적합한 경우

- NCP처럼 공식 Terraform Provider가 존재하는 클라우드를 주로 사용할 때
- 인프라 팀과 개발 팀이 분리되어 있고, 인프라 리뷰 접근성이 중요할 때
- 이미 Terraform 기반 레거시가 있거나 팀 내 HCL 경험이 있을 때
- 복잡도가 낮은 인프라 (단순 리소스 선언 위주)

## Pulumi가 적합한 경우

- 인프라 로직이 복잡하고 조건/동적 생성이 많을 때
- 개발자가 직접 인프라를 관리하는 Platform Engineering 문화일 때
- 단위 테스트나 통합 테스트를 인프라 코드에도 적용하고 싶을 때
- 멀티 클라우드 추상화 레이어를 언어 수준에서 만들고 싶을 때

## 전체 요약

|  | Terraform | Pulumi |
| --- | --- | --- |
| 언어 | HCL (DSL) | Python / TS / Go 등 |
| 철학 | 선언형 | 프로그래밍 언어 기반 |
| 생태계 | 매우 넓음 | 좁음 (Terraform bridge 가능) |
| NCP 지원 | ✓ 공식 | △ 비공식 |
| 복잡 로직 | 제한적 | 자유로움 |
| 학습 곡선 | 낮음 | 보통~높음 |
| 라이선스 | BSL 1.1 | Apache 2.0 |
| 추천 상황 | 대부분의 현업 | 복잡 로직, 개발자 중심 팀 |

Terraform은 넓은 생태계와 단순함으로 현업 표준으로 자리잡았고, Pulumi는 개발자 경험과 언어 유연성을 무기로 점유율을 넓혀가고 있습니다. 둘을 경쟁 관계보다는 용도별 선택지로 보는 것이 정확합니다.

---

# Pulumi Java 예시

## 개요

Pulumi는 Java를 포함한 범용 프로그래밍 언어로 인프라를 정의할 수 있습니다. NCP 공식 Pulumi Provider가 없기 때문에, AWS Provider 기준의 실제 동작하는 Java 예시와, NCP를 쓴다면 구조가 어떻게 될지를 함께 정리합니다.

## 프로젝트 구조

```
my-pulumi-project/
├── src/
│   └── main/
│       └── java/
│           └── myproject/
│               └── App.java
├── Pulumi.yaml
└── pom.xml
```

## Pulumi.yaml

```yaml
name: my-pulumi-project
runtime: java
description: NCP infrastructure with Pulumi Java
```

## pom.xml (의존성)

```xml
<dependencies>
  <dependency>
    <groupId>com.pulumi</groupId>
    <artifactId>pulumi</artifactId>
    <version>0.9.9</version>
  </dependency>
  <dependency>
    <groupId>com.pulumi</groupId>
    <artifactId>aws</artifactId>
    <version>6.0.0</version>
  </dependency>
</dependencies>
```

## App.java — AWS EC2 기준 (실제 동작)

```java
package myproject;

import com.pulumi.Pulumi;
import com.pulumi.aws.ec2.Instance;
import com.pulumi.aws.ec2.InstanceArgs;
import com.pulumi.aws.ec2.SecurityGroup;
import com.pulumi.aws.ec2.SecurityGroupArgs;
import com.pulumi.aws.ec2.inputs.SecurityGroupIngressArgs;
import java.util.List;

public class App {
    public static void main(String[] args) {
        Pulumi.run(ctx -> {

            var sg = new SecurityGroup("web-sg", SecurityGroupArgs.builder()
                .description("Allow HTTP")
                .ingress(SecurityGroupIngressArgs.builder()
                    .protocol("tcp")
                    .fromPort(80)
                    .toPort(80)
                    .cidrBlocks(List.of("0.0.0.0/0"))
                    .build())
                .build());

            var server = new Instance("web-server", InstanceArgs.builder()
                .ami("ami-0c55b159cbfafe1f0")
                .instanceType("t3.micro")
                .vpcSecurityGroupIds(sg.id().applyValue(List::of))
                .tags(java.util.Map.of("Name", "web-server"))
                .build());

            ctx.export("publicIp", server.publicIp());
            ctx.export("instanceId", server.id());
        });
    }
}
```

## NCP라면 구조상 이렇게 됩니다 (가상 코드)

NCP 공식 Provider가 없으므로 실제 클래스는 없지만, bridge가 완성된다면 아래와 같은 구조가 됩니다.

```java
package myproject;

import com.pulumi.Pulumi;
// 가상의 NCP Provider 클래스 (현재 미존재)
import com.pulumi.ncloud.Server;
import com.pulumi.ncloud.ServerArgs;
import com.pulumi.ncloud.Vpc;
import com.pulumi.ncloud.VpcArgs;

public class App {
    public static void main(String[] args) {
        Pulumi.run(ctx -> {

            var vpc = new Vpc("main-vpc", VpcArgs.builder()
                .name("main-vpc")
                .ipv4CidrBlock("10.0.0.0/16")
                .build());

            var server = new Server("web-server", ServerArgs.builder()
                .name("web-server")
                .serverImageProductCode("SW.VSVR.OS.LNX64.CNTOS.0703.B050")
                .serverProductCode("SVR.VSVR.STAND.C002.M008.NET.HDD.B050.G002")
                .vpcNo(vpc.vpcNo())
                .build());

            ctx.export("serverId", server.id());
        });
    }
}
```

## Python vs Java 비교

| 항목 | Python | Java |
| --- | --- | --- |
| 코드량 | 적음 | 많음 (boilerplate) |
| 타입 안정성 | 약함 | 강함 (컴파일 타임 오류 감지) |
| IDE 지원 | 보통 | 뛰어남 (IntelliJ 자동완성 강력) |
| 런타임 | 빠른 시작 | JVM 기동 시간 있음 |
| 팀 적합성 | 스크립트 친숙한 팀 | 백엔드 Java 팀 |
| 빌드 도구 | pip | Maven / Gradle |

Java로 Pulumi를 쓰는 경우는 주로 기존 Java 백엔드 팀이 인프라도 같은 언어로 관리하고 싶을 때입니다. 타입 안정성과 IDE 자동완성이 강력하지만, 코드량이 Python/TypeScript 대비 눈에 띄게 많아지는 것이 트레이드오프입니다.

---

# Java의 var (Local Variable Type Inference)

## 개요

Java 10(2018년 출시)부터 지역 변수 선언 시 타입을 명시하는 대신 `var`를 쓸 수 있습니다. 컴파일러가 오른쪽 표현식을 보고 타입을 추론합니다. 런타임에 `var`라는 타입이 존재하는 게 아니라, 컴파일 타임에 타입이 이미 확정됩니다.

```java
// 기존 방식
SecurityGroup sg = new SecurityGroup("web-sg", SecurityGroupArgs.builder()...build());

// var 사용 (완전히 동일한 의미, 타입은 컴파일 타임에 SecurityGroup으로 결정됨)
var sg = new SecurityGroup("web-sg", SecurityGroupArgs.builder()...build());
```

## 제약 조건

`var`는 지역 변수에만 사용 가능합니다. 아래 경우에는 사용할 수 없습니다.

```java
// 불가 — 클래스 필드
private var name = "hello";

// 불가 — 메서드 파라미터
public void foo(var x) { }

// 불가 — 초기값 없는 선언
var x;

// 불가 — null 초기화 (타입 추론 불가)
var x = null;
```

## JavaScript/TypeScript의 var와 다른 점

이름이 같아서 혼동할 수 있는데 전혀 다른 개념입니다.

|  | Java var | JS var |
| --- | --- | --- |
| 타입 | 컴파일 타임에 확정, 정적 타입 | 동적 타입, 런타임 결정 |
| 재할당 타입 변경 | 불가 | 가능 |
| 도입 목적 | 타입 명시 생략으로 가독성 향상 | 변수 선언 |
| 스코프 | 블록 스코프 | 함수 스코프 |

```java
var x = 42;       // int로 확정
x = "hello";      // 컴파일 에러 — 타입 변경 불가
```

Pulumi Java 예시에서 `var sg`, `var server`처럼 쓴 것은 긴 제네릭 타입명을 반복하지 않으려는 의도입니다. Pulumi 공식 문서 예시에서도 이 스타일을 권장하고 있습니다.