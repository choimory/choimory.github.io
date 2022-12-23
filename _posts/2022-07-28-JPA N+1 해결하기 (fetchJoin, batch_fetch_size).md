---
title: "JPA N+1 해결하기 (fetchJoin, batch_fetch_size)"
date: 2022-07-28T00:00:00
toc: true
toc_sticky: true
classes: wide
categories:
    - JVM
tags:
    - Java
    - Spring
    - JPA
    - Querydsl
    - Query tuning
    - Fetch join
---

# 요약

- fetch join은 지연로딩으로 설정된 연관관계 엔티티를, 주체가 되는 부모 엔티티를 조회할때 연관관계 엔티티도 한번에 같이 조회해오는 JPA 지원 조인 방식입니다.
- fetch join으로 연관관계 엔티티별로 쿼리가 불어나는 N+1 현상, 지연로딩 초기화 예외 등을 방지할 수 있습니다.
- fetch join은 보통 N+1으로 인행 한번에 수행되는 쿼리가 너무 많을수 있는 경우, 연관관계 엔티티의 데이터도 활용되어야 할때 등에 사용할 수 있습니다.
- 1:N 연관관계 엔티티는 하나의 엔티티만 fetch join이 가능하며, 이를 해결하기 위해 default_batch_fetch_size를 설정할 수 있습니다.

# 상세

- 지연로딩으로 설정된 연관관계 엔티티는 보통 한번에 조회하지 않습니다.
    - 먼저 영속성 컨텍스트가 모든 엔티티를 프록시 객체로 만들어놓고 SQL Storage에 쿼리를 준비해둔뒤
    - 해당 연관관계 엔티티 객체에 접근할때, 준비된 SQL로 조회하여 해당 연관관계 엔티티 데이터를 그때그때 가져오도록 되어 있습니다.
    - 그래서 지연로딩으로 설정된 엔티티는 부모와는 별도의, 연관관계 엔티티만을 위한 조회 쿼리를 마련한 뒤, 객체에 접근할때 해당 쿼리를 추가 수행해서 가져옵니다.
- 그래서 지연로딩으로 설정된 연관관계 엔티티는 쿼리를 준비할때 join이 아닌 `부모엔티티 조회쿼리 + 연관관계엔티티 조회쿼리` 두개로 찢어져서 준비됩니다
    - 이로인해 생기는 여러 문제점들을 즉시로딩이 아닌 다른방법으로 해결하는것이 fetch join입니다

# N+1

- 조회된 부모 엔티티의 수만큼 자식 엔티티의 조회 쿼리가 추가 발생하는 현상입니다 (부모 엔티티 조회 1 + 자식엔티티 조회 N)
- 부모 엔티티를 조회할때, 자식 엔티티들은 부모 엔티티를 조회하는 쿼리와 별개로 찢어져서 별도의 쿼리로 수행되게 됩니다.
- 그러면 부모 엔티티 하나를 조회하기 위해선 `부모엔티티 조회쿼리 + 자식엔티티조회쿼리`가 발생합니다
    - 부모 하나에 연관관계에 있는 지연로딩 자식엔티티가 10개라면?
        - 부모 조회 쿼리 1번 + 각각의 자식 조회 쿼리 10번 = 11개의 조회 쿼리가 수행됩니다
        - 이 상황에서 부모 목록 20개 조회한다면? 리포지토리 조회 쿼리 하나로 220번의 DB 요청이 들어가게 됩니다

# LazyInitializeException

- 지연로딩으로 설정된 연관관계를 추가적으로 가져오려는데 엔티티가 비영속화 되어 프록시 세션이 해제되어 있는 상태일때 발생
- fetch join은 지연로딩으로 설정된 연관관계 엔티티를 추가적으로(N+1) 불러오는게 아닌, 한번에 불러오기 때문에 지연로딩 초기화 관련 예외가 발생하지 않습니다.

# @Query fetch join

> join 뒤에 fetch를 붙여 페치조인을 사용 가능

```java
public interface TeamRepository extends JpaRepository<Team, Long> {
    @Query("SELECT DISTINCT t FROM Team t JOIN FETCH t.member m JOIN FETCH m.memberAuthority ma")
    List<Team> getTeams();
}
```

- Inner join으로 연관관계를 가져옵니다
- 하나의 1:N 연관관계 엔티티만 fetch join 가능합니다
- 다만 주 엔티티의 연관관계 엔티티가 많아지면 해당 연관관계를 모두 쿼리에 표현해야 하는것이 매우 불편해질 수 있다는 단점이 있습니다
- 그럴땐 EntityGraph를 사용할 수 있습니다

# @EntityGraph fetchJoin

```java
public interface TeamRepository extends JpaRepository<Team, Long> {
    @EntityGraph(attributePaths = {"member", "member.authority"})
    @Query("SELECT DISTINCT t FROM Team")
    List<Team> getTeams();
}
```

- Left Join으로 결과를 가져옵니다
- 하나의 1:N 연관관계 엔티티만 fetch join 가능합니다
- 쿼리에 주체 엔티티의 하위 엔티티, 하위 엔티티의 하위 엔티티등 많은 엔티들을 모두 fetch join으로 쓰기 번거로울때 사용합니다

# @Query와 @EntityGraph 주의사항

- 둘 다 조인으로 연관관계까지 가져오므로 주체 엔티티가 중복되어 쌓이므로 결과를 Set으로 받거나, 쿼리에 distinct 처리가 필요합니다

# Querydsl fetch join

```java
return query
        .selectFrom(team)
        .join(team.book, book).fetchJoin()
        .fetch();
```

- join() 뒤에 fetchJoin()을 체이닝하여 호출합니다.

# spring.jpa.properties.hibernate.default_batch_fetch_size

```yaml
spring:
  jpa:
    properties:
      hibernate.default_batch_fetch_size: 1000
```

- fetch join의 주의사항은 `1:N 연관관계의 fetch join은 단 한번만 사용 가능하다`는것입니다
- 주체 엔티티 A의 1:N 엔티티 B, C를 동시에 fetch join 하려할시 `MultiBagFecthException`이 발생합니다
- 그럴때 batch_fetch_size를 설정하여 `where in (부모1 id, 부모2 id, 부모3 id...)`하여 쿼리 횟수를 줄일 수 있습니다
- 고로 한개의 toMany를 조회할땐 fetch join을
  - 여러개의 toMany 엔티티를 조회할때는 가장 데이터가 많은 toMany 엔티티에 fetch join을 걸고, 나머지 toMany 엔티티들에 대해서는 batch_fetch_size로 문제를 해결해볼 수 있습니다
- 보통은 1000개 밑으로 지정하며, 1000개 넘게 설정하지 않습니다.

# 참고

- [https://jojoldu.tistory.com/165](https://jojoldu.tistory.com/165)
- [https://jojoldu.tistory.com/457](https://jojoldu.tistory.com/457)
- [https://www.inflearn.com/questions/39516](https://www.inflearn.com/questions/39516)
- [https://cobbybb.tistory.com/18](https://cobbybb.tistory.com/18)
- [https://www.popit.kr/jpa-n1-%EB%B0%9C%EC%83%9D%EC%9B%90%EC%9D%B8%EA%B3%BC-%ED%95%B4%EA%B2%B0-%EB%B0%A9%EB%B2%95/](https://www.popit.kr/jpa-n1-%EB%B0%9C%EC%83%9D%EC%9B%90%EC%9D%B8%EA%B3%BC-%ED%95%B4%EA%B2%B0-%EB%B0%A9%EB%B2%95/)
- [https://itmoon.tistory.com/77](https://itmoon.tistory.com/77)
- [https://blog.leocat.kr/notes/2019/05/26/spring-data-using-entitygraph-to-customize-fetch-graph](https://blog.leocat.kr/notes/2019/05/26/spring-data-using-entitygraph-to-customize-fetch-graph)