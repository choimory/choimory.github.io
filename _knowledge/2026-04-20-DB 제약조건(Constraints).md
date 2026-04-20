---
title: "DB 제약조건(Constraints)"
date: 2026-04-20T00:00:00
toc: true
toc_sticky: true
categories:
    - DB
tags:
    - Constraints
---

# DB 제약조건(Constraints)에는 어떤 종류가 있는가

- 데이터베이스에서 **제약조건(Constraints)**은 **데이터의 무결성**을 유지하고, **데이터의 일관성**을 보장하기 위해 테이블에 설정하는 규칙이다.
- 제약조건을 통해 테이블에 입력되는 데이터를 제한하거나, 데이터베이스의 논리적 일관성을 유지할 수 있다.

---

# 제약조건의 종류

## **PRIMARY KEY (기본키 제약조건)**:

- 기본키는 테이블에서 각 행을 **유일하게 식별**하는 하나 이상의 컬럼에 설정되는 제약조건이다.
- 기본키는 **중복**을 허용하지 않으며, 반드시 **NULL 값을 가질 수 없다**.
- **사용 예**: 고객 테이블에서 각 고객을 고유하게 식별하기 위해 `customer_id`를 기본키로 설정.
    
    ```sql
    CREATE TABLE customers (
      customer_id INT PRIMARY KEY,
      customer_name VARCHAR(100)
    );
    ```
    

## **FOREIGN KEY (외래키 제약조건)**:

- 외래키는 **다른 테이블의 기본키나 고유 키**를 참조하여 테이블 간의 관계를 설정한다.
- 외래키는 참조하는 테이블에 존재하는 값을 가져와야 하며, 이를 통해 **참조 무결성**을 유지한다.
- **사용 예**: 주문 테이블에서 `customer_id`가 고객 테이블의 `customer_id`를 참조.
    
    ```sql
    CREATE TABLE orders (
      order_id INT PRIMARY KEY,
      customer_id INT,
      order_date DATE,
      FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    );
    ```
    

## **UNIQUE (고유 제약조건)**:

- UNIQUE 제약조건은 특정 열의 값이 **고유**해야 함을 보장한다.
- 한 테이블에서 동일한 값을 가질 수 없지만, **NULL 값은 허용**될 수 있다.
- **사용 예**: 이메일 주소가 중복되지 않도록 `email` 열에 UNIQUE 제약조건을 설정.
    
    ```sql
    CREATE TABLE users (
      user_id INT PRIMARY KEY,
      email VARCHAR(100) UNIQUE
    );
    ```
    

## **NOT NULL (널 불허 제약조건)**:

- NOT NULL 제약조건은 해당 열이 **NULL 값을 가질 수 없도록** 설정한다.
- 즉, 반드시 값이 입력되어야 한다.
- **사용 예**: 사용자 이름은 반드시 입력되어야 하도록 `name` 열에 NOT NULL 제약조건을 설정.
    
    ```sql
    CREATE TABLE users (
      user_id INT PRIMARY KEY,
      name VARCHAR(100) NOT NULL
    );
    ```
    

## **CHECK (조건 제약조건)**:

- CHECK 제약조건은 열의 값이 **특정 조건**을 만족해야 함을 보장한다.
- 값을 삽입하거나 업데이트할 때 이 조건을 검사하여 유효하지 않은 데이터를 방지할 수 있다.
- **사용 예**: 나이가 0보다 커야 한다는 조건을 설정.
    
    ```sql
    CREATE TABLE employees (
      employee_id INT PRIMARY KEY,
      age INT CHECK (age > 0)
    );
    ```
    

## **DEFAULT (기본값 제약조건)**:

- DEFAULT 제약조건은 특정 열에 **기본값**을 설정하여, 사용자가 값을 입력하지 않았을 경우 자동으로 이 기본값을 사용하도록 한다.
- **사용 예**: 주문 상태가 입력되지 않으면 자동으로 'pending'으로 설정.
    
    ```sql
    CREATE TABLE orders (
      order_id INT PRIMARY KEY,
      order_status VARCHAR(20) DEFAULT 'pending'
    );
    ```
    

---

# 정리

- 제약조건은 데이터의 **무결성**과 **일관성**을 유지하는 중요한 도구다.
- 각 제약조건은 특정 목적을 위해 사용되며, 기본키와 외래키는 테이블 간의 관계를 정의하고, UNIQUE, NOT NULL, CHECK, DEFAULT와 같은 제약조건은 개별 컬럼의 유효성을 검사하는 데 사용된다.
- 이를 통해 데이터베이스는 신뢰성 있고 오류가 없는 데이터를 저장할 수 있다.