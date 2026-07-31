---
title: "JPA Fetch Join 페이징"
date: 2026-08-01T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - JPA
---

## 개요

Spring Data JPA에서 fetch join과 페이징을 함께 사용하면 예상치 못한 문제가 자주 발생합니다. 특히 1:N 관계에서 fetch join을 페이징과 결합하면 메모리 페이징 경고나 데이터 누락 같은 심각한 이슈로 이어질 수 있습니다. 이 문제의 근본 원인과 해결 방법을 정리합니다.

---

## Fetch Join의 동작 원리

### Fetch Join이란

Fetch Join은 JPQL에서 연관된 엔티티를 함께 조회하도록 명시하는 구문입니다. 일반 join과 달리 SELECT 절에 연관 엔티티를 포함시켜서, 별도의 추가 쿼리 없이 한 번의 쿼리로 연관 데이터까지 가져옵니다.

```kotlin
@Query("SELECT t FROM Team t JOIN FETCH t.members WHERE t.id = :teamId")
fun findTeamWithMembers(@Param("teamId") teamId: Long): Team?
```

#### N+1 문제와의 관계

일반적으로 지연 로딩(LAZY) 설정에서 연관 엔티티에 접근하면, 그 시점마다 추가 쿼리가 발생합니다. 컬렉션을 순회하며 각 엔티티의 연관 데이터를 조회하면, 1번의 쿼리에 N번의 추가 쿼리가 발생하는 N+1 문제로 이어집니다. Fetch join은 이 문제를 join을 통해 한 번에 해결하는 방법입니다.

#### SQL 레벨에서의 결과

1:N 관계를 fetch join하면, SQL 레벨에서는 INNER JOIN이나 LEFT JOIN으로 변환되어 부모 row가 자식 row 수만큼 카티전 곱(cartesian product)으로 늘어납니다. 예를 들어 Team 1개에 Member가 3명이면, 결과 row는 3개가 됩니다. JPA는 이렇게 늘어난 row를 다시 엔티티 단위로 묶어서(distinct하게) 반환합니다.

---

## 1:N Fetch Join과 페이징의 충돌

### 왜 문제가 되는가

페이징은 SQL의 LIMIT/OFFSET을 기준으로 동작합니다. 그런데 1:N fetch join의 결과는 부모 기준이 아니라 row 기준으로 늘어난 상태입니다. 만약 LIMIT을 SQL 단계에서 그대로 적용하면, 하나의 부모 엔티티에 속한 자식 데이터가 중간에 잘려나갈 수 있습니다.

예를 들어 Team A가 Member 5명을 가지고 있는데 페이지 크기가 3이라면, SQL 레벨에서 LIMIT 3을 적용하면 Team A의 Member 3개만 조회되고 나머지 2개는 누락됩니다. 이는 명백한 데이터 정합성 문제입니다.

### Hibernate의 대응 방식

Hibernate는 이 문제를 막기 위해, 1:N 컬렉션을 fetch join하면서 페이징(setFirstResult, setMaxResults)이 동시에 적용된 경우 SQL에 LIMIT/OFFSET을 적용하지 않고, 전체 결과를 메모리로 가져온 다음 애플리케이션 레벨에서 페이징을 수행합니다. 이때 다음과 같은 경고 로그가 출력됩니다.

```
HHH90003004: firstResult/maxResults specified with collection fetch; applying in memory
```

#### 이 경고가 의미하는 위험

이 동작은 정합성은 지켜주지만 성능 측면에서 위험합니다. 전체 데이터를 메모리에 모두 로드한 후 자바 코드 레벨에서 자르기 때문에, 데이터가 많아질수록 메모리 사용량과 응답 시간이 비선형적으로 증가합니다. 운영 환경에서는 이 경고 로그 자체가 잠재적 장애 요인으로 간주되어야 합니다.

---

## 해결 방법

### 방법 1: 페이징 쿼리와 컬렉션 조회 분리 (BatchSize 활용)

가장 널리 권장되는 방법입니다. 먼저 ID만으로 페이징 쿼리를 수행하고, 이후 해당 ID 목록으로 fetch join 없이 컬렉션을 별도 조회합니다.

```kotlin
// 1단계: ID 기준으로 페이징 (fetch join 없음)
@Query("SELECT t FROM Team t WHERE t.department = :dept")
fun findTeamsByDept(@Param("dept") dept: String, pageable: Pageable): Page<Team>

// 2단계: @BatchSize 또는 fetch join으로 컬렉션 채우기
@BatchSize(size = 100)
@OneToMany(mappedBy = "team")
val members: MutableList<Member> = mutableListOf()
```

`@BatchSize`를 설정하면, 컬렉션에 접근할 때 N개의 개별 쿼리 대신 `IN` 절을 사용한 배치 쿼리로 묶어서 조회합니다. 1단계에서 가져온 Team들의 ID를 목아서 `WHERE team_id IN (...)` 형태로 한 번에 Member를 조회하므로, N+1 문제도 해결하면서 페이징 정합성도 보장됩니다.

### 방법 2: ID 목록 조회 후 In절로 재조회

페이징 쿼리로 ID 목록만 먼저 뽑고, 그 ID들로 fetch join 쿼리를 다시 실행하는 방식입니다.

```kotlin
@Query("SELECT t.id FROM Team t WHERE t.department = :dept")
fun findTeamIdsByDept(@Param("dept") dept: String, pageable: Pageable): Page<Long>

@Query("SELECT DISTINCT t FROM Team t JOIN FETCH t.members WHERE t.id IN :ids")
fun findTeamsWithMembersByIds(@Param("ids") ids: List<Long>): List<Team>
```

이 방식은 두 번의 쿼리가 발생하지만, 정렬 순서를 보존하려면 애플리케이션 코드에서 ID 순서대로 재정렬하는 작업이 필요합니다. Page 객체의 순서 정보와 2차 조회 결과의 순서가 다를 수 있기 때문입니다.

### 방법 3: 다대일(N:1), 일대일(1:1) 관계만 Fetch Join

N:1이나 1:1 관계는 row가 늘어나지 않기 때문에 페이징과 함께 사용해도 안전합니다. 1:N 컬렉션은 페이징 대상에서 제외하고, ToOne 관계만 fetch join하는 것도 실무에서 자주 쓰이는 전략입니다.

```kotlin
@Query("SELECT m FROM Member m JOIN FETCH m.team WHERE m.status = :status")
fun findMembersWithTeam(@Param("status") status: String, pageable: Pageable): Page<Member>
```

### 방법 4: Querydsl이나 별도 DTO 프로젝션 사용

엔티티 그래프 전체가 필요하지 않고 화면에 필요한 데이터만 조회하면 되는 경우, 처음부터 DTO로 프로젝션하면서 페이징하는 방법도 고려할 수 있습니다. 이 경우 fetch join 자체가 필요 없어지는 경우가 많습니다.

---

## 방법 비교

| 방법 | N+1 해결 | 페이징 정합성 | 쿼리 횟수 | 적용 난이도 |
| --- | --- | --- | --- | --- |
| BatchSize + 분리 조회 | O | O | 2 (배치) | 낮음 |
| ID 조회 후 IN절 재조회 | O | O | 2 | 중간 (순서 보존 필요) |
| ToOne만 Fetch Join | O | O | 1 | 낮음 (1:N에는 미적용) |
| DTO 프로젝션 | O | O | 1 | 중간 (구조 변경) |
| 1:N Fetch Join + 페이징 | O | O (메모리) | 1 | 위험 (성능 문제) |

---

## 전체 요약

JPA에서 1:N 관계에 fetch join을 적용하면 SQL 결과 row가 자식 엔티티 수만큼 늘어나는데, 이 상태에서 페이징을 적용하면 데이터가 중간에 잘리는 정합성 문제가 발생합니다. Hibernate는 이를 방지하기 위해 메모리 페이징으로 전환하지만, 이는 전체 데이터를 메모리에 로드하는 성능 위험을 동반합니다. 실무에서는 ID 기준으로 먼저 페이징한 뒤 `@BatchSize`나 별도 IN절 쿼리로 컬렉션을 채우는 방식이 가장 안정적인 해결책으로 권장됩니다. ToOne 관계만 fetch join하거나, 필요한 데이터만 DTO로 프로젝션하는 방법도 상황에 따라 유효한 대안입니다.