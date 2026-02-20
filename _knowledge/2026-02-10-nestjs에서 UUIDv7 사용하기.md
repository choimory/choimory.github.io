---
title: "nestjs에서 UUIDv7 사용하기"
date: 2026-02-10T00:00:00
toc: true
toc_sticky: true
categories:
    - Node.js
tags:
    - Nest.js
---

# npm

```tsx
npm install uuid
```

- npm install uuid

# import v7

```tsx
import { v7 as uuid } from 'uuid';

export class classname{
	...
}
```

- import할때 원하는 버전을 선택해서 임포트하는 형식이다

# generate uuid

```tsx
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
  memberSuspension?: MemberSuspension;

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
    memberSuspension?: MemberSuspension,
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

- @beforeinsert로 uuidv7을 생성하여 넣을수 있다
- `@PrimaryGeneratedColumn('uuid')`으로 uuid 생성이 가능하긴 한데 v4로 생성되기 때문에 시간 정렬이 미지원이다
- postgres는 uuid컬럼을 지원하지만 해당 db만 지원하는 기능이므로, db기능에 의존하기가 내키지 않아서 코드로 풀었다

# uuid pipe

```tsx
@Controller('member')
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  @Get(':id')
  async find(@Param('id', new ParseUUIDPipe()) id: string) {
		...
	}
  
  ...
}
```

- @ParseUUIDPipe
- 사용시 uuid 포맷의 문자열만 허용된다