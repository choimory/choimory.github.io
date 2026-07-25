---
title: "Spring Boot API 테스트 코드"
date: 2026-07-25T00:00:00
toc: true
toc_sticky: true
categories:
    - JVM
tags:
    - TDD
---

## 개요

Spring Boot API 테스트 코드는 "Controller, Service, Repository, DB, 외부 API 연동"이 의도대로 동작하는지 자동으로 검증하는 코드입니다.

API 테스트는 보통 다음 3단계로 나눠서 작성합니다.

| 테스트 종류 | 대상 | 목적 | 대표 도구 |
| --- | --- | --- | --- |
| 단위 테스트 | Service, Util, Mapper | 비즈니스 로직만 빠르게 검증 | JUnit5, Mockito |
| Web MVC 테스트 | Controller | HTTP 요청/응답, Validation, Status 검증 | MockMvc, `@WebMvcTest` |
| 통합 테스트 | Controller + Service + Repository + DB | 실제 흐름 전체 검증 | `@SpringBootTest`, Testcontainers |

실무에서는 보통 "Service 단위 테스트 + Controller 테스트 + 일부 핵심 API 통합 테스트" 조합을 많이 사용합니다.

---

## 기본 테스트 의존성

Spring Boot 프로젝트에 기본적으로 아래 의존성이 필요합니다.

### Gradle Kotlin DSL

```kotlin
dependencies {
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.4.0")
}
```

`spring-boot-starter-test` 안에는 대체로 다음 도구들이 포함됩니다.

| 도구 | 역할 |
| --- | --- |
| JUnit5 | 테스트 실행 |
| AssertJ | 검증 코드 작성 |
| Mockito | Mock 객체 생성 |
| MockMvc | Controller API 테스트 |
| JsonPath | JSON 응답 검증 |

---

## 예시 API 구조

예시로 회원 조회 API를 테스트한다고 가정하겠습니다.

### Controller

```kotlin
@RestController
@RequestMapping("/api/users")
class UserController(
    private val userService: UserService
) {

    @GetMapping("/{userId}")
    fun getUser(
        @PathVariable userId: Long
    ): ResponseEntity<UserResponse> {
        val response = userService.getUser(userId)
        return ResponseEntity.ok(response)
    }

    @PostMapping
    fun createUser(
        @Valid @RequestBody request: CreateUserRequest
    ): ResponseEntity<UserResponse> {
        val response = userService.createUser(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }
}
```

### DTO

```kotlin
data class CreateUserRequest(
    @field:NotBlank
    val name: String,

    @field:Email
    @field:NotBlank
    val email: String
)

data class UserResponse(
    val id: Long,
    val name: String,
    val email: String
)
```

### Service

```kotlin
@Service
class UserService(
    private val userRepository: UserRepository
) {

    fun getUser(userId: Long): UserResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다.") }

        return UserResponse(
            id = user.id!!,
            name = user.name,
            email = user.email
        )
    }

    fun createUser(request: CreateUserRequest): UserResponse {
        val user = User(
            name = request.name,
            email = request.email
        )

        val savedUser = userRepository.save(user)

        return UserResponse(
            id = savedUser.id!!,
            name = savedUser.name,
            email = savedUser.email
        )
    }
}
```

---

## Controller 테스트

Controller 테스트는 HTTP 요청과 응답이 올바른지 검증합니다.

여기서는 Service를 Mock 처리하고 Controller만 테스트합니다.

### `@WebMvcTest` 사용

```kotlin
@WebMvcTest(UserController::class)
class UserControllerTest {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @MockBean
    lateinit var userService: UserService

    @Test
    fun `회원 단건 조회 성공`() {
        // given
        val userId = 1L
        val response = UserResponse(
            id = userId,
            name = "mory",
            email = "mory@example.com"
        )

        given(userService.getUser(userId)).willReturn(response)

        // when & then
        mockMvc.perform(
            get("/api/users/{userId}", userId)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("mory"))
            .andExpect(jsonPath("$.email").value("mory@example.com"))
    }

    @Test
    fun `회원 생성 성공`() {
        // given
        val request = CreateUserRequest(
            name = "mory",
            email = "mory@example.com"
        )

        val response = UserResponse(
            id = 1L,
            name = "mory",
            email = "mory@example.com"
        )

        given(userService.createUser(request)).willReturn(response)

        // when & then
        mockMvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("mory"))
            .andExpect(jsonPath("$.email").value("mory@example.com"))
    }
}
```

### 핵심 포인트

`@WebMvcTest`는 Controller 계층만 로딩합니다.

그래서 다음 검증에 적합합니다.

| 검증 대상 | 가능 여부 |
| --- | --- |
| URL 매핑 | 가능 |
| HTTP Method | 가능 |
| Request Body | 가능 |
| Response Status | 가능 |
| JSON 응답 구조 | 가능 |
| Validation | 가능 |
| Service 내부 로직 | 부적합 |
| DB 저장 여부 | 부적합 |

---

## Validation 테스트

API 테스트에서 중요한 부분은 잘못된 요청을 제대로 막는 것입니다.

예를 들어 이름이 비어 있거나 이메일 형식이 잘못된 경우입니다.

```kotlin
@Test
fun `회원 생성 실패 - 이름이 비어 있음`() {
    // given
    val request = CreateUserRequest(
        name = "",
        email = "mory@example.com"
    )

    // when & then
    mockMvc.perform(
        post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request))
    )
        .andExpect(status().isBadRequest)
}
```

```kotlin
@Test
fun `회원 생성 실패 - 이메일 형식이 아님`() {
    // given
    val request = CreateUserRequest(
        name = "mory",
        email = "invalid-email"
    )

    // when & then
    mockMvc.perform(
        post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request))
    )
        .andExpect(status().isBadRequest)
}
```

Validation 테스트는 실무에서 중요합니다.

프론트엔드에서 막더라도 백엔드 API는 반드시 자체적으로 요청 값을 검증해야 합니다.

---

## Service 단위 테스트

Service 테스트는 HTTP 없이 비즈니스 로직만 검증합니다.

Repository는 Mock 처리합니다.

```kotlin
@ExtendWith(MockitoExtension::class)
class UserServiceTest {

    @Mock
    lateinit var userRepository: UserRepository

    @InjectMocks
    lateinit var userService: UserService

    @Test
    fun `회원 단건 조회 성공`() {
        // given
        val userId = 1L
        val user = User(
            id = userId,
            name = "mory",
            email = "mory@example.com"
        )

        given(userRepository.findById(userId)).willReturn(Optional.of(user))

        // when
        val result = userService.getUser(userId)

        // then
        assertThat(result.id).isEqualTo(1L)
        assertThat(result.name).isEqualTo("mory")
        assertThat(result.email).isEqualTo("mory@example.com")
    }

    @Test
    fun `회원 단건 조회 실패 - 사용자가 없음`() {
        // given
        val userId = 999L

        given(userRepository.findById(userId)).willReturn(Optional.empty())

        // when & then
        assertThatThrownBy {
            userService.getUser(userId)
        }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessage("사용자를 찾을 수 없습니다.")
    }
}
```

### Service 테스트에서 검증할 것

| 항목 | 예시 |
| --- | --- |
| 정상 로직 | 회원 생성 성공, 주문 생성 성공 |
| 예외 로직 | 없는 회원 조회, 권한 없음 |
| 분기 로직 | 상태값에 따른 처리 |
| 계산 로직 | 가격, 할인, 포인트 계산 |
| Repository 호출 여부 | 저장/조회 메서드 호출 확인 |

Repository 호출 여부를 검증하고 싶다면 다음처럼 작성할 수 있습니다.

```kotlin
verify(userRepository).findById(1L)
verify(userRepository, never()).delete(any())
```

---

## Repository 테스트

Repository 테스트는 JPA 쿼리, Entity 매핑, DB 제약조건을 검증합니다.

```kotlin
@DataJpaTest
class UserRepositoryTest {

    @Autowired
    lateinit var userRepository: UserRepository

    @Test
    fun `이메일로 회원 조회 성공`() {
        // given
        val user = User(
            name = "mory",
            email = "mory@example.com"
        )

        userRepository.save(user)

        // when
        val result = userRepository.findByEmail("mory@example.com")

        // then
        assertThat(result).isPresent
        assertThat(result.get().name).isEqualTo("mory")
    }
}
```

`@DataJpaTest`는 JPA 관련 Bean만 로딩합니다.

기본적으로 테스트용 인메모리 DB를 사용하거나, 설정에 따라 실제 MySQL 테스트 DB를 사용할 수도 있습니다.

---

## 통합 테스트

통합 테스트는 실제 Spring Context를 띄워서 Controller부터 DB까지 전체 흐름을 검증합니다.

```kotlin
@SpringBootTest
@AutoConfigureMockMvc
class UserApiIntegrationTest {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var userRepository: UserRepository

    @BeforeEach
    fun setUp() {
        userRepository.deleteAll()
    }

    @Test
    fun `회원 생성 후 조회 성공`() {
        // given
        val request = CreateUserRequest(
            name = "mory",
            email = "mory@example.com"
        )

        // when
        val createResult = mockMvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.id").exists())
            .andExpect(jsonPath("$.name").value("mory"))
            .andReturn()

        val responseBody = createResult.response.contentAsString
        val createdUser = objectMapper.readValue(responseBody, UserResponse::class.java)

        // then
        mockMvc.perform(
            get("/api/users/{userId}", createdUser.id)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(createdUser.id))
            .andExpect(jsonPath("$.name").value("mory"))
            .andExpect(jsonPath("$.email").value("mory@example.com"))
    }
}
```

### 통합 테스트의 장점과 단점

| 구분 | 내용 |
| --- | --- |
| 장점 | 실제 API 흐름과 가장 유사하게 검증 가능 |
| 장점 | Controller, Service, Repository 연결 문제 발견 가능 |
| 단점 | 테스트 실행 속도가 느림 |
| 단점 | DB 초기화와 테스트 데이터 관리가 필요 |
| 단점 | 모든 케이스를 통합 테스트로 작성하면 유지보수가 어려움 |

---

## Testcontainers로 MySQL 테스트하기

실무에서는 H2보다 Testcontainers를 이용해 실제 MySQL과 비슷한 환경에서 테스트하는 것이 더 안전합니다.

### 의존성

```kotlin
dependencies {
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:mysql")
}
```

### 테스트 코드

```kotlin
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class UserApiMysqlIntegrationTest {

    companion object {

        @Container
        val mysql = MySQLContainer<Nothing>("mysql:8.0").apply {
            withDatabaseName("testdb")
            withUsername("test")
            withPassword("test")
        }

        @JvmStatic
        @DynamicPropertySource
        fun properties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url") { mysql.jdbcUrl }
            registry.add("spring.datasource.username") { mysql.username }
            registry.add("spring.datasource.password") { mysql.password }
            registry.add("spring.datasource.driver-class-name") { mysql.driverClassName }
        }
    }

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var userRepository: UserRepository

    @BeforeEach
    fun setUp() {
        userRepository.deleteAll()
    }

    @Test
    fun `회원 생성 성공`() {
        // given
        val request = CreateUserRequest(
            name = "mory",
            email = "mory@example.com"
        )

        // when & then
        mockMvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.name").value("mory"))
            .andExpect(jsonPath("$.email").value("mory@example.com"))
    }
}
```

### 왜 H2보다 MySQL 테스트가 좋은가

H2와 MySQL은 SQL 문법, 인덱스, 컬럼 타입, 예약어, JSON 타입, 날짜 처리 방식이 다를 수 있습니다.

그래서 실제 운영 DB가 MySQL이면 테스트도 MySQL 기반으로 돌리는 것이 장애 예방에 더 좋습니다.

---

## 에러 응답 테스트

실무 API에서는 성공 응답보다 에러 응답 형식이 더 중요할 때가 많습니다.

예를 들어 모든 에러를 아래 형태로 내려준다고 가정합니다.

```kotlin
data class ErrorResponse(
    val code: String,
    val message: String
)
```

### GlobalExceptionHandler

```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgumentException(
        e: IllegalArgumentException
    ): ResponseEntity<ErrorResponse> {
        return ResponseEntity
            .badRequest()
            .body(
                ErrorResponse(
                    code = "BAD_REQUEST",
                    message = e.message ?: "잘못된 요청입니다."
                )
            )
    }
}
```

### 에러 응답 테스트

```kotlin
@Test
fun `회원 조회 실패 - 사용자를 찾을 수 없음`() {
    // given
    val userId = 999L

    given(userService.getUser(userId))
        .willThrow(IllegalArgumentException("사용자를 찾을 수 없습니다."))

    // when & then
    mockMvc.perform(
        get("/api/users/{userId}", userId)
    )
        .andExpect(status().isBadRequest)
        .andExpect(jsonPath("$.code").value("BAD_REQUEST"))
        .andExpect(jsonPath("$.message").value("사용자를 찾을 수 없습니다."))
}
```

---

## 인증이 있는 API 테스트

Spring Security를 사용하는 API라면 인증 정보가 필요합니다.

### 테스트 의존성

```kotlin
dependencies {
    testImplementation("org.springframework.security:spring-security-test")
}
```

### Mock User 사용

```kotlin
@Test
@WithMockUser(username = "mory", roles = ["USER"])
fun `인증된 사용자는 내 정보 조회 가능`() {
    mockMvc.perform(
        get("/api/me")
    )
        .andExpect(status().isOk)
}
```

### 인증 없는 요청 검증

```kotlin
@Test
fun `인증되지 않은 사용자는 내 정보 조회 실패`() {
    mockMvc.perform(
        get("/api/me")
    )
        .andExpect(status().isUnauthorized)
}
```

### 권한 부족 검증

```kotlin
@Test
@WithMockUser(username = "mory", roles = ["USER"])
fun `일반 사용자는 관리자 API 접근 실패`() {
    mockMvc.perform(
        get("/api/admin/users")
    )
        .andExpect(status().isForbidden)
}
```

---

## 테스트 코드 작성 기준

API 테스트는 모든 것을 다 테스트하기보다 "깨지면 큰일 나는 부분"을 우선해야 합니다.

### 우선순위

| 우선순위 | 테스트 대상 |
| --- | --- |
| 1순위 | 핵심 비즈니스 로직 |
| 1순위 | 결제, 주문, 권한, 인증 |
| 1순위 | 데이터 정합성 |
| 2순위 | Controller 요청/응답 |
| 2순위 | Validation |
| 2순위 | 예외 응답 |
| 3순위 | 단순 CRUD |
| 3순위 | Getter/Setter 수준 코드 |

### 추천 조합

```
Controller 테스트:
- HTTP status
- request validation
- response json
- error response

Service 테스트:
- 핵심 비즈니스 로직
- 예외 상황
- 상태 변경
- 권한 판단

Repository 테스트:
- 커스텀 쿼리
- unique 제약조건
- 복잡한 조회 조건

통합 테스트:
- 회원가입
- 로그인
- 주문 생성
- 결제 요청
- 권한 필요한 API
```

---

## 테스트 코드 네이밍

Kotlin에서는 백틱을 이용해 테스트 이름을 자연어처럼 작성할 수 있습니다.

```kotlin
@Test
fun `회원 생성 성공`() {
}
```

```kotlin
@Test
fun `이메일이 비어 있으면 회원 생성에 실패한다`() {
}
```

추천 패턴은 다음과 같습니다.

```
상황 + 기대 결과
```

예시는 다음과 같습니다.

```
회원 생성 성공
존재하지 않는 회원 조회 시 예외 발생
이메일 형식이 아니면 회원 생성 실패
인증되지 않은 사용자는 내 정보 조회 실패
관리자가 아니면 관리자 API 접근 실패
```

---

## given-when-then 패턴

테스트 코드는 보통 다음 구조로 작성하면 읽기 좋습니다.

```kotlin
@Test
fun `회원 생성 성공`() {
    // given
    val request = CreateUserRequest(
        name = "mory",
        email = "mory@example.com"
    )

    // when
    val result = userService.createUser(request)

    // then
    assertThat(result.name).isEqualTo("mory")
}
```

| 구간 | 의미 |
| --- | --- |
| given | 테스트 준비 |
| when | 실제 실행 |
| then | 결과 검증 |

Controller 테스트에서는 `when`과 `then`을 합쳐서 작성하는 경우도 많습니다.

---

## 실무 권장 테스트 전략

Spring Boot API에서는 아래 전략을 추천합니다.

### 1. Controller는 얇게 테스트합니다

Controller에서는 다음만 검증합니다.

```
URL
HTTP Method
Request Body
Validation
Status Code
Response JSON
```

비즈니스 로직은 Controller 테스트에서 깊게 검증하지 않습니다.

---

### 2. Service에서 비즈니스 로직을 집중 검증합니다

Service 테스트는 빠르고 유지보수가 쉽습니다.

```
주문 가능 여부
재고 차감
포인트 적립
권한 체크
상태 변경
예외 조건
```

이런 핵심 로직은 Service 단위 테스트로 많이 작성하는 것이 좋습니다.

---

### 3. Repository는 커스텀 쿼리 위주로 테스트합니다

단순한 `findById`, `save`는 굳이 테스트하지 않아도 됩니다.

대신 아래는 테스트하는 것이 좋습니다.

```
복잡한 검색 조건
QueryDSL 쿼리
JPQL
Native Query
Unique 제약조건
페이징 정렬
```

---

### 4. 통합 테스트는 핵심 흐름만 작성합니다

모든 API를 통합 테스트로 작성하면 느려집니다.

대신 아래 흐름은 통합 테스트 가치가 높습니다.

```
회원가입
로그인
주문 생성
결제 요청
파일 업로드
권한별 접근 제어
외부 API 연동 실패 처리
```

---

## 추천 디렉토리 구조

```
src
 └── test
     └── kotlin
         └── com.example.demo
             ├── user
             │   ├── controller
             │   │   └── UserControllerTest.kt
             │   ├── service
             │   │   └── UserServiceTest.kt
             │   ├── repository
             │   │   └── UserRepositoryTest.kt
             │   └── integration
             │       └── UserApiIntegrationTest.kt
             └── support
                 ├── Fixture.kt
                 └── TestSecurityConfig.kt
```

테스트가 많아지면 `support` 패키지에 테스트 공통 유틸을 분리하면 좋습니다.

---

## Fixture 사용 예시

테스트 데이터 생성을 매번 직접 작성하면 코드가 길어집니다.

그래서 Fixture 함수를 만들어두면 좋습니다.

```kotlin
object UserFixture {

    fun createUser(
        id: Long? = 1L,
        name: String = "mory",
        email: String = "mory@example.com"
    ): User {
        return User(
            id = id,
            name = name,
            email = email
        )
    }

    fun createUserRequest(
        name: String = "mory",
        email: String = "mory@example.com"
    ): CreateUserRequest {
        return CreateUserRequest(
            name = name,
            email = email
        )
    }

    fun userResponse(
        id: Long = 1L,
        name: String = "mory",
        email: String = "mory@example.com"
    ): UserResponse {
        return UserResponse(
            id = id,
            name = name,
            email = email
        )
    }
}
```

사용 예시는 다음과 같습니다.

```kotlin
val request = UserFixture.createUserRequest()
val response = UserFixture.userResponse()
```

---

## 전체 예시 테스트 세트

아래 정도면 기본적인 API 테스트 구성이 됩니다.

```kotlin
@WebMvcTest(UserController::class)
class UserControllerTest {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @MockBean
    lateinit var userService: UserService

    @Test
    fun `회원 조회 성공`() {
        val response = UserResponse(
            id = 1L,
            name = "mory",
            email = "mory@example.com"
        )

        given(userService.getUser(1L)).willReturn(response)

        mockMvc.perform(
            get("/api/users/{userId}", 1L)
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("mory"))
    }

    @Test
    fun `회원 생성 성공`() {
        val request = CreateUserRequest(
            name = "mory",
            email = "mory@example.com"
        )

        val response = UserResponse(
            id = 1L,
            name = "mory",
            email = "mory@example.com"
        )

        given(userService.createUser(request)).willReturn(response)

        mockMvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.name").value("mory"))
            .andExpect(jsonPath("$.email").value("mory@example.com"))
    }

    @Test
    fun `회원 생성 실패 - 이름이 비어 있음`() {
        val request = CreateUserRequest(
            name = "",
            email = "mory@example.com"
        )

        mockMvc.perform(
            post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isBadRequest)
    }
}
```

---

## 전체 요약

Spring Boot API 테스트는 목적에 따라 나눠 작성하는 것이 좋습니다.

| 테스트 | 추천 사용처 |
| --- | --- |
| `@WebMvcTest` | Controller 요청/응답 검증 |
| Mockito 단위 테스트 | Service 비즈니스 로직 검증 |
| `@DataJpaTest` | Repository, JPA 쿼리 검증 |
| `@SpringBootTest` | API 전체 흐름 검증 |
| Testcontainers | 실제 MySQL 기반 통합 테스트 |

가장 추천하는 실무 조합은 다음과 같습니다.

```
1. Controller 테스트로 HTTP 요청/응답 검증
2. Service 테스트로 핵심 비즈니스 로직 검증
3. Repository 테스트로 커스텀 쿼리 검증
4. 통합 테스트로 핵심 API 흐름만 검증
```

즉, 모든 API를 무조건 통합 테스트로 덮기보다는 "빠른 단위 테스트를 많이 작성하고, 중요한 흐름만 통합 테스트로 검증하는 방식"이 가장 유지보수하기 좋습니다.