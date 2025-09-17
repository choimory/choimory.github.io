---
title: "MySQL 실행계획(explain plan)"
date: 2025-09-17T00:00:00
toc: true
toc_sticky: true
categories:
    - DB
tags:
    - MySQL
    - MariaDB
    - QueryTunning
---

# Intro

- MySQL에서 `EXPLAIN` 명령어는 쿼리 실행 계획을 보여주어, 쿼리가 어떻게 실행될지에 대한 정보를 제공한다.
- 이를 통해 쿼리 성능을 최적화할 수 있다.
- `EXPLAIN`을 사용하면 MySQL이 테이블을 어떻게 읽고, 인덱스를 어떻게 사용하며, 최적화가 필요한 부분이 있는지 확인할 수 있다.

```sql
EXPLAIN SELECT * FROM table_name WHERE condition;
```

---

# `EXPLAIN`의 주요 필드

## **id**:

- 쿼리의 순서 또는 실행 순서를 나타낸다.
- `id`가 같은 경우는 동시에 실행되고, 숫자가 클수록 먼저 실행되는 하위 쿼리를 의미한다.

## **select_type**:

- 쿼리의 유형을 설명한다.
- **SIMPLE:** 서브쿼리나 UNION 없이 단순한 SELECT 쿼리.
- **PRIMARY:** 가장 외부의 SELECT 쿼리.
- **SUBQUERY:** 서브쿼리로서 다른 SELECT 안에 포함된 SELECT.
- **DERIVED:** 파생 테이블(서브쿼리의 결과를 임시 테이블로 처리).

## **table**:

- 쿼리에 사용되는 테이블의 이름을 나타낸다.

## **partitions**:

- 사용된 파티션을 나타낸다.
- 파티셔닝된 테이블을 사용할 때 관련 정보를 제공한다.

## **type**:

- 조인 타입 또는 테이블에서 데이터를 읽는 방법을 나타낸다.
- 이는 쿼리 성능에 중요한 요소다.
- **ALL**:
    - 풀 테이블 스캔. 테이블 전체를 읽는다.
- **index**:
    - 인덱스를 사용하지만 테이블 전체를 스캔한다.
- **range**:
    - 인덱스 범위 스캔. 조건에 맞는 범위만 읽는다.
- **ref**:
    - 인덱스를 사용하여 값에 따라 테이블을 검색한다.
- **eq_ref**:
    - 인덱스를 사용해 단일 값을 검색한다. 주로 기본 키나 유니크 키를 활용.
- **const/system**:
    - 상수처럼 값을 조회할 때, 단일 행만 반환한다.

## **possible_keys**:

- 쿼리에서 사용할 수 있는 인덱스를 나타낸다.
- 이 필드는 데이터베이스가 쿼리 최적화를 위해 어떤 인덱스를 사용할 수 있는지 보여준다.

## **key**:

- 실제로 사용된 인덱스를 나타낸다.
- `NULL`이면 인덱스를 사용하지 않은 것이다.

## **key_len**:

- 사용된 인덱스의 길이를 나타낸다.
- 인덱스가 효율적으로 사용되었는지 확인할 수 있다.

## **ref**:

- `key` 필드에서 사용된 인덱스의 비교 대상이 되는 값이나 컬럼을 나타낸다.

## **rows**:

- 쿼리 실행 시 예상되는 읽기 행 수를 나타낸다.
- 이 숫자가 클수록 쿼리가 느릴 가능성이 높다.

## **filtered**:

- 쿼리에서 필터링될 것으로 예상되는 행의 비율을 백분율로 나타낸다.

## **Extra**:

- 추가적인 정보를 제공하는 필드로, 쿼리 최적화와 관련된 정보를 제공한다.
- **Using index**:
    - 인덱스만 사용하여 데이터를 조회한다. 테이블의 데이터를 읽지 않으므로 성능에 유리하다.
- **Using where**:
    - `WHERE` 조건을 사용하여 행을 필터링하고 있음을 의미한다.
- **Using temporary**:
    - 쿼리 실행 시 임시 테이블을 사용한다.
- **Using filesort**:
    - 데이터가 정렬되어 있지 않아, 정렬을 위해 파일 정렬을 수행한다.

---

# 예시

```sql
EXPLAIN SELECT * FROM employees WHERE salary > 50000;
```

- 출력 예시:

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | Extra |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | SIMPLE | employees | range | salary_index | salary_index | 5 | NULL | 2000 | Using where |
- 이 예시는 `employees` 테이블에서 `salary` 조건을 사용하여 인덱스 범위 스캔(`range`)을 수행하며, `WHERE` 조건을 통해 데이터를 필터링한다는 것을 보여준다.