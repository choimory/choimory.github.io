---
title: "Kotlin DSL"
date: 2026-08-03T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - Kotlin DSL
---

## 개요

Kotlin DSL(Domain Specific Language)은 Kotlin의 언어 특성을 활용하여 특정 도메인에 특화된 선언적 API를 구축하는 패턴입니다. XML이나 일반 코드 대신, 마치 설정 파일을 읽는 것처럼 자연스러운 코드 블록으로 복잡한 구조를 표현할 수 있게 해줍니다.

Spring 생태계에서 Kotlin DSL은 Bean 정의, Security 설정, Router Function, Test 등 다양한 곳에서 활용됩니다.

---

## 핵심 언어 기능

### 람다와 수신 객체 (Lambda with Receiver)

Kotlin DSL의 핵심 메커니즘입니다. `T.() -> Unit` 형태의 함수 타입으로, 람다 내부에서 `this`가 특정 타입의 인스턴스를 가리키게 됩니다.

```kotlin
// 수신 객체가 있는 람다 타입
fun buildString(block: StringBuilder.() -> Unit): String {
    val sb = StringBuilder()
    sb.block() // sb가 this가 됨
    return sb.toString()
}

val result = buildString {
    append("Hello")  // this.append() 와 동일
    append(", World")
}
```

### 확장 함수 (Extension Function)

기존 클래스를 수정하지 않고 새로운 함수를 추가합니다. DSL 블록을 기존 클래스에 붙이는 데 핵심적인 역할을 합니다.

```kotlin
fun HttpSecurity.customConfig() {
    csrf { it.disable() }
    sessionManagement { it.sessionCreationPolicy(STATELESS) }
}
```

### @DslMarker

중첩된 DSL 블록에서 암묵적인 수신 객체 접근을 제한하는 어노테이션입니다. 잘못된 스코프 접근을 컴파일 타임에 차단합니다.

```kotlin
@DslMarker
annotation class HtmlDsl

@HtmlDsl
class Html {
    fun body(block: Body.() -> Unit) { ... }
}

@HtmlDsl
class Body {
    fun p(block: P.() -> Unit) { ... }
}

html {
    body {
        p {
            body { } // @DslMarker 덕분에 컴파일 에러 발생
        }
    }
}
```

---

## Spring에서의 Kotlin DSL 활용

### Spring Security DSL

Spring Security 5.2부터 Kotlin DSL을 공식 지원합니다.

#### 기존 Java 스타일

```kotlin
@Configuration
class SecurityConfig : WebSecurityConfigurerAdapter() {

    override fun configure(http: HttpSecurity) {
        http
            .csrf().disable()
            .authorizeRequests()
                .antMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
                .and()
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
    }
}
```

#### Kotlin DSL 스타일

```kotlin
@Configuration
@EnableWebSecurity
class SecurityConfig {

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain {
        http {
            csrf { disable() }
            authorizeHttpRequests {
                authorize("/public/**", permitAll)
                authorize(anyRequest, authenticated)
            }
            sessionManagement {
                sessionCreationPolicy = SessionCreationPolicy.STATELESS
            }
        }
        return http.build()
    }
}
```

### Spring MVC Router DSL (Functional Endpoints)

어노테이션 기반 Controller 대신 함수형으로 라우팅을 정의합니다. WebFlux와 Spring MVC 모두 지원합니다.

#### WebFlux Router DSL

```kotlin
@Configuration
class RouterConfig(private val userHandler: UserHandler) {

    @Bean
    fun routes(): RouterFunction<ServerResponse> = router {
        "/api/users".nest {
            GET("", userHandler::findAll)
            GET("/{id}", userHandler::findById)
            POST("", userHandler::create)
            PUT("/{id}", userHandler::update)
            DELETE("/{id}", userHandler::delete)
        }
        "/api/orders".nest {
            GET("", userHandler::findOrders)
        }
    }
}
```

```kotlin
@Component
class UserHandler(private val userService: UserService) {

    suspend fun findAll(request: ServerRequest): ServerResponse {
        val users = userService.findAll()
        return ServerResponse.ok().bodyValueAndAwait(users)
    }

    suspend fun findById(request: ServerRequest): ServerResponse {
        val id = request.pathVariable("id").toLong()
        val user = userService.findById(id)
            ?: return ServerResponse.notFound().buildAndAwait()
        return ServerResponse.ok().bodyValueAndAwait(user)
    }
}
```

### Spring Bean DSL

XML 또는 `@Configuration` + `@Bean` 대신 DSL로 Bean을 등록합니다.

```kotlin
val beans = beans {
    bean<UserRepository>()
    bean<UserService>()
    bean {
        UserController(ref())  // ref()로 다른 Bean 참조
    }
    profile("dev") {
        bean<DevDataInitializer>()
    }
}

@SpringBootApplication
class MyApplication

fun main(args: Array<String>) {
    runApplication<MyApplication>(*args) {
        addInitializers(beans)
    }
}
```

### Kotlin JOOQ DSL

QueryDSL과 유사하게 JOOQ도 Kotlin DSL을 통해 타입 안전한 쿼리 작성을 지원합니다.

```kotlin
@Repository
class UserRepositoryImpl(private val dsl: DSLContext) {

    fun findActiveUsers(minAge: Int): List<UserRecord> {
        return dsl
            .selectFrom(USER)
            .where(
                USER.STATUS.eq("ACTIVE")
                    .and(USER.AGE.greaterThan(minAge))
            )
            .orderBy(USER.CREATED_AT.desc())
            .fetch()
    }
}
```

---

## 커스텀 DSL 구현

직접 DSL을 만들어 복잡한 객체 생성 로직을 캡슐화할 수 있습니다.

### Builder 패턴을 DSL로

```kotlin
@DslMarker
annotation class RequestDsl

@RequestDsl
class HttpRequestBuilder {
    var method: String = "GET"
    var url: String = ""
    private val headers = mutableMapOf<String, String>()
    private var body: String? = null

    fun header(name: String, value: String) {
        headers[name] = value
    }

    fun body(block: () -> String) {
        body = block()
    }

    fun build(): HttpRequest = HttpRequest(method, url, headers, body)
}

fun httpRequest(block: HttpRequestBuilder.() -> Unit): HttpRequest {
    return HttpRequestBuilder().apply(block).build()
}

val request = httpRequest {
    method = "POST"
    url = "https://api.example.com/users"
    header("Content-Type", "application/json")
    header("Authorization", "Bearer $token")
    body { """{ "name": "Mory" }""" }
}
```

### 실무 예시: 알림 설정 DSL

```kotlin
@DslMarker
annotation class NotificationDsl

@NotificationDsl
class NotificationBuilder {
    var title: String = ""
    var message: String = ""
    private val channels = mutableListOf<Channel>()

    fun email(block: EmailChannelBuilder.() -> Unit) {
        channels.add(EmailChannelBuilder().apply(block).build())
    }

    fun slack(block: SlackChannelBuilder.() -> Unit) {
        channels.add(SlackChannelBuilder().apply(block).build())
    }

    fun build() = Notification(title, message, channels)
}

fun notification(block: NotificationBuilder.() -> Unit): Notification {
    return NotificationBuilder().apply(block).build()
}

val noti = notification {
    title = "배포 완료"
    message = "서버 배포가 성공적으로 완료되었습니다."
    email {
        to = "team@example.com"
        cc = listOf("manager@example.com")
    }
    slack {
        channel = "#deploy"
        mention = "@here"
    }
}
```

---

## Gradle Kotlin DSL

빌드 파일도 Kotlin DSL로 작성할 수 있습니다 (`build.gradle.kts`).

```kotlin
plugins {
    kotlin("jvm") version "1.9.25"
    kotlin("plugin.spring") version "1.9.25"
    id("org.springframework.boot") version "3.3.0"
    id("io.spring.dependency-management") version "1.1.5"
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    runtimeOnly("com.mysql:mysql-connector-j")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.test {
    useJUnitPlatform()
}
```

Groovy DSL(`build.gradle`)과 달리 IDE에서 자동완성, 타입 체크, 리팩토링이 완전히 지원됩니다.

---

## 요약

| 구분 | 핵심 내용 |
| --- | --- |
| 핵심 메커니즘 | 수신 객체가 있는 람다 (`T.() -> Unit`) |
| 스코프 제어 | `@DslMarker`로 잘못된 블록 접근 방지 |
| Spring Security | `http { }` 블록으로 선언적 보안 설정 |
| Router DSL | 어노테이션 없이 함수형으로 라우팅 정의 |
| Bean DSL | `beans { }` 블록으로 빈 등록 |
| 커스텀 DSL | `apply`  • 진입점 함수 조합으로 직접 구현 |
| Gradle DSL | `build.gradle.kts`로 타입 안전한 빌드 설정 |