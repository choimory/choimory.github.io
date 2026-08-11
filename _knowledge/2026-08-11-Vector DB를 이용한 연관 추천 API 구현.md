---
title: "Vector DB를 이용한 연관 추천 API 구현"
date: 2026-08-11T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Vector
    - Recommend
---

## 개요

Vector DB 기반 추천 시스템은 "의미적 유사도(Semantic Similarity)"를 기반으로 동작합니다. 단순한 키워드 매칭이나 통계 기반 협업 필터링과 달리, 텍스트나 데이터를 고차원 벡터(숫자 배열)로 변환한 뒤, 벡터 공간에서의 거리를 계산하여 가장 유사한 항목을 찾아냅니다.

예를 들어 상품 설명 "겨울 따뜻한 패딩 자켓"이 있을 때, 이를 벡터로 변환하면 "방한용 아우터"라는 전혀 다른 표현과도 의미적으로 가깝다고 판단할 수 있습니다. 이것이 기존 LIKE 검색이나 태그 기반 추천과의 근본적인 차이입니다.

---

## 핵심 개념

### 임베딩(Embedding)

임베딩은 텍스트, 이미지, 또는 임의의 데이터를 고정 크기의 실수 벡터로 변환하는 과정입니다.

- 의미적으로 유사한 데이터는 벡터 공간에서 가깝게 위치합니다.
- 모델에 따라 차원 수가 다릅니다. (예: OpenAI `text-embedding-3-small`은 1536차원)
- 한 번 생성한 임베딩은 저장해두고 재사용합니다.

```
"스프링 부트 개발" → [0.12, -0.45, 0.88, ... (1536차원)]
"Spring Boot 백엔드" → [0.11, -0.43, 0.91, ...]  ← 벡터가 유사함
"강아지 간식 레시피" → [-0.72, 0.33, -0.21, ...] ← 벡터가 다름
```

### 유사도 측정 방식

| 방식 | 설명 | 사용 시점 |
| --- | --- | --- |
| 코사인 유사도 | 벡터 방향의 각도 차이 | 텍스트 임베딩 (가장 일반적) |
| 유클리드 거리 | 벡터 사이의 직선 거리 | 정규화된 수치 데이터 |
| 내적(Dot Product) | 벡터의 내적 값 | 정규화된 임베딩, 속도 우선 |

### Vector DB의 역할

일반 DB는 `WHERE name = '패딩'` 처럼 정확한 값 매칭만 가능하지만, Vector DB는 "이 벡터와 가장 가까운 K개의 벡터를 찾아라(KNN / ANN)"라는 쿼리를 고속으로 처리합니다. 수백만 개의 벡터 중에서도 근사 최근접 이웃(ANN, Approximate Nearest Neighbor) 알고리즘(HNSW, IVF 등)을 사용해 빠르게 검색합니다.

---

## 주요 Vector DB 선택지

### 옵션 비교

| DB | 특징 | Spring 연동 |
| --- | --- | --- |
| "Qdrant" | Rust 기반, 고성능, Docker 간편 | REST/gRPC 클라이언트 직접 사용 |
| "Weaviate" | GraphQL API, 스키마 기반 | REST 클라이언트 |
| "Pinecone" | 완전 관리형 SaaS | REST 클라이언트 |
| "pgvector" | PostgreSQL 확장, RDB와 통합 | Spring Data JPA + 커스텀 쿼리 |
| "Milvus" | 대규모 엔터프라이즈 | Java SDK |

Spring 프로젝트에서 빠르게 시작하기 좋은 선택은 두 가지입니다.

- "pgvector": 기존 PostgreSQL 인프라를 재사용 가능, JPA와 자연스럽게 통합
- "Qdrant": Vector 전용 DB가 필요할 때, Docker로 로컬 구동 용이

---

## 구현 방법 1 — pgvector + Spring Data JPA

### 개념

pgvector는 PostgreSQL의 확장(extension)으로, 기존 RDB 테이블에 `vector` 타입 컬럼을 추가하고 벡터 유사도 검색을 SQL로 수행할 수 있게 해줍니다. 별도 인프라 없이 기존 PostgreSQL 환경에서 바로 사용 가능합니다.

### 환경 설정

```yaml
# docker-compose.yml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: recommendation_db
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
```

```kotlin
// build.gradle.kts
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.postgresql:postgresql")
    // pgvector Java 클라이언트
    implementation("com.pgvector:pgvector:0.1.6")
    // 임베딩 생성을 위한 Spring AI (선택적)
    implementation("org.springframework.ai:spring-ai-openai-spring-boot-starter:1.0.0")
}
```

### 엔티티 설계

```kotlin
// PostgreSQL vector 타입을 위한 커스텀 타입 등록
@TypeDef(name = "vector", typeClass = VectorType::class)
@Entity
@Table(name = "products")
class Product(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    val name: String,
    val description: String,
    val category: String,

    // vector(1536) — OpenAI text-embedding-3-small 차원 수
    @Column(columnDefinition = "vector(1536)")
    @Type(type = "vector")
    var embedding: FloatArray? = null
)
```

```sql
-- 마이그레이션 (Flyway/Liquibase)
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE products (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    description TEXT,
    category   VARCHAR(100),
    embedding  vector(1536)
);

-- 유사도 검색 성능을 위한 인덱스 (HNSW 알고리즘)
CREATE INDEX ON products USING hnsw (embedding vector_cosine_ops);
```

### Repository 구현

```kotlin
interface ProductRepository : JpaRepository<Product, Long> {

    // 코사인 유사도 기반 상위 K개 조회 (네이티브 쿼리)
    @Query(
        value = """
            SELECT *, 
                   1 - (embedding <=> CAST(:embedding AS vector)) AS similarity
            FROM products
            WHERE id != :excludeId
            ORDER BY embedding <=> CAST(:embedding AS vector)
            LIMIT :limit
        """,
        nativeQuery = true
    )
    fun findSimilarProducts(
        @Param("embedding") embedding: String,  // "[0.1, 0.2, ...]" 형식 문자열
        @Param("excludeId") excludeId: Long,
        @Param("limit") limit: Int
    ): List<ProductSimilarityProjection>
}

// 유사도 값도 함께 반환하기 위한 Projection
interface ProductSimilarityProjection {
    val id: Long
    val name: String
    val description: String
    val category: String
    val similarity: Double
}
```

pgvector의 연산자 의미:

- `<=>` : 코사인 거리 (1 - 코사인 유사도), 값이 작을수록 유사
- `<->` : 유클리드 거리
- `<#>` : 음수 내적

### 임베딩 생성 서비스

```kotlin
@Service
class EmbeddingService(
    private val openAiClient: OpenAiEmbeddingClient  // Spring AI
) {

    fun generateEmbedding(text: String): FloatArray {
        val request = EmbeddingRequest(listOf(text), OpenAiEmbeddingOptions.builder()
            .withModel("text-embedding-3-small")
            .build()
        )
        val response = openAiClient.call(request)
        return response.results.first().output.map { it.toFloat() }.toFloatArray()
    }

    // 배치 처리 (다수 항목 임베딩 시 비용/속도 최적화)
    fun generateEmbeddings(texts: List<String>): List<FloatArray> {
        val request = EmbeddingRequest(texts, OpenAiEmbeddingOptions.builder()
            .withModel("text-embedding-3-small")
            .build()
        )
        return openAiClient.call(request).results
            .map { result -> result.output.map { it.toFloat() }.toFloatArray() }
    }
}
```

### 추천 서비스

```kotlin
@Service
@Transactional(readOnly = true)
class RecommendationService(
    private val productRepository: ProductRepository,
    private val embeddingService: EmbeddingService
) {

    // 특정 상품과 유사한 상품 추천
    fun findSimilarProducts(productId: Long, limit: Int = 10): List<RecommendationDto> {
        val product = productRepository.findById(productId)
            .orElseThrow { EntityNotFoundException("Product not found: $productId") }

        requireNotNull(product.embedding) { "Product has no embedding: $productId" }

        // FloatArray → pgvector 문자열 형식 변환 "[0.1, 0.2, ...]"
        val embeddingStr = product.embedding!!.joinToString(",", "[", "]")

        return productRepository.findSimilarProducts(
            embedding = embeddingStr,
            excludeId = productId,
            limit = limit
        ).map { RecommendationDto.from(it) }
    }

    // 텍스트 쿼리로 유사한 상품 검색
    fun searchByText(query: String, limit: Int = 10): List<RecommendationDto> {
        val queryEmbedding = embeddingService.generateEmbedding(query)
        val embeddingStr = queryEmbedding.joinToString(",", "[", "]")

        return productRepository.findSimilarProducts(
            embedding = embeddingStr,
            excludeId = -1L,  // 제외할 ID 없음
            limit = limit
        ).map { RecommendationDto.from(it) }
    }
}
```

### API 컨트롤러

```kotlin
@RestController
@RequestMapping("/api/recommendations")
class RecommendationController(
    private val recommendationService: RecommendationService
) {

    // 상품 ID 기반 연관 추천
    @GetMapping("/products/{id}/similar")
    fun getSimilarProducts(
        @PathVariable id: Long,
        @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<RecommendationDto>> {
        return ResponseEntity.ok(
            recommendationService.findSimilarProducts(id, limit)
        )
    }

    // 텍스트 검색 기반 추천
    @GetMapping("/products/search")
    fun searchSimilarProducts(
        @RequestParam query: String,
        @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<RecommendationDto>> {
        return ResponseEntity.ok(
            recommendationService.searchByText(query, limit)
        )
    }
}
```

---

## 구현 방법 2 — Spring AI + Qdrant (Vector DB 전용)

### 개념

Spring AI는 Spring 생태계에서 AI 기능을 통합하는 공식 프레임워크입니다. `VectorStore` 추상화를 제공하여 Qdrant, Pinecone, Redis 등 다양한 Vector DB를 동일한 인터페이스로 교체 가능하게 해줍니다.

### 환경 설정

```kotlin
// build.gradle.kts
dependencies {
    implementation("org.springframework.ai:spring-ai-qdrant-store-spring-boot-starter:1.0.0")
    implementation("org.springframework.ai:spring-ai-openai-spring-boot-starter:1.0.0")
}
```

```yaml
# application.yml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      embedding:
        options:
          model: text-embedding-3-small
    vectorstore:
      qdrant:
        host: localhost
        port: 6334
        collection-name: products
        initialize-schema: true  # 컬렉션 자동 생성
```

### Spring AI VectorStore 사용

```kotlin
@Service
class SpringAiRecommendationService(
    private val vectorStore: VectorStore,          // Spring AI 추상화
    private val embeddingModel: EmbeddingModel     // Spring AI 임베딩
) {

    // 상품 저장 시 임베딩 자동 생성 & Vector DB 저장
    fun saveProduct(product: Product) {
        val document = Document(
            id = product.id.toString(),
            content = "${product.name} ${product.description}",
            metadata = mapOf(
                "category" to product.category,
                "productId" to product.id,
                "name" to product.name
            )
        )
        // Spring AI가 내부적으로 임베딩 생성 후 Qdrant에 저장
        vectorStore.add(listOf(document))
    }

    // 유사 상품 검색
    fun findSimilar(productId: Long, topK: Int = 10): List<RecommendationDto> {
        // 대상 상품의 텍스트로 쿼리
        val targetDoc = vectorStore.similaritySearch(
            SearchRequest.query("product:$productId").withTopK(1)
        ).firstOrNull() ?: return emptyList()

        // 해당 상품 제외하고 유사 상품 검색
        return vectorStore.similaritySearch(
            SearchRequest
                .query(targetDoc.content)
                .withTopK(topK + 1)
                .withSimilarityThreshold(0.7)  // 유사도 0.7 이상만
                .withFilterExpression("productId != $productId")
        )
        .filter { it.metadata["productId"] != productId }
        .take(topK)
        .map { RecommendationDto.fromDocument(it) }
    }
}
```

---

## 임베딩 생성 전략

### 초기 데이터 벌크 임베딩

상품이 이미 DB에 대량으로 있는 경우, 배치 작업으로 임베딩을 일괄 생성해야 합니다.

```kotlin
@Component
class EmbeddingBatchJob(
    private val productRepository: ProductRepository,
    private val embeddingService: EmbeddingService
) {

    // Spring Batch 또는 @Scheduled로 실행
    @Transactional
    fun generateMissingEmbeddings() {
        val batchSize = 100
        var page = 0

        while (true) {
            // 임베딩이 없는 상품만 조회
            val products = productRepository.findByEmbeddingIsNull(
                PageRequest.of(page++, batchSize)
            )
            if (products.isEmpty) break

            // 텍스트 추출
            val texts = products.content.map { "${it.name} ${it.description}" }

            // 배치 임베딩 생성 (API 호출 횟수 최소화)
            val embeddings = embeddingService.generateEmbeddings(texts)

            // 저장
            products.content.forEachIndexed { i, product ->
                product.embedding = embeddings[i]
            }
            productRepository.saveAll(products.content)

            log.info("Processed ${page * batchSize} products")
        }
    }
}
```

### 신규 데이터 실시간 임베딩

```kotlin
@Service
class ProductService(
    private val productRepository: ProductRepository,
    private val embeddingService: EmbeddingService
) {

    @Transactional
    fun createProduct(request: ProductCreateRequest): ProductResponse {
        val product = Product(
            name = request.name,
            description = request.description,
            category = request.category
        )

        // 저장 후 임베딩 비동기 생성 (응답 지연 방지)
        val saved = productRepository.save(product)
        generateEmbeddingAsync(saved.id)

        return ProductResponse.from(saved)
    }

    @Async
    fun generateEmbeddingAsync(productId: Long) {
        val product = productRepository.findById(productId).orElseReturn { return }
        val text = "${product.name} ${product.description}"
        product.embedding = embeddingService.generateEmbedding(text)
        productRepository.save(product)
    }
}
```

---

## 성능 최적화 포인트

### 캐싱 전략

임베딩 API 호출은 비용이 발생하고 외부 네트워크 의존적이므로, 동일 텍스트에 대한 중복 호출을 방지해야 합니다.

```kotlin
@Service
class CachedEmbeddingService(
    private val embeddingService: EmbeddingService
) {

    @Cacheable(value = ["embeddings"], key = "#text.hashCode()")
    fun getEmbedding(text: String): FloatArray {
        return embeddingService.generateEmbedding(text)
    }
}
```

### 인덱스 선택 (pgvector 기준)

```sql
-- HNSW: 검색 속도 빠름, 메모리 사용 많음 (운영 환경 권장)
CREATE INDEX ON products USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- IVFFlat: 메모리 효율적, 빌드 시 lists 값 중요
-- lists 값 = 총 row 수 / 1000 (일반적 권장)
CREATE INDEX ON products USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

### 임베딩 차원 축소

비용과 속도를 위해 더 작은 차원의 임베딩 모델을 선택하거나, Matryoshka 임베딩(차원을 잘라 사용하는 기법)을 활용할 수 있습니다.

| 모델 | 차원 | 특징 |
| --- | --- | --- |
| `text-embedding-3-small` | 1536 | 비용 저렴, 한국어 지원 |
| `text-embedding-3-large` | 3072 | 고정밀, 비용 높음 |
| `text-embedding-ada-002` | 1536 | 구세대, 하위 호환 |

---

## 전체 요약

| 항목 | 내용 |
| --- | --- |
| 핵심 원리 | 텍스트 → 임베딩(벡터) 변환 후, 벡터 공간에서 코사인 유사도로 유사 항목 탐색 |
| pgvector 방식 | 기존 PostgreSQL에 확장 추가, JPA 네이티브 쿼리로 `<=>` 연산자 사용 |
| Spring AI 방식 | `VectorStore` 추상화로 Qdrant 등 연동, DB 교체가 유연 |
| 임베딩 생성 | 초기 데이터는 배치 처리, 신규 데이터는 `@Async` 비동기 생성 |
| 성능 | HNSW 인덱스, 캐싱, 배치 임베딩 API 호출로 최적화 |
| 유사도 임계값 | 0.7 이상(코사인)을 기준으로 "관련 없는" 결과 필터링 권장 |