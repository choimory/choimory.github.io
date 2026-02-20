---
title: "트랜잭션 격리수준(Transaction Isolation level)"
date: 2025-11-04T00:00:00
toc: true
toc_sticky: true
categories:
    - DB
tags:
    - Transaction
---

# Intro

- *트랜잭션 격리 수준(Transaction Isolation Level)*은 **데이터베이스의 트랜잭션 간 상호작용을 제어**하는 방법을 정의하는 개념이다.
- 다중 트랜잭션이 동시에 수행될 때, 각 트랜잭션이 다른 트랜잭션의 중간 결과나 데이터를 볼 수 있는지, 어떻게 상호작용하는지를 결정한다.
- 격리 수준이 높을수록 트랜잭션 간의 간섭이 줄어들지만, 동시에 성능이 저하될 수 있다.

---

# 동시성 문제들

## **Dirty Read (더티 리드)**:

- 한 트랜잭션이 **다른 트랜잭션이 커밋되지 않은 변경사항**을 읽는 현상.
- A 트랜잭션에서 데이터를 변경한 후 아직 커밋하지 않았을 때, B 트랜잭션이 이 변경된 데이터를 읽을 수 있는 상황이다.

## **Non-Repeatable Read (반복 불가능한 읽기)**:

- 같은 트랜잭션 내에서 **같은 쿼리를 여러 번 실행할 때, 값이 달라지는 현상**.
- A 트랜잭션에서 데이터를 읽은 후, B 트랜잭션에서 데이터를 수정하고 커밋한 경우 A가 다시 읽었을 때 다른 결과를 얻는 상황이다.

## **Phantom Read (팬텀 리드)**:

- 한 트랜잭션에서 범위 쿼리를 수행했을 때, **다른 트랜잭션이 데이터를 삽입하거나 삭제하여 레코드 갯수가 달라지는 현상**.
- A 트랜잭션에서 범위 쿼리를 실행한 후, B 트랜잭션이 새로운 데이터를 삽입한 경우 A가 다시 같은 범위 쿼리를 실행했을 때 추가된 데이터를 읽게 되는 현상이다.

---

# 트랜잭션 격리 수준의 종류

## **READ UNCOMMITTED (커밋되지 않은 읽기 허용)**:

- 가장 낮은 격리 수준으로, **다른 트랜잭션이 커밋하지 않은 변경사항을 읽을 수 있다**.
- 이는 **Dirty Read**를 허용하며, 성능은 가장 높지만, 데이터의 무결성이 낮아질 수 있다.
- **허용되는 문제**: Dirty Read, Non-Repeatable Read, Phantom Read
- **특징**: 트랜잭션 격리보다는 성능이 중요할 때 사용.

```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
```

## **READ COMMITTED (커밋된 데이터만 읽기 허용)**:

- 트랜잭션이 **커밋된 데이터만 읽을 수 있다**.
- **Dirty Read는 방지**되지만, 같은 트랜잭션 내에서 데이터를 반복해서 읽을 때 **Non-Repeatable Read**가 발생할 수 있다.
- **허용되는 문제**: Non-Repeatable Read, Phantom Read
- **특징**: 대부분의 DBMS에서 기본 격리 수준으로 사용되며, 일반적인 읽기 작업에 적합하다.

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

## **REPEATABLE READ (반복 가능 읽기)**:

- 트랜잭션이 데이터를 처음 읽었을 때부터 **변경되지 않은 데이터만 계속 읽을 수 있다**.
- 이는 **Dirty Read**와 **Non-Repeatable Read**를 방지하지만, **Phantom Read**는 여전히 발생할 수 있다.
- **허용되는 문제**: Phantom Read
- **특징**: 데이터가 읽히는 동안 데이터의 일관성을 유지하면서, 데이터베이스 성능을 크게 떨어뜨리지 않는 수준이다. MySQL에서는 기본 격리 수준으로 사용된다.

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

## **SERIALIZABLE (직렬화 가능)**:

- 가장 높은 수준의 격리로, **완벽하게 트랜잭션을 분리**하여 동시 실행되는 트랜잭션들이 마치 하나씩 순차적으로 실행되는 것처럼 동작하게 한다.
- **Dirty Read, Non-Repeatable Read, Phantom Read 모두 방지**된다.
- **허용되는 문제**: 없음
- **특징**: 동시성이 낮아져 **성능이 저하**되지만, 데이터의 **일관성이 가장 강력하게 보장**된다. 매우 높은 데이터 무결성이 요구되는 환경에서 사용된다.

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

---

# 비교

| 격리 수준 | Dirty Read | Non-Repeatable Read | Phantom Read | 성능 |
| --- | --- | --- | --- | --- |
| **READ UNCOMMITTED** | 허용 | 허용 | 허용 | 매우 높음 |
| **READ COMMITTED** | 차단 | 허용 | 허용 | 높음 |
| **REPEATABLE READ** | 차단 | 차단 | 허용 | 보통 |
| **SERIALIZABLE** | 차단 | 차단 | 차단 | 낮음 |

| 격리 수준 | 특징 | 동시성 문제 | 장점 | 단점 |
| --- | --- | --- | --- | --- |
| READ UNCOMMITTED | 커밋되지 않은 데이터를 읽을 수 있음 | Dirty Read 발생 가능 | 가장 빠른 성능 | 데이터 일관성 및 무결성 보장되지 않음 |
| READ COMMITTED | 커밋된 데이터만 읽을 수 있음 | Non-Repeatable Read 발생 가능 | Dirty Read 방지, 대부분의 DBMS 기본 설정 | Non-Repeatable Read 발생 가능 |
| REPEATABLE READ | 한 트랜잭션 내에서 동일한 데이터를 여러 번 읽어도 같은 결과를 보장 | Phantom Read 발생 가능 | Non-Repeatable Read 방지 | Phantom Read 발생 가능 |
| SERIALIZABLE | 트랜잭션을 순차적으로 실행하여 동시성 문제를 완전히 방지 | 동시성 문제 없음 | 모든 동시성 문제 해결 | 가장 느린 성능 |

# 정리

- **트랜잭션 격리 수준**은 데이터베이스의 **동시성**과 **데이터 일관성** 사이의 균형을 맞추는 중요한 개념이다.
- 더 높은 격리 수준은 데이터의 일관성을 더 강력하게 보장하지만, **성능 저하**를 초래할 수 있다.
- 반대로, 낮은 격리 수준은 성능은 좋지만 **데이터 무결성**에 문제가 생길 수 있다.
- 따라서, 시스템의 요구 사항에 맞춰 **격리 수준을 적절히 선택**하는 것이 중요하다.