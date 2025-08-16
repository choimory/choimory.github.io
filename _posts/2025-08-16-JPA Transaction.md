---
title: "JPA Transaction"
date: 2025-08-16T00:00:00
toc: true
toc_sticky: true
categories:
    - 
tags:
    - 
---

# JPA Transaction

JPA에서의 **Transaction(트랜잭션)** 은 데이터베이스의 **일관성 유지**와 **원자성 보장**을 위해 매우 중요한 개념

### 1. 트랜잭션이란?

- 하나의 작업 단위를 의미함.
- 모든 작업이 **성공**하면 **커밋(commit)**, 중간에 하나라도 **실패**하면 **롤백(rollback)** 됨.
- ACID(Atomicity, Consistency, Isolation, Durability)를 보장.

---

### 2. JPA에서 트랜잭션 필요성

- JPA는 **엔티티 매니저(EntityManager)** 를 통해 DB 작업 수행.
- **쓰기 작업(Persist, Merge, Remove)** 은 반드시 트랜잭션 안에서 실행되어야 함.
- 트랜잭션 없이 호출 시 `javax.persistence.TransactionRequiredException` 발생.

### 3. 스프링에서의 트랜잭션 사용 방법

### 방법 1: `@Transactional` 어노테이션 사용

```java
@Service
public class UserService {

    @Transactional
    public void registerUser(User user) {
        entityManager.persist(user); // 트랜잭션 내에서 실행됨
    }
}
```

- 클래스 또는 메서드에 붙일 수 있음.
- 읽기 전용이면 `@Transactional(readOnly = true)`로 최적화 가능.

### 방법 2: 수동 트랜잭션 (EntityManager 직접 제어)

```java
EntityTransaction tx = entityManager.getTransaction();
try {
    tx.begin();
    // 작업 수행
    tx.commit();
} catch (Exception e) {
    tx.rollback();
}
```

- 일반 Java SE 환경에서 사용됨 (Spring 환경 X).

### 4. 트랜잭션 전파 (Propagation)

스프링은 메서드 간 트랜잭션을 어떻게 처리할지 `propagation` 속성으로 제어 가능.

예시:

```java
@Transactional(propagation = Propagation.REQUIRES_NEW)
```

- `REQUIRED`: 기본값. 이미 트랜잭션이 있으면 참여, 없으면 새로 생성.
- `REQUIRES_NEW`: 항상 새 트랜잭션 생성.
- `NESTED`: 내부 트랜잭션처럼 작동.

### 5. 정리

- JPA에서는 트랜잭션이 필수.
- 스프링에서는 `@Transactional`로 선언적 트랜잭션 쉽게 사용 가능.
- 트랜잭션 범위 설정, 전파, 예외 발생 시 롤백 정책 등이 중요 포인트.

---

# 내부적으로 AOP나 자체 Proxy 패턴이 적용되어 있나?

스프링에서 `@Transactional`이 **어떻게 동작하는지**를 보면 내부적으로 **프록시(Proxy) + AOP 방식**을 사용

### 핵심 개념: **프록시 기반 AOP**

스프링은 `@Transactional` 같은 기능을 제공할 때, **AOP(관점 지향 프로그래밍)** 를 이용

**트랜잭션 시작 → 비즈니스 로직 실행 → 커밋 or 롤백** 흐름을 자동으로 처리함

### 1. **프록시 기반 구조**

스프링이 `@Transactional` 어노테이션이 붙은 클래스를 감싸는 **프록시 객체**를 생성함.

### 2가지 방식이 존재:

- **JDK 동적 프록시**: 인터페이스 기반
- **CGLIB 프록시**: 클래스 기반 (인터페이스가 없거나 `proxyTargetClass=true`일 때)

### 2. AOP 어드바이스로 트랜잭션 처리

스프링은 `TransactionInterceptor`라는 AOP 어드바이스를 사용해서 트랜잭션을 처리하는것이 핵심

```
클라이언트 → 프록시 → TransactionInterceptor
                   ↳ PlatformTransactionManager를 통해 트랜잭션 시작
                   ↳ 실제 비즈니스 로직 호출
                   ↳ 성공 시 커밋 / 예외 시 롤백
```

### 3. 중요한 점

- **`@Transactional`은 메서드 외부에서 호출되면 트랜잭션 안 걸림.**
    
    내부 메서드 호출 시 프록시를 통하지 않기 때문 (self-invocation 문제)
    

### 4. 요약

| 구분 | 설명 |
| --- | --- |
| 방식 | AOP 기반 트랜잭션 처리 |
| 구현 | 프록시 객체 생성 (JDK or CGLIB) |
| 내부 처리 | `TransactionInterceptor`가 트랜잭션 시작/커밋/롤백 제어 |
| 핵심 인터페이스 | `PlatformTransactionManager`, `TransactionDefinition`, `TransactionStatus` |