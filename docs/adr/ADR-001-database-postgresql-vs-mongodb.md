# ADR-001: 데이터베이스 선택 — PostgreSQL vs MongoDB

| 항목       | 내용                 |
| ---------- | -------------------- |
| **상태**   | Accepted             |
| **날짜**   | 2026-05-16           |
| **결정자** | 아키텍처 팀          |
| **검토자** | 백엔드 팀, 인프라 팀 |

---

## 컨텍스트

Online Shopping Mall은 동시 접속자 10,000명 규모의 이커머스 플랫폼으로, 다음과 같은 도메인 모델을 가집니다.

```
User ─── Order ─── OrderItem ─── Product
                └── Payment
                └── Delivery
```

주문·결제·재고 데이터는 서로 강하게 연결되어 있으며, 재고 차감과 결제 상태 변경이 **하나의 원자적 작업**으로 처리되어야 합니다. 또한 쇼핑몰 특성상 상품 카탈로그와 주문 이력 데이터의 **스키마가 비교적 안정적**으로 유지됩니다.

### 평가 기준

1. 트랜잭션 무결성 (재고 Race Condition 방지)
2. 관계형 데이터 쿼리 성능 (주문 내역 + 상품 + 사용자 조인)
3. 10,000 동시 접속 대응 확장성
4. 팀의 기술 친숙도 및 생태계 성숙도
5. Prisma ORM 연동 지원

---

## 결정 (Y-Statement)

> **In the context of** 복수의 도메인 엔티티(User, Product, Order, Payment, Delivery)가 강한 관계와 엄격한 정합성을 요구하는 이커머스 플랫폼을 구축하는 상황에서,
>
> **facing** 주문 생성 시 재고 차감·결제 처리·배송 생성이 하나의 트랜잭션으로 묶여야 하고, 실패 시 완전한 롤백이 보장되어야 한다는 핵심 우려에 직면하여,
>
> **we decided** PostgreSQL을 주 데이터베이스로 채택하기로 결정했습니다.
>
> **to achieve** ACID 트랜잭션 보장, 외래 키 기반 참조 무결성, 복잡한 조인 쿼리의 안정적인 성능, 그리고 Prisma와의 완성도 높은 통합을 달성하기 위해,
>
> **accepting** 상품 속성처럼 구조가 유동적인 데이터(예: 카테고리별 다른 스펙)에 대해서는 스키마 변경 비용이 MongoDB보다 높다는 트레이드오프를 수용합니다.

---

## 옵션 비교

### Option A — PostgreSQL ✅ (채택)

**장점**

- **ACID 트랜잭션**: `BEGIN / COMMIT / ROLLBACK`으로 재고 차감·결제·주문 생성을 단일 트랜잭션으로 묶을 수 있음
- **참조 무결성**: 외래 키 제약으로 `OrderItem.productId`가 존재하지 않는 Product를 참조하는 상황을 DB 레벨에서 차단
- **복잡한 쿼리**: 주문 내역에서 상품명·결제 상태·배송 상태를 한 번에 조회하는 다중 조인이 자연스러움
- **Prisma 지원**: Prisma의 가장 성숙한 드라이버, 마이그레이션 도구 완비
- **팀 친숙도**: SQL 기반 쿼리 최적화, EXPLAIN ANALYZE, 인덱스 전략에 대한 기존 지식 활용 가능
- **확장 옵션**: Read Replica, PgBouncer, Citus(샤딩) 등 검증된 확장 경로 존재

**단점**

- 유동적 스키마(상품별 속성 차이)에 대응하려면 `JSONB` 컬럼 또는 EAV 패턴이 필요
- 수평 쓰기 확장(샤딩)이 MongoDB 대비 복잡
- 스키마 변경 시 마이그레이션 절차 필요 (ALTER TABLE → 다운타임 위험)

---

### Option B — MongoDB (기각)

**장점**

- 상품 스펙처럼 카테고리마다 구조가 다른 데이터를 스키마 없이 저장 가능
- 수평 샤딩이 내장되어 있어 쓰기 부하 분산이 용이
- 도큐먼트 단위 조회로 단순한 읽기 패턴에서 지연 시간이 낮을 수 있음

**단점**

- **트랜잭션 제한**: 멀티 도큐먼트 트랜잭션은 MongoDB 4.0+부터 지원되지만, 성능 비용이 크고 사용 패턴이 복잡함
- **참조 무결성 없음**: `OrderItem`이 삭제된 `Product`를 참조해도 DB가 막아주지 않음 → 애플리케이션 레벨에서 모두 처리해야 함
- **조인 비용**: `$lookup`은 관계형 JOIN에 비해 성능과 가독성 모두 불리
- **Prisma 지원 미흡**: Prisma의 MongoDB 드라이버는 미리보기(Preview) 상태로 일부 기능 미지원
- **이커머스 정합성 리스크**: 결제 완료 후 재고 차감 실패 시 보상 트랜잭션(Saga 패턴)을 직접 구현해야 하는 복잡도 증가

---

## 결과 및 영향

### 긍정적 영향

- 주문·결제·재고를 단일 `prisma.$transaction()`으로 처리 → 데이터 정합성 보장
- 외래 키 제약이 데이터 품질의 안전망 역할
- 팀이 익숙한 SQL로 성능 병목 분석 가능 (`EXPLAIN ANALYZE`)

### 부정적 영향 및 대응

| 리스크                      | 대응 방안                                                         |
| --------------------------- | ----------------------------------------------------------------- |
| 상품 속성 유연성 부족       | `products.attributes JSONB` 컬럼으로 카테고리별 가변 속성 저장    |
| 단일 인스턴스 SPOF          | Read Replica 구성 + PgBouncer 커넥션 풀링 (ADR-002 예정)          |
| 대규모 스키마 변경 다운타임 | `pg_repack`, 무중단 마이그레이션 전략 적용                        |
| 쓰기 확장 한계              | 초기에는 단일 Primary로 충분, 필요 시 Citus 또는 서비스 분리 검토 |

---

## 관련 결정

- **ADR-002** (예정): PostgreSQL 고가용성 — Read Replica & PgBouncer 구성
- **ADR-003** (예정): Redis 캐싱 전략 — 상품 목록 캐시 TTL 및 무효화 정책

---

## 참고 자료

- [PostgreSQL ACID Transactions](https://www.postgresql.org/docs/current/transaction-iso.html)
- [Prisma PostgreSQL Connector](https://www.prisma.io/docs/orm/overview/databases/postgresql)
- [MongoDB Multi-Document Transactions](https://www.mongodb.com/docs/manual/core/transactions/)
- [Thoughtworks Technology Radar — PostgreSQL](https://www.thoughtworks.com/radar/platforms/postgresql)
