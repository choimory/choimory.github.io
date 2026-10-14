---
title: "Karpenter란"
date: 2026-10-14T00:00:00
toc: true
categories: ["DevOps"]
tags: ["AWS", "EKS", "k8s", "Cloud"]
---

## 개요
Karpenter는 Kubernetes 클러스터의 노드 자동 확장을 담당하는 오픈소스 노드 프로비저너입니다. AWS가 개발하여 CNCF에 기부한 프로젝트로, 기존 Cluster Autoscaler(CA)의 한계를 극복하기 위해 설계되었습니다.

핵심 철학은 "just-in-time provisioning"으로, Pod가 Pending 상태가 되는 즉시 해당 Pod의 요구사항에 정확히 맞는 노드를 직접 클라우드 API를 통해 프로비저닝합니다.

## 핵심 개념
### Pending Pod 감지와 프로비저닝 흐름
kube-scheduler가 노드를 찾지 못해 Pod를 Pending 상태로 두면, Karpenter가 해당 Pod의 리소스 요청, tolerations, nodeSelector, affinity 등을 분석하여 최적의 노드 타입을 결정하고 클라우드 API를 직접 호출합니다.

기존 CA와의 가장 큰 차이점은 Node Group(Auto Scaling Group) 없이도 동작한다는 것입니다.

### NodePool (구 Provisioner)
Karpenter v0.32 이상에서 NodePool 리소스로 이름이 변경되었습니다. Karpenter가 프로비저닝할 수 있는 노드의 허용 범위를 정의합니다.

```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["m5.large", "m5.xlarge", "c5.large"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1
        kind: EC2NodeClass
        name: default
  limits:
    cpu: "1000"
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
```

### EC2NodeClass
AWS 전용 설정(AMI, subnet, security group, IAM role 등)을 정의하는 리소스입니다. NodePool과 분리된 이유는 클라우드 프로바이더 중립적 설계 때문입니다.

## 주요 기능
### Consolidation (통합)
노드 수를 줄이기 위해 워크로드를 재배치하고 불필요한 노드를 제거하는 기능입니다.

- WhenUnderutilized: 노드 리소스 사용률이 낮을 때 통합
- WhenEmpty: 빈 노드만 제거

### Spot 인스턴스 처리
SQS 기반 이벤트 큐를 통해 Spot 인스턴스 중단 2분 전 알림을 감지하여 워크로드를 미리 다른 노드로 이동시킵니다.

### 멀티 인스턴스 타입 지원
단일 Pod에 대해 여러 인스턴스 타입을 후보로 두고, 비용과 가용성을 고려하여 최적을 선택합니다. (instance type flexibility)

## CA vs Karpenter 비교

| 항목 | Cluster Autoscaler | Karpenter |
|---|---|---|
| 프로비저닝 단위 | Node Group / ASG | 개별 인스턴스 (직접 API) |
| 인스턴스 타입 결정 | ASG 설정 기준 | Pod 요구사항 기반 동적 결정 |
| 반응 속도 | 느림 (수 분) | 빠름 (수십 초) |
| 비용 최적화 | 제한적 | Spot + 다양한 인스턴스 타입 조합 |
| 클라우드 지원 | 멀티 클라우드 | 주로 AWS |

## NKS 환경에서의 유의사항
Karpenter는 현재 AWS EKS에 최적화되어 있습니다. NCP NKS에서는 공식 Karpenter가 지원되지 않으며, NCP 자체 노드 오토스케일링 기능(NKS 노드 풀 자동 확장)을 별도로 제공합니다.
