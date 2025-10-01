---
title: "Kotlin, Kafka, Circuit breaker를 적용한 Sender API 만들어보기"
date: 2025-10-01T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - JVM
    - Queue
    - Circuit breaker
---

# 코틀린과 JavaMailSender 이메일 전송

JavaMailSender는 스프링 프레임워크에서 제공하는 이메일 전송을 위한 추상화 인터페이스. 

내부적으로 JavaMail API를 래핑하여 더 간편하고 일관된 방식으로 이메일을 전송할 수 있게 해준다. 

SMTP 서버를 통해 다양한 형태의 이메일(텍스트, HTML, 첨부파일 포함)을 전송할 수 있으며, 비동기 처리와 템플릿 엔진 연동도 가능.

## 기본 설정

### 의존성 추가

- Spring Boot Starter Mail 의존성 필요
- `implementation 'org.springframework.boot:spring-boot-starter-mail'`
- 자동으로 JavaMailSender 빈이 등록됨

### application.properties 설정

properties

```yaml
# Gmail SMTP 설정 예시
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=your-email@gmail.com
spring.mail.password=your-app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true`
```

## 코틀린 구현

### 기본 텍스트 이메일

kotlin

```kotlin
@Service
class EmailService(
    private val mailSender: JavaMailSender
) {
    fun sendSimpleEmail(to: String, subject: String, text: String) {
        val message = SimpleMailMessage().apply {
            setTo(to)
            setSubject(subject)
            setText(text)
            setFrom("noreply@example.com")
        }
        mailSender.send(message)
    }
}
```

### HTML 이메일과 첨부파일

kotlin

```kotlin
fun sendHtmlEmail(to: String, subject: String, htmlContent: String, attachmentPath: String? = null) {
    val message = mailSender.createMimeMessage()
    val helper = MimeMessageHelper(message, true, "UTF-8")
    
    helper.setTo(to)
    helper.setSubject(subject)
    helper.setText(htmlContent, true) *// HTML 모드*
    helper.setFrom("noreply@example.com")
    
    // 첨부파일 추가
    attachmentPath?.let { path ->
        val file = FileSystemResource(path)
        helper.addAttachment(file.filename ?: "attachment", file)
    }
    
    mailSender.send(message)
}
```

### 이메일 템플릿 활용

kotlin

```kotlin
@Service
class TemplateEmailService(
    private val mailSender: JavaMailSender,
    private val templateEngine: TemplateEngine
) {
    fun sendTemplateEmail(to: String, templateName: String, variables: Map<String, Any>) {
        val context = Context().apply {
            setVariables(variables)
        }
        
        val htmlContent = templateEngine.process(templateName, context)
        
        val message = mailSender.createMimeMessage()
        val helper = MimeMessageHelper(message, true, "UTF-8")
        
        helper.setTo(to)
        helper.setSubject(variables["subject"] as String)
        helper.setText(htmlContent, true)
        helper.setFrom("noreply@example.com")
        
        mailSender.send(message)
    }
}
```

## 그외 기능

### 비동기 이메일 전송

kotlin

```kotlin
@Service
class AsyncEmailService(
    private val mailSender: JavaMailSender
) {
    @Async
    fun sendEmailAsync(to: String, subject: String, content: String): CompletableFuture<Boolean> {
        return try {
            val message = SimpleMailMessage().apply {
                setTo(to)
                setSubject(subject)
                setText(content)
            }
            mailSender.send(message)
            CompletableFuture.completedFuture(true)
        } catch (e: Exception) {
            CompletableFuture.completedFuture(false)
        }
    }
}
```

### 대량 이메일 전송

kotlin

```kotlin
fun sendBulkEmails(recipients: List<String>, subject: String, content: String) {
    val messages = recipients.map { recipient ->
        SimpleMailMessage().apply {
            setTo(recipient)
            setSubject(subject)
            setText(content)
            setFrom("noreply@example.com")
        }
    }.toTypedArray()
    
    mailSender.send(*messages)
}
```

## 예외 처리와 로깅

### 전송 실패 처리

kotlin

```kotlin
fun sendEmailWithErrorHandling(to: String, subject: String, content: String): Boolean {
    return try {
        val message = SimpleMailMessage().apply {
            setTo(to)
            setSubject(subject)
            setText(content)
        }
        mailSender.send(message)
        logger.info("Email sent successfully to: $to")
        true
    } catch (e: MailException) {
        logger.error("Failed to send email to: $to", e)
        false
    }
}
```

## 보안 고려사항

### SMTP 인증 설정

- Gmail의 경우 앱 비밀번호 사용 필수
- OAuth2 인증 방식 권장
- STARTTLS 암호화 활성화

### 환경별 설정 분리

kotlin

```kotlin
@ConfigurationProperties(prefix = "app.mail")
data class MailProperties(
    val fromAddress: String,
    val fromName: String,
    val replyToAddress: String
)
```

## 전체 요약

코틀린에서 JavaMailSender를 활용한 이메일 전송은 스프링의 추상화된 인터페이스를 통해 간단하게 구현 가능하다. 기본적인 텍스트 이메일부터 HTML 콘텐츠, 첨부파일, 템플릿 기반 이메일까지 다양한 형태를 지원함. 비동기 처리를 통한 성능 최적화와 적절한 예외 처리로 안정적인 이메일 서비스 구축 가능. SMTP 보안 설정과 환경별 설정 분리를 통해 운영 환경에서의 안전성도 확보할 수 있다.

---

# 코틀린 Kafka Consumer와 JavaMailSender 통합

Kafka는 분산 이벤트 스트리밍 플랫폼으로, 대용량의 실시간 데이터를 안정적으로 처리할 수 있는 메시징 시스템. Producer가 메시지를 토픽에 발행하면 Consumer가 이를 구독하여 처리하는 구조. 이메일 전송 시스템에서는 Kafka를 통해 이메일 요청을 비동기적으로 큐잉하고, Consumer에서 JavaMailSender로 실제 전송을 처리하여 시스템의 확장성과 안정성을 보장할 수 있음.

## 기본 설정

### 의존성 추가

gradle

```kotlin
*// build.gradle.kts*
implementation("org.springframework.kafka:spring-kafka")
implementation("org.springframework.boot:spring-boot-starter-mail")
implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
implementation("org.apache.kafka:kafka-streams")
```

### Kafka 설정

yaml

```yaml
*# application.yml*
spring:
  kafka:
    bootstrap-servers: localhost:9092
    consumer:
      group-id: email-sender-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "com.example.email.dto"
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
```

## 데이터 모델 정의

### 이메일 요청 DTO

kotlin

```kotlin
@JsonIgnoreProperties(ignoreUnknown = true)
data class EmailRequest(
    val id: String = UUID.randomUUID().toString(),
    val to: String,
    val subject: String,
    val content: String,
    val contentType: EmailContentType = EmailContentType.TEXT,
    val attachments: List<AttachmentInfo> = emptyList(),
    val priority: EmailPriority = EmailPriority.NORMAL,
    val timestamp: LocalDateTime = LocalDateTime.now()
)
```

```kotlin
enum class EmailContentType {
    TEXT, HTML
}

enum class EmailPriority {
    LOW, NORMAL, HIGH
}

data class AttachmentInfo(
    val filename: String,
    val contentType: String,
    val data: ByteArray
)
```

## Kafka Consumer 구현

### 기본 Consumer

kotlin

```kotlin
@Component
@EnableKafka
class EmailKafkaConsumer(
    private val emailService: EmailService
) {
    private val logger = LoggerFactory.getLogger(EmailKafkaConsumer::class.java)

    @KafkaListener(
        topics = ["email-requests"],
        groupId = "email-sender-group",
        containerFactory = "kafkaListenerContainerFactory"
    )
    fun consumeEmailRequest(
        @Payload emailRequest: EmailRequest,
        @Header headers: Map<String, Any>
    ) {
        try {
            logger.info("Received email request: ${emailRequest.id}")
            emailService.processEmailRequest(emailRequest)
            logger.info("Successfully processed email: ${emailRequest.id}")
        } catch (e: Exception) {
            logger.error("Failed to process email: ${emailRequest.id}", e)
            throw e *// 재시도를 위해 예외를 다시 던짐*
        }
    }
}
```

### 배치 처리 Consumer

kotlin

```kotlin
@KafkaListener(
    topics = ["email-bulk-requests"],
    groupId = "email-bulk-group",
    containerFactory = "batchKafkaListenerContainerFactory"
)
fun consumeBulkEmailRequests(
    @Payload emailRequests: List<EmailRequest>
) {
    logger.info("Received ${emailRequests.size} email requests for bulk processing")
    
    emailRequests.chunked(10).forEach { batch ->
        try {
            emailService.processBulkEmails(batch)
        } catch (e: Exception) {
            logger.error("Failed to process email batch", e)
            *// 개별 처리로 fallback*
            batch.forEach { request ->
                try {
                    emailService.processEmailRequest(request)
                } catch (ex: Exception) {
                    logger.error("Failed to process individual email: ${request.id}", ex)
                }
            }
        }
    }
}
```

## 이메일 서비스 구현

### 통합 이메일 서비스

kotlin

```kotlin
@Service
class EmailService(
    private val mailSender: JavaMailSender,
    private val templateEngine: TemplateEngine
) {
    private val logger = LoggerFactory.getLogger(EmailService::class.java)

    fun processEmailRequest(request: EmailRequest) {
        when (request.contentType) {
            EmailContentType.TEXT -> sendTextEmail(request)
            EmailContentType.HTML -> sendHtmlEmail(request)
        }
    }

    private fun sendTextEmail(request: EmailRequest) {
        val message = SimpleMailMessage().apply {
            setTo(request.to)
            setSubject(request.subject)
            setText(request.content)
            setFrom("noreply@example.com")
        }
        
        mailSender.send(message)
        logger.info("Text email sent to: ${request.to}")
    }

    private fun sendHtmlEmail(request: EmailRequest) {
        val message = mailSender.createMimeMessage()
        val helper = MimeMessageHelper(message, true, "UTF-8")
        
        helper.setTo(request.to)
        helper.setSubject(request.subject)
        helper.setText(request.content, true)
        helper.setFrom("noreply@example.com")
        
        *// 첨부파일 처리*
        request.attachments.forEach { attachment ->
            val resource = ByteArrayResource(attachment.data)
            helper.addAttachment(attachment.filename, resource)
        }
        
        mailSender.send(message)
        logger.info("HTML email sent to: ${request.to}")
    }

    fun processBulkEmails(requests: List<EmailRequest>) {
        val messages = requests.map { request ->
            createMimeMessage(request)
        }.toTypedArray()
        
        mailSender.send(*messages)
        logger.info("Bulk emails sent: ${requests.size} messages")
    }
}
```

## Kafka 설정 클래스

### Consumer 설정

kotlin

```kotlin
@Configuration
@EnableKafka
class KafkaConsumerConfig {

    @Bean
    fun consumerFactory(): ConsumerFactory<String, EmailRequest> {
        val props = mapOf(
            ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG to "localhost:9092",
            ConsumerConfig.GROUP_ID_CONFIG to "email-sender-group",
            ConsumerConfig.AUTO_OFFSET_RESET_CONFIG to "earliest",
            ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG to StringDeserializer::class.java,
            ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG to JsonDeserializer::class.java,
            JsonDeserializer.TRUSTED_PACKAGES to "com.example.email.dto",
            JsonDeserializer.VALUE_DEFAULT_TYPE to EmailRequest::class.java.name
        )
        return DefaultKafkaConsumerFactory(props)
    }

    @Bean
    fun kafkaListenerContainerFactory(): ConcurrentKafkaListenerContainerFactory<String, EmailRequest> {
        val factory = ConcurrentKafkaListenerContainerFactory<String, EmailRequest>()
        factory.consumerFactory = consumerFactory()
        factory.setConcurrency(3) *// 동시 처리 스레드 수*
        
        *// 에러 핸들링*
        factory.setCommonErrorHandler(DefaultErrorHandler().apply {
            setRetryListeners { record, ex, deliveryAttempt ->
                println("Retry attempt $deliveryAttempt for record: $record")
            }
        })
        
        return factory
    }
}
```

## 우선순위별 처리

### 우선순위 기반 Consumer

kotlin

```kotlin
@Component
class PriorityEmailConsumer(
    private val emailService: EmailService
) {
    
    @KafkaListener(topics = ["high-priority-emails"])
    fun consumeHighPriorityEmails(@Payload emailRequest: EmailRequest) {
        logger.info("Processing HIGH priority email: ${emailRequest.id}")
        emailService.processEmailRequest(emailRequest)
    }
    
    @KafkaListener(topics = ["normal-priority-emails"])
    fun consumeNormalPriorityEmails(@Payload emailRequest: EmailRequest) {
        logger.info("Processing NORMAL priority email: ${emailRequest.id}")
        emailService.processEmailRequest(emailRequest)
    }
    
    @KafkaListener(topics = ["low-priority-emails"])
    fun consumeLowPriorityEmails(@Payload emailRequest: EmailRequest) {
        logger.info("Processing LOW priority email: ${emailRequest.id}")
        Thread.sleep(100) *// 낮은 우선순위는 약간의 지연*
        emailService.processEmailRequest(emailRequest)
    }
}
```

## 모니터링과 메트릭

### Consumer 상태 모니터링

kotlin

```kotlin
@Component
class EmailConsumerMetrics {
    private val processedEmails = Counter.builder("emails.processed")
        .description("Total processed emails")
        .register(Metrics.globalRegistry)
    
    private val failedEmails = Counter.builder("emails.failed")
        .description("Total failed emails")
        .register(Metrics.globalRegistry)

    fun incrementProcessed() = processedEmails.increment()
    fun incrementFailed() = failedEmails.increment()
}
```

## 에러 처리와 재시도

### Dead Letter Topic 처리

kotlin

```kotlin
@Component
class DeadLetterConsumer(
    private val emailService: EmailService
) {
    
    @KafkaListener(topics = ["email-requests-dlt"])
    fun handleDeadLetterEmails(@Payload emailRequest: EmailRequest) {
        logger.warn("Processing email from dead letter topic: ${emailRequest.id}")
        
        *// 수동 재시도 또는 알림 발송*
        try {
            emailService.processEmailRequest(emailRequest)
            logger.info("Successfully recovered email from DLT: ${emailRequest.id}")
        } catch (e: Exception) {
            logger.error("Final failure for email: ${emailRequest.id}", e)
            *// 관리자 알림 또는 별도 저장*
        }
    }
}
```

## Producer 구현 (테스트용)

### 이메일 요청 발송

kotlin

```kotlin
@Component
class EmailProducer(
    private val kafkaTemplate: KafkaTemplate<String, EmailRequest>
) {
    
    fun sendEmailRequest(emailRequest: EmailRequest) {
        val topic = when (emailRequest.priority) {
            EmailPriority.HIGH -> "high-priority-emails"
            EmailPriority.NORMAL -> "normal-priority-emails"
            EmailPriority.LOW -> "low-priority-emails"
        }
        
        kafkaTemplate.send(topic, emailRequest.id, emailRequest)
            .whenComplete { result, ex ->
                if (ex != null) {
                    logger.error("Failed to send email request: ${emailRequest.id}", ex)
                } else {
                    logger.info("Email request sent: ${emailRequest.id}")
                }
            }
    }
}
```

## 전체 요약

Kafka Consumer를 통한 이메일 전송 시스템은 메시지 큐의 안정성과 JavaMailSender의 편의성을 결합한 확장 가능한 아키텍처. Kafka의 분산 처리 능력으로 대용량 이메일 요청을 안정적으로 큐잉하고, Consumer에서 우선순위별, 배치별 처리를 통해 효율성을 극대화함. 에러 처리와 재시도 메커니즘, Dead Letter Topic을 활용한 장애 복구, 메트릭 수집을 통한 모니터링까지 포함하여 운영 환경에서 안정적인 이메일 서비스 구축 가능함.

---

# Circuit Breaker 패턴과 이메일 서비스 장애 격리

Circuit Breaker 패턴은 전기 회로의 차단기에서 영감을 받은 장애 격리 패턴. 외부 서비스 호출 실패가 연속적으로 발생할 때 일정 시간 동안 호출을 차단하여 시스템 전체의 연쇄 장애를 방지하는 메커니즘. 이메일 서비스에서는 SMTP 서버 장애, 네트워크 이슈, 인증 실패 등으로 인한 장애가 전체 애플리케이션에 영향을 미치지 않도록 격리하는 데 활용됨. Closed(정상), Open(차단), Half-Open(테스트) 세 가지 상태를 통해 동적으로 장애를 감지하고 복구를 시도.

## 기본 개념과 상태

### Circuit Breaker 상태 다이어그램

- **Closed**: 정상 상태, 모든 요청이 통과
- **Open**: 차단 상태, 모든 요청을 즉시 실패 처리
- **Half-Open**: 테스트 상태, 제한된 수의 요청만 허용하여 복구 여부 확인

### 핵심 메트릭

- Failure Rate: 실패율 임계값 (예: 50%)
- Failure Count: 연속 실패 횟수 임계값
- Timeout Duration: 차단 유지 시간
- Slow Call Duration: 느린 호출 판단 기준

## Resilience4j 기반 구현

### 의존성 추가

gradle

```groovy
*// build.gradle.kts*
implementation("io.github.resilience4j:resilience4j-spring-boot2:1.7.1")
implementation("io.github.resilience4j:resilience4j-kotlin")
implementation("org.springframework.boot:spring-boot-starter-actuator")
implementation("io.micrometer:micrometer-registry-prometheus")
```

### Circuit Breaker 설정

yaml

```yaml
*# application.yml*
resilience4j:
  circuitbreaker:
    configs:
      default:
        sliding-window-size: 100
        failure-rate-threshold: 50
        wait-duration-in-open-state: 60000
        minimum-number-of-calls: 10
        permitted-number-of-calls-in-half-open-state: 5
        slow-call-duration-threshold: 10000
        slow-call-rate-threshold: 50
        automatic-transition-from-open-to-half-open-enabled: true
    instances:
      email-service:
        base-config: default
        failure-rate-threshold: 60
        wait-duration-in-open-state: 30000
      smtp-service:
        base-config: default
        failure-rate-threshold: 40
        wait-duration-in-open-state: 45000
        
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,circuitbreakers
  health:
    circuitbreakers:
      enabled: true
```

## 이메일 서비스 Circuit Breaker 구현

### 기본 Circuit Breaker 서비스

kotlin

```kotlin
@Service
class ResilientEmailService(
    private val mailSender: JavaMailSender,
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val emailFallbackService: EmailFallbackService
) {
    private val logger = LoggerFactory.getLogger(ResilientEmailService::class.java)
    
    private val emailCircuitBreaker = circuitBreakerRegistry.circuitBreaker("email-service")
    private val smtpCircuitBreaker = circuitBreakerRegistry.circuitBreaker("smtp-service")

    init {
        setupCircuitBreakerEventListeners()
    }

    @CircuitBreaker(name = "email-service", fallbackMethod = "sendEmailFallback")
    @TimeLimiter(name = "email-service")
    @Retry(name = "email-service")
    suspend fun sendEmailAsync(emailRequest: EmailRequest): CompletableFuture<EmailResult> {
        return CompletableFuture.supplyAsync {
            try {
                sendEmailInternal(emailRequest)
                EmailResult.success(emailRequest.id, "Email sent successfully")
            } catch (e: Exception) {
                logger.error("Failed to send email: ${emailRequest.id}", e)
                throw EmailSendException("Email sending failed", e)
            }
        }
    }

    private fun sendEmailInternal(request: EmailRequest) {
        val message = mailSender.createMimeMessage()
        val helper = MimeMessageHelper(message, true, "UTF-8")
        
        helper.setTo(request.to)
        helper.setSubject(request.subject)
        helper.setText(request.content, request.contentType == EmailContentType.HTML)
        helper.setFrom("noreply@example.com")
        
        *// 첨부파일 처리*
        request.attachments.forEach { attachment ->
            val resource = ByteArrayResource(attachment.data)
            helper.addAttachment(attachment.filename, resource)
        }
        
        mailSender.send(message)
    }

    *// Fallback 메서드*
    fun sendEmailFallback(emailRequest: EmailRequest, ex: Exception): CompletableFuture<EmailResult> {
        logger.warn("Email service fallback triggered for: ${emailRequest.id}", ex)
        return emailFallbackService.handleFailedEmail(emailRequest, ex)
    }
}
```

### Circuit Breaker 상태별 처리

kotlin

```kotlin
@Component
class EmailCircuitBreakerService(
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val kafkaTemplate: KafkaTemplate<String, EmailRequest>,
    private val cacheManager: CacheManager
) {
    
    fun sendEmailWithCircuitBreaker(emailRequest: EmailRequest): EmailResult {
        val circuitBreaker = circuitBreakerRegistry.circuitBreaker("email-service")
        
        return when (circuitBreaker.state) {
            CircuitBreaker.State.CLOSED -> {
                *// 정상 상태: 이메일 전송 시도*
                executeEmailSending(emailRequest)
            }
            CircuitBreaker.State.OPEN -> {
                *// 차단 상태: 즉시 fallback 처리*
                logger.warn("Circuit breaker is OPEN, queuing email: ${emailRequest.id}")
                queueEmailForLater(emailRequest)
                EmailResult.queued(emailRequest.id, "Email queued due to service unavailability")
            }
            CircuitBreaker.State.HALF_OPEN -> {
                *// 테스트 상태: 제한적 전송 시도*
                logger.info("Circuit breaker is HALF_OPEN, attempting email: ${emailRequest.id}")
                executeEmailSending(emailRequest)
            }
        }
    }

    private fun executeEmailSending(emailRequest: EmailRequest): EmailResult {
        val supplier = CircuitBreaker.decorateSupplier(
            circuitBreakerRegistry.circuitBreaker("email-service")
        ) {
            sendEmailDirectly(emailRequest)
        }
        
        return supplier.get()
    }

    private fun queueEmailForLater(emailRequest: EmailRequest) {
        *// Kafka로 재시도 큐에 전송*
        kafkaTemplate.send("email-retry-queue", emailRequest.id, emailRequest)
        
        *// 캐시에 임시 저장*
        cacheManager.getCache("failed-emails")?.put(emailRequest.id, emailRequest)
    }
}
```

## 다층 Circuit Breaker 구조

### SMTP 서버별 Circuit Breaker

kotlin

```kotlin
@Service
class MultiSmtpEmailService(
    private val primaryMailSender: JavaMailSender,
    private val secondaryMailSender: JavaMailSender,
    private val circuitBreakerRegistry: CircuitBreakerRegistry
) {
    
    fun sendEmailWithFailover(emailRequest: EmailRequest): EmailResult {
        *// Primary SMTP 시도*
        val primaryResult = tryWithCircuitBreaker(
            "primary-smtp",
            primaryMailSender,
            emailRequest
        )
        
        if (primaryResult.isSuccess) {
            return primaryResult
        }
        
        *// Secondary SMTP로 fallback*
        logger.warn("Primary SMTP failed, trying secondary for: ${emailRequest.id}")
        return tryWithCircuitBreaker(
            "secondary-smtp",
            secondaryMailSender,
            emailRequest
        )
    }

    private fun tryWithCircuitBreaker(
        circuitBreakerName: String,
        mailSender: JavaMailSender,
        emailRequest: EmailRequest
    ): EmailResult {
        val circuitBreaker = circuitBreakerRegistry.circuitBreaker(circuitBreakerName)
        
        return try {
            val supplier = CircuitBreaker.decorateSupplier(circuitBreaker) {
                sendEmailWithSender(mailSender, emailRequest)
                EmailResult.success(emailRequest.id, "Email sent via $circuitBreakerName")
            }
            supplier.get()
        } catch (e: CallNotPermittedException) {
            EmailResult.circuitOpen(emailRequest.id, "Circuit breaker open for $circuitBreakerName")
        } catch (e: Exception) {
            EmailResult.failure(emailRequest.id, "Failed to send via $circuitBreakerName", e)
        }
    }
}
```

### 이메일 타입별 Circuit Breaker

kotlin

```kotlin
@Service
class TypedEmailCircuitBreakerService(
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val emailService: EmailService
) {
    
    fun sendTransactionalEmail(emailRequest: EmailRequest): EmailResult {
        return executeWithCircuitBreaker("transactional-email", emailRequest, true)
    }
    
    fun sendMarketingEmail(emailRequest: EmailRequest): EmailResult {
        return executeWithCircuitBreaker("marketing-email", emailRequest, false)
    }
    
    fun sendNotificationEmail(emailRequest: EmailRequest): EmailResult {
        return executeWithCircuitBreaker("notification-email", emailRequest, true)
    }

    private fun executeWithCircuitBreaker(
        type: String,
        emailRequest: EmailRequest,
        isHighPriority: Boolean
    ): EmailResult {
        val circuitBreaker = circuitBreakerRegistry.circuitBreaker(type)
        
        return if (circuitBreaker.state == CircuitBreaker.State.OPEN && !isHighPriority) {
            *// 낮은 우선순위는 차단 상태에서 즉시 실패*
            EmailResult.skipped(emailRequest.id, "Circuit breaker open for $type")
        } else {
            val supplier = CircuitBreaker.decorateSupplier(circuitBreaker) {
                emailService.sendEmail(emailRequest)
            }
            supplier.get()
        }
    }
}
```

## Kafka Integration과 Circuit Breaker

### Kafka Consumer에 Circuit Breaker 적용

kotlin

```kotlin
@Component
class ResilientEmailKafkaConsumer(
    private val resilientEmailService: ResilientEmailService,
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val emailMetrics: EmailMetrics
) {
    
    @KafkaListener(topics = ["email-requests"])
    fun consumeEmailRequest(@Payload emailRequest: EmailRequest) {
        val circuitBreaker = circuitBreakerRegistry.circuitBreaker("email-consumer")
        
        val supplier = CircuitBreaker.decorateSupplier(circuitBreaker) {
            processEmailWithCircuitBreaker(emailRequest)
        }
        
        try {
            supplier.get()
        } catch (e: CallNotPermittedException) {
            logger.warn("Email consumer circuit breaker is open, requeueing: ${emailRequest.id}")
            requeueEmail(emailRequest)
        } catch (e: Exception) {
            logger.error("Failed to process email: ${emailRequest.id}", e)
            handleFailedEmail(emailRequest, e)
        }
    }

    private fun processEmailWithCircuitBreaker(emailRequest: EmailRequest): EmailResult {
        val startTime = System.currentTimeMillis()
        
        return try {
            val result = resilientEmailService.sendEmailAsync(emailRequest).get()
            emailMetrics.recordSuccess(System.currentTimeMillis() - startTime)
            result
        } catch (e: Exception) {
            emailMetrics.recordFailure(System.currentTimeMillis() - startTime)
            throw e
        }
    }

    private fun requeueEmail(emailRequest: EmailRequest) {
        *// 재시도 큐로 전송 (지연 처리)*
        val delayedRequest = emailRequest.copy(
            timestamp = LocalDateTime.now().plusMinutes(5)
        )
        kafkaTemplate.send("email-delayed-retry", delayedRequest)
    }
}
```

## 모니터링과 알림

### Circuit Breaker 메트릭 수집

kotlin

```kotlin
@Component
class CircuitBreakerMetrics {
    private val circuitBreakerStateGauge = Gauge.builder("circuit.breaker.state")
        .description("Circuit breaker current state")
        .register(Metrics.globalRegistry)
    
    private val circuitBreakerTransitions = Counter.builder("circuit.breaker.transitions")
        .description("Circuit breaker state transitions")
        .register(Metrics.globalRegistry)

    @EventListener
    fun handleCircuitBreakerEvent(event: CircuitBreakerEvent) {
        when (event) {
            is CircuitBreakerOnStateTransitionEvent -> {
                logger.info("Circuit breaker '${event.circuitBreakerName}' " +
                          "transitioned from ${event.stateTransition.fromState} " +
                          "to ${event.stateTransition.toState}")
                
                circuitBreakerTransitions.increment(
                    Tags.of(
                        "name", event.circuitBreakerName,
                        "from_state", event.stateTransition.fromState.name,
                        "to_state", event.stateTransition.toState.name
                    )
                )
                
                *// 알림 발송*
                if (event.stateTransition.toState == CircuitBreaker.State.OPEN) {
                    sendCircuitBreakerAlert(event.circuitBreakerName, "OPENED")
                }
            }
            is CircuitBreakerOnFailureRateExceededEvent -> {
                logger.warn("Circuit breaker '${event.circuitBreakerName}' " +
                          "failure rate exceeded: ${event.failureRate}%")
            }
        }
    }

    private fun sendCircuitBreakerAlert(circuitBreakerName: String, state: String) {
        *// Slack, 이메일 등으로 알림 발송*
        logger.error("ALERT: Circuit breaker '$circuitBreakerName' is $state")
    }
}
```

### Health Check Integration

kotlin

```kotlin
@Component
class EmailServiceHealthIndicator(
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val emailService: EmailService
) : HealthIndicator {
    
    override fun health(): Health {
        val emailCircuitBreaker = circuitBreakerRegistry.circuitBreaker("email-service")
        val smtpCircuitBreaker = circuitBreakerRegistry.circuitBreaker("smtp-service")
        
        val emailState = emailCircuitBreaker.state
        val smtpState = smtpCircuitBreaker.state
        
        return when {
            emailState == CircuitBreaker.State.OPEN && smtpState == CircuitBreaker.State.OPEN -> {
                Health.down()
                    .withDetail("email-circuit", "OPEN")
                    .withDetail("smtp-circuit", "OPEN")
                    .withDetail("message", "All email services are down")
                    .build()
            }
            emailState == CircuitBreaker.State.OPEN || smtpState == CircuitBreaker.State.OPEN -> {
                Health.down()
                    .withDetail("email-circuit", emailState.name)
                    .withDetail("smtp-circuit", smtpState.name)
                    .withDetail("message", "Some email services are degraded")
                    .build()
            }
            else -> {
                Health.up()
                    .withDetail("email-circuit", emailState.name)
                    .withDetail("smtp-circuit", smtpState.name)
                    .build()
            }
        }
    }
}
```

## Fallback 전략

### 다단계 Fallback 시스템

kotlin

```kotlin
@Service
class EmailFallbackService(
    private val kafkaTemplate: KafkaTemplate<String, EmailRequest>,
    private val fileStorageService: FileStorageService,
    private val notificationService: NotificationService
) {
    
    fun handleFailedEmail(emailRequest: EmailRequest, exception: Exception): CompletableFuture<EmailResult> {
        return CompletableFuture.supplyAsync {
            when (emailRequest.priority) {
                EmailPriority.HIGH -> handleHighPriorityFailure(emailRequest, exception)
                EmailPriority.NORMAL -> handleNormalPriorityFailure(emailRequest, exception)
                EmailPriority.LOW -> handleLowPriorityFailure(emailRequest, exception)
            }
        }
    }

    private fun handleHighPriorityFailure(emailRequest: EmailRequest, exception: Exception): EmailResult {
        *// 1. 즉시 재시도 큐에 추가*
        kafkaTemplate.send("email-immediate-retry", emailRequest)
        
        *// 2. 관리자에게 즉시 알림*
        notificationService.sendUrgentAlert(
            "High priority email failed: ${emailRequest.id}",
            exception.message ?: "Unknown error"
        )
        
        *// 3. 로컬 파일에 백업*
        fileStorageService.saveFailedEmail(emailRequest, exception)
        
        return EmailResult.fallback(emailRequest.id, "High priority email queued for immediate retry")
    }

    private fun handleNormalPriorityFailure(emailRequest: EmailRequest, exception: Exception): EmailResult {
        *// 지연된 재시도 큐에 추가*
        val delayedRequest = emailRequest.copy(
            timestamp = LocalDateTime.now().plusMinutes(10)
        )
        kafkaTemplate.send("email-delayed-retry", delayedRequest)
        
        return EmailResult.fallback(emailRequest.id, "Email queued for delayed retry")
    }

    private fun handleLowPriorityFailure(emailRequest: EmailRequest, exception: Exception): EmailResult {
        *// 단순히 실패 로깅만 수행*
        logger.info("Low priority email failed, will not retry: ${emailRequest.id}")
        return EmailResult.failure(emailRequest.id, "Low priority email abandoned", exception)
    }
}
```

## 전체 요약

Circuit Breaker 패턴을 적용한 이메일 서비스는 SMTP 서버 장애나 네트워크 이슈로 인한 연쇄 장애를 효과적으로 차단하고 시스템의 안정성을 보장. Resilience4j를 활용한 다층 Circuit Breaker 구조로 서비스별, 우선순위별 차별화된 장애 처리가 가능하며, Kafka와의 통합을 통해 실패한 이메일의 재처리와 fallback 전략을 체계적으로 구현. 실시간 모니터링과 알림 시스템을 통해 장애 상황을 즉시 감지하고 대응할 수 있어, 대용량 이메일 처리 환경에서도 안정적인 서비스 운영이 가능.

---

# Kubernetes에서 Circuit Breaker 기반 이메일 서비스 배포 전략

Kubernetes는 컨테이너 오케스트레이션 플랫폼으로, Circuit Breaker 패턴과 결합하면 애플리케이션 레벨과 인프라 레벨에서 이중 장애 격리가 가능. Pod의 자동 재시작, Service Mesh의 트래픽 제어, HPA의 자동 스케일링과 Circuit Breaker의 상태 기반 요청 차단이 조화롭게 작동하여 고가용성 이메일 서비스를 구현할 수 있음. ConfigMap을 통한 Circuit Breaker 설정 동적 변경, Prometheus와 Grafana를 활용한 모니터링, 그리고 Blue-Green 배포를 통한 무중단 서비스 업데이트까지 포괄하는 전략이 필요.

## 아키텍처 설계

### 마이크로서비스 구조

yaml

```yaml
*# 이메일 서비스 아키텍처*
apiVersion: v1
kind: Namespace
metadata:
  name: email-system
---
*# 이메일 발송 서비스*
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-sender-service
  namespace: email-system
spec:
  replicas: 3
  selector:
    matchLabels:
      app: email-sender
  template:
    metadata:
      labels:
        app: email-sender
        version: v1
    spec:
      containers:
      - name: email-sender
        image: email-sender:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        - name: KAFKA_BOOTSTRAP_SERVERS
          value: "kafka-service:9092"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
```

### Service와 Ingress 설정

yaml

```yaml
*# 이메일 서비스 Service*
apiVersion: v1
kind: Service
metadata:
  name: email-sender-service
  namespace: email-system
  labels:
    app: email-sender
spec:
  selector:
    app: email-sender
  ports:
  - port: 80
    targetPort: 8080
    name: http
  type: ClusterIP
---
*# Ingress 설정*
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: email-service-ingress
  namespace: email-system
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    nginx.ingress.kubernetes.io/circuit-breaker-failure-threshold: "5"
    nginx.ingress.kubernetes.io/circuit-breaker-recovery-timeout: "30s"
spec:
  rules:
  - host: email-api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: email-sender-service
            port:
              number: 80
```

## ConfigMap 기반 Circuit Breaker 설정

### 동적 설정 관리

yaml

```yaml
*# Circuit Breaker 설정 ConfigMap*
apiVersion: v1
kind: ConfigMap
metadata:
  name: circuit-breaker-config
  namespace: email-system
data:
  application.yml: |
    resilience4j:
      circuitbreaker:
        configs:
          default:
            sliding-window-size: 100
            failure-rate-threshold: 50
            wait-duration-in-open-state: 60s
            minimum-number-of-calls: 10
            permitted-number-of-calls-in-half-open-state: 5
            automatic-transition-from-open-to-half-open-enabled: true
        instances:
          email-smtp:
            base-config: default
            failure-rate-threshold: ${CIRCUIT_BREAKER_SMTP_FAILURE_RATE:60}
            wait-duration-in-open-state: ${CIRCUIT_BREAKER_SMTP_WAIT_DURATION:30s}
          email-template:
            base-config: default
            failure-rate-threshold: ${CIRCUIT_BREAKER_TEMPLATE_FAILURE_RATE:70}
            wait-duration-in-open-state: ${CIRCUIT_BREAKER_TEMPLATE_WAIT_DURATION:45s}
      retry:
        configs:
          default:
            max-attempts: 3
            wait-duration: 1s
            exponential-backoff-multiplier: 2
        instances:
          email-smtp:
            base-config: default
            max-attempts: ${RETRY_SMTP_MAX_ATTEMPTS:5}
---
*# Secret for SMTP credentials*
apiVersion: v1
kind: Secret
metadata:
  name: email-smtp-secret
  namespace: email-system
type: Opaque
data:
  smtp-username: *# base64 encoded*
  smtp-password: *# base64 encoded*
  smtp-host: *# base64 encoded*
```

### 환경별 설정 오버라이드

yaml

```yaml
*# 개발환경 ConfigMap*
apiVersion: v1
kind: ConfigMap
metadata:
  name: circuit-breaker-config-dev
  namespace: email-system
data:
  CIRCUIT_BREAKER_SMTP_FAILURE_RATE: "80"
  CIRCUIT_BREAKER_SMTP_WAIT_DURATION: "10s"
  RETRY_SMTP_MAX_ATTEMPTS: "2"
---
*# 운영환경 ConfigMap*
apiVersion: v1
kind: ConfigMap
metadata:
  name: circuit-breaker-config-prod
  namespace: email-system
data:
  CIRCUIT_BREAKER_SMTP_FAILURE_RATE: "40"
  CIRCUIT_BREAKER_SMTP_WAIT_DURATION: "60s"
  RETRY_SMTP_MAX_ATTEMPTS: "3"
```

## 이메일 서비스 Deployment 최적화

### 다중 인스턴스와 Circuit Breaker 통합

kotlin

```kotlin
*// Kubernetes 환경 대응 Circuit Breaker 설정*
@Configuration
@Profile("kubernetes")
class KubernetesCircuitBreakerConfig {
    
    @Bean
    @Primary
    fun kubernetesCircuitBreakerRegistry(
        @Value("\${spring.application.name}") appName: String,
        @Value("\${HOSTNAME:unknown}") hostname: String
    ): CircuitBreakerRegistry {
        
        val config = CircuitBreakerConfig.custom()
            .slidingWindowSize(100)
            .failureRateThreshold(50.0f)
            .waitDurationInOpenState(Duration.ofSeconds(60))
            .minimumNumberOfCalls(10)
            .permittedNumberOfCallsInHalfOpenState(5)
            .automaticTransitionFromOpenToHalfOpenEnabled(true)
            .recordExceptions(
                MailException::class.java,
                TimeoutException::class.java,
                ConnectException::class.java
            )
            .ignoreExceptions(
                IllegalArgumentException::class.java,
                ValidationException::class.java
            )
            .build()
        
        return CircuitBreakerRegistry.of(config)
    }
}
```

### Pod 레벨 Circuit Breaker 통합

yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-sender-ha
  namespace: email-system
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: email-sender-ha
  template:
    metadata:
      labels:
        app: email-sender-ha
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/actuator/prometheus"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: email-sender
        image: email-sender:v2.1.0
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 8081
          name: management
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        envFrom:
        - configMapRef:
            name: circuit-breaker-config-prod
        - secretRef:
            name: email-smtp-secret
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        - name: logs-volume
          mountPath: /app/logs
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8081
          initialDelaySeconds: 120
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 1
      volumes:
      - name: config-volume
        configMap:
          name: circuit-breaker-config
      - name: logs-volume
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - email-sender-ha
              topologyKey: kubernetes.io/hostname
```

## HPA와 Circuit Breaker 연동

### 메트릭 기반 자동 스케일링

yaml

```yaml
*# HPA 설정*
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: email-sender-hpa
  namespace: email-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: email-sender-ha
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: circuit_breaker_failure_rate
      target:
        type: AverageValue
        averageValue: "30"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### Custom Metrics Server 설정

kotlin

```kotlin
@Component
class CircuitBreakerMetricsCollector(
    private val circuitBreakerRegistry: CircuitBreakerRegistry,
    private val meterRegistry: MeterRegistry
) {
    
    @Scheduled(fixedRate = 30000)
    fun collectCircuitBreakerMetrics() {
        circuitBreakerRegistry.allCircuitBreakers.forEach { circuitBreaker ->
            val metrics = circuitBreaker.metrics
            
            *// HPA용 커스텀 메트릭 등록*
            Gauge.builder("circuit_breaker_failure_rate")
                .tag("name", circuitBreaker.name)
                .tag("pod", System.getenv("POD_NAME") ?: "unknown")
                .register(meterRegistry) { metrics.failureRate }
                
            Gauge.builder("circuit_breaker_slow_call_rate")
                .tag("name", circuitBreaker.name)
                .tag("pod", System.getenv("POD_NAME") ?: "unknown")
                .register(meterRegistry) { metrics.slowCallRate }
                
            Gauge.builder("circuit_breaker_state")
                .tag("name", circuitBreaker.name)
                .tag("pod", System.getenv("POD_NAME") ?: "unknown")
                .register(meterRegistry) { 
                    when (circuitBreaker.state) {
                        CircuitBreaker.State.CLOSED -> 0.0
                        CircuitBreaker.State.OPEN -> 1.0
                        CircuitBreaker.State.HALF_OPEN -> 0.5
                    }
                }
        }
    }
}
```

## Service Mesh 통합 (Istio)

### Istio Circuit Breaker 설정

yaml

```yaml
*# Istio DestinationRule*
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: email-sender-circuit-breaker
  namespace: email-system
spec:
  host: email-sender-service.email-system.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 10
        maxRetries: 3
        consecutiveGatewayErrors: 5
        interval: 30s
        baseEjectionTime: 30s
        maxEjectionPercent: 50
    outlierDetection:
      consecutive5xxErrors: 3
      consecutiveGatewayErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 30
---
*# Istio VirtualService*
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: email-sender-vs
  namespace: email-system
spec:
  hosts:
  - email-sender-service.email-system.svc.cluster.local
  http:
  - match:
    - headers:
        priority:
          exact: high
    route:
    - destination:
        host: email-sender-service.email-system.svc.cluster.local
      weight: 100
    timeout: 10s
    retries:
      attempts: 5
      perTryTimeout: 2s
  - route:
    - destination:
        host: email-sender-service.email-system.svc.cluster.local
      weight: 100
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 5s
```

## 모니터링과 알림 시스템

### Prometheus 모니터링 설정

yaml

```yaml
*# ServiceMonitor for Prometheus*
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: email-service-monitor
  namespace: email-system
  labels:
    app: email-sender
spec:
  selector:
    matchLabels:
      app: email-sender
  endpoints:
  - port: management
    path: /actuator/prometheus
    interval: 30s
    scrapeTimeout: 10s
---
*# PrometheusRule for Alerting*
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: email-service-alerts
  namespace: email-system
spec:
  groups:
  - name: email-service
    rules:
    - alert: EmailCircuitBreakerOpen
      expr: circuit_breaker_state{name="email-smtp"} == 1
      for: 2m
      labels:
        severity: critical
        service: email
      annotations:
        summary: "Email service circuit breaker is open"
        description: "Circuit breaker {{ $labels.name }} has been open for more than 2 minutes"
    
    - alert: EmailServiceHighFailureRate
      expr: rate(circuit_breaker_calls_total{name="email-smtp",outcome="failure"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
        service: email
      annotations:
        summary: "Email service has high failure rate"
        description: "Email service failure rate is {{ $value | humanizePercentage }}"
    
    - alert: EmailServicePodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total{namespace="email-system"}[15m]) > 0
      for: 5m
      labels:
        severity: critical
        service: email
      annotations:
        summary: "Email service pod is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"
```

### Grafana 대시보드

json

```json
{
  "dashboard": {
    "title": "Email Service Circuit Breaker Dashboard",
    "panels": [
      {
        "title": "Circuit Breaker States",
        "type": "stat",
        "targets": [
          {
            "expr": "circuit_breaker_state",
            "legendFormat": "{{ name }}"
          }
        ],
        "fieldConfig": {
          "mappings": [
            {"value": 0, "text": "CLOSED", "color": "green"},
            {"value": 0.5, "text": "HALF_OPEN", "color": "yellow"},
            {"value": 1, "text": "OPEN", "color": "red"}
          ]
        }
      },
      {
        "title": "Email Success Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(circuit_breaker_calls_total{outcome=\"success\"}[5m]) / rate(circuit_breaker_calls_total[5m]) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      },
      {
        "title": "Pod Resource Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{namespace=\"email-system\"}[5m]) * 100",
            "legendFormat": "CPU % - {{ pod }}"
          },
          {
            "expr": "container_memory_usage_bytes{namespace=\"email-system\"} / container_spec_memory_limit_bytes * 100",
            "legendFormat": "Memory % - {{ pod }}"
          }
        ]
      }
    ]
  }
}
```

## Blue-Green 배포 전략

### Blue-Green Deployment 구현

yaml

```yaml
*# Blue Environment (Current)*
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: email-sender-rollout
  namespace: email-system
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: email-sender-active
      previewService: email-sender-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: circuit-breaker-analysis
        args:
        - name: service-name
          value: email-sender-preview
      postPromotionAnalysis:
        templates:
        - templateName: circuit-breaker-analysis
        args:
        - name: service-name
          value: email-sender-active
  selector:
    matchLabels:
      app: email-sender
  template:
    metadata:
      labels:
        app: email-sender
    spec:
      containers:
      - name: email-sender
        image: email-sender:latest
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
---
*# AnalysisTemplate for Circuit Breaker validation*
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: circuit-breaker-analysis
  namespace: email-system
spec:
  args:
  - name: service-name
  metrics:
  - name: circuit-breaker-success-rate
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc.cluster.local:9090
        query: |
          rate(circuit_breaker_calls_total{outcome="success",service="{{ args.service-name }}"}[5m]) /
          rate(circuit_breaker_calls_total{service="{{ args.service-name }}"}[5m]) * 100
    successCondition: result[0] >= 95
    interval: 30s
    count: 5
    failureLimit: 2
```

## 장애 시나리오별 대응 전략

### SMTP 서버 장애 대응

kotlin

```yaml
@Component
class SmtpFailureHandler(
    private val kubernetesClient: KubernetesClient,
    private val circuitBreakerRegistry: CircuitBreakerRegistry
) {
    
    @EventListener
    fun handleSmtpCircuitBreakerOpen(event: CircuitBreakerOnStateTransitionEvent) {
        if (event.stateTransition.toState == CircuitBreaker.State.OPEN &&
            event.circuitBreakerName.contains("smtp")) {
            
            logger.error("SMTP Circuit Breaker opened, scaling up pods")
            
            *// HPA 최대 replica 수 증가*
            scaleUpEmailService()
            
            *// ConfigMap 업데이트로 fallback SMTP 활성화*
            enableFallbackSmtp()
            
            *// 우선순위 높은 이메일만 처리하도록 설정 변경*
            enableHighPriorityOnlyMode()
        }
    }
    
    private fun scaleUpEmailService() {
        val hpa = kubernetesClient.autoscaling().v2().horizontalPodAutoscalers()
            .inNamespace("email-system")
            .withName("email-sender-hpa")
            .get()
            
        hpa.spec.maxReplicas = hpa.spec.maxReplicas * 2
        
        kubernetesClient.autoscaling().v2().horizontalPodAutoscalers()
            .inNamespace("email-system")
            .withName("email-sender-hpa")
            .replace(hpa)
    }
}
```

### 자동 복구 시스템

yaml

```yaml
*# CronJob for Circuit Breaker Health Check*
apiVersion: batch/v1
kind: CronJob
metadata:
  name: circuit-breaker-health-check
  namespace: email-system
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: health-checker
            image: curlimages/curl:latest
            command:
            - /bin/sh
            - -c
            - |
              # Circuit Breaker 상태 확인
              for pod in $(kubectl get pods -n email-system -l app=email-sender -o name); do
                kubectl exec $pod -n email-system -- curl -s http://localhost:8081/actuator/health/circuitbreakers
              done
          restartPolicy: OnFailure
---
*# Emergency Scale Down Job*
apiVersion: batch/v1
kind: Job
metadata:
  name: emergency-scale-down
  namespace: email-system
spec:
  template:
    spec:
      containers:
      - name: scaler
        image: bitnami/kubectl:latest
        command:
        - /bin/bash
        - -c
        - |
          # 모든 Circuit Breaker가 CLOSED 상태인지 확인
          if kubectl get pods -n email-system -l app=email-sender -o jsonpath='{.items[*].metadata.name}' | \
             xargs -I {} kubectl exec {} -n email-system -- \
             curl -s http://localhost:8081/actuator/circuitbreakers | \
             jq -r '.[] | select(.state != "CLOSED") | .name' | \
             wc -l | grep -q "^0$"; then
            # 모든 Circuit Breaker가 정상이면 스케일 다운
            kubectl scale deployment email-sender-ha --replicas=3 -n email-system
          fi
      restartPolicy: Never
```

## 전체 요약

Kubernetes 환경에서 Circuit Breaker 기반 이메일 서비스는 컨테이너 오케스트레이션의 자동 복구 기능과 애플리케이션 레벨의 장애 격리를 통합하여 높은 가용성을 제공. ConfigMap을 통한 동적 설정 관리, HPA와 연동된 자동 스케일링, Service Mesh의 트래픽 제어, 그리고 Prometheus/Grafana 기반 모니터링이 유기적으로 결합되어 장애 상황에서도 안정적인 이메일 서비스 운영을 보장. Blue-Green 배포와 자동화된 복구 시스템을 통해 무중단 서비스 업데이트와 장애 대응이 가능하며, 다양한 장애 시나리오에 대한 사전 정의된 대응 전략으로 운영 부담을 최소화할 수 있음.
