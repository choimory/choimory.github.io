---
title: "TypeORM Synchronized 스네이크 케이스로 생성하기"
date: 2026-03-16T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - TypeORM
---

# TypeORM Synchronized 스네이크 케이스로 생성하기

- synchronize: true로 테이블을 생성할 때, 기본적으로 엔터티 클래스의 필드 이름은 camelCase로 정의되며, 이는 데이터베이스에서도 그대로 적용된다.
- 그러나 데이터베이스 컬럼 이름을 snake_case로 변환하려면 TypeORM에서 제공하는 설정을 사용하면 된다.

# 해결 방법: namingStrategy 사용

TypeORM의 DefaultNamingStrategy 대신 SnakeNamingStrategy를 사용하면 컬럼 이름을 자동으로 snake_case로 변환할 수 있다.

### 1. SnakeNamingStrategy 설치

먼저 typeorm-naming-strategies 패키지를 설치한다.

```bash
npm install typeorm-naming-strategies
```

### 2. SnakeNamingStrategy 설정

SnakeNamingStrategy를 설정 파일에 적용한다.

```tsx
import { DataSource } from 'typeorm';
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';

const dataSource = new DataSource({
  type: 'mysql', // 또는 'postgres'
  host: 'localhost',
  port: 3306,
  username: 'root',
  password: 'password',
  database: 'test',
  entities: [__dirname + '/**/*.entity{.ts,.js}'],
  synchronize: true, // 개발 환경에서만 사용
  namingStrategy: new SnakeNamingStrategy(),
});

export default dataSource;
```

### 3. SnakeNamingStrategy를 사용하면 자동 변환

이제 엔터티에서 camelCase로 작성된 필드가 데이터베이스에서 snake_case로 변환된다.

```tsx
import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  firstName: string;

  @Column()
  lastName: string;
}
```

위 코드는 다음과 같은 테이블로 변환된다.

| id | first_name | last_name |
| --- | --- | --- |

# 요약

- typeorm-naming-strategies의 SnakeNamingStrategy를 사용하면 camelCase 필드를 snake_case 컬럼으로 변환할 수 있다.
- namingStrategy 옵션을 SnakeNamingStrategy로 설정하면 자동으로 처리된다.