---
title: "Querydsl Projections"
date: 2022-07-28T00:00:00
toc: true
toc_sticky: true
categories: 
    - Back-end
tags:
    - JVM
    - Querydsl
---

# 개요

- 기본적으로 JPA 엔티티에는 Hibernate 1차 캐싱 등이 걸려있어 엔티티를 그대로 다룰시 성능하락이 있을수 있습니다.
- 때문에 특별한 상황이 아닌 단순한 상황에서는, 엔티티를 별도의 객체로 바로 변환하여 해당 객체를 이용하는게 성능상 이득이 있습니다
- 또한 조회할때 필요한 컬럼만 select하여 조회하는것도 성능 상승에 아주 큰 요소가 됩니다
- Querydsl의 Projections는 위의 두 문제를 처리해주는 기능입니다

# Querydsl Projections을 권장한다

- 기본 엔티티를 넘기는것보다 Projections를 통해 매핑한 DTO 등의 객체를 넘기는것을 권장합다.
    - 이는 서비스단에서 매핑 작업을 추가적으로 거치는것보다 성능상으로 이득이 있기 때문입니다.
        - 필요한 컬럼만 조회할 수 있다는 점.
        - 엔티티를 건내면 Hibernate 1차 캐싱이 적용되어 성능이 하락되므로, 엔티티 대신 DTO로 바로 건내주는것에 이득이 있다.

# Querydsl Projections의 종류

- Projections에는 constructor, fields, bean 세가지가 존재하며 각각의 유의사항이 있습니다.

## Projections.constructor

- 생성자를 통해 객체를 생성합니다
- 주의사항: 생성자를 빌더패턴으로 적용하였다 하더라도 특정 필드만 초기화하는것이 불가능합니다.
    - Projections.constructor()를 통해 특정 필드만 초기화하고 싶을시, 해당 필드들을 넘겨받는 생성자를 선언해야 합니다.
        - 상황에 따라 동적으로 하고 싶을땐 케이스별로 모든 생성자가 있어야 합니다. 빌더로는 불가능.
    - 결국 Projections.constructor()를 통해 동적으로 원하는 필드만 주입하는것이 사실상 매우 번거롭기 때문에 전체 필드를 초기화하는 경우에만 사용합니다.

```java
@Builder
@RequiredArgsConstructor
@Getter
public class MemberDto {
    private final int id;
    private final String name;
    private final int age;
    private final Double height;
    private final Double weight;
}

@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
    
  public List<MemberDto> selectMembers() {
    return query.select(Projections.constructor(MemberDto.class,
                    member.id,
                    member.name,
                    member.age,
                    member.height,
                    member.weight))
            .from(member)
            .fetch();
  }
}
```

## Projections.fields

- 객체 생성 후, 초기화 된 필드에 2차적으로 값을 직접 주입합니다
- 주의사항: 기본적으로 객체를 생성 한 뒤, 필드에 직접 값을 주입하기 때문에, 필드가 final 변수일시 값 주입이 불가능합니다.
    - 때문에 fields()를 사용할 객체는 final 변수 + 필수 생성자를 사용할 수 없고, 일반 변수 + 기본 생성자 + 전체 생성자로 설계해야합니다
    - field에 직접 접근하지만 접근제어자가 private인것은 문제되지 않습니다.

```java
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Getter
public class MemberDto {
    private int id;
    private String name;
    private int age;
    private Double height;
    private Double weight;
}

@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
    
  public List<MemberDto> selectMembers() {
    return query.select(Projections.fields(MemberDto.class,
                    member.id,
                    member.name,
                    member.age,
                    member.height,
                    member.weight))
            .from(member)
            .fetch();
  }
}
```

## Projections.bean

- 객체 생성 후, 초기화 된 필드에 2차적으로 setter를 통해 값을 주입합니다
- 주의사항: 필드가 final 변수일시 값 주입이 불가능하며, setter 메소드도 존재해야 합니다.
    - 때문에 bean()을 사용할 객체는 final 변수 + 필수 생성자를 사용할 수 없고, 일반 변수 + 기본 생성자 + 전체 생성자에 setter도 마련하도록 설계해야합니다

```java
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Setter
@Getter
public class MemberDto {
    private int id;
    private String name;
    private int age;
    private Double height;
    private Double weight;
}

@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
    
  public List<MemberDto> selectMembers() {
    return query.select(Projections.bean(MemberDto.class,
                    member.id,
                    member.name,
                    member.age,
                    member.height,
                    member.weight))
            .from(member)
            .fetch();
  }
}
```

## as()

- 매핑할 객체의 필드와 엔티티의 필드의 이름이 동일해야 하며, 다를시 .as()를 통해 매핑할 객체의 필드에 맞춰주면 됩니다.

```java
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Getter
public class MemberDto {
    private int id;
    private String memberName;
    private int memberAge;
    private Double memberHeight;
    private Double memberWeight;
}

@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
    
  public List<MemberDto> selectMembers() {
    return query.select(Projections.fields(MemberDto.class,
                    member.id,
                    member.name.as("memberName"),
                    member.age.as("memberAge"),
                    member.height.as("memberHeight"),
                    member.weight.as("memberWeight")))
            .from(member)
            .fetch();
  }
}
```

## @QueryProjection 객체 만들기

- 생성자에 @QueryProjection을 부여해 DTO QClass를 생성하여, Projections를 대신할 수도 있습니다.
- final 변수를 동적으로 생성할 수 있으므로 constructor()와 fields()의 장점을 모두 취한다고 할 수 있습니다.
- 하지만 Querydsl에 의존성이 생기는 객체가 되므로 유의합니다.

```java
@Builder
@Getter
public class MemberDto {
    private final int id;
    private final String name;
    private final int age;
    private final Double height;
    private final Double weight;
    
    @Builder
    @QueryProjection
    public MemberDto (int id, String name, int age, Double height, Double weight){
        this.id = id;
        this.name = name;
        this.age = age;
        this.height = height;
        this.weight = weight;
    }
}

@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
    
  public List<MemberDto> selectMembers() {
    return query.select(new QMemberDto(member.name, member.age))
            .from(member)
            .fetch();
  }
}
```

## 단일 컬럼만 조회해서 리턴하기

```java
@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;

  @Override
  public List<String> findIdentityByMembersId(List<Integer> membersId) {
    return query.select(Projections.constructor(String.class, 
            member.identity))
            .from(member)
            .where(member.id.in(membersId))
            .limit(size)
            .fetch();
  }
}
```

- 단일 컬럼만 조회하여 해당 타입을 리턴할때 주의할 점은, 래퍼 클래스의 특징을 고려했을때 Projections.fields 대신 constructor를 사용해야 한다는것

## DTO 안의 객체에 매핑하기

- `MemberDto`내의 `MemberAuthorityDto` 필드를 매핑해봅니다

```java
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
public class MemberDto {
  private Long id;
  private String identity;
  private String nickname;
  private String email;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime createdAt;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime modifiedAt;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime deletedAt;
  private MemberAuthorityDto memberAuthority;
  private List<MemberSocialDto> memberSocials;
  private List<MemberSuspensionDto> memberSuspensions;

  @Builder
  @NoArgsConstructor
  @AllArgsConstructor
  @Getter
  public static class MemberAuthorityDto {
    private AuthLevel authLevel;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime createdAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime modifiedAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime deletedAt;
  }
}
```

```java
@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;

  @Override
  public List<MemberDto> findAllNoOffset(int lastId, int size, String identity, String nickname, String email, AuthLevel authLevel, LocalDateTime createdFrom, LocalDateTime createdTo, LocalDateTime modifiedFrom, LocalDateTime modifiedTo, LocalDateTime deletedFrom, LocalDateTime deletedTo) {
    return query.select(Projections.fields(MemberDto.class,
            member.identity,
            Projections.fields(MemberDto.MemberAuthorityDto.class,
                    memberAuthority.authLevel).as("memberAuthority")))
            .from(member)
            .innerJoin(member.memberAuthority, memberAuthority)
            .where(gtId(lastId),
                    eqIdentity(identity),
                    containsNickname(nickname),
                    containsEmail(email),
                    eqAuthLevel(authLevel),
                    betweenCreatedAt(createdFrom, createdTo),
                    betweenModifiedAt(modifiedFrom, modifiedTo),
                    betweenDeletedAt(deletedFrom, deletedTo))
            .limit(size)
            .fetch();
  }
}
```

- Projections 안에 추가로 Projections를 넣어주고 as로 필드명과 동일한 alias를 지정해주면 됩니다

## DTO 안의 컬렉션 객체에 매핑하기

- `MemberDto`내의 `List<MemberSocialDto>` 필드를 매핑해봅니다

```java
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
public class MemberDto {
  private Long id;
  private String identity;
  private String nickname;
  private String email;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime createdAt;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime modifiedAt;
  @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
  private LocalDateTime deletedAt;
  private MemberAuthorityDto memberAuthority;
  private List<MemberSocialDto> memberSocials;
  private List<MemberSuspensionDto> memberSuspensions;

  @Builder
  @NoArgsConstructor
  @AllArgsConstructor
  @Getter
  @Setter
  public static class MemberSocialDto {
    private SocialType socialType;
    private String socialId;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime createdAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime modifiedAt;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Seoul")
    private LocalDateTime deletedAt;
  }
}
```

```java
@Repository
@RequiredArgsConstructor
public class repo {
  private final QueryFactory query;
  
  @Override
  public List<MemberDto> findAllNoOffset(int lastId, int size, String identity, String nickname, String email, AuthLevel authLevel, LocalDateTime createdFrom, LocalDateTime createdTo, LocalDateTime modifiedFrom, LocalDateTime modifiedTo, LocalDateTime deletedFrom, LocalDateTime deletedTo) {
    return query.select(
            Projections.fields(MemberDto.class,
                    member.id,
                    member.identity,
                    member.nickname,
                    Projections.fields(MemberDto.MemberAuthorityDto.class,
                            memberAuthority.authLevel).as("memberAuthority")
            ),
            Projections.list(
                    memberSocial.socialType,
                    memberSocial.socialId)
    )
            .from(member)
            .where(gtId(lastId),
                    eqIdentity(identity),
                    containsNickname(nickname),
                    containsEmail(email),
                    eqAuthLevel(authLevel),
                    betweenCreatedAt(createdFrom, createdTo),
                    betweenModifiedAt(modifiedFrom, modifiedTo),
                    betweenDeletedAt(deletedFrom, deletedTo))
            .innerJoin(member.memberAuthority, memberAuthority)
            .leftJoin(member.memberSocials, memberSocial)
            .transform(GroupBy.groupBy(member.identity)
                    .list(Projections.fields(MemberDto.class, member.id, member.identity, member.nickname,
                            Projections.fields(MemberDto.MemberAuthorityDto.class, memberAuthority.authLevel).as("memberAuthority"),
                            GroupBy.list(Projections.fields(MemberDto.MemberSocialDto.class, memberSocial.socialType, memberSocial.socialId)).as("memberSocials"))));
  }
}
```

- 객체가 아닌 컬렉션은 두번에 나눠 처리를 하게 됩니다.
    1. 필드 및 1:1 객체는 select절에 `Projection.fields()`내에 바로 매핑처리를 해주고
    2. 1:N 컬렉션 객체는 select절에 `Projections.list()`로 분리하여 따로 받습니다
       ![img.png](/assets/images/2022-07-28-Querydsl%20Projections/img.png)
    - 이때 바로 fetch 할시엔 `List<Tuple>`을 받게 되며 `Tuple` 내에는 1번과 2번 항목이 분리되어 들어있습니다
    - 하지만 바로 Tuple을 받는것 대신 Querydsl의 `.transform()`을 이용하여 result aggregration 처리하여 바로 매핑 해줄수 있습니다
    3. Querydsl의 `.transform()`을 이용하여 result aggregation을 진행해줍니다
        - 이때 해야할 작업은 1:N 조인으로 인한 중복 레코드 제거, dto 매핑입니다.
    4. `.transform()`에 먼저 `GroupBy.groupBy(주체엔티티.컬럼)`을 넣어 그룹핑 시켜 중복 레코드를 처리해줍니다
    - `.transform(GroupBy.groupBy(member.id))`
    - 컬렉션을 매핑한다는것은 1:N 조인이 반드시 들어간다는 뜻이고, 결국 카테시안 곱으로 인한 주체 엔티티 중복 레코드가 생성되기 때문에
    5. GroupBy.list()를 추가로 호출하여 dto 매핑해준다. 이때 GroupBy.list()안에는 매핑 처리할 Projections.fields()들을 작성해주면 됩니다.
    - select절과 다른점은 이때는 하나의 Projection.Fields()안에 컬렉션도 모두 기입해준다. 이때 컬렉션은 GroupBy.list()로 매핑해줍니다

# Projections.fields()를 매핑할 시 주의사항

- 매핑을 엔티티가 아닌 DTO 클래스로 할 경우 fetchJoin()을 사용할 수 없습니다.
    - 페치조인은 엔티티 그래프를 참고하는것이기 때문에 엔티티가 아닌 클래스를 projection 한 경우 사용할 수 없습니다

# 관련 참고 문서

- [https://www.inflearn.com/questions/149985](https://www.inflearn.com/questions/149985)
- [https://jojoldu.tistory.com/342](https://jojoldu.tistory.com/342)
- [https://stackoverflow.com/questions/66366976/querydsl-how-to-return-dto-list](https://stackoverflow.com/questions/66366976/querydsl-how-to-return-dto-list)
- [https://bbuljj.github.io/querydsl/2021/05/17/jpa-querydsl-projection-list.html](https://bbuljj.github.io/querydsl/2021/05/17/jpa-querydsl-projection-list.html)
- [https://stackoverflow.com/questions/17116711/collections-in-querydsl-projections](https://stackoverflow.com/questions/17116711/collections-in-querydsl-projections)

# 소스코드

- https://github.com/choimory/item-value-checker-user-api