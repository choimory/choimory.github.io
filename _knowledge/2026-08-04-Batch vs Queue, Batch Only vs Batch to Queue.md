---
title: "Batch vs Queue, Batch Only vs Batch to Queue"
date: 2026-08-04T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Batch
    - Queue
---

# Batch vs Queue

## 개요

Batch와 Queue는 데이터를 처리하는 두 가지 핵심 패러다임입니다. 이 둘은 종종 혼동되거나 함께 사용되지만, 근본적으로 다른 개념입니다. Batch는 "어떻게 처리할 것인가"에 대한 처리 방식이고, Queue는 "어떻게 작업을 전달하고 대기시킬 것인가"에 대한 데이터 구조 및 통신 메커니즘입니다.

---

## Batch (배치 처리)

### 개념

Batch 처리는 작업(Job)을 하나씩 즉시 처리하는 것이 아니라, 일정량 또는 일정 시간 동안 모아서 한꺼번에 처리하는 방식입니다.

핵심 특성은 "지연된 일괄 처리"입니다. 결과가 즉시 필요하지 않은 작업, 대량 데이터 처리에 적합합니다.

### 처리 트리거 방식

#### 시간 기반 (Time-based)

특정 시각 또는 주기에 실행됩니다.

```
매일 새벽 2시에 전날 주문 정산 실행
→ 24시간치 데이터를 한 번에 처리
```

#### 크기 기반 (Size-based)

데이터가 일정 건수나 용량에 도달하면 실행됩니다.

```
로그가 10,000건 쌓이면 → 분석 배치 실행
```

#### 이벤트 기반 (Event-based)

특정 조건이 만족될 때 실행됩니다.

```
파일 업로드 완료 → 이미지 리사이징 배치 실행
```

### 장단점

| 구분 | 내용 |
| --- | --- |
| ✅ 장점 | 자원 효율성 (DB I/O를 묶어서 처리), 단순한 재처리 로직 |
| ✅ 장점 | 시스템 부하 분산 (피크 타임 회피) |
| ❌ 단점 | 실시간성 없음 (결과가 늦게 반영됨) |
| ❌ 단점 | 실패 시 전체 재처리 비용 발생 가능 |

### Spring Batch 핵심 구조

Spring Batch는 "Job → Step → (Reader → Processor → Writer)" 구조를 따릅니다.

```kotlin
@Configuration
class OrderSettlementJobConfig(
    private val jobRepository: JobRepository,
    private val transactionManager: PlatformTransactionManager,
    private val dataSource: DataSource
) {

    @Bean
    fun orderSettlementJob(orderSettlementStep: Step): Job =
        JobBuilder("orderSettlementJob", jobRepository)
            .start(orderSettlementStep)
            .build()

    @Bean
    fun orderSettlementStep(
        reader: ItemReader<Order>,
        processor: ItemProcessor<Order, Settlement>,
        writer: ItemWriter<Settlement>
    ): Step =
        StepBuilder("orderSettlementStep", jobRepository)
            .chunk<Order, Settlement>(1000, transactionManager) // 1000건씩 청크 처리
            .reader(reader)
            .processor(processor)
            .writer(writer)
            .build()

    @Bean
    fun orderReader(): JdbcCursorItemReader<Order> =
        JdbcCursorItemReaderBuilder<Order>()
            .name("orderReader")
            .dataSource(dataSource)
            .sql("SELECT * FROM orders WHERE status = 'COMPLETED' AND settled = false")
            .rowMapper { rs, _ ->
                Order(id = rs.getLong("id"), amount = rs.getBigDecimal("amount"))
            }
            .build()
}
```

청크(Chunk) 방식의 핵심은, 1000건을 읽고 → 처리하고 → 쓰는 단위를 하나의 트랜잭션으로 묶는다는 것입니다. 전체를 메모리에 올리지 않아 OOM 위험이 없습니다.

---

## Queue (큐)

### 개념

Queue는 "FIFO (First In, First Out)" 원칙을 따르는 자료구조이자, 분산 시스템에서 생산자(Producer)와 소비자(Consumer) 사이의 비동기 통신 채널입니다.

Queue의 핵심 역할은 세 가지입니다.

- "디커플링(Decoupling)": 생산자와 소비자가 서로를 몰라도 됩니다
- "버퍼링(Buffering)": 소비자가 느려도 메시지가 유실되지 않습니다
- "부하 평준화(Load Leveling)": 트래픽 스파이크를 흡수합니다

### Queue의 종류

#### Simple Queue (단순 큐)

메시지를 순서대로 하나씩 전달합니다. 대표적으로 Redis List, SQS Standard가 있습니다.

```
Producer → [msg5, msg4, msg3, msg2, msg1] → Consumer
```

#### Topic / Pub-Sub

하나의 메시지를 여러 소비자에게 동시에 전달합니다. 대표적으로 Kafka Topic, SNS가 있습니다.

```
Producer → Topic → Consumer A
                  → Consumer B
                  → Consumer C
```

#### Priority Queue

우선순위에 따라 처리 순서가 달라집니다. 대표적으로 RabbitMQ Priority Queue가 있습니다.

### Kafka 기반 Queue 예시 (Kotlin + Spring Boot)

```kotlin
// Producer
@Service
class NotificationProducer(private val kafkaTemplate: KafkaTemplate<String, NotificationEvent>) {

    fun send(event: NotificationEvent) {
        kafkaTemplate.send("notification.send", event.userId, event)
            .whenComplete { result, ex ->
                if (ex != null) log.error("메시지 전송 실패: ${event.userId}", ex)
                else log.info("메시지 전송 성공: offset=${result.recordMetadata.offset()}")
            }
    }
}

// Consumer
@Component
class NotificationConsumer {

    @KafkaListener(topics = ["notification.send"], groupId = "notification-group")
    fun consume(event: NotificationEvent, ack: Acknowledgment) {
        try {
            emailService.send(event)
            ack.acknowledge() // 처리 완료 후 명시적 커밋
        } catch (e: Exception) {
            log.error("처리 실패, DLQ로 이동 예정", e)
            throw e // 재시도 or DLQ 전송
        }
    }
}
```

### 장단점

| 구분 | 내용 |
| --- | --- |
| ✅ 장점 | 서비스 간 느슨한 결합 (Decoupling) |
| ✅ 장점 | 실패 내성 (메시지 보존, 재처리 가능) |
| ✅ 장점 | 트래픽 버퍼링 |
| ❌ 단점 | 인프라 복잡도 증가 (Kafka, RabbitMQ 운영 필요) |
| ❌ 단점 | 메시지 순서 보장이 까다로울 수 있음 |
| ❌ 단점 | 중복 처리(At-least-once) 고려 필요 |

---

## Batch vs Queue 비교

### 핵심 차이

| 구분 | Batch | Queue |
| --- | --- | --- |
| 처리 시점 | 모아서 나중에 | 도착하는 대로 (비동기) |
| 실시간성 | ❌ 없음 | ✅ 있음 (거의 실시간) |
| 주요 역할 | 대량 데이터 일괄 처리 | 서비스 간 메시지 전달 |
| 인프라 | Scheduler (Cron, Quartz) | Message Broker (Kafka, RabbitMQ) |
| 실패 처리 | Step 단위 재시작 | DLQ, 재시도 |
| 사용 예 | 정산, 리포트, 마이그레이션 | 알림, 이벤트 전파, 주문 처리 |

### 함께 사용하는 패턴

Batch와 Queue는 서로 대체재가 아니라 보완재입니다. 실무에서는 자주 함께 쓰입니다.

```
[패턴 1] Queue → Batch
대량 주문 이벤트가 Kafka에 쌓이면
→ 새벽에 배치가 Kafka에서 읽어 정산 처리

[패턴 2] Batch → Queue
정산 배치가 완료되면
→ 결과를 Kafka에 발행 → 알림 서비스가 소비

[패턴 3] Micro-batch
Kafka Consumer가 메시지를 일정 건수만큼 모아서
→ 한 번에 DB에 Bulk Insert (Queue + Batch 혼합)
```

### 선택 기준

```
즉시 처리가 필요한가?
  → Yes: Queue 사용
  → No: Batch로 충분

데이터 양이 매우 많고 주기적인가?
  → Yes: Batch 적합

서비스 간 이벤트를 전달해야 하는가?
  → Yes: Queue 필수

두 조건 모두 해당하는가?
  → Queue + Batch 함께 설계
```

---

## 요약

- "Batch"는 데이터를 모아서 한꺼번에 처리하는 방식으로, 실시간성보다 효율성이 중요한 정산·리포트·마이그레이션 작업에 적합합니다.
- "Queue"는 Producer와 Consumer 사이의 비동기 메시지 채널로, 서비스 디커플링과 트래픽 버퍼링이 목적입니다.
- 둘은 대체 관계가 아니며, "Queue → Batch" 또는 "Batch → Queue" 형태로 조합하는 패턴이 실무에서 매우 흔합니다.
- Spring Boot 환경에서는 Spring Batch(배치)와 Spring Kafka / Spring AMQP(큐)를 조합해 사용하는 것이 일반적입니다.

---

# Batch Only vs Batch → Queue

## 개요

"Batch Only"는 배치 작업이 처리부터 후속 작업까지 모두 직접 수행하는 방식이고, "Batch → Queue"는 배치가 처리 결과를 Queue에 발행하고 후속 작업은 별도 Consumer가 담당하는 방식입니다.

두 방식의 차이는 단순히 기술 선택의 문제가 아니라, "책임의 경계를 어디에 둘 것인가"의 아키텍처 설계 문제입니다.

---

## Batch Only 방식

### 개념

배치 Job이 데이터 읽기 → 처리 → 후속 작업(알림, 외부 API 호출, 상태 업데이트 등)까지 모두 직접 수행합니다.

```
[Batch Job]
  Reader → Processor → Writer
                         ↓
               (직접) 이메일 발송
               (직접) 푸시 알림
               (직접) 외부 API 호출
               (직접) 다른 테이블 업데이트
```

### 동작 예시: 정산 후 알림 발송

```kotlin
@Component
class SettlementItemWriter(
    private val settlementRepository: SettlementRepository,
    private val emailService: EmailService,
    private val pushService: PushService,
    private val slackService: SlackService
) : ItemWriter<Settlement> {

    override fun write(chunk: Chunk<out Settlement>) {
        settlementRepository.saveAll(chunk.items)

        chunk.items.forEach { settlement ->
            emailService.sendSettlementComplete(settlement)
            pushService.sendPush(settlement.userId)
            slackService.notify(settlement)
        }
    }
}
```

### 문제점 분석

#### 단일 실패가 전체에 영향

```
1000건 처리 중 700번째 이메일 발송 실패
→ Writer 예외 발생
→ 청크(Chunk) 전체 롤백
→ 700건 정산 데이터도 함께 롤백
→ 재시작 시 700건 재처리
```

정산(DB 저장)과 알림(이메일)은 성격이 다른 작업인데, 하나의 트랜잭션 경계 안에 묶여 있어 서로 영향을 줍니다.

#### 외부 시스템 장애가 배치를 멈춤

```
이메일 서버 일시 장애 (30분)
→ 배치 전체가 30분간 블로킹 or 실패
→ 정산이라는 핵심 작업도 함께 중단
```

#### 속도 병목

```
청크 1000건 처리 시
→ DB Write: 0.1초
→ 이메일 1건당 평균 0.05초 × 1000건 = 50초
→ 청크 처리 시간이 50배 증가
```

#### 배치가 모든 후속 도메인을 알아야 함

배치 Job이 이메일, 푸시, Slack, 외부 API 등 모든 후속 시스템에 직접 의존하게 됩니다. 새로운 후속 작업이 추가될 때마다 배치 코드를 수정해야 합니다.

### 적합한 상황

Batch Only가 나쁜 것은 아닙니다. 아래 조건에서는 오히려 단순하고 적합합니다.

- 후속 작업이 없거나 단순 DB 저장만 하는 경우
- 외부 시스템 호출이 전혀 없는 경우
- 규모가 작고 실패 허용 범위가 넓은 경우
- 팀 규모가 작아 인프라 복잡도를 줄여야 하는 경우

---

## Batch → Queue 방식

### 개념

배치 Job은 "핵심 처리(정산, 집계 등)"만 담당하고, 결과를 Queue(Kafka, RabbitMQ 등)에 발행합니다. 후속 작업(알림, 외부 연동 등)은 별도 Consumer 서비스가 독립적으로 처리합니다.

```
[Batch Job]
  Reader → Processor → Writer
                         ↓
               Queue에 이벤트 발행
               (정산완료 이벤트)

[Consumer A] 이메일 서비스 → 이메일 발송
[Consumer B] 푸시 서비스  → 푸시 알림
[Consumer C] Slack 서비스 → Slack 알림
```

### 동작 예시: 정산 후 이벤트 발행

```kotlin
data class SettlementCompletedEvent(
    val settlementId: Long,
    val userId: String,
    val amount: BigDecimal,
    val completedAt: LocalDateTime
)

@Component
class SettlementItemWriter(
    private val settlementRepository: SettlementRepository,
    private val kafkaTemplate: KafkaTemplate<String, SettlementCompletedEvent>
) : ItemWriter<Settlement> {

    override fun write(chunk: Chunk<out Settlement>) {
        val saved = settlementRepository.saveAll(chunk.items)

        saved.forEach { settlement ->
            val event = SettlementCompletedEvent(
                settlementId = settlement.id,
                userId = settlement.userId,
                amount = settlement.amount,
                completedAt = LocalDateTime.now()
            )
            kafkaTemplate.send("settlement.completed", settlement.userId, event)
        }
    }
}
```

```kotlin
// Consumer A: 이메일 서비스
@Component
class SettlementEmailConsumer(private val emailService: EmailService) {

    @KafkaListener(topics = ["settlement.completed"], groupId = "email-group")
    fun handleSettlementCompleted(event: SettlementCompletedEvent, ack: Acknowledgment) {
        try {
            emailService.sendSettlementComplete(event.userId, event.amount)
            ack.acknowledge()
        } catch (e: Exception) {
            log.error("이메일 발송 실패: userId=${event.userId}", e)
            throw e
        }
    }
}

// Consumer B: 푸시 서비스
@Component
class SettlementPushConsumer(private val pushService: PushService) {

    @KafkaListener(topics = ["settlement.completed"], groupId = "push-group")
    fun handleSettlementCompleted(event: SettlementCompletedEvent, ack: Acknowledgment) {
        pushService.sendPush(event.userId, "정산이 완료되었습니다.")
        ack.acknowledge()
    }
}
```

### 개선되는 점

#### 관심사 분리 (Separation of Concerns)

```
Batch Job의 책임: 정산 계산 + 이벤트 발행
Consumer의 책임: 각자의 후속 작업

→ 새로운 후속 작업 추가 시, 배치 코드 수정 없이
  새 Consumer만 추가하면 됨 (OCP 원칙)
```

#### 장애 격리 (Fault Isolation)

```
이메일 서버 장애 발생
→ 이메일 Consumer만 실패
→ 배치 Job은 정상 완료
→ 푸시 Consumer도 정상 동작
→ 이메일 메시지는 Kafka에 보존 → 서버 복구 후 재처리
```

#### 처리 속도 향상

```
Batch Only:
  청크 1000건 × (DB Write + 이메일 0.05초 + 푸시 0.03초) = 매우 느림

Batch → Queue:
  청크 1000건 × (DB Write + Kafka Produce ~1ms) = 빠름
  후속 처리는 Consumer가 병렬로 비동기 처리
```

#### 독립적 스케일링

```
알림 발송이 느려질 경우
→ Consumer 인스턴스만 수평 확장
→ 배치 Job은 그대로 유지
```

### 주의할 점

#### 이벤트 발행과 DB 저장의 정합성

```
정산 DB 저장 성공
→ Kafka 발행 실패
→ 이메일이 영영 발송되지 않음
```

이 문제는 "Outbox Pattern"으로 해결합니다. DB 저장과 이벤트 발행을 같은 트랜잭션으로 묶는 대신, 이벤트를 DB의 Outbox 테이블에 함께 저장하고 별도 프로세스가 Kafka에 발행합니다.

```kotlin
@Transactional
fun write(chunk: Chunk<out Settlement>) {
    val saved = settlementRepository.saveAll(chunk.items)

    val outboxEvents = saved.map { settlement ->
        OutboxEvent(
            aggregateId = settlement.id.toString(),
            eventType = "SettlementCompleted",
            payload = objectMapper.writeValueAsString(
                SettlementCompletedEvent(settlement.id, settlement.userId, settlement.amount)
            )
        )
    }
    outboxRepository.saveAll(outboxEvents)
}
```

#### 메시지 중복 처리 (At-least-once)

Kafka는 기본적으로 "최소 1회 전달"을 보장하므로, Consumer는 멱등성(Idempotency)을 보장해야 합니다.

```kotlin
@KafkaListener(topics = ["settlement.completed"], groupId = "email-group")
fun handle(event: SettlementCompletedEvent, ack: Acknowledgment) {
    if (emailSendHistoryRepository.exists(event.settlementId)) {
        ack.acknowledge()
        return
    }
    emailService.send(event)
    emailSendHistoryRepository.save(event.settlementId)
    ack.acknowledge()
}
```

---

## 두 방식 비교 요약

| 구분 | Batch Only | Batch → Queue |
| --- | --- | --- |
| 구조 복잡도 | 낮음 | 높음 (Broker 필요) |
| 책임 분리 | ❌ 배치가 모두 담당 | ✅ 역할별 분리 |
| 장애 격리 | ❌ 외부 장애가 배치 중단 | ✅ 후속 장애가 배치에 무영향 |
| 처리 속도 | 느림 (동기 처리) | 빠름 (비동기 분리) |
| 확장성 | 배치 전체 스케일링 | Consumer 단위 스케일링 |
| 재처리 | 배치 재실행 | Consumer DLQ 재처리 |
| 정합성 관리 | 단순 (단일 트랜잭션) | 복잡 (Outbox Pattern 필요) |
| 적합한 규모 | 소규모, 단순 후속 작업 | 중대규모, 다양한 후속 작업 |

### 선택 기준

```
후속 작업이 외부 시스템 호출을 포함하는가?
  → Yes: Batch → Queue 고려

후속 작업의 종류가 앞으로 늘어날 가능성이 있는가?
  → Yes: Batch → Queue (OCP 확보)

팀이 Kafka 등 Broker 운영 여건이 되는가?
  → No: Batch Only로 시작, 이후 전환

배치 처리 속도가 병목인가?
  → Yes: Batch → Queue로 비동기 분리
```

---

## 요약 (Batch Only vs Batch → Queue)

- "Batch Only"는 구조가 단순하지만, 외부 시스템 장애가 배치 전체에 전파되고 후속 작업이 늘수록 배치가 비대해지는 문제가 있습니다.
- "Batch → Queue"는 배치가 핵심 처리에만 집중하고, 후속 작업은 Consumer가 독립적으로 처리하여 장애 격리, 속도, 확장성 모두 개선됩니다.
- 단, Batch → Queue는 Outbox Pattern과 멱등성 처리를 함께 설계해야 정합성을 보장할 수 있습니다.
- 소규모 시스템에서는 Batch Only로 시작하고, 후속 작업 종류와 규모가 커질 때 Queue를 도입하는 점진적 전환 전략이 현실적입니다.