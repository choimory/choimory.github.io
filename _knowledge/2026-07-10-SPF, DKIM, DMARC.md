---
title: "SPF, DKIM, DMARC"
date: 2026-07-10T00:00:00
toc: true
toc_sticky: true
categories:
    - CS
tags:
    - Mail
    - SPF
    - DKIM
    - DMARC
---

## 개요

SPF, DKIM, DMARC는 이메일이 "진짜 발신자가 보낸 메일인지" 검증하기 위한 이메일 인증 기술입니다.

이메일은 기본적으로 발신자 주소를 쉽게 위조할 수 있습니다. 그래서 공격자는 `admin@example.com`, `support@company.com` 같은 주소를 흉내 내어 피싱 메일을 보낼 수 있습니다.

이를 막기 위해 DNS에 인증 정책을 등록하고, 수신 메일 서버가 해당 정책을 확인하여 메일의 신뢰성을 판단합니다.

---

## SPF

SPF는 "이 도메인에서 메일을 보낼 수 있는 서버 IP가 맞는지" 확인하는 방식입니다.

즉, `example.com` 도메인이 메일을 보낼 수 있는 서버 목록을 DNS에 등록해두고, 수신 서버는 실제 메일을 보낸 IP가 그 목록에 포함되어 있는지 검사합니다.

### 동작 방식

예를 들어 `example.com`이 Gmail을 통해 메일을 보낸다면, DNS에 Gmail 메일 서버를 허용하는 SPF 레코드를 등록합니다.

```
example.com. TXT "v=spf1 include:_spf.google.com ~all"
```

수신 서버는 메일을 받았을 때 다음을 확인합니다.

```
이 메일을 보낸 서버 IP가 example.com의 SPF 정책에 포함되어 있는가?
```

포함되어 있으면 SPF 통과, 아니면 실패입니다.

### SPF 예시

```
v=spf1 ip4:192.0.2.10 include:_spf.google.com ~all
```

의미는 다음과 같습니다.

| 항목 | 의미 |
| --- | --- |
| `v=spf1` | SPF 버전 |
| `ip4:192.0.2.10` | 이 IPv4 주소에서 발송 허용 |
| `include:_spf.google.com` | Google의 SPF 정책도 허용 |
| `~all` | 나머지는 SoftFail 처리 |

### SPF의 한계

SPF는 "발신 서버 IP"만 검증합니다.

따라서 메일 내용이 중간에서 변조되었는지, 실제 보낸 사람이 도메인 소유자인지는 완전히 보장하지 못합니다.

또한 메일 포워딩 환경에서는 SPF가 실패할 수 있습니다. 원래 발신 서버가 아닌 포워딩 서버가 최종 수신 서버에 메일을 전달하기 때문입니다.

---

## DKIM

DKIM은 "메일이 발송된 후 내용이 변조되지 않았는지"와 "도메인 소유자가 서명한 메일인지" 확인하는 방식입니다.

메일 발송 서버는 개인키로 메일에 디지털 서명을 추가하고, 수신 서버는 DNS에 공개된 공개키로 서명을 검증합니다.

### 동작 방식

1. 발신 서버가 메일 제목, 본문, 일부 헤더를 기반으로 서명을 생성합니다.
2. 메일 헤더에 `DKIM-Signature`를 추가합니다.
3. 수신 서버는 발신 도메인의 DNS에서 공개키를 조회합니다.
4. 공개키로 서명을 검증합니다.
5. 검증에 성공하면 DKIM 통과입니다.

### DKIM DNS 예시

```
selector1._domainkey.example.com. TXT "v=DKIM1; k=rsa; p=PUBLIC_KEY_VALUE"
```

각 항목의 의미는 다음과 같습니다.

| 항목 | 의미 |
| --- | --- |
| `selector1` | DKIM 키를 구분하는 이름 |
| `_domainkey` | DKIM 전용 DNS 네임스페이스 |
| `v=DKIM1` | DKIM 버전 |
| `k=rsa` | 키 알고리즘 |
| `p=...` | 공개키 |

### DKIM의 장점

DKIM은 메일 내용과 헤더 일부에 서명을 하기 때문에, 메일이 발송된 후 중간에서 변조되면 검증에 실패합니다.

또한 포워딩 환경에서도 SPF보다 안정적으로 동작할 수 있습니다. 포워딩되더라도 메일 내용이 변조되지 않으면 DKIM 서명이 유지될 수 있기 때문입니다.

---

## DMARC

DMARC는 SPF와 DKIM의 결과를 바탕으로 "인증 실패한 메일을 어떻게 처리할지" 정하는 정책입니다.

SPF와 DKIM이 각각 인증 기술이라면, DMARC는 그 결과를 해석하고 정책화하는 상위 규칙입니다.

### DMARC가 필요한 이유

SPF와 DKIM만 설정해도 인증은 가능하지만, 수신 서버에게 다음과 같은 명확한 지시를 내리지는 못합니다.

```
인증 실패한 메일을 그냥 받을지, 스팸으로 보낼지, 아예 거부할지
```

DMARC는 이 정책을 DNS에 등록합니다.

### DMARC 예시

```
_dmarc.example.com. TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc-report@example.com"
```

의미는 다음과 같습니다.

| 항목 | 의미 |
| --- | --- |
| `v=DMARC1` | DMARC 버전 |
| `p=quarantine` | 실패한 메일을 격리 또는 스팸 처리 |
| `rua=mailto:...` | 집계 리포트 받을 주소 |

### DMARC 정책 종류

| 정책 | 의미 |
| --- | --- |
| `p=none` | 모니터링만 하고 차단하지 않음 |
| `p=quarantine` | 인증 실패 메일을 스팸함 또는 격리 처리 |
| `p=reject` | 인증 실패 메일 수신 거부 |

일반적으로 처음에는 `p=none`으로 시작해서 리포트를 확인하고, 문제가 없으면 `quarantine`, 최종적으로 `reject`로 강화합니다.

---

## Alignment

DMARC에서 중요한 개념이 "Alignment"입니다.

DMARC는 단순히 SPF나 DKIM이 통과했는지만 보지 않습니다. 메일의 `From` 도메인과 SPF 또는 DKIM에서 검증된 도메인이 일치하는지도 확인합니다.

### 예시

메일 화면에 보이는 발신자가 다음과 같다고 가정합니다.

```
From: user@example.com
```

DMARC는 SPF 또는 DKIM 검증 결과가 `example.com`과 정렬되는지 확인합니다.

```
SPF 통과 + Return-Path 도메인이 example.com과 일치
또는
DKIM 통과 + DKIM 서명 도메인이 example.com과 일치
```

둘 중 하나라도 만족하면 DMARC 통과가 가능합니다.

---

## 세 가지의 관계

SPF, DKIM, DMARC의 역할을 비교하면 다음과 같습니다.

| 구분 | 검증 대상 | 핵심 질문 |
| --- | --- | --- |
| SPF | 발송 서버 IP | 이 서버가 이 도메인의 메일을 보낼 권한이 있는가? |
| DKIM | 메일 서명 | 이 메일은 도메인 소유자가 서명했고 중간에 변조되지 않았는가? |
| DMARC | SPF, DKIM 결과와 정책 | 인증 실패한 메일을 어떻게 처리할 것인가? |

간단히 말하면 다음과 같습니다.

```
SPF = 허용된 서버인지 확인
DKIM = 메일이 진짜 서명되었고 변조되지 않았는지 확인
DMARC = 실패한 메일을 어떻게 처리할지 결정
```

---

## 실제 설정 순서

실무에서는 보통 다음 순서로 설정합니다.

### 1. SPF 설정

먼저 현재 도메인에서 메일을 발송하는 서비스를 파악합니다.

예를 들어 다음과 같은 서비스가 있을 수 있습니다.

```
Google Workspace
Microsoft 365
SendGrid
AWS SES
Mailchimp
자체 SMTP 서버
```

그 후 DNS에 SPF 레코드를 등록합니다.

```
v=spf1 include:_spf.google.com include:sendgrid.net ~all
```

주의할 점은 SPF 레코드는 도메인당 하나만 있어야 한다는 것입니다. 여러 개를 따로 만들면 문제가 생길 수 있습니다.

### 2. DKIM 설정

메일 발송 서비스에서 DKIM 키를 생성한 뒤, 제공된 DNS 레코드를 등록합니다.

예를 들어 Google Workspace나 AWS SES에서는 DKIM 설정 메뉴에서 DNS 레코드를 제공합니다.

```
selector._domainkey.example.com TXT "v=DKIM1; k=rsa; p=..."
```

### 3. DMARC 설정

처음에는 차단하지 않고 모니터링부터 시작하는 것이 안전합니다.

```
v=DMARC1; p=none; rua=mailto:dmarc-report@example.com
```

이후 리포트를 보면서 정상 발송 메일이 SPF/DKIM을 통과하는지 확인합니다.

문제가 없으면 점진적으로 강화합니다.

```
v=DMARC1; p=quarantine; rua=mailto:dmarc-report@example.com
```

최종적으로는 다음처럼 강한 정책을 적용할 수 있습니다.

```
v=DMARC1; p=reject; rua=mailto:dmarc-report@example.com
```

---

## 운영 시 주의사항

### SPF 레코드는 하나로 합쳐야 합니다

잘못된 예시는 다음과 같습니다.

```
v=spf1 include:_spf.google.com ~all
v=spf1 include:sendgrid.net ~all
```

SPF 레코드가 2개 이상이면 SPF 검증 오류가 발생할 수 있습니다.

올바른 예시는 다음과 같습니다.

```
v=spf1 include:_spf.google.com include:sendgrid.net ~all
```

### SPF DNS 조회 제한이 있습니다

SPF는 검증 과정에서 DNS 조회 횟수 제한이 있습니다. 일반적으로 `include`를 너무 많이 사용하면 SPF PermError가 발생할 수 있습니다.

외부 메일 발송 서비스를 많이 쓰는 조직에서는 SPF flattening 또는 발송 서비스 정리가 필요할 수 있습니다.

### DKIM 키 교체가 필요할 수 있습니다

DKIM은 공개키/개인키 기반이기 때문에, 장기 운영 시 키 로테이션을 고려해야 합니다.

보통 `selector`를 바꿔서 새 키를 등록하고, 충분히 전파된 뒤 기존 키를 제거하는 방식으로 운영합니다.

### DMARC는 바로 reject로 시작하지 않는 것이 좋습니다

처음부터 `p=reject`를 설정하면 정상적인 업무 메일이 차단될 수 있습니다.

특히 다음과 같은 경우 문제가 생길 수 있습니다.

```
외부 마케팅 발송 서비스 누락
레거시 SMTP 서버 누락
협력사 대행 발송
메일 포워딩
서브도메인 발송
```

그래서 `p=none`으로 리포트를 먼저 수집하는 것이 안전합니다.

---

## 예시 구성

`example.com`이 Google Workspace와 SendGrid를 사용한다고 가정하면 다음과 같이 구성할 수 있습니다.

### SPF

```
example.com TXT "v=spf1 include:_spf.google.com include:sendgrid.net ~all"
```

### DKIM

```
google._domainkey.example.com TXT "v=DKIM1; k=rsa; p=..."
s1._domainkey.example.com TXT "v=DKIM1; k=rsa; p=..."
s2._domainkey.example.com TXT "v=DKIM1; k=rsa; p=..."
```

### DMARC

```
_dmarc.example.com TXT "v=DMARC1; p=none; rua=mailto:dmarc-report@example.com"
```

이후 리포트 확인 후 다음처럼 강화합니다.

```
_dmarc.example.com TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc-report@example.com"
```

최종적으로 다음처럼 설정할 수 있습니다.

```
_dmarc.example.com TXT "v=DMARC1; p=reject; rua=mailto:dmarc-report@example.com"
```

---

## 전체 요약

SPF, DKIM, DMARC는 이메일 위조와 피싱을 줄이기 위한 이메일 인증 체계입니다.

SPF는 "허용된 서버에서 보낸 메일인지" 확인하고, DKIM은 "메일이 도메인 소유자의 서명을 받았고 변조되지 않았는지" 확인합니다. DMARC는 SPF와 DKIM 결과를 바탕으로 인증 실패 메일을 어떻게 처리할지 결정합니다.

실무에서는 SPF와 DKIM을 먼저 정상화하고, DMARC는 `p=none`으로 리포트를 확인한 뒤 `quarantine`, `reject` 순서로 점진적으로 강화하는 것이 안전합니다.