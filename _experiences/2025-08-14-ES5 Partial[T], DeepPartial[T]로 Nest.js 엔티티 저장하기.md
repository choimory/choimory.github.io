---
title: "ES5 Partial<T>, DeepPartial<T>로 Nest.js 엔티티 저장하기"
date: 2025-08-14T00:00:00
toc: true
toc_sticky: true
categories:
    - Back-end
tags:
    - Node.js
    - TypeScript
---

# 개요

- Partial<T>은 원하는 프로퍼티만 선택적으로 초기화를 하며 객체를 생성하게 해주는 유틸리티 타입
- 클래스 객체를 생성할때, 생성자로 생성하면 모든 프로퍼티를 초기화해야한다
- 원하는 프로퍼티만 선택적으로 초기화를 하기 위해, ?를 프로퍼티에 지정할 수 도 있지만 Partial<T>를 이용할 수 도 있다
- Partial<T>로 생성한 객체는, 클래스의 인스턴스가 아닌 객체 리터럴이다
- 중첩된 객체까지 Partial하게 생성할땐 DeepPartial<T>를 사용한다

# 변경 전

```tsx
import { CreateDateColumn, DeleteDateColumn, UpdateDateColumn } from 'typeorm';

export abstract class CommonTime {
  @CreateDateColumn({ type: 'timestamp', nullable: false })
  createdAt?: Date;

  @UpdateDateColumn({ type: 'timestamp', nullable: true })
  modifiedAt?: Date;

  @DeleteDateColumn({ type: 'timestamp', nullable: true })
  deletedAt?: Date;

  protected constructor(createdAt?: Date, modifiedAt?: Date, deletedAt?: Date) {
    this.createdAt = createdAt;
    this.modifiedAt = modifiedAt;
    this.deletedAt = deletedAt;
  }
}

---

import {
  BeforeInsert,
  Column,
  Entity,
  OneToMany,
  PrimaryColumn,
} from 'typeorm';
import { CommonTime } from '../../common/entities/common-time.entity';
import { v7 as uuid } from 'uuid';
import { MemberSuspension } from './member-suspension.entity';

@Entity()
export class Member extends CommonTime {
  @PrimaryColumn('uuid')
  id?: string;

  @Column({ unique: true, nullable: false })
  email: string;

  @Column({ unique: true, nullable: false })
  nickname: string;

  @Column({ nullable: false })
  password: string;

  @Column({ nullable: true })
  image?: string;

  @Column({ nullable: true })
  introduce?: string;

  @OneToMany(
    () => MemberSuspension,
    (memberSuspension) => memberSuspension.member,
  )
  memberSuspension?: MemberSuspension;

  constructor(
    email: string,
    nickname: string,
    password: string,
    id?: string,
    image?: string,
    introduce?: string,
    memberSuspension?: MemberSuspension,
    createdAt?: Date,
    modifiedAt?: Date,
    deletedAt?: Date,
  ) {
    super(createdAt, modifiedAt, deletedAt);
    this.id = id;
    this.email = email;
    this.nickname = nickname;
    this.password = password;
    this.image = image;
    this.introduce = introduce;
    this.memberSuspension = memberSuspension;
  }

  @BeforeInsert()
  beforeInsert() {
    this.id = uuid();
  }
}

```

- 엔티티

```tsx
async join(payload: JoinMemberRequestDto) {
    return;
  async join(payload: JoinMemberRequestDto): Promise<CommonResponseDto> {
    // bcrypt
    const hashed: string = await bcrypt.hash(
      payload.password,
      await bcrypt.genSalt(),
    );

    // payload to entity
    const member: Member = new Member(payload.email, payload.nickname, hashed);

    // transaction and save
    return await this.dataSource.transaction(async (manager) => {
      const result: Member = await manager.save(member);

      // return
      return new CommonResponseDto(
        HttpStatus.CREATED,
        HttpStatus[HttpStatus.CREATED],
        { id: result.id, nickname: result.nickname, email: result.email },
      );
    });
  }
```

- 로직

# Partial<T>로 변경

```tsx
import { CreateDateColumn, DeleteDateColumn, UpdateDateColumn } from 'typeorm';

export abstract class CommonTime {
  @CreateDateColumn({ type: 'timestamp', nullable: false })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamp', nullable: true })
  modifiedAt: Date;

  @DeleteDateColumn({ type: 'timestamp', nullable: true })
  deletedAt: Date;

  protected constructor(createdAt: Date, modifiedAt: Date, deletedAt: Date) {
    this.createdAt = createdAt;
    this.modifiedAt = modifiedAt;
    this.deletedAt = deletedAt;
  }
}

---

import { Column, Entity, OneToMany, PrimaryColumn } from 'typeorm';
import { CommonTime } from '../../common/entities/common-time.entity';
import { MemberSuspension } from './member-suspension.entity';

@Entity()
export class Member extends CommonTime {
  @PrimaryColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: false })
  email: string;

  @Column({ unique: true, nullable: false })
  nickname: string;

  @Column({ nullable: false })
  password: string;

  @Column({ nullable: true })
  image: string;

  @Column({ nullable: true })
  introduce: string;

  @OneToMany(
    () => MemberSuspension,
    (memberSuspension) => memberSuspension.member,
  )
  memberSuspension: MemberSuspension;

  constructor(
    createdAt: Date,
    modifiedAt: Date,
    deletedAt: Date,
    id: string,
    email: string,
    nickname: string,
    password: string,
    image: string,
    introduce: string,
    memberSuspension: MemberSuspension,
  ) {
    super(createdAt, modifiedAt, deletedAt);
    this.id = id;
    this.email = email;
    this.nickname = nickname;
    this.password = password;
    this.image = image;
    this.introduce = introduce;
    this.memberSuspension = memberSuspension;
  }
}

```

- 엔티티
- 매우 간결해짐

```tsx
async join(payload: JoinMemberRequestDto): Promise<CommonResponseDto> {
    // bcrypt
    const hashed: string = await bcrypt.hash(
      payload.password,
      await bcrypt.genSalt(),
    );

    // payload to entity
    const partial: Partial<Member> = {
      id: uuid(),
      email: payload.email,
      nickname: payload.nickname,
      password: hashed,
    };

    // transaction and save
    return await this.dataSource.transaction(async (manager) => {
      const result: Partial<Member> = await manager.save(Member, partial);

      // return
      return new CommonResponseDto(
        HttpStatus.CREATED,
        HttpStatus[HttpStatus.CREATED],
        { id: result.id, nickname: result.nickname, email: result.email },
      );
    });
  }
```

- 로직
- save부분에 Partial<Member>객체만 넘겨서 객체 리터럴을 사용하면, 타입을 인식하지 못하기 때문에 앞에 타입을 명시해줘야 한다
    - manager.save(partial) → manager.save(Member, partial)

# DeepPartial<T>로 변경

중첩된 객체형식의 프로퍼티도 Partial하게 생성하고 싶을땐, Partial<T> 대신 DeepPartial<T>를 이용할 수 있다

```tsx
// Partial<T> to DeepPartial<T>
const member: DeepPartial<Member> = {
      id: uuid(),
      email: payload.email,
      nickname: payload.nickname,
      password: hashed,
      memberSuspension: [{ id: uuid(), reason: 'test' }],
    };

  // transaction and save
  return await this.dataSource.transaction(async (manager) => {
    const result: DeepPartial<Member> = await manager.save(Member, member);

    // return
    return new CommonResponseDto(
    HttpStatus.CREATED,
    HttpStatus[HttpStatus.CREATED],
    { id: result.id, nickname: result.nickname, email: result.email },
  );
```

- 엔티티 DeepPartial<T>로 자식까지 저장할때는, 부모쪽에서 자식의 cascade가 설정되어야 같이 insert 된다