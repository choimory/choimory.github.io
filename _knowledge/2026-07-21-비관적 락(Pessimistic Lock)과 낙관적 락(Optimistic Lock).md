---
title: "비관적 락(Pessimistic Lock)과 낙관적 락(Optimistic Lock)"
date: 2026-07-21T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Lock
---

# 비관적 락(Pessimistic Lock)과 낙관적 락(Optimistic Lock)

## 개요

동시에 여러 사용자가 같은 데이터를 수정할 수 있는 환경에서는 "동시성(Concurrency)" 문제가 발생할 수 있습니다. 이를 해결하는 대표적인 방법이 "비관적 락"과 "낙관적 락"입니다.

핵심 차이는 다음과 같습니다.

- "비관적 락": 충돌이 자주 발생한다고 가정하고 미리 잠급니다.
- "낙관적 락": 충돌이 거의 없다고 가정하고 마지막에 확인합니다.

---

## 비관적 락 (Pessimistic Lock)

### 개념

데이터를 읽는 순간부터 다른 트랜잭션이 수정하지 못하도록 DB에서 락을 걸어버리는 방식입니다.

즉,

> "누군가 수정할 수도 있으니 미리 잠가두자."
> 

라는 전략입니다.

### 동작 과정

```
사용자 A
SELECT ... FOR UPDATE

      ↓
DB Row Lock 획득

      ↓
사용자 B
같은 데이터 수정 시도

      ↓
대기(Blocking)

      ↓
A Commit

      ↓
B 실행
```

예시

```sql
BEGIN;

SELECT *
FROM account
WHERE id = 1
FOR UPDATE;

UPDATE account
SET balance = balance - 1000
WHERE id = 1;

COMMIT;
```

`FOR UPDATE`를 사용하면 해당 Row에 Exclusive Lock이 걸립니다.

### 장점

- 데이터 충돌이 거의 발생하지 않습니다.
- Lost Update 문제가 없습니다.
- 구현이 비교적 단순합니다.

### 단점

- 다른 트랜잭션이 대기해야 합니다.
- 성능이 떨어질 수 있습니다.
- 데드락이 발생할 가능성이 있습니다.

### 적합한 상황

- 은행 계좌
- 재고 차감
- 포인트 사용
- 결제

---

## 낙관적 락 (Optimistic Lock)

### 개념

읽을 때는 아무 락도 걸지 않습니다.

수정하는 순간 "내가 읽은 이후 누군가 수정했는지"만 검사합니다.

즉,

> "설마 다른 사람이 수정했겠어."
> 

라는 전략입니다.

### Version 컬럼 사용

보통 Version 컬럼을 하나 둡니다.

```
id | name | version
-------------------
1  | Kim  | 3
```

사용자가 읽을 때

```
version = 3
```

수정 시

```sql
UPDATE member
SET name='Lee',
    version=4
WHERE id=1
AND version=3;
```

만약 다른 사람이 먼저 수정했다면 `version = 4`가 되어 있기 때문에 업데이트 대상이 0건이 됩니다.

그러면 애플리케이션은 동시 수정이 발생했다고 판단합니다.

### 동작 과정

```
A 조회(version=3)

B 조회(version=3)

A 수정
version=4

B 수정 시도

WHERE version=3

↓

0 rows

↓

충돌 감지
```

### 장점

- 락을 오래 잡지 않습니다.
- 성능이 좋습니다.
- 데드락이 거의 없습니다.
- 읽기가 많은 서비스에 적합합니다.

### 단점

- 충돌이 발생하면 재시도해야 합니다.
- 충돌이 많으면 오히려 성능이 나빠질 수 있습니다.
- 구현이 조금 더 복잡합니다.

### 적합한 상황

- 게시글 수정
- 회원 정보 수정
- 관리자 화면
- 대부분의 CRUD 서비스

---

## Spring Boot에서 사용

### 비관적 락

JPA

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select m from Member m where m.id = :id")
Member find(Long id);
```

실제로는 다음과 같은 SQL이 실행됩니다.

```sql
SELECT ...
FOR UPDATE
```

### 낙관적 락

엔티티에 Version 컬럼을 추가합니다.

```java
@Version
private Long version;
```

JPA가 자동으로 `WHERE version = ?` 조건을 추가합니다.

충돌하면 `OptimisticLockException`이 발생합니다.

---

## 언제 무엇을 사용할까?

| 항목 | 비관적 락 | 낙관적 락 |
| --- | --- | --- |
| 락 획득 | 조회 시 즉시 | 수정 시 검증 |
| 성능 | 상대적으로 낮음 | 높음 |
| 충돌 처리 | 대기 | 실패 후 재시도 |
| 데드락 | 가능 | 거의 없음 |
| 읽기 성능 | 낮음 | 높음 |
| 구현 난이도 | 쉬움 | 약간 복잡 |
| 추천 상황 | 금융, 재고, 결제 | 게시판, 일반 CRUD |

---

## 재고 예시

재고가 1개 남은 상품을 두 사람이 동시에 구매한다고 가정합니다.

### 비관적 락

```
A 구매 시작
↓
상품 Lock
↓
B 구매
↓
대기
↓
A 구매 완료
↓
B 실행
↓
재고 없음
```

항상 순서대로 처리됩니다.

### 낙관적 락

```
A 조회 (재고 1, version=5)

B 조회 (재고 1, version=5)

↓

A 구매 성공
version=6

↓

B 구매

WHERE version=5

↓

실패

↓

재시도 또는 "품절"
```

잠그지는 않지만 충돌을 감지하여 잘못된 업데이트를 막습니다.

---

## 전체 요약

- "비관적 락"은 데이터 충돌을 미리 방지하기 위해 조회 시점부터 DB 락을 걸어 다른 트랜잭션을 대기시키는 방식입니다. 충돌이 잦거나 데이터 정합성이 매우 중요한 금융, 재고, 결제 시스템에 적합합니다.
- "낙관적 락"은 조회 시에는 락을 걸지 않고 수정 시점에 `version` 등의 값을 비교해 충돌 여부를 확인하는 방식입니다. 성능이 좋고 데드락 위험이 적어 일반적인 웹 서비스와 CRUD 작업에 널리 사용됩니다.
- 일반적으로 "충돌 가능성이 낮고 읽기가 많은 서비스"는 낙관적 락을, "충돌 가능성이 높고 절대 데이터가 틀리면 안 되는 서비스"는 비관적 락을 선택하는 것이 적합합니다.