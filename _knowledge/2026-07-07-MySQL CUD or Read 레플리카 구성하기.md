---
title: "MySQL CUD or Read 레플리카 구성하기"
date: 2026-07-07T00:00:00
toc: true
toc_sticky: true
categories:
    - DB
tags:
    - Replica
---

## 개요

MySQL에서 CUD와 Read를 분리한다는 것은 "쓰기 작업"과 "읽기 작업"을 서로 다른 DB 인스턴스로 보내는 구조입니다.

여기서 CUD는 보통 다음 작업을 의미합니다.

| 구분 | 의미 | SQL |
| --- | --- | --- |
| C | Create | INSERT |
| U | Update | UPDATE |
| D | Delete | DELETE |
| Read | 조회 | SELECT |

일반적인 구성은 다음과 같습니다.

```
Application
   |
   |-- INSERT / UPDATE / DELETE --> Writer DB, Primary, Master
   |
   |-- SELECT -------------------> Reader DB, Replica, Read Replica
```

핵심은 "쓰기 DB는 하나로 유지하고", "읽기 DB를 여러 개로 늘려 조회 부하를 분산"하는 것입니다.

---

## 기본 구조

MySQL CUD/Read 분리 구조는 보통 "Primary-Replica Replication" 기반으로 구성합니다.

```
                 +----------------+
                 |  Application   |
                 +--------+-------+
                          |
          +---------------+---------------+
          |                               |
   CUD, Transaction                   SELECT
          |                               |
          v                               v
+-------------------+          +-------------------+
| Primary MySQL     |  ----->  | Read Replica 1    |
| Writer DB         | binlog   | Reader DB         |
+-------------------+          +-------------------+
          |
          | binlog replication
          v
+-------------------+
| Read Replica 2    |
| Reader DB         |
+-------------------+
```

Primary DB는 모든 변경 작업을 처리합니다.

Read Replica는 Primary의 변경 사항을 복제해서 따라갑니다.

애플리케이션은 SQL의 성격에 따라 DB 연결을 다르게 사용합니다.

---

## 구성 목적

### 읽기 부하 분산

서비스에서 DB 부하의 대부분은 조회에서 발생하는 경우가 많습니다.

예를 들어 게시글 서비스라면 다음과 같습니다.

```
글 작성: INSERT
글 수정: UPDATE
글 삭제: DELETE
글 목록 조회: SELECT
글 상세 조회: SELECT
댓글 조회: SELECT
검색: SELECT
```

쓰기보다 읽기가 훨씬 많기 때문에 SELECT를 Replica로 보내면 Primary DB의 부담을 줄일 수 있습니다.

### Primary 안정성 확보

Primary DB는 데이터의 원본입니다.

따라서 Primary가 과부하로 느려지거나 장애가 나면 서비스 전체가 위험해집니다.

Read Replica를 두면 읽기 트래픽을 분산해서 Primary를 상대적으로 안정적으로 유지할 수 있습니다.

### 조회 성능 확장

Read Replica는 여러 대로 늘릴 수 있습니다.

```
SELECT 트래픽 증가
    |
    v
Read Replica 추가
```

즉, 읽기 성능은 수평 확장이 가능합니다.

단, 쓰기 성능은 기본적으로 Primary 한 대에 집중됩니다.

---

## MySQL Replication 개념

### Binary Log

Primary DB에서 INSERT, UPDATE, DELETE 같은 변경이 발생하면 MySQL은 변경 내역을 "Binary Log"에 기록합니다.

Replica는 이 Binary Log를 가져와서 동일한 변경을 자기 DB에도 적용합니다.

```
Primary
  |
  | 1. 변경 발생
  | 2. binlog 기록
  v
Replica
  |
  | 3. binlog 수신
  | 4. 동일 변경 적용
```

### 복제 지연

Read Replica는 Primary와 완전히 동시에 반영되지 않을 수 있습니다.

이 차이를 "Replication Lag", 즉 복제 지연이라고 합니다.

예를 들어 사용자가 게시글을 작성한 직후 바로 조회하면 문제가 생길 수 있습니다.

```
1. Primary에 게시글 INSERT 성공
2. Replica에는 아직 반영 안 됨
3. 사용자가 목록 조회
4. Replica에서 조회
5. 방금 쓴 글이 안 보임
```

이 문제 때문에 CUD/Read 분리에서는 "읽기 일관성" 처리가 매우 중요합니다.

---

## 애플리케이션 라우팅 방식

## 1. 코드에서 직접 분리

가장 단순한 방식은 애플리케이션 코드에서 Writer용 DataSource와 Reader용 DataSource를 따로 두는 것입니다.

```
writeDataSource -> Primary DB
readDataSource  -> Read Replica DB
```

예시는 다음과 같습니다.

```java
userRepository.save(user);        // writer
userReadRepository.findById(id);  // reader
```

장점은 명확합니다.

단점은 개발자가 실수로 조회를 Writer에 보내거나, 쓰기를 Reader에 보내지 않도록 신경 써야 합니다.

---

## 2. Transaction readOnly 기준 분리

Spring 환경에서는 보통 `@Transactional(readOnly = true)` 여부를 기준으로 DB를 자동 라우팅합니다.

```java
@Transactional
public void createUser() {
    userRepository.save(user); // Primary
}

@Transactional(readOnly = true)
public User getUser(Long id) {
    return userRepository.findById(id); // Replica
}
```

개념적으로는 다음과 같습니다.

```
readOnly = false 또는 기본값 -> Primary
readOnly = true              -> Replica
```

Spring에서는 보통 `AbstractRoutingDataSource`를 사용해서 현재 트랜잭션이 readOnly인지 확인하고 적절한 DataSource를 선택합니다.

---

## 3. ProxySQL, MySQL Router 사용

애플리케이션에서 직접 분리하지 않고, 중간에 DB Proxy를 두는 방식도 있습니다.

```
Application
   |
   v
ProxySQL / MySQL Router
   |
   |-- Write Query --> Primary
   |
   |-- Read Query ---> Replica
```

대표적으로 다음 도구를 사용할 수 있습니다.

| 도구 | 설명 |
| --- | --- |
| ProxySQL | 쿼리 룰 기반으로 읽기/쓰기 분리 가능 |
| MySQL Router | MySQL InnoDB Cluster와 함께 자주 사용 |
| Cloud DB Proxy | 클라우드 서비스에서 제공하는 프록시 기능 |

장점은 애플리케이션 코드 변경이 줄어든다는 점입니다.

단점은 Proxy 레이어의 운영 복잡도가 생긴다는 점입니다.

---

## Spring Boot 구성 예시

### DataSource 구성 개념

```
Primary DataSource
  - jdbc:mysql://primary:3306/app

Replica DataSource
  - jdbc:mysql://replica:3306/app

Routing DataSource
  - readOnly 여부에 따라 primary 또는 replica 선택
```

### application.yml 예시

```yaml
spring:
  datasource:
    writer:
      jdbc-url: jdbc:mysql://primary-db:3306/app
      username: app_user
      password: password
      driver-class-name: com.mysql.cj.jdbc.Driver

    reader:
      jdbc-url: jdbc:mysql://replica-db:3306/app
      username: app_user
      password: password
      driver-class-name: com.mysql.cj.jdbc.Driver
```

### RoutingDataSource 예시

```java
public class ReplicationRoutingDataSource extends AbstractRoutingDataSource {

    @Override
    protected Object determineCurrentLookupKey() {
        boolean readOnly = TransactionSynchronizationManager
                .isCurrentTransactionReadOnly();

        return readOnly ? "reader" : "writer";
    }
}
```

### DataSource 설정 예시

```java
@Configuration
public class DataSourceConfig {

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource.writer")
    public DataSource writerDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource.reader")
    public DataSource readerDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean
    public DataSource routingDataSource(
            @Qualifier("writerDataSource") DataSource writerDataSource,
            @Qualifier("readerDataSource") DataSource readerDataSource
    ) {
        Map<Object, Object> dataSources = new HashMap<>();
        dataSources.put("writer", writerDataSource);
        dataSources.put("reader", readerDataSource);

        ReplicationRoutingDataSource routingDataSource =
                new ReplicationRoutingDataSource();

        routingDataSource.setTargetDataSources(dataSources);
        routingDataSource.setDefaultTargetDataSource(writerDataSource);

        return routingDataSource;
    }

    @Primary
    @Bean
    public DataSource dataSource(DataSource routingDataSource) {
        return new LazyConnectionDataSourceProxy(routingDataSource);
    }
}
```

여기서 중요한 부분은 `LazyConnectionDataSourceProxy`입니다.

트랜잭션이 시작되자마자 커넥션을 잡아버리면 readOnly 여부가 반영되기 전에 DataSource가 결정될 수 있습니다.

`LazyConnectionDataSourceProxy`를 사용하면 실제 쿼리가 실행되는 시점에 커넥션을 가져오므로 라우팅이 더 정확하게 동작합니다.

---

## 읽기 일관성 문제

### 문제 상황

CUD/Read 분리에서 가장 흔한 문제는 "방금 쓴 데이터가 안 보이는 현상"입니다.

```
사용자 회원가입
   |
   v
Primary INSERT 성공
   |
   v
바로 사용자 정보 조회
   |
   v
Replica SELECT
   |
   v
복제 지연 때문에 데이터 없음
```

이 문제는 버그처럼 보이지만, 구조적으로 자연스럽게 발생할 수 있습니다.

---

## 해결 방법

### 1. 쓰기 직후 일정 시간 Primary에서 읽기

사용자가 CUD 작업을 한 직후에는 일정 시간 동안 SELECT도 Primary로 보냅니다.

```
INSERT / UPDATE / DELETE 발생
   |
   v
현재 사용자 세션에 write flag 저장
   |
   v
몇 초 동안 SELECT도 Primary로 라우팅
```

예를 들어 다음과 같은 정책을 둘 수 있습니다.

```
쓰기 후 3초 동안은 Primary에서 읽기
```

장점은 구현이 비교적 단순합니다.

단점은 Primary 읽기 부하가 일부 증가합니다.

---

### 2. 중요한 조회는 무조건 Primary에서 읽기

정합성이 중요한 조회는 Replica를 사용하지 않는 방식입니다.

예를 들어 다음 조회는 Primary를 쓰는 것이 안전합니다.

| 상황 | 이유 |
| --- | --- |
| 로그인 직후 사용자 정보 조회 | 방금 생성/수정된 계정 정보 필요 |
| 결제 직후 주문 조회 | 데이터 정합성이 중요 |
| 관리자 상태 변경 직후 조회 | 최신 상태가 중요 |
| 재고 차감 직후 재고 조회 | 잘못 보이면 장애 가능 |

즉, 모든 SELECT를 Replica로 보내면 안 됩니다.

"조금 늦어도 괜찮은 조회"만 Replica로 보내는 것이 좋습니다.

---

### 3. 트랜잭션 내부 조회는 Primary 사용

하나의 트랜잭션 안에서 쓰기 후 읽기가 발생한다면 Primary를 사용해야 합니다.

```java
@Transactional
public Order createOrder() {
    orderRepository.save(order);

    return orderRepository.findById(order.getId()).orElseThrow();
}
```

이 경우 `readOnly = false` 트랜잭션이므로 Primary로 라우팅되는 것이 자연스럽습니다.

---

### 4. Replica Lag 모니터링

Replica가 Primary를 얼마나 늦게 따라가고 있는지 확인해야 합니다.

MySQL에서는 보통 다음 명령으로 확인합니다.

```sql
SHOW REPLICA STATUS\G
```

예전 버전에서는 다음 명령을 사용합니다.

```sql
SHOW SLAVE STATUS\G
```

중요하게 보는 값은 다음입니다.

```
Seconds_Behind_Source
```

예전 명칭으로는 다음입니다.

```
Seconds_Behind_Master
```

이 값이 커지면 Replica가 Primary를 따라가지 못하고 있다는 뜻입니다.

---

## 운영 구성 예시

### 소규모 서비스

소규모 서비스에서는 다음 정도로 시작할 수 있습니다.

```
Primary 1대
Read Replica 1대
```

```
Application
   |
   |-- CUD, 중요 SELECT --> Primary
   |
   |-- 일반 SELECT ------> Replica
```

이 구조만으로도 Primary의 조회 부하를 상당히 줄일 수 있습니다.

---

### 중규모 서비스

트래픽이 늘면 Replica를 여러 대로 늘립니다.

```
Primary 1대
Read Replica 2~3대
```

```
Application
   |
   |-- CUD --> Primary
   |-- SELECT --> Replica 1
   |-- SELECT --> Replica 2
   |-- SELECT --> Replica 3
```

이때 애플리케이션 또는 DB Proxy에서 Replica 간 로드밸런싱을 해야 합니다.

---

### 대규모 서비스

대규모에서는 단순 Read Replica 외에도 다음이 필요해질 수 있습니다.

| 구성 | 목적 |
| --- | --- |
| Read Replica 여러 대 | 조회 분산 |
| ProxySQL | 쿼리 라우팅 |
| Connection Pool 분리 | Writer/Reader 풀 관리 |
| Sharding | 쓰기 병목 해결 |
| Cache | 반복 조회 감소 |
| CQRS | 읽기 모델과 쓰기 모델 분리 |
| Search Engine | 검색 부하 분리 |

Read Replica는 읽기 확장의 시작점이지만, 모든 DB 확장 문제를 해결하지는 않습니다.

특히 쓰기 트래픽이 커지면 Sharding, Partitioning, Queue, Cache 같은 추가 전략이 필요해질 수 있습니다.

---

## 클라우드 환경에서의 구성

### AWS RDS

AWS RDS for MySQL에서는 Read Replica를 생성할 수 있습니다.

구성은 보통 다음과 같습니다.

```
RDS Primary Instance
   |
   v
RDS Read Replica
```

애플리케이션에서는 Writer Endpoint와 Reader Endpoint를 분리해서 사용합니다.

```
writer endpoint -> CUD
reader endpoint -> SELECT
```

Aurora MySQL을 사용하면 Cluster Endpoint와 Reader Endpoint 개념이 더 명확합니다.

```
Cluster Endpoint -> Writer
Reader Endpoint  -> Reader replicas
```

---

### NCP Cloud DB for MySQL

NCP Cloud DB for MySQL에서도 읽기 부하 분산을 위해 Read Replica 구성을 사용할 수 있습니다.

개념은 동일합니다.

```
Primary DB
   |
   v
Read Replica DB
```

애플리케이션에서는 다음처럼 분리합니다.

```
CUD 요청  -> Primary DB 접속 정보
Read 요청 -> Read Replica 접속 정보
```

NCP 환경에서는 ACG, Subnet, Private Domain, DB 접근 권한, 애플리케이션 서버의 네트워크 위치까지 함께 확인해야 합니다.

---

## 실무 체크리스트

### DB 구성

| 항목 | 확인 |
| --- | --- |
| Primary DB 생성 | CUD 처리 |
| Read Replica 생성 | SELECT 처리 |
| binlog 활성화 | 복제 기반 |
| Replica 상태 확인 | 복제 정상 여부 |
| Replica Lag 모니터링 | 지연 감지 |
| 백업 정책 | 장애 복구 |
| 장애 조치 정책 | Primary 장애 대응 |

---

### 애플리케이션 구성

| 항목 | 확인 |
| --- | --- |
| Writer DataSource | Primary 연결 |
| Reader DataSource | Replica 연결 |
| RoutingDataSource | readOnly 기준 분기 |
| Connection Pool 분리 | Writer/Reader 각각 관리 |
| 트랜잭션 readOnly 설정 | 조회 서비스에 적용 |
| 중요 조회 Primary 처리 | 정합성 확보 |
| 쓰기 직후 Primary 조회 | 복제 지연 대응 |

---

### 운영 모니터링

| 항목 | 설명 |
| --- | --- |
| Primary CPU | 쓰기 병목 확인 |
| Replica CPU | 조회 부하 확인 |
| Connection 수 | 커넥션 고갈 방지 |
| Slow Query | 느린 조회 개선 |
| Replication Lag | 복제 지연 확인 |
| Disk I/O | DB 성능 병목 확인 |
| Error Log | 복제 오류 확인 |

---

## 주의할 점

### SELECT라고 무조건 Replica로 보내면 안 됨

모든 SELECT를 Replica로 보내는 것은 위험합니다.

다음처럼 최신 데이터가 중요한 SELECT는 Primary를 사용해야 합니다.

```
내가 방금 쓴 글 조회
결제 직후 주문 상태 조회
권한 변경 직후 권한 확인
재고 차감 직후 재고 조회
```

Replica는 "약간 늦어도 되는 조회"에 적합합니다.

---

### Read Replica는 쓰기 확장이 아님

Read Replica는 읽기 성능을 확장하는 구조입니다.

쓰기 작업은 여전히 Primary에 집중됩니다.

```
INSERT
UPDATE
DELETE
```

이 작업들이 병목이라면 Read Replica만으로 해결되지 않습니다.

쓰기 병목은 다음 전략을 함께 검토해야 합니다.

```
쿼리 최적화
인덱스 개선
배치 처리
Queue 도입
Sharding
Partitioning
Cache
```

---

### Connection Pool을 분리해야 함

Writer와 Reader는 커넥션 풀을 따로 관리하는 것이 좋습니다.

```
writerPool: Primary용
readerPool: Replica용
```

그래야 Reader 쿼리가 많아져도 Writer 커넥션을 고갈시키지 않습니다.

---

## 권장 구성

일반적인 Spring Boot + MySQL 서비스라면 다음 구성을 추천합니다.

```
1. Primary DB 1대
2. Read Replica 1대 이상
3. Writer DataSource 구성
4. Reader DataSource 구성
5. AbstractRoutingDataSource로 readOnly 분기
6. LazyConnectionDataSourceProxy 적용
7. @Transactional(readOnly = true) 적극 사용
8. 쓰기 직후 조회는 Primary 강제
9. Replica Lag 모니터링
```

구조는 다음과 같습니다.

```
Controller
   |
Service
   |
   |-- @Transactional
   |       -> Writer DB
   |
   |-- @Transactional(readOnly = true)
           -> Reader DB
```

---

## 전체 요약

MySQL CUD/Read 레플리카 구성은 "쓰기 작업은 Primary DB", "조회 작업은 Read Replica DB"로 분리하는 구조입니다.

이 구조의 핵심 목적은 조회 부하를 분산하고 Primary DB를 안정적으로 보호하는 것입니다.

다만 Read Replica는 Primary 데이터를 약간 늦게 따라갈 수 있기 때문에, 쓰기 직후 조회나 정합성이 중요한 조회는 Primary로 보내야 합니다.

Spring Boot에서는 보통 `@Transactional(readOnly = true)`와 `AbstractRoutingDataSource`, `LazyConnectionDataSourceProxy`를 조합해서 구현합니다.

결론적으로 Read Replica는 읽기 확장에는 효과적이지만, 쓰기 병목 해결책은 아니며 복제 지연과 트랜잭션 정합성까지 함께 고려해야 합니다.