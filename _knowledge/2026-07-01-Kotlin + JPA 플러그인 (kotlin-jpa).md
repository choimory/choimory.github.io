---
title: "Kotlin + JPA 플러그인 (kotlin-jpa)"
date: 2026-07-01T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - Kotlin
---

## 개요

`kotlin-jpa` 플러그인은 Kotlin과 JPA(Jakarta Persistence API)를 함께 사용할 때 발생하는 근본적인 호환성 문제를 해결하기 위한 Kotlin 컴파일러 플러그인입니다. Kotlin의 언어 특성이 JPA의 요구사항과 충돌하는 지점이 명확하기 때문에, 이 플러그인이 왜 필요한지를 먼저 이해하는 것이 핵심입니다.

## 왜 필요한가

### Kotlin 클래스의 기본 특성 vs JPA 요구사항

JPA는 리플렉션을 통해 엔티티 객체를 생성하고 필드를 채웁니다. 이를 위해 세 가지를 요구합니다.

| JPA 요구사항 | Kotlin 기본 동작 | 충돌 여부 |
| --- | --- | --- |
| 인수 없는 기본 생성자 | 기본 생성자 없음 (주 생성자만) | ✅ 충돌 |
| 클래스 상속 가능 (프록시) | `final` 클래스 | ✅ 충돌 |
| 필드 지연 초기화 | `val` 불변 프로퍼티 | ⚠️ 주의 필요 |

이 충돌들을 해결하는 것이 `kotlin-jpa` 및 `kotlin-spring` 플러그인의 역할입니다.

## 플러그인 구성

### build.gradle.kts 설정

```kotlin
plugins {
    kotlin("plugin.spring") version "1.9.25"  // @Configuration 등 open 처리
    kotlin("plugin.jpa")    version "1.9.25"  // JPA 엔티티 기본 생성자 자동 생성
}
```

두 플러그인은 역할이 다르므로 함께 사용합니다.

### 각 플러그인의 역할

```
kotlin-spring  → @Component, @Configuration, @Transactional 등이 붙은 클래스를 자동으로 open 처리
kotlin-jpa     → @Entity, @MappedSuperclass, @Embeddable 이 붙은 클래스에 기본 생성자 자동 추가
```

## 해결하는 문제들

### 기본 생성자 자동 생성

#### 문제 상황

```kotlin
@Entity
class User(
    val name: String,
    val email: String,
    @Id @GeneratedValue val id: Long = 0
)
// JPA: "No default constructor found" 예외 발생
```

JPA는 리플렉션으로 `User()` 형태의 기본 생성자를 호출하려 합니다.

하지만 Kotlin은 파라미터가 있는 주 생성자만 생성합니다.

#### kotlin-jpa 플러그인 적용 후

```kotlin
@Entity
class User(
    val name: String,
    val email: String,
    @Id @GeneratedValue val id: Long = 0
)
// 컴파일 시 자동으로 아래와 동일하게 처리됨
// constructor() { } ← 합성 기본 생성자가 바이트코드에 삽입됨
```

플러그인이 `@Entity`, `@MappedSuperclass`, `@Embeddable`이 붙은 클래스에 기본 생성자를 바이트코드 레벨에서 자동 삽입합니다.

### "open" 클래스 처리

#### 문제 상황

Hibernate는 지연 로딩(Lazy Loading)을 위해 엔티티를 상속한 프록시 클래스를 런타임에 생성합니다.

```kotlin
@Entity
class User(...)
// Kotlin 기본: final class → Hibernate 프록시 생성 불가
// 결과: 모든 연관관계가 강제 즉시 로딩(EAGER)되거나 예외 발생
```

#### kotlin-spring 플러그인 적용 후

```kotlin
@Entity // ← 이 어노테이션으로 인해 kotlin-spring이 자동으로 open 처리
class User(...)
// Hibernate 프록시 생성 가능 → 지연 로딩 정상 동작
```

## 실제 엔티티 작성 패턴

### 기본 엔티티 구조

```kotlin
@Entity
@Table(name = "users")
class User(
    @Column(nullable = false)
    val name: String,

    @Column(nullable = false, unique = true)
    val email: String,

    @Enumerated(EnumType.STRING)
    val status: UserStatus = UserStatus.ACTIVE,

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0
)

enum class UserStatus { ACTIVE, INACTIVE, DELETED }
```

#### "val" vs "var" 선택 기준

```kotlin
// val: 불변 → 생성 후 변경 불필요한 필드
val email: String

// var: 가변 → 비즈니스 로직으로 변경되는 필드
var status: UserStatus = UserStatus.ACTIVE
```

### "data class" 사용을 피해야 하는 이유

JPA 엔티티에 `data class`를 사용하면 여러 문제가 생깁니다.

```kotlin
// 권장하지 않음
@Entity
data class User(val name: String, val email: String, @Id val id: Long = 0)
```

`data class`가 자동 생성하는 `equals()` / `hashCode()`는 모든 프로퍼티를 기반으로 동작합니다.

JPA 엔티티에서는 동일성 비교를 `id`(PK)로만 해야 하으므로, `data class`의 기본 구현이 의도치 않은 동작을 만듭니다.

#### 권장 패턴: 일반 클래스 + 명시적 "equals"/"hashCode"

```kotlin
@Entity
@Table(name = "users")
class User(
    @Column(nullable = false)
    val name: String,

    @Column(nullable = false, unique = true)
    val email: String,

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0
) {
    // PK 기반으로만 동등성 비교
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is User) return false
        return id != 0L && id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "User(id=$id, email=$email)"
}
```

### 연관관계 매핑 주의사항

#### 양방향 관계와 "lazy" 로딩

```kotlin
@Entity
@Table(name = "orders")
class Order(
    @ManyToOne(fetch = FetchType.LAZY)  // 반드시 LAZY 명시
    @JoinColumn(name = "user_id")
    val user: User,

    @OneToMany(mappedBy = "order", cascade = [CascadeType.ALL], orphanRemoval = true)
    val items: MutableList<OrderItem> = mutableListOf(),

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0
) {
    // 양방향 편의 메서드
    fun addItem(item: OrderItem) {
        items.add(item)
    }
}
```

#### "FetchType.LAZY"가 동작하려면 플러그인이 필수

```
kotlin-jpa → 기본 생성자 제공  ← 없으면 엔티티 인스턴스화 자체 불가
kotlin-spring → open 클래스    ← 없으면 Hibernate 프록시 생성 불가 → LAZY 동작 안 함
```

### "@Embedded" / "@Embeddable" 패턴

```kotlin
@Embeddable
class Address(
    @Column(name = "city") val city: String,
    @Column(name = "street") val street: String,
    @Column(name = "zip_code") val zipCode: String
)
// kotlin-jpa가 @Embeddable에도 기본 생성자를 자동 삽입

@Entity
class User(
    @Embedded val address: Address,
    @Id @GeneratedValue val id: Long = 0
)
```

## 자주 만나는 문제와 해결

### "could not initialize proxy" 예외

```kotlin
// 문제: 트랜잭션 밖에서 지연 로딩 시도
val user = userRepository.findById(1L).get()
// 트랜잭션 종료 후...
val orderCount = user.orders.size  // LazyInitializationException 발생

// 해결 1: fetch join 사용
@Query("SELECT u FROM User u JOIN FETCH u.orders WHERE u.id = :id")
fun findWithOrders(@Param("id") id: Long): User?

// 해결 2: @Transactional 범위 내에서 접근
@Transactional(readOnly = true)
fun getUserWithOrders(userId: Long): User {
    val user = userRepository.findById(userId).orElseThrow()
    user.orders.size  // 트랜잭션 내 → 정상 동작
    return user
}
```

## 요약

!kotlin_jpa_plugin_flow.png

`kotlin-jpa` 플러그인은 JPA가 요구하는 "기본 생성자"를 Kotlin의 `@Entity`, `@MappedSuperclass`, `@Embeddable` 클래스에 컴파일 타임에 자동으로 삽입합니다. `kotlin-spring` 플러그인과 함께 사용하면 `final` 클래스 문제도 해결되어 Hibernate 프록시 기반 지연 로딩이 정상 동작합니다. 실무에서는 엔티티를 `data class`가 아닌 일반 `class`로 정의하고, PK 기반의 `equals`/`hashCode`를 명시적으로 구현하는 것이 안정적인 패턴입니다.