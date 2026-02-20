---
title: "이벤트 기반 아키텍처 Event-driven Architecture, EDA"
date: 2025-09-01T00:00:00
toc: true
toc_sticky: true
categories:
    - 
tags:
    - 
---

# Intro

Kafka를 이용한 Event-Driven Architecture 구성에서의 API 예시 코드는 아래와 같은 흐름으로 구성됨:

1. **Producer (API 서버)**: 이벤트 발생 시 Kafka로 메시지 전송
2. **Kafka Broker**: 이벤트를 중개
3. **Consumer (Worker 서비스)**: Kafka로부터 메시지 수신 및 처리

---

# Nest.js

### 1. Kafka 설정 (공통)

```tsx
// kafka.config.ts
import { KafkaOptions, Transport } from '@nestjs/microservices'

export const kafkaConfig: KafkaOptions = {
  transport: Transport.KAFKA,
  options: {
    client: {
      clientId: 'api-service',
      brokers: ['localhost:9092'],
    },
    consumer: {
      groupId: 'api-consumer-group',
    },
  },
}
```

### 2. Producer: API 서버에서 Kafka로 이벤트 전송

```tsx
// app.module.ts
import { Module } from '@nestjs/common'
import { ClientsModule, Transport } from '@nestjs/microservices'
import { AppController } from './app.controller'

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'KAFKA_SERVICE',
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: 'api-service',
            brokers: ['localhost:9092'],
          },
          producerOnlyMode: true,
        },
      },
    ]),
  ],
  controllers: [AppController],
})
export class AppModule {}
```

```tsx
// app.controller.ts
import { Controller, Post, Body, Inject } from '@nestjs/common'
import { ClientKafka } from '@nestjs/microservices'

@Controller('orders')
export class AppController {
  constructor(@Inject('KAFKA_SERVICE') private readonly kafkaClient: ClientKafka) {}

  @Post()
  async createOrder(@Body() data: any) {
    await this.kafkaClient.emit('order.created', {
      orderId: data.id,
      userId: data.userId,
      total: data.total,
    })
    return { message: 'Order event published' }
  }
}
```

### 3. Consumer: Kafka에서 이벤트 수신

```tsx
// worker.module.ts
import { Module } from '@nestjs/common'
import { WorkerService } from './worker.service'
import { kafkaConfig } from './kafka.config'

@Module({
  providers: [WorkerService],
})
export class WorkerModule {}
```

```tsx
// main.ts (Worker Entry Point)
import { NestFactory } from '@nestjs/core'
import { MicroserviceOptions } from '@nestjs/microservices'
import { WorkerModule } from './worker.module'
import { kafkaConfig } from './kafka.config'

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(WorkerModule, kafkaConfig)
  await app.listen()
}
bootstrap()
```

```tsx
// worker.service.ts
import { Injectable } from '@nestjs/common'
import { MessagePattern, Payload } from '@nestjs/microservices'

@Injectable()
export class WorkerService {
  @MessagePattern('order.created')
  handleOrderCreated(@Payload() message: any) {
    console.log('Received order event:', message.value)
    // 주문 처리 로직
  }
}
```

---

# Java

### 구성 요소

1. **Producer**: REST API 호출 시 Kafka로 이벤트 전송
2. **Consumer**: Kafka에서 이벤트 수신 후 처리

---

### 1. 의존성 추가 (`build.gradle` 또는 `pom.xml`)

**Gradle**

```groovy
implementation 'org.springframework.boot:spring-boot-starter-web'
implementation 'org.springframework.kafka:spring-kafka'
```

**Maven**

```xml
<dependency>
  <groupId>org.springframework.kafka</groupId>
  <artifactId>spring-kafka</artifactId>
</dependency>
```

---

### 2. Kafka 설정

```yaml
# application.yml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    consumer:
      group-id: order-consumer-group
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
```

---

### 3. Producer 예제 (API → Kafka)

```java
// OrderEventProducer.java
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class OrderEventProducer {
    private final KafkaTemplate<String, String> kafkaTemplate;

    public OrderEventProducer(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void sendOrderCreatedEvent(String orderJson) {
        kafkaTemplate.send("order.created", orderJson);
    }
}
```

```java
// OrderController.java
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/orders")
public class OrderController {
    private final OrderEventProducer producer;

    public OrderController(OrderEventProducer producer) {
        this.producer = producer;
    }

    @PostMapping
    public String createOrder(@RequestBody String order) {
        producer.sendOrderCreatedEvent(order);
        return "Order event sent";
    }
}
```

---

### 4. Consumer 예제 (Kafka → 처리)

```java
// OrderEventConsumer.java
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class OrderEventConsumer {
    @KafkaListener(topics = "order.created", groupId = "order-consumer-group")
    public void handleOrderCreated(String message) {
        System.out.println("Received order event: " + message);
        // 주문 처리 로직
    }
}
```

### 요약 흐름

1. 클라이언트가 `/orders` API 요청
2. API 서버가 `order.created` 이벤트 Kafka에 emit
3. Consumer(Worker)가 해당 이벤트를 수신하고 처리

---

# 동작 흐름

Spring Kafka에서는 메시지가 Kafka에 올라가면 `@KafkaListener`가 붙은 메소드가 자동으로 호출

NestJS에서 작성한 Kafka consumer (`@MessagePattern`)도 메시지가 Kafka에 올라가면 자동으로 호출(Spring의 @KafkaListener와 개념적으로 동일)

### Java

1. `KafkaTemplate.send(...)` → Kafka topic (`order.created`)에 메시지 전송
2. Kafka는 해당 topic에 메시지를 브로드캐스트
3. `@KafkaListener(topics = "order.created", ...)`가 설정된 메서드가 자동으로 메시지를 구독
4. 메시지가 도착하면 메서드가 **자동 실행**

```java
@KafkaListener(topics = "order.created", groupId = "order-consumer-group")
public void handleOrderCreated(String message) {
    System.out.println("Received order event: " + message);
    // 여기 로직이 자동으로 실행됨
}
```

- Spring이 내부적으로 Kafka consumer client를 관리하면서, 지정한 topic의 메시지를 백그라운드에서 listen 하고 있다가 이벤트가 오면 바로 실행시켜줌
- 추가로 자동 호출이 잘 되려면
    - Kafka가 정상 구동 중이어야 하고
    - 해당 topic이 존재해야 하며 (Kafka가 자동 생성하도록 설정되어 있지 않다면 미리 만들어야 함)
    - Consumer group id가 충돌되지 않도록 관리되어야 함

### Nest.js

1. `kafkaClient.emit('order.created', {...})` → Kafka topic에 메시지 전송
2. NestJS microservice (`@MessagePattern('order.created')`)가 해당 topic을 구독 중
3. 메시지가 오면 해당 메서드가 **자동 호출**

```tsx
@Injectable()
export class WorkerService {
  @MessagePattern('order.created')
  handleOrderCreated(@Payload() message: any) {
    console.log('Received order event:', message.value)
    // 이 부분이 메시지 도착 시 자동 실행됨
  }
}
```

---

# 동작 조건 정리

1. `main.ts`에서 `NestFactory.createMicroservice(...)`로 microservice를 실행 중이어야 하고
2. topic 이름 (`order.created`)이 일치해야 하며
3. Kafka broker가 정상 연결되어 있어야 함
- 추가로, NestJS는 `@EventPattern`도 있는데, `@MessagePattern`과의 차이는 **RPC 응답 여부**임.
    - `@MessagePattern`: 요청-응답 (기본적으로 메시지를 return 함)
    - `@EventPattern`: fire-and-forget (응답 없음, 단순 이벤트 처리용)
- `emit()`은 `@EventPattern`이 더 맞긴 한데, 둘 다 메시지를 받을 수 있어서 예시에서는 `@MessagePattern` 사용

---

# 컨트롤러 엔드포인트의 역할

**컨트롤러의 엔드포인트는 Kafka 이벤트를 트리거하는 진입점 역할**

## 구조적으로 보면

### **Controller 엔드포인트**

→ 클라이언트의 요청(HTTP)을 받음

→ Kafka에 메시지를 **publish (emit)**

→ 본인은 아무 처리 안 하고 응답만 반환 (예: 200 OK)

### **Consumer (`@MessagePattern`)**

→ Kafka로부터 메시지 수신

→ 실제 **비즈니스 로직 처리**

### 예시

```tsx
// 1. Controller
@Post()
createOrder(@Body() data: any) {
  kafkaClient.emit('order.created', data)
  return { message: 'Event published' }
}

// 2. Consumer
@MessagePattern('order.created')
handleOrderCreated(@Payload() message: any) {
  // 여기서 실제 주문 처리
}
```

## 왜 이렇게 분리하는가

- **비동기 처리** 구조 → API는 빠르게 응답하고, 무거운 작업은 백그라운드에서 처리
- **서비스 간 결합도 낮추기** → 여러 서비스가 같은 Kafka 이벤트를 소비 가능 (ex. 주문 이벤트 → 배송 서비스, 알림 서비스 등)
- **확장성 / 재시도 / 로그 추적 등에서 유리**

---

## 컨트롤러 엔드포인트 결론

- **컨트롤러는 트리거만 담당**, 실제 처리는 이벤트 수신 쪽에서 맡는 구조
- 원하면 REST 없이 바로 Kafka만 소비하는 구조도 만들 수 있음

---

# 회원조회 API가 있다면 엔드 포인트는 받아서 Produce만 하고 비즈니스 로직은 Consumer가 담당하는가

- **회원조회 API 같은 *즉각적인 응답이 필요한 경우에는* Kafka를 굳이 거치지 않고, 엔드포인트에서 직접 처리**

## 이유는

- Kafka 기반 구조는 **비동기이므로** 메시지를 보내면 → Kafka에 들어감 → Consumer가 언제 처리할지 모름
- 그래서 `조회`같이 **바로 결과가 필요한 작업**에는 **안 맞는다**

## 그럼 Kafka는 언제 쓰는가

- **회원가입**, **주문생성**, **결제완료** 등 → 요청을 받고 "처리 요청"만 Kafka로 넘기고, 실제 DB 저장/후속 처리는 백그라운드에서

```
POST /orders → emit 'order.created' → 바로 응답 (202 Accepted)
               → worker가 DB 저장하고 알림도 보내고 로깅도 하고
```

## 반대로 조회 API는?

- `GET /users/:id`
    
    → Kafka 안 씀
    
    → 그냥 컨트롤러에서 서비스 호출해서 DB 조회하고 응답
    
    → 빠르고 동기적인 응답이 중요하니까
    

## 요약

| 작업 종류 | Kafka 사용 | 컨트롤러 역할 | 비즈니스 로직 위치 |
| --- | --- | --- | --- |
| 회원조회 | X | 직접 서비스 호출 | 컨트롤러 또는 서비스 |
| 회원가입 | O | Kafka에 이벤트 emit | Consumer (회원 DB 저장 등) |
| 주문생성 | O | Kafka에 이벤트 emit | Consumer (주문 처리 등) |
| 알림 발송 | O | Kafka 이벤트에 따라 동작 | Consumer (알림 처리) |
- **즉각 응답이 필요한 "조회/검색" → 동기 (Kafka X)**
- **처리 후속작업이 필요한 "생성/갱신/삭제" → 비동기 (Kafka O)**

---

# Item API에서 Member 조회해야 할땐 메시지 큐 안쓰고 Member API에 직접 호출하는가

- **Item API에서 Member 정보를 바로 써야 한다면, Kafka를 거치지 않고 Member API를 직접 호출하는 게 일반적**

## 이유

- Kafka는 **비동기 메시징**
- 하지만 **item에서 member를 바로 조회해야 한다면 → 동기적 HTTP 호출**이 맞음

## 시나리오 예시

**Item API**

```tsx
// item.service.ts
async getItemDetails(itemId: string) {
  const item = await this.itemRepository.findById(itemId)

  // 멤버 정보가 필요할 경우, 동기 호출 (REST or gRPC)
  const member = await this.httpService.get(`http://member-api/users/${item.memberId}`).toPromise()

  return {
    ...item,
    memberName: member.data.name,
  }
}
```

## 왜 Kafka는 안 쓰는지?

Kafka는 “이벤트 발생 → 처리”에 적합한 구조인데,

item API에서 member 정보를 **바로 응답에 포함해야 하는 상황**이면,

Kafka로 "member 정보를 줘!" 하고 보내봐야

- 응답 언제 올지 모름
- 리턴을 연결할 방법이 없음

즉, **request-response 구조가 불가능하거나 복잡해짐**

## 정리

| 상황 | 방식 | 이유 |
| --- | --- | --- |
| Item 생성 → 회원에게 알림 전송 | Kafka | 후속 작업, 비동기 |
| Item 상세 조회 중 회원 이름 필요 | HTTP 직접 호출 | 즉시 응답 필요, 동기적 |

필요하면 이런 동기 호출을 gRPC, GraphQL 등으로 구성할 수도 있음

또는 **데이터 중복 저장** 전략 (e.g. item DB에 memberName 캐싱) 도 상황에 따라 고려

---

# Member API에서 처리한 사항이 Item API에도 적용되어야할때 메시지 큐를 써서 동기화 하는가?

- Member API에서 변경된 내용을 Item API에도 반영하려면, Kafka 같은 메시지 기반 비동기 시스템으로 “동기화” 이벤트를 보내는 방식이 적합
- 단 DB 중복저장 자체가 좋은 구조는 아님

## 예시 상황

- **Member API**에서 회원 이름을 수정함 (`PUT /users/:id`)
- 그런데 **Item API**는 아이템 정보에 `memberName`을 저장하고 있어서 같이 바꿔줘야 함
    
    → 이럴 땐 Kafka로 `member.updated` 같은 이벤트를 전파
    

## 동기화 흐름 예시

1. **Member API**
    
    ```tsx
    @Put('/users/:id')
    updateUser(@Param('id') id: string, @Body() dto: UpdateUserDto) {
      // DB에서 회원 정보 수정
      await this.userService.update(id, dto)
    
      // Kafka에 이벤트 발행
      await this.kafkaClient.emit('member.updated', {
        memberId: id,
        name: dto.name,
      })
      return { message: 'Member updated' }
    }
    ```
    
2. **Item API (Consumer)**
    
    ```tsx
    @MessagePattern('member.updated')
    async handleMemberUpdate(@Payload() message: any) {
      const { memberId, name } = message.value
      // memberName이 포함된 아이템들 업데이트
      await this.itemService.updateMemberName(memberId, name)
    }
    ```
    

## 왜 이렇게 하나?

- **서비스 간 직접 호출은 의존성이 생기고 트래픽 많아질수 있음**
- Kafka 쓰면 각 서비스가 느슨하게 연결되고, 이벤트만 구독하면 되니까 확장성과 유지보수에 유리
- 여러 서비스가 이 `member.updated` 이벤트를 동시에 구독할 수도 있음 (ex. 알림 서비스, 로그 서비스 등)

## 정리

| 목적 | 방법 |
| --- | --- |
| A 서비스의 변경 사항을 B 서비스에도 반영 | Kafka로 이벤트 발행 (ex. `member.updated`) |
| A 서비스가 B 서비스의 데이터를 즉시 필요로 함 | 동기 HTTP 호출 (REST, gRPC 등) |

이거를 기반으로 멱등 처리, 중복 이벤트 방지, 실패 재처리 방식까지 넘어감

---

# Item API에서 Member API에 요청해서 정보 조회할때 Member API가 문제발생해서 오류가 전파되는 사항은 어떻게 처리하는가

- 마이크로서비스에서 흔히 겪는 **"서비스 간 의존성 문제"이다**

## 상황 설명

- `Item API`가 `Member API`에 **동기 호출**로 member 정보를 요청함
- 근데 `Member API`가 죽거나 느리거나 오류 발생
- → `Item API`도 같이 응답 못 하고 죽어버림 (Fail Cascade)

## 해결 전략들

### 1. **타임아웃 + 예외 처리**

- 호출 시간이 너무 길어지면 실패로 간주하고 fallback 처리
- 기본적인 보호 장치

```tsx
try {
  const member = await this.httpService
    .get(`http://member-api/users/${id}`, { timeout: 3000 })
    .toPromise()
  return member.data
} catch (err) {
  console.warn('Member API 오류 → 기본값 반환')
  return { name: 'Unknown Member' } // 또는 null
}
```

### 2. **Circuit Breaker (회로 차단기 패턴)**

- 일정 횟수 이상 실패하면, 일정 시간 동안 더 이상 호출하지 않고 바로 fallback
- `@nestjs/terminus` 또는 `opossum` 같은 라이브러리로 구현 가능

```tsx
// 라이브러리 따라 다름
if (circuitBreaker.isOpen()) {
  return { name: 'Unknown Member' }
}
```

### 3. **로컬 캐시 / DB에 복제 저장 (데이터 중복)**

- 조회 성능이나 안정성 중시 시, `memberName` 같은 정보를 item DB에도 같이 저장
- Member가 업데이트되면 Kafka로 이벤트(`member.updated`)를 보내 item DB도 업데이트

→ **조회는 로컬에서, 동기 호출은 없음 = 안정성 극대화**

### 4. **Fallback 서비스나 Graceful Degradation**

- Member API가 안 되면 UI에 `"정보를 불러올 수 없습니다"` 같은 메시지 표시하고 기능 일부만 제공

### 5. **Retry / 재시도 정책**

- 일시적인 문제면 1~2회 재시도 (너무 많이 하면 안 됨)
- Axios 사용 시 `axios-retry` 같은 모듈 사용 가능

## 정리

| 전략 | 언제 사용 | 장점 |
| --- | --- | --- |
| 타임아웃 + 예외 처리 | 기본 | 죽지 않음 |
| Circuit Breaker | 반복 실패 차단 | 연쇄 실패 방지 |
| 로컬 캐시 or 중복 저장 | 조회가 자주 일어남 | 안정적, 빠름 |
| Fallback 처리 | 사용자 경험 고려 | 전체 장애 방지 |
| Retry | 일시적 네트워크 문제 | 회복 가능성 증가 |

현실적으로는 **중복 저장 + 예외 처리 조합**이 가장 많이 쓰임

---

# DB 데이터가 아니라 구조가 바뀌면?

- 마이크로서비스 데이터 분리 설계에서 나오는 **핵심적인 이슈**
- **데이터 스키마의 독립성 vs 동기화 문제**

## 문제 상황 요약

- **Item 서비스가 `memberName`을 갖고 있음** → 원래는 Member 서비스 DB에 있음
- 그런데 Member 서비스가 **DB 스키마 변경** (예: `name` → `firstName + lastName`)
- 그러면 Item 서비스에 있는 복제된 `memberName`은 어떻게 업데이트할까?

## 해결 전략은 크게 3가지

### 1. **이벤트 버전 관리 (Event Versioning)**

- Kafka 이벤트 스키마를 **버전 관리**해서, 기존 구조 깨지지 않게 유지
- 예: `member.updated.v1`, `member.updated.v2` 두 개 이벤트 운영

```json
// v1
{
  "memberId": "abc123",
  "name": "홍길동"
}

// v2
{
  "memberId": "abc123",
  "firstName": "길동",
  "lastName": "홍"
}
```

→ Consumer는 버전에 따라 다른 필드를 처리하거나, 새 이벤트만 구독하도록 설계

### 2. **중간 스키마 변환 계층 추가 (Adapter Layer)**

- Member 서비스 내부에서 이벤트 발행 시,
    
    **구버전 구조로도 이벤트를 계속 만들어주는 어댑터**를 둠
    

```tsx
// member.service.ts
emit('member.updated.v1', {
  memberId,
  name: `${dto.lastName} ${dto.firstName}`,
})
emit('member.updated.v2', {
  memberId,
  firstName: dto.firstName,
  lastName: dto.lastName,
})
```

→ Item 서비스는 `v1`만 듣고 있으면 됨

### 3. **Item 서비스도 스키마 진화에 맞춰 리팩토링**

- 즉, `Item.memberName` → `Item.memberFirstName`, `Item.memberLastName` 으로 구조 변경
- 이 경우:
    - 마이그레이션 배포 필요
    - 이벤트 구조에 맞게 DB 구조도 바꿔야 함
    - Kafka 이벤트를 기준으로 마이그레이션 스크립트를 돌릴 수도 있음

## 보통은 이렇게 운영함

- **스키마 변경이 예고되면**
    - `member.updated.v2` 이벤트를 새로 만들어서 **두 이벤트 병행 발행**
    - Consumer(Item)는 기존 구조 유지하다가 여유 있을 때 새 구조로 리팩토링
    - 완료되면 `v1` 제거

## 추가 팁: Schema Registry 사용

Kafka에서 Avro or JSON Schema + Schema Registry를 쓰면

- **이벤트 구조를 명세화**하고
- 스키마 진화(변경)를 추적하고 호환성 체크 가능
    
    → 예기치 않은 스키마 깨짐 방지
    

## 정리

| 상황 | 대응 방식 |
| --- | --- |
| DB 구조 변경 | 이벤트 버전 관리 (`v1`, `v2`) |
| 구조 공존 필요 | 어댑터 계층에서 변환 |
| 구조 통일 필요 | Consumer 서비스도 구조 변경 & 마이그레이션 |
| 자동 검증 필요 | Schema Registry 도입 |

이거 제대로 안 하면 서비스 간 지옥의 연쇄 리팩토링이 생길수 있음