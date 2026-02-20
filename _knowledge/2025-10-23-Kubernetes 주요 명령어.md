---
title: "Kubernetes 주요 명령어"
date: 2025-10-23T00:00:00
toc: true
toc_sticky: true
categories:
    - DevOps
tags:
    - Kubernetes
---
 
# Intro

Kubernetes(k8s)는 컨테이너 오케스트레이션 플랫폼으로, kubectl이라는 CLI 도구를 통해 클러스터를 관리한다. kubectl 명령어는 리소스 관리, 디버깅, 모니터링 등 다양한 작업을 수행하며, 선언적 방식(YAML)과 명령형 방식 모두를 지원한다.

## 클러스터 정보 및 상태 확인

- `kubectl cluster-info`: 클러스터의 마스터 및 서비스 정보 확인
- `kubectl get nodes`: 클러스터 내 노드 목록과 상태 조회
- `kubectl get componentstatuses`: 컨트롤 플레인 컴포넌트 상태 확인
- `kubectl version`: kubectl 클라이언트와 서버 버전 확인

## Pod 관리

- `kubectl get pods`: 네임스페이스 내 모든 Pod 목록 조회
- `kubectl get pods -o wide`: IP, 노드 정보 등 상세 정보 포함 조회
- `kubectl describe pod <pod-name>`: Pod의 상세 정보, 이벤트, 상태 확인
- `kubectl logs <pod-name>`: Pod의 로그 출력 확인
- `kubectl logs -f <pod-name>`: 실시간 로그 스트리밍
- `kubectl exec -it <pod-name> -- /bin/bash`: Pod 내부 컨테이너 접속
- `kubectl delete pod <pod-name>`: Pod 삭제
- `kubectl port-forward <pod-name> 8080:80`: 로컬에서 Pod로 포트 포워딩

## Deployment 관리

- `kubectl create deployment <name> --image=<image>`: Deployment 생성
- `kubectl get deployments`: Deployment 목록 조회
- `kubectl describe deployment <name>`: Deployment 상세 정보 확인
- `kubectl scale deployment <name> --replicas=3`: 레플리카 수 조정
- `kubectl rollout status deployment/<name>`: 롤아웃 진행 상태 확인
- `kubectl rollout history deployment/<name>`: 배포 히스토리 조회
- `kubectl rollout undo deployment/<name>`: 이전 버전으로 롤백
- `kubectl set image deployment/<name> <container>=<new-image>`: 이미지 업데이트

## Service 관리

- `kubectl get services` 또는 `kubectl get svc`: Service 목록 조회
- `kubectl expose deployment <name> --port=80 --type=LoadBalancer`: Service 생성
- `kubectl describe service <name>`: Service 상세 정보 및 엔드포인트 확인
- `kubectl delete service <name>`: Service 삭제

## ConfigMap 및 Secret 관리

- `kubectl create configmap <name> --from-literal=key=value`: ConfigMap 생성
- `kubectl get configmaps`: ConfigMap 목록 조회
- `kubectl describe configmap <name>`: ConfigMap 내용 확인
- `kubectl create secret generic <name> --from-literal=password=1234`: Secret 생성
- `kubectl get secrets`: Secret 목록 조회
- `kubectl describe secret <name>`: Secret 메타데이터 확인 (값은 인코딩됨)

## 네임스페이스 관리

- `kubectl get namespaces` 또는 `kubectl get ns`: 네임스페이스 목록 조회
- `kubectl create namespace <name>`: 네임스페이스 생성
- `kubectl delete namespace <name>`: 네임스페이스 삭제
- `kubectl config set-context --current --namespace=<name>`: 기본 네임스페이스 변경
- `kubectl get pods -n <namespace>`: 특정 네임스페이스의 리소스 조회

## YAML 파일 기반 리소스 관리

- `kubectl apply -f <file.yaml>`: YAML 파일로 리소스 생성/업데이트 (선언적)
- `kubectl create -f <file.yaml>`: YAML 파일로 리소스 생성 (명령형)
- `kubectl delete -f <file.yaml>`: YAML 파일로 정의된 리소스 삭제
- `kubectl get -f <file.yaml>`: YAML 파일에 정의된 리소스 상태 조회
- `kubectl diff -f <file.yaml>`: 현재 상태와 YAML 파일 비교

## 리소스 조회 및 포맷팅

- `kubectl get all`: 네임스페이스 내 주요 리소스 일괄 조회
- `kubectl get pods -o json`: JSON 형식으로 출력
- `kubectl get pods -o yaml`: YAML 형식으로 출력
- `kubectl get pods --selector=app=nginx`: 레이블 셀렉터로 필터링
- `kubectl get pods --field-selector=status.phase=Running`: 필드 셀렉터로 필터링
- `kubectl get events --sort-by=.metadata.creationTimestamp`: 이벤트를 시간순 정렬

## 디버깅 및 트러블슈팅

- `kubectl top nodes`: 노드의 CPU/메모리 사용량 확인 (Metrics Server 필요)
- `kubectl top pods`: Pod의 리소스 사용량 확인
- `kubectl get events`: 클러스터 이벤트 조회
- `kubectl describe`: 리소스의 상세 정보와 이벤트 확인
- `kubectl logs <pod-name> --previous`: 종료된 컨테이너의 이전 로그 확인
- `kubectl logs <pod-name> -c <container-name>`: 멀티 컨테이너 Pod의 특정 컨테이너 로그

## Context 및 Config 관리

- `kubectl config view`: kubeconfig 설정 확인
- `kubectl config get-contexts`: 사용 가능한 컨텍스트 목록 조회
- `kubectl config use-context <context-name>`: 다른 클러스터 컨텍스트로 전환
- `kubectl config current-context`: 현재 사용 중인 컨텍스트 확인

## 고급 명령어

- `kubectl attach <pod-name>`: 실행 중인 컨테이너에 연결
- `kubectl cp <pod-name>:/path /local/path`: Pod와 로컬 간 파일 복사
- `kubectl proxy`: 로컬에서 Kubernetes API 서버로 프록시 실행
- `kubectl auth can-i <verb> <resource>`: 현재 사용자의 권한 확인
- `kubectl drain <node-name>`: 노드를 스케줄링 불가능하게 하고 Pod 제거
- `kubectl cordon <node-name>`: 노드를 스케줄링 불가능하게 설정
- `kubectl uncordon <node-name>`: 노드를 다시 스케줄링 가능하게 설정

## 전체 요약

- **kubectl은 Kubernetes 클러스터를 관리하는 핵심 CLI 도구**로, 리소스 생성/조회/수정/삭제를 모두 수행한다
- **클러스터 및 노드 상태 확인** 명령어로 전체 인프라의 건강 상태를 모니터링한다
- **Pod 관리** 명령어는 컨테이너 실행, 로그 확인, 내부 접속 등 가장 기본적인 작업을 수행한다
- **Deployment, Service, ConfigMap, Secret** 등 주요 리소스별로 생성/조회/수정 명령어가 존재한다
- **YAML 파일 기반 관리**는 선언적 방식으로 인프라를 코드화하여 버전 관리가 가능하다
- **네임스페이스**를 활용하면 리소스를 논리적으로 격리하고 멀티 테넌트 환경을 구성할 수 있다
- **디버깅 명령어**(logs, describe, top, events)는 문제 해결과 성능 분석에 필수적이다
- **Context 관리**를 통해 여러 클러스터 간 전환이 가능하며, 멀티 클러스터 환경을 효율적으로 운영한다
- **고급 명령어**는 노드 관리, 권한 확인, 파일 전송 등 특수한 작업에 활용된다