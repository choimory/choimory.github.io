---
title: "Spring WebFlux + Netty"
date: 2026-08-18T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - WebFlux
    - Netty
---

## 개요

"Spring WebFlux + Netty"는 Spring Boot에서 비동기·논블로킹 방식으로 HTTP 서버를 구축하는 대표적인 조합입니다.

역할을 구분하면 다음과 같습니다.

- Spring WebFlux: 요청을 처리하는 웹 프레임워크입니다.
- Reactor: 비동기 데이터 흐름을 표현하는 리액티브 라이브러리입니다.
- Netty: 실제 네트워크 연결과 HTTP 입출력을 처리하는 서버 엔진입니다.

즉, 전체 흐름은 대략 다음과 같습니다.

```
클라이언트
  ↓
Netty
  ↓
Spring WebFlux
  ↓
Reactor Mono / Flux
  ↓
서비스 및 외부 시스템
```

---

## Spring WebFlux란

Spring WebFlux는 Spring MVC와 비슷한 역할을 하지만 내부 처리 방식이 다릅니다.

### Spring MVC

Spring MVC는 일반적으로 요청 하나를 스레드 하나가 처리하는 구조입니다.

```
요청 1 → 스레드 1
요청 2 → 스레드 2
요청 3 → 스레드 3
```

데이터베이스나 외부 API 응답을 기다리는 동안에도 해당 스레드는 대기 상태가 됩니다.

### Spring WebFlux

Spring WebFlux는 소수의 이벤트 루프 스레드가 많은 요청을 처리합니다.

```
요청 1 ─┐
요청 2 ─┼→ Event Loop
요청 3 ─┘
```

외부 API나 데이터베이스 응답을 기다리는 동안 스레드를 점유하지 않고 다른 요청을 처리할 수 있습니다.

이를 "논블로킹 I/O"라고 합니다.

---

## Netty란

Netty는 Java NIO 기반의 비동기 네트워크 프레임워크입니다.

Spring WebFlux 애플리케이션에서는 기본 내장 서버로 Reactor Netty를 사용하는 경우가 많습니다.

```kotlin
implementation("org.springframework.boot:spring-boot-starter-webflux")
```

위 의존성을 추가하면 기본적으로 다음 구조가 사용됩니다.

```
Spring WebFlux
  ↓
Reactor Netty
  ↓
Java NIO
  ↓
운영체제 네트워크
```

Spring MVC의 기본 서버가 Tomcat인 것과 비교할 수 있습니다.

| 구분 | Spring MVC | Spring WebFlux |
| --- | --- | --- |
| 기본 서버 | Tomcat | Netty |
| 처리 방식 | 동기·블로킹 | 비동기·논블로킹 |
| 스레드 모델 | 요청당 스레드 | 이벤트 루프 |
| 대표 타입 | 일반 객체 | Mono, Flux |

---

## Mono와 Flux

WebFlux에서는 Reactor의 `Mono`와 `Flux`를 사용합니다.

### Mono

0개 또는 1개의 결과를 표현합니다.

```kotlin
@GetMapping("/users/{id}")
fun getUser(
    @PathVariable id: Long
): Mono<UserResponse> {
    return userService.findById(id)
}
```

개념적으로는 다음과 같습니다.

```
Mono<User> = 나중에 User 하나가 도착할 수 있음
```

### Flux

0개 이상의 여러 결과를 표현합니다.

```kotlin
@GetMapping("/users")
fun getUsers(): Flux<UserResponse> {
    return userService.findAll()
}
```

```
Flux<User> = User가 여러 개 순차적으로 도착할 수 있음
```

Flux는 모든 데이터를 한 번에 메모리에 적재하지 않고 스트림 형태로 전달할 수도 있습니다.

---

## 기본 컨트롤러 예제

```kotlin
@RestController
@RequestMapping("/api/users")
class UserController(
    private val userService: UserService
) {

    @GetMapping("/{id}")
    fun getUser(
        @PathVariable id: Long
    ): Mono<UserResponse> {
        return userService.findById(id)
    }

    @GetMapping
    fun getUsers(): Flux<UserResponse> {
        return userService.findAll()
    }

    @PostMapping
    fun createUser(
        @RequestBody request: CreateUserRequest
    ): Mono<UserResponse> {
        return userService.create(request)
    }
}
```

서비스는 다음과 같이 구성할 수 있습니다.

```kotlin
@Service
class UserService(
    private val userRepository: UserRepository
) {

    fun findById(id: Long): Mono<UserResponse> {
        return userRepository.findById(id)
            .switchIfEmpty(
                Mono.error(IllegalArgumentException("사용자를 찾을 수 없습니다."))
            )
            .map { user ->
                UserResponse(
                    id = user.id,
                    name = user.name
                )
            }
    }
}
```

---

## WebFlux의 스레드 모델

Netty는 일반적으로 적은 수의 이벤트 루프 스레드를 사용합니다.

스레드 이름은 다음과 비슷하게 나타납니다.

```
reactor-http-nio-1
reactor-http-nio-2
reactor-http-nio-3
```

이 스레드들은 다음 작업을 담당합니다.

- 클라이언트 연결 수락
- HTTP 요청 읽기
- WebFlux 파이프라인 실행
- HTTP 응답 전송

중요한 점은 이벤트 루프 스레드에서 블로킹 작업을 수행하면 안 된다는 것입니다.

```kotlin
@GetMapping("/bad")
fun bad(): Mono<String> {
    Thread.sleep(5000)
    return Mono.just("완료")
}
```

위 코드는 이벤트 루프 스레드를 5초 동안 막습니다.

그러면 같은 이벤트 루프에서 처리하는 다른 요청들도 지연될 수 있습니다.

---

## WebFlux에서 블로킹 작업을 사용하면 안 되는 이유

WebFlux의 장점은 적은 스레드로 많은 동시 요청을 처리하는 것입니다.

그런데 다음과 같은 블로킹 기술을 사용하면 이 장점이 사라집니다.

- JDBC
- Spring Data JPA
- `Thread.sleep()`
- 블로킹 파일 입출력
- 동기 HTTP 클라이언트
- 오래 걸리는 CPU 연산

예를 들어 JPA는 기본적으로 블로킹 방식입니다.

```kotlin
fun getUser(id: Long): Mono<User> {
    return Mono.just(userJpaRepository.findById(id).get())
}
```

겉으로는 `Mono`를 반환하지만 내부에서 JPA가 스레드를 점유하므로 진짜 논블로킹 코드가 아닙니다.

---

## WebFlux와 데이터베이스

WebFlux의 장점을 유지하려면 데이터베이스 접근도 논블로킹이어야 합니다.

### 권장 조합

```
Spring WebFlux
+
R2DBC
+
Reactive Repository
```

예시는 다음과 같습니다.

```kotlin
interface UserRepository :
    ReactiveCrudRepository<User, Long>
```

```kotlin
@Table("users")
data class User(
    @Id
    val id: Long? = null,
    val name: String
)
```

### 주의할 조합

```
Spring WebFlux
+
JPA
+
JDBC
```

이 조합도 기술적으로 실행은 가능하지만, JPA 호출이 블로킹이기 때문에 WebFlux의 장점이 제한됩니다.

필요하다면 별도 스레드 풀로 격리할 수 있습니다.

```kotlin
fun findUser(id: Long): Mono<User> {
    return Mono.fromCallable {
        userJpaRepository.findById(id)
            .orElseThrow()
    }.subscribeOn(Schedulers.boundedElastic())
}
```

하지만 이 방식은 블로킹을 제거하는 것이 아니라 다른 스레드 풀로 옮기는 것입니다.

---

## WebClient

WebFlux 환경에서 외부 HTTP API를 호출할 때는 `WebClient`를 사용합니다.

```kotlin
@Configuration
class WebClientConfig {

    @Bean
    fun webClient(
        builder: WebClient.Builder
    ): WebClient {
        return builder
            .baseUrl("https://example.com")
            .build()
    }
}
```

```kotlin
@Service
class ExternalApiService(
    private val webClient: WebClient
) {

    fun getUser(id: Long): Mono<ExternalUserResponse> {
        return webClient.get()
            .uri("/users/{id}", id)
            .retrieve()
            .bodyToMono(ExternalUserResponse::class.java)
    }
}
```

`WebClient`는 HTTP 응답을 기다리는 동안 이벤트 루프 스레드를 점유하지 않습니다.

반면 다음과 같은 동기 클라이언트는 블로킹 방식입니다.

- RestTemplate
- 동기 방식의 OpenFeign
- Java의 일부 동기 HTTP 클라이언트

---

## WebFlux가 적합한 상황

WebFlux는 "요청 수가 많다"는 이유만으로 사용하는 것은 아닙니다.

핵심은 "대기 시간이 많은 I/O 작업"입니다.

### 적합한 사례

- 채팅 서버
- SSE 서버
- WebSocket 서버
- API Gateway
- BFF 서버
- 외부 API 호출이 많은 서버
- 스트리밍 서버
- 장시간 연결을 유지하는 서버
- 높은 동시 접속을 처리하는 서버

예를 들어 외부 API를 여러 개 병렬 호출하는 서비스에 적합합니다.

```kotlin
fun getDashboard(): Mono<DashboardResponse> {
    val userMono = userApi.getUser()
    val orderMono = orderApi.getOrders()
    val paymentMono = paymentApi.getPayments()

    return Mono.zip(
        userMono,
        orderMono,
        paymentMono
    ).map { tuple ->
        DashboardResponse(
            user = tuple.t1,
            orders = tuple.t2,
            payments = tuple.t3
        )
    }
}
```

세 API가 각각 1초 걸린다면 순차 호출은 약 3초가 걸리지만 병렬 호출은 약 1초 정도에 완료될 수 있습니다.

---

## WebFlux가 불리한 상황

다음과 같은 환경에서는 Spring MVC가 더 단순하고 적합할 수 있습니다.

- JPA가 중심인 일반적인 CRUD 서버
- 대부분의 작업이 동기 방식인 서버
- 논블로킹 드라이버가 없는 외부 시스템
- 복잡한 트랜잭션 로직
- 팀이 Reactor에 익숙하지 않은 경우
- CPU 연산이 대부분인 경우

특히 다음 구조라면 WebFlux 사용 효과가 크지 않습니다.

```
WebFlux
  ↓
JPA
  ↓
MySQL JDBC
```

요청 진입부만 비동기이고 데이터베이스에서는 블로킹되기 때문입니다.

일반적인 JPA 기반 관리자 시스템이나 CRUD API는 다음 구성이 더 실용적입니다.

```
Spring MVC
+
Tomcat
+
JPA
+
MySQL
```

---

## 채팅 서버에서의 WebFlux + Netty

채팅과 같은 서버에서는 WebFlux + Netty가 유리한 경우가 많습니다.

채팅 서버는 다음 특성이 있기 때문입니다.

- 연결이 오래 유지됨
- 동시에 연결된 사용자가 많음
- 메시지가 간헐적으로 발생함
- 네트워크 대기 시간이 많음
- WebSocket을 자주 사용함

```kotlin
@Component
class ChatWebSocketHandler : WebSocketHandler {

    override fun handle(
        session: WebSocketSession
    ): Mono<Void> {
        val receive = session.receive()
            .map { message ->
                session.textMessage(
                    "echo: ${message.payloadAsText}"
                )
            }

        return session.send(receive)
    }
}
```

Netty 이벤트 루프는 수많은 WebSocket 연결을 요청당 별도 스레드 없이 관리할 수 있습니다.

다만 실제 채팅 서버에서는 다음 요소도 함께 고려해야 합니다.

- 메시지 브로커
- Redis Pub/Sub 또는 Redis Streams
- Kafka
- 세션 분산
- 사용자 접속 상태
- 메시지 유실 방지
- 재연결 처리
- 순서 보장

---

## Spring MVC와 WebFlux 선택 기준

### Spring MVC가 더 적합한 경우

```
JPA 기반 CRUD
관리자 페이지
일반적인 REST API
복잡한 트랜잭션
블로킹 라이브러리 중심
```

### WebFlux가 더 적합한 경우

```
WebSocket
SSE
스트리밍
API Gateway
외부 API 병렬 호출
높은 동시 연결
R2DBC 기반 데이터 접근
```

### 핵심 선택 기준

```
동시 요청이 많다
```

보다 더 중요한 질문은 다음입니다.

```
처리 과정 전체를 논블로킹으로 구성할 수 있는가?
```

Netty만 사용한다고 자동으로 성능이 좋아지는 것은 아닙니다.

```
Netty + WebFlux + JDBC
```

보다는

```
Netty + WebFlux + WebClient + R2DBC
```

처럼 전체 호출 체인이 논블로킹이어야 효과가 큽니다.

---

## 전체 요약

Spring WebFlux + Netty는 적은 이벤트 루프 스레드로 많은 네트워크 연결과 비동기 요청을 처리하는 구조입니다.

```
Spring WebFlux = 웹 요청 처리 프레임워크
Reactor = Mono, Flux 기반 비동기 데이터 흐름
Netty = 비동기 네트워크 서버
```

WebSocket, SSE, 채팅, API Gateway, 외부 API 호출이 많은 서비스에는 잘 맞습니다.

반면 JPA와 JDBC 기반의 일반 CRUD 서버라면 Spring MVC가 더 단순하고 효율적일 수 있습니다.

가장 중요한 원칙은 다음과 같습니다.

```
WebFlux의 성능을 얻으려면
Controller부터 DB와 외부 API까지
전체 흐름이 논블로킹이어야 합니다.
```