---
title: "Thread safety란"
date: 2026-05-20T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Thread
---

# Thread safety란

- **Thread safety**는 멀티쓰레드 환경에서 여러 쓰레드가 동시에 공유 자원에 접근하더라도 데이터 일관성을 유지하고, 예기치 않은 결과가 발생하지 않도록 하는 것.

# 동기화 메소드, 동기화 블록 사용

## **동기화 메서드(Synchronized Method)**:

- 메서드 전체를 동기화하여, 한 번에 하나의 쓰레드만 메서드를 실행할 수 있도록 보장함.
- 사용 예:
    
    ```java
    public synchronized void increment() {
        count++;
    }
    ```
    

## **동기화 블록(Synchronized Block)**:

- 메서드의 일부 코드 블록만 동기화하여, 특정 코드만 한 번에 하나의 쓰레드만 실행할 수 있도록 함. 더 세밀한 동기화 제어가 가능함.
- 사용 예:
    
    ```java
    public void increment() {
        synchronized (this) {
            count++;
        }
    }
    ```
    

---

# volatile 키워드 사용

- `volatile` 키워드는 변수의 값을 메인 메모리에서 읽고 쓰도록 보장하여, 변수에 대한 모든 쓰레드의 접근이 항상 최신 상태로 유지되도록 함.
- 쓰레드 간의 **메모리 가시성 문제**를 해결하는 데 사용됨.
- 사용 예:
    
    ```java
    private volatile boolean running = true;
    ```
    

# Atomic 클래스 사용

- `AtomicInteger`, `AtomicLong`, `AtomicReference`와 같은 **Atomic 클래스**들은 원자적 연산(atomic operation)을 제공하여 동기화 없이도 스레드 안전성을 보장함.
- 이러한 클래스는 내부적으로 **CAS(Compare-And-Swap)** 연산을 사용하여, 멀티쓰레드 환경에서 안전하게 값을 변경할 수 있음.
- 사용 예:
    
    ```java
    AtomicInteger count = new AtomicInteger(0);
    count.incrementAndGet();  // 스레드 안전한 증가 연산
    ```
    

---

# java.util.concurrent 패키지 사용

- `java.util.concurrent` 패키지는 멀티쓰레드 프로그래밍을 지원하는 다양한 클래스를 제공함.
- 이를 통해 **쓰레드 안전한 컬렉션**(`ConcurrentHashMap`, `CopyOnWriteArrayList` 등)이나 **락(Lock)**을 사용하여 안전한 멀티쓰레드 프로그래밍을 구현할 수 있음.
- 사용 예:
    
    ```java
    ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();
    ```
    

## **Lock 사용**:

- `ReentrantLock`, `ReadWriteLock` 등을 사용하여, 동기화 블록보다 더 유연한 락 제어를 할 수 있음. 이를 통해 쓰레드 안전성을 보장하고, 특히 읽기/쓰기가 빈번히 혼합되는 환경에서 성능 최적화를 이룰 수 있음.
- 사용 예:
    
    ```java
    ReentrantLock lock = new ReentrantLock();
    
    public void increment() {
        lock.lock();
        try {
            count++;
        } finally {
            lock.unlock();
        }
    }
    ```
    

---

# 불변 객체 사용

- *불변 객체(Immutable Object)*는 상태가 한 번 설정되면 변경되지 않기 때문에, 여러 쓰레드가 동시에 접근하더라도 안전함.
- 모든 필드를 `final`로 선언하고, 생성자에서만 값을 설정하며, setter 메서드를 제공하지 않음으로써 객체를 불변으로 만들 수 있음.
- 사용 예:
    
    ```java
    public final class ImmutableData {
        private final int value;
    
        public ImmutableData(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    ```