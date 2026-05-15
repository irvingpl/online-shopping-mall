# 🛍️ Online Shopping Mall

> 확장 가능한 모노레포 기반 이커머스 플랫폼 — NestJS · Next.js · PostgreSQL · Redis · Kubernetes

[![CI](https://github.com/irvingpl/online-shopping-mall/actions/workflows/ci.yml/badge.svg)](https://github.com/irvingpl/online-shopping-mall/actions/workflows/ci.yml)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org)
[![pnpm](https://img.shields.io/badge/pnpm-9.x-F69220?logo=pnpm)](https://pnpm.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 목차

- [프로젝트 개요](#프로젝트-개요)
- [아키텍처](#아키텍처)
- [기술 스택](#기술-스택)
- [패키지 구조](#패키지-구조)
- [설치 가이드](#설치-가이드)
- [환경 변수 설정](#환경-변수-설정)
- [개발 서버 실행](#개발-서버-실행)
- [Docker로 실행](#docker로-실행)
- [API 문서](#api-문서)
- [테스트](#테스트)
- [배포](#배포)
- [컨트리뷰션 가이드](#컨트리뷰션-가이드)

---

## 프로젝트 개요

Online Shopping Mall은 **동시 접속자 10,000명** 규모를 지원하도록 설계된 이커머스 플랫폼입니다. pnpm 워크스페이스와 Turborepo 기반 모노레포로 구성되어 있으며, 백엔드(NestJS)·프론트엔드(Next.js)·공유 패키지를 단일 저장소에서 관리합니다.

### 주요 기능

| 도메인 | 기능                                              |
| ------ | ------------------------------------------------- |
| 인증   | 회원가입 · 로그인 · JWT Access/Refresh Token      |
| 상품   | 목록 조회(필터·페이지네이션) · 상세 · 관리자 CRUD |
| 주문   | 주문 생성 · 상태 추적 · 취소                      |
| 결제   | 카드 · 계좌이체 · 가상계좌                        |
| 배송   | 운송장 등록 · 단계별 배송 추적                    |
| 사용자 | 프로필 관리 · 주문 내역                           |

---

## 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                 │
│                                                     │
│  ┌──────────┐    ┌──────────┐    ┌───────────────┐  │
│  │  Next.js │    │ NestJS   │    │  PostgreSQL   │  │
│  │  Web     │───▶│  API     │───▶│  (Primary +   │  │
│  │  :3000   │    │  :4000   │    │   Read Replica│  │
│  └──────────┘    └──────────┘    └───────────────┘  │
│                       │                             │
│                  ┌────▼─────┐    ┌───────────────┐  │
│                  │  Redis   │    │  PgBouncer    │  │
│                  │  Cache   │    │  (커넥션 풀)   │  │
│                  └──────────┘    └───────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 기술 스택

### Backend (`packages/api`)

| 분류         | 기술                                | 버전 |
| ------------ | ----------------------------------- | ---- |
| 프레임워크   | [NestJS](https://nestjs.com)        | 10.x |
| ORM          | [Prisma](https://prisma.io)         | 5.x  |
| 데이터베이스 | PostgreSQL                          | 16   |
| 캐시         | Redis                               | 7.2  |
| 인증         | JWT (Passport.js)                   | —    |
| API 문서     | Swagger (OpenAPI 3.0)               | —    |
| 유효성 검사  | class-validator · class-transformer | —    |

### Frontend (`packages/web`)

| 분류       | 기술                                       | 버전 |
| ---------- | ------------------------------------------ | ---- |
| 프레임워크 | [Next.js](https://nextjs.org) (App Router) | 14.x |
| 언어       | TypeScript                                 | 5.x  |
| 스타일     | Tailwind CSS                               | —    |

### 공통

| 분류           | 기술                                               |
| -------------- | -------------------------------------------------- |
| 모노레포       | pnpm Workspaces · [Turborepo](https://turbo.build) |
| 컨테이너       | Docker · Docker Compose                            |
| 오케스트레이션 | Kubernetes                                         |
| CI/CD          | GitHub Actions                                     |
| 코드 품질      | ESLint · Prettier · Husky · commitlint             |

---

## 패키지 구조

```
online-shopping-mall/
├── packages/
│   ├── api/          # NestJS 백엔드 API
│   │   ├── prisma/   # 데이터베이스 스키마 & 마이그레이션
│   │   └── src/
│   │       └── modules/
│   │           ├── auth/
│   │           ├── users/
│   │           ├── products/
│   │           └── orders/
│   ├── web/          # Next.js 프론트엔드
│   │   └── src/
│   │       ├── app/  # App Router 페이지
│   │       └── lib/  # API 클라이언트 등 유틸리티
│   ├── ui/           # 공유 React 컴포넌트 (Button, Card, Badge)
│   └── shared/       # 공유 타입 & 상수 (프론트/백 동시 사용)
├── scripts/          # 자동화 스크립트 (GitHub 이슈, Jira 티켓 생성 등)
├── docker-compose.yml
├── turbo.json
└── pnpm-workspace.yaml
```

---

## 설치 가이드

### 사전 요구사항

- **Node.js** `>=20.0.0` — [설치](https://nodejs.org) 또는 `nvm use` (`.nvmrc` 자동 적용)
- **pnpm** `>=9.0.0` — `npm install -g pnpm`
- **Docker Desktop** — [설치](https://docs.docker.com/get-docker/) (로컬 DB 실행 시 필요)

### 1. 저장소 클론

```bash
git clone https://github.com/irvingpl/online-shopping-mall.git
cd online-shopping-mall
```

### 2. 의존성 설치

```bash
pnpm install
```

### 3. 환경 변수 설정

```bash
# API 환경 변수
cp packages/api/.env.example packages/api/.env

# Web 환경 변수
cp packages/web/.env.local.example packages/web/.env.local
```

각 파일의 값을 [환경 변수 설정](#환경-변수-설정) 섹션을 참고하여 입력합니다.

### 4. 데이터베이스 초기화

```bash
# PostgreSQL · Redis 컨테이너 시작
docker compose up postgres redis -d

# Prisma 마이그레이션 실행
pnpm --filter @mall/api exec prisma migrate dev

# (선택) 시드 데이터 입력
pnpm --filter @mall/api exec prisma db seed
```

---

## 환경 변수 설정

### `packages/api/.env`

| 변수           | 설명                                           | 예시                                                          |
| -------------- | ---------------------------------------------- | ------------------------------------------------------------- |
| `DATABASE_URL` | PostgreSQL 연결 문자열                         | `postgresql://postgres:postgres@localhost:5432/shopping_mall` |
| `REDIS_URL`    | Redis 연결 문자열                              | `redis://localhost:6379`                                      |
| `JWT_SECRET`   | JWT 서명 시크릿 **(프로덕션에서 반드시 교체)** | `openssl rand -hex 64` 결과값                                 |
| `PORT`         | API 서버 포트                                  | `4000`                                                        |
| `CORS_ORIGIN`  | 허용할 프론트엔드 Origin                       | `http://localhost:3000`                                       |

### `packages/web/.env.local`

| 변수                  | 설명            | 예시                    |
| --------------------- | --------------- | ----------------------- |
| `NEXT_PUBLIC_API_URL` | 백엔드 API 주소 | `http://localhost:4000` |

> **보안 주의**: `.env` 파일은 절대 Git에 커밋하지 마세요. `.gitignore`에 등록되어 있습니다.
> 프로덕션 시크릿은 Kubernetes Secret 또는 Vault를 사용하여 관리하세요.

---

## 개발 서버 실행

```bash
# 전체 패키지 동시 실행 (Turborepo 병렬 실행)
pnpm dev

# 개별 패키지 실행
pnpm dev:api   # http://localhost:4000
pnpm dev:web   # http://localhost:3000
```

---

## Docker로 실행

```bash
# 전체 스택 (Web + API + PostgreSQL + Redis) 실행
docker compose up

# 백그라운드 실행
docker compose up -d

# 로그 확인
docker compose logs -f api

# 종료
docker compose down
```

---

## API 문서

개발 서버 실행 후 아래 URL에서 Swagger UI를 확인할 수 있습니다.

| 환경     | URL                        |
| -------- | -------------------------- |
| 로컬     | http://localhost:4000/docs |
| 스테이징 | —                          |
| 프로덕션 | —                          |

### 주요 엔드포인트 요약

```
POST   /v1/auth/register          회원가입
POST   /v1/auth/login             로그인

GET    /v1/products               상품 목록 조회 (페이지네이션)
GET    /v1/products/:id           상품 상세 조회
POST   /v1/products               상품 등록 (Admin)

POST   /v1/orders                 주문 생성
GET    /v1/orders                 내 주문 목록
GET    /v1/orders/:id             주문 상세
PATCH  /v1/orders/:id/cancel      주문 취소

GET    /v1/users/me               내 프로필 조회
PATCH  /v1/users/me               프로필 수정

GET    /health                    헬스체크
```

---

## 테스트

```bash
# 전체 테스트 실행
pnpm test

# 특정 패키지만 실행
pnpm --filter @mall/api test

# 타입 검사
pnpm type-check

# 린트
pnpm lint
pnpm lint:fix
```

---

## 배포

### Kubernetes

```bash
# 컨테이너 이미지 빌드
docker build -f packages/api/Dockerfile -t mall-api:latest .
docker build -f packages/web/Dockerfile -t mall-web:latest .

# Kubernetes 배포 (매니페스트 적용)
kubectl apply -f k8s/
```

### 환경별 브랜치 전략

| 브랜치      | 환경     | 배포 방식              |
| ----------- | -------- | ---------------------- |
| `main`      | 프로덕션 | 태그 푸시 시 자동 배포 |
| `develop`   | 스테이징 | PR 머지 시 자동 배포   |
| `feature/*` | 로컬     | 수동                   |

---

## 컨트리뷰션 가이드

기여를 환영합니다! 아래 절차를 따라주세요.

### 브랜치 네이밍

```
feat/    새로운 기능        feat/product-search
fix/     버그 수정          fix/order-stock-race
chore/   빌드·설정 변경     chore/update-deps
docs/    문서 수정          docs/api-guide
```

### 커밋 메시지

[Conventional Commits](https://www.conventionalcommits.org) 규칙을 따릅니다.

```
feat(api): 상품 검색 API 구현
fix(web): 장바구니 수량 음수 방지
chore: pnpm 9.15.0으로 업그레이드
```

> `git commit` 시 `commitlint`가 자동으로 형식을 검사합니다.

### PR 프로세스

1. `develop` 브랜치에서 기능 브랜치 생성
   ```bash
   git checkout develop
   git checkout -b feat/your-feature
   ```
2. 변경사항 작성 후 커밋
3. `develop`을 대상으로 Pull Request 생성
4. CI 통과 확인 (type-check · lint · test)
5. 리뷰어 1명 이상 Approve 후 Squash & Merge

### 코드 스타일

- 커밋 전 lint-staged가 자동으로 ESLint + Prettier를 실행합니다.
- 수동 실행: `pnpm format && pnpm lint:fix`

### 이슈 리포트

버그 또는 기능 제안은 [GitHub Issues](https://github.com/irvingpl/online-shopping-mall/issues)에 등록해 주세요.

---

## 라이선스

[MIT](LICENSE) © 2026 irvingpl
