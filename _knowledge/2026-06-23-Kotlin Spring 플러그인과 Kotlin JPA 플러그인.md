---
title: "Kotlin Spring 플러그인과 Kotlin JPA 플러그인"
date: 2026-06-23T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - Kotlin
---

# Kotlin Spring 플러그인과 Kotlin JPA 플러그인

Spring Boot + Kotlin 프로젝트를 생성하면 보통 `kotlin("plugin.spring")` 과 `kotlin("plugin.jpa")` 두 플러그인이 함께 추가됩니다.

이 플러그인들은 Kotlin의 기본 특성과 Spring/JPA의 요구사항이 충돌하는 부분을 해결하기 위해 존재합니다.

---

## Kotlin의 기본 특성

Kotlin 클래스는 기본적으로 다음과 같습니다.

```kotlin
class User
```

실제로는 다음과 비슷합니다.

```java
public final class User {
}
```

즉,

- 클래스는 기본적으로 `final`
- 메서드도 기본적으로 `final`
- 생성자를 직접 만들지 않으면 기본 생성자 없음

반면 Spring과 JPA는 다음을 요구합니다.

- Spring AOP → 상속 기반 Proxy 생성
- Hibernate → Entity Proxy 생성
- JPA → 기본 생성자 필요

그래서 Kotlin 전용 플러그인이 필요합니다.

---

## kotlin-spring 플러그인

### 역할

특정 Spring 어노테이션이 붙은 클래스를 자동으로 `open` 처리합니다.

원래 Kotlin은 상속이 불가능합니다.

```kotlin
@Service
class UserService
```

컴파일 후

```kotlin
open class UserService
```

처럼 변환됩니다.

---

### 왜 필요한가

Spring은 AOP, Transaction, Lazy Loading 등을 위해 프록시 객체를 만듭니다.

예시

```kotlin
@Service
@Transactional
class UserService
```

Spring 내부

```java
class UserServiceProxy extends UserService
```

상속을 통해 프록시를 생성합니다.

그런데 Kotlin 클래스는 final이라 상속이 불가능합니다.

그래서 자동으로 open 처리해주는 것입니다.

---

### 자동으로 open 되는 어노테이션

대표적으로

```kotlin
@Component
@Service
@Repository
@Controller
@RestController
@Configuration
```

그리고 이들을 메타 어노테이션으로 사용하는 어노테이션도 포함됩니다.

예시

```kotlin
@Service
class UserService
```

↓

```kotlin
open class UserService
```

---

### Gradle

```kotlin
plugins {
    kotlin("plugin.spring") version "2.2.0"
}
```

---

## kotlin-jpa 플러그인

### 역할

JPA Entity에 기본 생성자를 자동 생성합니다.

JPA 스펙은 다음을 요구합니다.

```java
public User() {}
```

즉,

- public 또는 protected
- 파라미터 없는 생성자

가 필요합니다.

---

### 문제

Kotlin 데이터 클래스

```kotlin
@Entity
class User(
    val id: Long,
    val name: String
)
```

컴파일 결과

```java
public User(Long id, String name)
```

기본 생성자가 없습니다.

Hibernate가 객체를 생성할 수 없습니다.

---

### 플러그인 적용 후

```kotlin
@Entity
class User(
    val id: Long,
    val name: String
)
```

컴파일 시

```java
protected User() {
}
```

가 자동 생성됩니다.

---

### 내부적으로 사용하는 플러그인

사실

```kotlin
kotlin("plugin.jpa")
```

는

```kotlin
kotlin("plugin.noarg")
```

를 JPA용으로 미리 설정한 래퍼입니다.

다음 어노테이션에 대해 기본 생성자를 생성합니다.

```kotlin
@Entity
@Embeddable
@MappedSuperclass
```

---

### Gradle

```kotlin
plugins {
    kotlin("plugin.jpa") version "2.2.0"
}
```

---

## 둘의 차이

| 플러그인 | 해결 문제 | 적용 대상 |
| --- | --- | --- |
| kotlin-spring | Spring Proxy를 위한 open 클래스 생성 | @Service, @Component 등 |
| kotlin-jpa | JPA 기본 생성자 생성 | @Entity, @Embeddable 등 |

---

## Spring Boot 프로젝트에서 보통 같이 사용하는 이유

실제 Entity

```kotlin
@Entity
class User(
    @Id
    val id: Long,
    val name: String
)
```

실제 Service

```kotlin
@Service
@Transactional
class UserService
```

필요한 것

- Entity → 기본 생성자 필요
- Service → open 클래스 필요

따라서 대부분의 Spring Boot + JPA 프로젝트는

```kotlin
plugins {
    kotlin("jvm")
    kotlin("plugin.spring")
    kotlin("plugin.jpa")
}
```

구성을 사용합니다.

---

## 전체 요약

- `kotlin-spring`
    - Spring 프록시 생성을 위해 클래스와 메서드를 자동 `open` 처리합니다.
    - `@Service`, `@Component`, `@Configuration` 등에 적용됩니다.
- `kotlin-jpa`
    - JPA가 요구하는 기본 생성자를 자동 생성합니다.
    - `@Entity`, `@Embeddable`, `@MappedSuperclass` 등에 적용됩니다.
- Spring Boot + JPA 프로젝트에서는 거의 항상 두 플러그인을 함께 사용합니다.