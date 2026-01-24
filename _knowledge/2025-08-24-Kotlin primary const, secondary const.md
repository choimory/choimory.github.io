---
title: "Kotlin primary const, secondary const"
date: 2025-08-24T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - JVM
    - Kotlin
---

# primary

Kotlin 클래스에서 가장 일반적으로 사용되는 생성자

클래스 헤더에 직접 선언되며, 클래스를 인스턴스화할 때 가장 먼저 실행되는 초기화 로직을 담당

```kotlin
class User(val name: String, var age: Int = 30) { // name은 필수, age는 기본값 30
    init {
        println("User 객체 생성: 이름 - $name, 나이 - $age")
    }
}

fun main() {
    val user1 = User("김철수") // name만 제공, age는 30
    val user2 = User("박영희", 25) // name과 age 모두 제공
}
```

- 클래스 이름 뒤 괄호 `()` 안에 선언
- 클래스 선언과 동시에 프로퍼티를 선언하고 초기화할 수 있어 코드가 매우 간결해짐
- 주 생성자는 필수가 아님
- 만약 주 생성자가 없으면, 매개변수가 없는 기본 생성자(no-argument constructor)가 자동으로 생성
- 주 생성자에는 직접적인 코드 블록이 없음
- 초기화 로직이 필요하다면 `init` 블록을 사용해야 함. `init` 블록은 주 생성자 다음에 실행
- 주 생성자의 매개변수에 기본값을 지정하여, 해당 매개변수를 생략하고도 객체를 생성할 수 있게 할 수 있음

# secondary

보조 생성자는 `constructor` 키워드를 사용하여 클래스 본문 내부에 선언

주로 다양한 방식으로 객체를 생성해야 할 때 사용

```kotlin
class Product(val name: String, val price: Double) { // 주 생성자

    var quantity: Int = 0

    // 보조 생성자 1: 이름과 가격만으로 생성 (수량은 0으로 초기화)
    constructor(name: String, price: Double, initialQuantity: Int) : this(name, price) {
        this.quantity = initialQuantity
        println("Product 객체 생성 (이름, 가격, 수량): $name, $price, $initialQuantity")
    }

    // 보조 생성자 2: 이름만으로 생성 (가격은 0.0, 수량은 0으로 초기화)
    constructor(name: String) : this(name, 0.0) { // 주 생성자 호출
        println("Product 객체 생성 (이름): $name")
    }
}

fun main() {
    val product1 = Product("노트북", 1200.0) // 주 생성자 사용
    val product2 = Product("마우스", 25.0, 100) // 보조 생성자 1 사용
    val product3 = Product("키보드") // 보조 생성자 2 사용
}
```

- 클래스 본문 `{}` 안에 `constructor` 키워드와 함께 선언
- 하나의 클래스에 여러 개의 보조 생성자를 가질 수 있음. (매개변수 시그니처가 달라야 함)
- 만약 클래스에 주 생성자가 있다면, 모든 보조 생성자는 직접 또는 간접적으로 주 생성자를 호출해야 함
이는 `: this(...)` 구문을 사용하여 이루어짐
주 생성자가 없다면, 보조 생성자는 주 생성자를 호출할 필요가 없음
- 특정 필드만 초기화하거나, 외부 데이터를 가공하여 객체를 생성하는 등 복잡한 초기화 로직에 유용

# Kotlin 생성자로 원하는 필드만 초기화하여 생성하기

```kotlin
class Person(val name: String, val age: Int = 30, val city: String? = null) {
    // name은 반드시 초기화해야 함
    // age는 초기화하지 않으면 30이 됨
    // city는 초기화하지 않으면 null이 됨
}

fun main() {
    val person1 = Person("김철수") // name만 초기화, age는 30, city는 null
    println("이름: ${person1.name}, 나이: ${person1.age}, 도시: ${person1.city}")

    val person2 = Person("박영희", age = 25) // name과 age 초기화, city는 null
    println("이름: ${person2.name}, 나이: ${person2.age}, 도시: ${person2.city}")

    val person3 = Person("이지은", city = "서울") // name과 city 초기화, age는 30
    println("이름: ${person3.name}, 나이: ${person3.age}, 도시: ${person3.city}")
}
```

- 생성자로 초기화를 생략하고 싶은 필드에 기본값이 지정되어 있어야 생성자에서 생략 가능

# 요약

- 주 생성자: 대부분의 경우 주 생성자를 사용하는 것이 좋습니다. 간결하고 명시적이며, 기본값 지정을 통해 유연성을 확보할 수 있음.
- 보조 생성자: 객체 생성 방식이 다양하거나, 복잡한 초기화 로직이 필요할 때 보조 생성자를 고려합니다. 단, 주 생성자가 있다면 반드시 주 생성자를 호출해야 함
- Kotlin은 주 생성자를 통해 간결한 코드 작성을 장려하며, 보조 생성자는 특정 상황에서 유연성을 더해주는 역할을 함