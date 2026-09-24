---
title: "Spring @Cacheable"
date: 2026-09-24T00:00:00
toc: true
categories: ["JVM"]
tags: ["Cache"]
---

## 개요

Spring의 `@Cacheable`은 "메서드의 실행 결과를 캐시에 저장해두고, 같은 조건의 요청이 다시 들어오면 메서드를 실행하지 않고 캐시된 값을 반환"하도록 해주는 애노테이션입니다.

대표적으로 DB 조회처럼 "자주 호출되지만 결과가 자주 바뀌지 않는 로직"에 사용합니다.

```java
@Cacheable(cacheNames = "users", key = "#id")
public UserDto getUser(Long id) {
    return userRepository.findById(id)
            .map(UserDto::from)
            .orElseThrow();
}
```

동작은 다음과 같습니다.

```
getUser(1) 호출
    ↓
캐시에 users::1 존재?
    ↓
없음
    ↓
메서드 실행 → DB 조회
    ↓
결과 캐시에 저장
    ↓
반환

getUser(1) 다시 호출
    ↓
캐시에 users::1 존재
    ↓
메서드 실행 안 함
    ↓
캐시 값 바로 반환
```

---

## 기본 설정

Spring Boot에서는 먼저 캐시 기능을 활성화해야 합니다.

```java
@SpringBootApplication
@EnableCaching
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

그리고 캐시 대상 메서드에 `@Cacheable`을 붙입니다.

```java
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    @Cacheable(cacheNames = "users", key = "#id")
    public UserDto findById(Long id) {
        System.out.println("DB 조회");

        User user = userRepository.findById(id)
                .orElseThrow();

        return UserDto.from(user);
    }
}
```

```java
userService.findById(1L);
userService.findById(1L);
userService.findById(1L);
```

캐시가 정상적으로 적용되었다면 `"DB 조회"`는 최초 한 번만 출력됩니다.

---

## `cacheNames`

`cacheNames` 또는 `value`는 사용할 캐시 영역의 이름입니다.

```java
@Cacheable(cacheNames = "users")
```

아래도 동일합니다.

```java
@Cacheable(value = "users")
```

개념적으로는 다음과 같은 저장 공간이 있다고 보면 됩니다.

```
users
├── 1 → UserDto(...)
├── 2 → UserDto(...)
└── 3 → UserDto(...)

products
├── 1 → ProductDto(...)
└── 2 → ProductDto(...)
```

즉 `users`는 캐시를 논리적으로 구분하기 위한 이름입니다.

---

## `key`

캐시에서 값을 구분하는 키입니다.

```java
@Cacheable(
    cacheNames = "users",
    key = "#id"
)
public UserDto findById(Long id)
```

`id = 1`이면 개념적으로 다음과 같이 저장됩니다.

```
users
└── 1 → UserDto(...)
```

파라미터가 여러 개라면 조합할 수도 있습니다.

```java
@Cacheable(
    cacheNames = "boards",
    key = "#tenantId + ':' + #boardId"
)
public BoardDto findBoard(
        Long tenantId,
        Long boardId
) {
    ...
}
```

```
boards
├── "1:100" → ...
├── "1:101" → ...
└── "2:100" → ...
```

Spring Expression Language인 "SpEL"을 사용합니다.

---

## key를 생략하면

`key`는 반드시 지정할 필요는 없습니다.

```java
@Cacheable(cacheNames = "users")
public UserDto findById(Long id)
```

Spring이 메서드 파라미터를 기반으로 자동으로 키를 만듭니다.

파라미터 하나라면 사실상 해당 파라미터가 키가 됩니다.

```
findById(1L)

key = 1L
```

여러 개라면 `SimpleKey`가 생성됩니다.

```java
findBoard(1L, 100L)
```

```
SimpleKey [1, 100]
```

실무에서는 키 구조를 명확하게 통제하고 싶다면 직접 `key`를 지정하는 경우가 많습니다.

---

## `condition`

특정 조건에서만 캐시 기능을 사용하도록 할 수 있습니다.

```java
@Cacheable(
    cacheNames = "users",
    key = "#id",
    condition = "#id > 0"
)
public UserDto findById(Long id) {
    ...
}
```

`id > 0`인 경우에만 캐시를 확인하고 저장합니다.

---

## `unless`

`condition`과 비슷해 보이지만 실행 시점이 다릅니다.

`condition`:

```
메서드 실행 전 판단
```

`unless`:

```
메서드 실행 후 결과를 보고 판단
```

예를 들어 조회 결과가 `null`이면 캐시에 저장하지 않을 수 있습니다.

```java
@Cacheable(
    cacheNames = "users",
    key = "#id",
    unless = "#result == null"
)
public UserDto findById(Long id) {
    ...
}
```

즉 다음과 같습니다.

```
DB 조회
 ↓
result == null?
 ↓
YES → 캐시에 저장하지 않음
NO  → 캐시에 저장
```

---

## `@Cacheable`과 DB 조회

예를 들어 다음 코드가 있다고 하겠습니다.

```java
@Cacheable(cacheNames = "users", key = "#id")
public UserDto findById(Long id) {

    User user = userRepository.findById(id)
            .orElseThrow();

    return UserDto.from(user);
}
```

첫 번째 요청은 다음과 같습니다.

```
Controller
    ↓
Service.findById(1)
    ↓
Cache 확인
    ↓ miss
Repository
    ↓
DB
    ↓
UserDto 생성
    ↓
Cache 저장
    ↓
Controller
```

두 번째부터는 다음과 같습니다.

```
Controller
    ↓
Service.findById(1)
    ↓
Cache 확인
    ↓ hit
UserDto 반환
```

`Repository`와 DB까지 내려가지 않습니다.

---

## 중요한 점: Spring Proxy 기반입니다

`@Cacheable`은 Spring AOP Proxy 기반으로 동작합니다.

개념적으로 실제 구조는 다음에 가깝습니다.

```
Controller
    ↓
UserService Proxy
    ↓
CacheInterceptor
    ↓
실제 UserService
```

Proxy가 메서드 실행 전에 캐시를 확인하는 것입니다.

따라서 같은 클래스 내부에서 직접 호출하면 캐시가 적용되지 않는 문제가 발생할 수 있습니다.

```java
@Service
public class UserService {

    public void process() {
        findById(1L);
    }

    @Cacheable(cacheNames = "users", key = "#id")
    public UserDto findById(Long id) {
        ...
    }
}
```

위 `process()` → `findById()` 호출은 일반적으로 Proxy를 거치지 않습니다.

```
UserService.process()
    ↓
this.findById()
```

따라서 `@Cacheable`이 동작하지 않습니다.

이 문제를 `"self invocation"` 문제라고 합니다.

---

## `private` 메서드에도 주의해야 합니다

Proxy 기반이므로 다음과 같이 사용하는 것도 일반적인 Spring Proxy 환경에서는 적절하지 않습니다.

```java
@Cacheable("users")
private UserDto findById(Long id) {
    ...
}
```

보통 캐싱 대상 메서드는 외부 빈에서 호출되는 `public` 메서드에 둡니다.

---

## 데이터가 변경되면 어떻게 하나

`@Cacheable`만 사용하면 DB 데이터가 변경되어도 기존 캐시가 남아 있을 수 있습니다.

예를 들어:

```
DB
User(id=1, name="mory")

Cache
1 → name="mory"
```

이후 DB를 수정합니다.

```
DB
User(id=1, name="new-name")

Cache
1 → name="mory"
```

조회하면 캐시가 우선이므로 여전히 `"mory"`를 반환할 수 있습니다.

그래서 보통 `@CacheEvict` 또는 `@CachePut`을 같이 사용합니다.

---

## `@CacheEvict`

캐시를 삭제합니다.

```java
@CacheEvict(
    cacheNames = "users",
    key = "#id"
)
@Transactional
public void updateUser(Long id, UpdateUserRequest request) {

    User user = userRepository.findById(id)
            .orElseThrow();

    user.updateName(request.name());
}
```

흐름은 다음과 같습니다.

```
사용자 수정
    ↓
DB 변경
    ↓
users::1 캐시 삭제
    ↓
다음 조회
    ↓
DB 다시 조회
    ↓
최신 값 캐시 저장
```

삭제할 때도 동일합니다.

```java
@CacheEvict(cacheNames = "users", key = "#id")
@Transactional
public void deleteUser(Long id) {
    userRepository.deleteById(id);
}
```

---

## `@CachePut`

`@CachePut`은 메서드를 항상 실행한 뒤 결과로 캐시를 갱신합니다.

```java
@CachePut(
    cacheNames = "users",
    key = "#id"
)
@Transactional
public UserDto updateUser(
        Long id,
        UpdateUserRequest request
) {

    User user = userRepository.findById(id)
            .orElseThrow();

    user.updateName(request.name());

    return UserDto.from(user);
}
```

차이는 다음과 같습니다.

| 애노테이션 | 메서드 실행 | 주요 용도 |
| --- | --- | --- |
| `@Cacheable` | 캐시가 있으면 실행 안 함 | 조회 |
| `@CachePut` | 항상 실행 | 캐시 갱신 |
| `@CacheEvict` | 실행 후/전 캐시 삭제 | 수정/삭제 |

---

## 실제 캐시는 어디에 저장되는가

`@Cacheable` 자체가 Redis를 의미하는 것은 아닙니다.

Spring Cache는 "추상화"입니다.

```
Application
    ↓
Spring Cache abstraction
    ↓
CacheManager
    ↓
실제 Cache 구현
```

구현체로 여러 가지를 사용할 수 있습니다.

```
ConcurrentMap
Caffeine
Redis
Ehcache
...
```

예를 들어 별도 캐시 구현체가 없으면 간단한 메모리 캐시를 사용할 수 있습니다.

```java
@Bean
public CacheManager cacheManager() {
    return new ConcurrentMapCacheManager("users");
}
```

하지만 서버가 여러 대인 환경에서는 로컬 캐시가 서버마다 따로 존재합니다.

```
Pod A
Cache
users::1

Pod B
Cache
users::1

Pod C
Cache
users::1
```

따라서 Kubernetes나 다중 인스턴스 환경에서는 Redis 같은 분산 캐시를 많이 사용합니다.

```
Pod A ─┐
Pod B ─┼── Redis
Pod C ─┘
```

---

## Redis와 함께 사용하는 예시

Spring Boot에서는 보통 다음 의존성을 사용합니다.

```
implementation 'org.springframework.boot:spring-boot-starter-cache'
implementation 'org.springframework.boot:spring-boot-starter-data-redis'
```

설정:

```yaml
spring:
  cache:
    type: redis

  data:
    redis:
      host: localhost
      port: 6379
```

그리고 사용하는 코드는 똑같습니다.

```java
@Cacheable(
    cacheNames = "users",
    key = "#id"
)
public UserDto findById(Long id) {
    return userRepository.findById(id)
            .map(UserDto::from)
            .orElseThrow();
}
```

이게 Spring Cache 추상화의 장점입니다.

비즈니스 코드는:

```java
@Cacheable(...)
```

만 알고 있고 실제 저장소가

```
Caffeine
Redis
Ehcache
```

중 무엇인지는 `CacheManager`가 결정합니다.

---

## TTL

실무에서는 캐시를 영구적으로 두기보다 만료 시간을 지정하는 경우가 많습니다.

예를 들어:

```
users 캐시 TTL = 10분
```

이면

```
11:00 캐시 생성
11:10 캐시 만료
11:11 요청 → DB 조회 → 캐시 재생성
```

Redis에서는 `RedisCacheManager`를 통해 설정할 수 있습니다.

```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public RedisCacheManager cacheManager(
            RedisConnectionFactory connectionFactory
    ) {

        RedisCacheConfiguration config =
                RedisCacheConfiguration.defaultCacheConfig()
                        .entryTtl(Duration.ofMinutes(10));

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(config)
                .build();
    }
}
```

---

## 실무에서 주로 쓰는 형태

조회:

```java
@Cacheable(
    cacheNames = "users",
    key = "#userId",
    unless = "#result == null"
)
@Transactional(readOnly = true)
public UserDto findUser(Long userId) {

    User user = userRepository.findById(userId)
            .orElseThrow();

    return UserDto.from(user);
}
```

수정:

```java
@CacheEvict(
    cacheNames = "users",
    key = "#userId"
)
@Transactional
public void updateUser(
        Long userId,
        UpdateUserRequest request
) {

    User user = userRepository.findById(userId)
            .orElseThrow();

    user.update(request.name());
}
```

이 방식은 `"Cache Aside"` 패턴과 비슷한 형태가 됩니다.

```
조회
Cache → 없으면 DB → Cache 저장

수정
DB 수정 → Cache 제거

다음 조회
DB → 최신 값 → Cache 저장
```

Spring에서 가장 이해하기 쉽고 관리하기도 편한 방식입니다.

---

## 주의할 점

캐시는 모든 조회에 무조건 붙이는 기능은 아닙니다.

다음 데이터에 효과적입니다.

```
조회 빈도 높음
        +
변경 빈도 낮음
        +
DB 조회 비용 높음
```

예를 들면:

```
코드/공통 데이터
게시판 카테고리
상품 정보
기관 설정
권한 정보
자주 조회되는 상세 데이터
```

반대로 초 단위로 계속 바뀌거나 항상 최신 값이 중요한 데이터는 캐시 무효화 전략을 먼저 설계해야 합니다.

특히 Spring + JPA에서는 다음 세 가지를 같이 생각해야 합니다.

```
DB 데이터
    ↓
JPA Persistence Context
    ↓
Spring Cache
    ↓
Redis/Caffeine
```

JPA 1차 캐시와 `@Cacheable`의 캐시는 서로 다른 개념입니다.

---

## 전체 요약

`@Cacheable`은 다음 원리입니다.

```
@Cacheable
    ↓
캐시 확인
    ↓
HIT ───→ 캐시 값 반환
    ↓ MISS
메서드 실행
    ↓
DB 조회
    ↓
결과 Cache 저장
    ↓
반환
```

핵심만 정리하면:

```java
@Cacheable   // 있으면 캐시 반환, 없으면 실행 후 저장
@CachePut    // 항상 실행 후 캐시 갱신
@CacheEvict  // 캐시 삭제
```

그리고 Spring `@Cacheable`은 `"Spring AOP Proxy + CacheManager"` 기반이며, Redis는 `@Cacheable` 자체가 아니라 Spring Cache 뒤에 붙는 실제 캐시 저장소 중 하나입니다.

실무에서는 대체로 `"조회는 @Cacheable, 수정/삭제는 @CacheEvict, Redis에는 TTL 설정"` 구조로 시작하면 이해하기 좋습니다.