#!/usr/bin/env bash
set -euo pipefail

# ==============================================================
# Online Shopping Mall — GitHub Issues 자동 생성 스크립트
# WBS 기반 6개 Sprint × 64개 이슈 + 마일스톤 + 레이블 생성
# ==============================================================
# 사용법:
#   chmod +x scripts/create-github-issues.sh
#   ./scripts/create-github-issues.sh --repo <owner/repo>
#   ./scripts/create-github-issues.sh --repo <owner/repo> --dry-run
#
# 의존성:
#   gh CLI (https://cli.github.com) + gh auth login 완료
# ==============================================================

# ── 전역 변수 ────────────────────────────────────────────────
REPO=""
DRY_RUN=false
DELAY=0.8          # GitHub API rate limit 방지 (요청 간 대기)
TOTAL_CREATED=0

# ── 색상 출력 ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── 인수 파싱 ────────────────────────────────────────────────
usage() {
  echo "사용법: $0 --repo <owner/repo> [--dry-run] [--delay <초>]"
  echo ""
  echo "옵션:"
  echo "  --repo     GitHub 저장소 (예: myorg/online-shopping-mall) [필수]"
  echo "  --dry-run  실제 생성 없이 생성될 이슈 목록만 출력"
  echo "  --delay    API 요청 간 대기 시간(초), 기본값 0.8"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)    REPO="$2";    shift 2 ;;
    --dry-run) DRY_RUN=true; shift   ;;
    --delay)   DELAY="$2";   shift 2 ;;
    -h|--help) usage ;;
    *) echo "알 수 없는 옵션: $1"; usage ;;
  esac
done

[[ -z "$REPO" ]] && { echo -e "${RED}❌ --repo <owner/repo> 가 필요합니다.${NC}"; usage; }

# ══════════════════════════════════════════════════════════════
# 사전 조건 확인
# ══════════════════════════════════════════════════════════════
check_prerequisites() {
  echo -e "${BOLD}🔍 사전 조건 확인...${NC}"

  if ! command -v gh &>/dev/null; then
    echo -e "${RED}❌ gh CLI가 설치되지 않았습니다.${NC}"
    echo "   설치: https://cli.github.com"
    exit 1
  fi

  if ! gh auth status &>/dev/null; then
    echo -e "${RED}❌ GitHub 인증이 필요합니다.${NC}"
    echo "   실행: gh auth login"
    exit 1
  fi

  if ! gh repo view "$REPO" &>/dev/null; then
    echo -e "${RED}❌ 저장소를 찾을 수 없습니다: $REPO${NC}"
    echo "   저장소가 존재하고 접근 권한이 있는지 확인하세요."
    exit 1
  fi

  echo -e "${GREEN}✅ gh CLI 인증 및 저장소 접근 확인 완료${NC}"
}

# ══════════════════════════════════════════════════════════════
# 레이블 생성
# ══════════════════════════════════════════════════════════════
create_labels() {
  echo ""
  echo -e "${BOLD}${BLUE}🏷️  레이블 생성 중...${NC}"

  # "이름:색상:설명" 형식
  local labels=(
    "sprint-1:0052cc:Sprint 1 — 프로젝트 착수 (05/18~05/29)"
    "sprint-2:0075ca:Sprint 2 — 인증·사용자 (06/01~06/12)"
    "sprint-3:1d76db:Sprint 3 — 상품 관리 (06/15~06/26)"
    "sprint-4:0e8a16:Sprint 4 — 장바구니·주문 (06/29~07/10)"
    "sprint-5:e4e669:Sprint 5 — 결제·배송 (07/13~07/24)"
    "sprint-6:d93f0b:Sprint 6 — 테스트·배포 (07/27~08/07)"
    "backend:c5def5:NestJS 백엔드 API 작업"
    "frontend:fef2c0:Next.js 프론트엔드 UI 작업"
    "devops:bfd4f2:Docker·Kubernetes·CI/CD"
    "testing:f9d0c4:단위·통합·E2E 테스트"
    "infra:e4e669:인프라 및 환경 설정"
    "db:d4c5f9:데이터베이스·Prisma·스키마"
    "D1:0075ca:담당자 D1 (백엔드 중심)"
    "D2:e99695:담당자 D2 (프론트엔드 중심)"
    "blocked:ee0701:다른 이슈에 의해 블로킹됨"
    "high-priority:b60205:우선순위 높음"
  )

  for entry in "${labels[@]}"; do
    IFS=':' read -r name color desc <<< "$entry"
    if $DRY_RUN; then
      printf "  [DRY-RUN] label  %-15s  #%s\n" "$name" "$color"
    else
      gh label create "$name" \
        --repo "$REPO" \
        --color "$color" \
        --description "$desc" 2>/dev/null \
        && echo -e "  ${GREEN}✅ $name${NC}" \
        || echo -e "  ${YELLOW}⚠️  $name (이미 존재 — 건너뜀)${NC}"
    fi
  done
}

# ══════════════════════════════════════════════════════════════
# 마일스톤 생성
# ══════════════════════════════════════════════════════════════
create_milestones() {
  echo ""
  echo -e "${BOLD}${BLUE}🎯 마일스톤 생성 중...${NC}"

  # "제목|마감일|설명" 형식
  local milestones=(
    "Sprint 1|2026-05-29|환경 설정 · 공통 인프라 완료"
    "Sprint 2|2026-06-12|인증 · 사용자 관리 완료"
    "Sprint 3|2026-06-26|상품 관리 완료"
    "Sprint 4|2026-07-10|장바구니 · 주문 처리 완료"
    "Sprint 5|2026-07-24|결제 · 배송 추적 완료"
    "Sprint 6|2026-08-07|테스트 · 배포 · MVP 릴리즈"
  )

  for entry in "${milestones[@]}"; do
    IFS='|' read -r title due desc <<< "$entry"
    if $DRY_RUN; then
      printf "  [DRY-RUN] milestone  %-12s  due: %s\n" "$title" "$due"
    else
      gh api "repos/$REPO/milestones" \
        --method POST \
        -f title="$title" \
        -f due_on="${due}T23:59:59Z" \
        -f description="$desc" \
        --silent \
        && echo -e "  ${GREEN}✅ $title${NC}" \
        || echo -e "  ${YELLOW}⚠️  $title (이미 존재할 수 있음)${NC}"
    fi
  done
}

# ══════════════════════════════════════════════════════════════
# 이슈 생성 헬퍼
# ══════════════════════════════════════════════════════════════
create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"   # 쉼표 구분
  local milestone="$4"

  if $DRY_RUN; then
    printf "  ${CYAN}[DRY-RUN]${NC} %-65s  [%s]\n" "$title" "$milestone"
    ((TOTAL_CREATED++)) || true
    return 0
  fi

  # 쉼표 구분 레이블 → 개별 --label 플래그
  local label_flags=()
  IFS=',' read -ra label_arr <<< "$labels"
  for lbl in "${label_arr[@]}"; do
    label_flags+=(--label "$lbl")
  done

  local url
  if url=$(gh issue create \
      --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --milestone "$milestone" \
      "${label_flags[@]}" 2>&1); then
    echo -e "  ${GREEN}✅${NC} $url"
    ((TOTAL_CREATED++)) || true
  else
    echo -e "  ${RED}❌ 실패:${NC} $title"
    echo "     $url"
  fi

  sleep "$DELAY"
}

# ══════════════════════════════════════════════════════════════
# Sprint 1 — 프로젝트 착수 · 인프라 (05/18 ~ 05/29)
# ══════════════════════════════════════════════════════════════
create_sprint1_issues() {
  local M="Sprint 1"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}📦 Sprint 1 — 프로젝트 착수 · 인프라 (05/18~05/29)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[1.1.1] 모노레포 환경 구성" \
"## 📋 작업 개요
pnpm workspace 기반 모노레포 초기 구성 및 개발 도구 설정

## ✅ 작업 항목
- [ ] pnpm workspace + Turborepo 파이프라인 설정
- [ ] \`packages/shared\`, \`web\`, \`api\`, \`ui\` 패키지 구조 생성
- [ ] \`tsconfig.base.json\` strict 모드 설정 (noUncheckedIndexedAccess 등)
- [ ] ESLint (패키지별 설정) + Prettier 설정
- [ ] Husky + lint-staged + commitlint 설정
- [ ] \`.vscode/settings.json\`, \`extensions.json\`, \`launch.json\` 설정

## 🎯 완료 기준
- \`pnpm dev\` 실행 시 모든 패키지 동시 기동
- 커밋 시 lint-staged 자동 실행 확인
- VSCode에서 저장 시 자동 포맷 동작 확인

## 📎 메타
- **WBS:** 1.1.1 | **공수:** 1일 | **담당:** D1 + D2" \
    "sprint-1,infra,D1,D2,high-priority" "$M"

  create_issue "[1.1.2] GitHub 브랜치 전략 수립" \
"## 📋 작업 개요
팀 협업을 위한 Git 브랜치 규칙 및 PR 프로세스 정의

## ✅ 작업 항목
- [ ] 브랜치 전략 문서화: \`main\` / \`develop\` / \`feature/*\` / \`hotfix/*\`
- [ ] PR 템플릿 작성 (\`.github/pull_request_template.md\`)
- [ ] Issue 템플릿 작성 (기능/버그/질문)
- [ ] \`main\`, \`develop\` 브랜치 보호 규칙 설정 (require review, status checks)
- [ ] 코드 리뷰 가이드라인 작성

## 🎯 완료 기준
- PR 오픈 시 템플릿 자동 적용 확인
- main 브랜치 직접 push 차단 확인

## 📎 메타
- **WBS:** 1.1.2 | **공수:** 0.5일 | **담당:** D1" \
    "sprint-1,infra,D1" "$M"

  create_issue "[1.1.3] GitHub Actions CI 파이프라인 구성" \
"## 📋 작업 개요
PR/push 이벤트 시 자동으로 품질 검증하는 CI 파이프라인 구축

## ✅ 작업 항목
- [ ] \`.github/workflows/ci.yml\` 작성
- [ ] Job 구성: \`lint\` → \`type-check\` → \`build\` → \`test\`
- [ ] Node.js 20 LTS, pnpm 9 버전 고정
- [ ] Turborepo 캐시 + pnpm store 캐시 적용
- [ ] PR에 CI 상태 배지 표시

## 🎯 완료 기준
- PR 오픈 시 CI 자동 실행 확인
- 캐시 적용 후 빌드 시간 50% 단축 확인

## 📎 메타
- **WBS:** 1.1.3 | **공수:** 1일 | **담당:** D2
- **의존성:** #1.1.1" \
    "sprint-1,devops,D2,high-priority" "$M"

  create_issue "[1.1.4] Docker Compose 로컬 개발 환경 구성" \
"## 📋 작업 개요
로컬에서 전체 스택을 한 번에 기동하는 Docker Compose 환경 구성

## ✅ 작업 항목
- [ ] \`docker-compose.yml\`: PostgreSQL 16, Redis 7.2, API, Web
- [ ] 헬스체크 설정 (PostgreSQL \`pg_isready\`, Redis \`ping\`)
- [ ] 서비스 간 의존성 순서 설정 (\`depends_on: condition: service_healthy\`)
- [ ] \`.env.example\` 파일 작성
- [ ] \`README.md\` 로컬 실행 가이드 작성

## 🎯 완료 기준
- \`docker compose up -d\` 한 번에 전체 환경 기동
- DB/Redis 헬스체크 통과 후 API 기동 확인

## 📎 메타
- **WBS:** 1.1.4 | **공수:** 1일 | **담당:** D1" \
    "sprint-1,devops,infra,D1" "$M"

  create_issue "[1.2.1] 데이터베이스 스키마 설계 확정" \
"## 📋 작업 개요
서비스 전체 도메인 엔티티 및 관계 설계

## ✅ 작업 항목
- [ ] ERD 작성 (User, Product, Category, Order, OrderItem, Payment, Delivery)
- [ ] Prisma schema.prisma 초안 작성
- [ ] 인덱스 전략 정의 (자주 조회되는 FK, 검색 컬럼)
- [ ] Enum 정의 (OrderStatus, PaymentStatus, DeliveryStatus, Role)
- [ ] 팀 리뷰 및 스키마 확정

## 🎯 완료 기준
- 모든 도메인 엔티티 관계 ERD로 표현
- prisma validate 통과

## 📎 메타
- **WBS:** 1.2.1 | **공수:** 1일 | **담당:** D1 + D2" \
    "sprint-1,db,D1,D2,high-priority" "$M"

  create_issue "[1.2.2] Prisma 초기 마이그레이션 및 시드 데이터" \
"## 📋 작업 개요
확정된 스키마로 DB 마이그레이션 실행 및 개발용 시드 데이터 생성

## ✅ 작업 항목
- [ ] \`prisma migrate dev --name init\` 실행
- [ ] \`prisma/seed.ts\` 작성 (카테고리 10개, 상품 50개, 테스트 유저 3명)
- [ ] \`package.json\`에 seed 스크립트 추가
- [ ] CI에서 migrate deploy 자동 실행 설정

## 🎯 완료 기준
- \`prisma migrate status\` 최신 상태 확인
- 시드 실행 후 데이터 조회 가능

## 📎 메타
- **WBS:** 1.2.2 | **공수:** 0.5일 | **담당:** D1
- **의존성:** #1.2.1" \
    "sprint-1,db,D1" "$M"

  create_issue "[1.3.1] NestJS 공통 모듈 구현" \
"## 📋 작업 개요
전체 API에서 공통으로 사용하는 모듈 구현

## ✅ 작업 항목
- [ ] \`GlobalExceptionFilter\`: HTTP 에러 → 표준 응답 변환
- [ ] \`LoggingInterceptor\`: 요청/응답 로깅 (메서드, URL, 상태코드, 응답시간)
- [ ] \`JwtAuthGuard\`: JWT 검증 전역 가드
- [ ] \`TransformInterceptor\`: ApiResponse 래퍼 자동 적용
- [ ] PrismaService 싱글톤 등록

## 🎯 완료 기준
- 모든 에러가 \`{ success: false, error: string, statusCode: number }\` 형태로 응답
- 요청마다 로그 출력 확인

## 📎 메타
- **WBS:** 1.3.1 | **공수:** 2일 | **담당:** D1" \
    "sprint-1,backend,D1,high-priority" "$M"

  create_issue "[1.3.2] API 응답 형식 표준화" \
"## 📋 작업 개요
\`@mall/shared\`의 공통 타입을 활용한 API 응답 형식 통일

## ✅ 작업 항목
- [ ] \`ApiResponse<T>\`, \`PaginatedResponse<T>\` DTO 정의
- [ ] \`TransformInterceptor\`에 응답 래핑 적용
- [ ] 페이지네이션 유틸 함수 구현
- [ ] Swagger 예시 응답 형식 반영

## 🎯 완료 기준
- 모든 성공 응답이 \`{ success: true, data: T }\` 구조
- 페이지네이션 응답에 \`total\`, \`page\`, \`totalPages\` 포함

## 📎 메타
- **WBS:** 1.3.2 | **공수:** 0.5일 | **담당:** D1
- **의존성:** #1.3.1" \
    "sprint-1,backend,D1" "$M"

  create_issue "[1.3.3] Swagger API 문서 설정" \
"## 📋 작업 개요
개발 및 프론트엔드 협업을 위한 API 문서 자동화

## ✅ 작업 항목
- [ ] \`@nestjs/swagger\` 설정 및 \`/docs\` 엔드포인트 활성화
- [ ] 모든 DTO에 \`@ApiProperty\` 데코레이터 추가
- [ ] Bearer Auth 설정 (JWT 토큰 테스트 가능)
- [ ] 컨트롤러별 \`@ApiTags\` 그룹화
- [ ] 환경별 Swagger 노출 제어 (prod 비활성화)

## 🎯 완료 기준
- \`http://localhost:4000/docs\`에서 전체 엔드포인트 확인
- Swagger UI에서 직접 JWT 인증 후 API 호출 가능

## 📎 메타
- **WBS:** 1.3.3 | **공수:** 0.5일 | **담당:** D1
- **의존성:** #1.3.1" \
    "sprint-1,backend,D1" "$M"

  create_issue "[1.4.1] Next.js 공통 레이아웃 컴포넌트" \
"## 📋 작업 개요
전체 페이지에서 공유되는 레이아웃 컴포넌트 구현

## ✅ 작업 항목
- [ ] \`Header\`: 로고, 검색창, 장바구니 아이콘, 로그인/마이페이지 링크
- [ ] \`Footer\`: 회사 정보, 이용약관, 개인정보처리방침 링크
- [ ] \`Navigation\`: 카테고리 메뉴 (모바일 햄버거 메뉴 포함)
- [ ] \`app/layout.tsx\`에 공통 레이아웃 적용
- [ ] 반응형 레이아웃 (모바일/태블릿/데스크탑)

## 🎯 완료 기준
- 모든 페이지에서 Header/Footer 표시 확인
- 모바일 breakpoint(768px)에서 레이아웃 정상 동작

## 📎 메타
- **WBS:** 1.4.1 | **공수:** 1.5일 | **담당:** D2" \
    "sprint-1,frontend,D2" "$M"

  create_issue "[1.4.2] 공통 UI 컴포넌트 라이브러리 구축" \
"## 📋 작업 개요
\`@mall/ui\` 패키지에 재사용 가능한 기본 컴포넌트 구현

## ✅ 작업 항목
- [ ] \`Button\`: variant (primary/secondary/danger/ghost), size, loading 상태
- [ ] \`Input\`: label, error, helper text, 아이콘 지원
- [ ] \`Card\` / \`CardHeader\` / \`CardBody\`
- [ ] \`Badge\` / \`OrderStatusBadge\`
- [ ] \`Modal\` / \`Dialog\`
- [ ] \`Skeleton\` 로딩 컴포넌트
- [ ] \`Toast\` / \`Notification\`

## 🎯 완료 기준
- 모든 컴포넌트 TypeScript 타입 완비
- \`@mall/web\`에서 import 후 정상 렌더링 확인

## 📎 메타
- **WBS:** 1.4.2 | **공수:** 2일 | **담당:** D2" \
    "sprint-1,frontend,D2,high-priority" "$M"

  create_issue "[1.4.3] Next.js API 클라이언트 설정" \
"## 📋 작업 개요
백엔드 API 통신을 위한 fetch 래퍼 및 인증 토큰 자동 처리 구현

## ✅ 작업 항목
- [ ] \`src/lib/api.ts\`: GET/POST/PATCH/DELETE 메서드 래퍼
- [ ] 요청 헤더에 Access Token 자동 주입
- [ ] 401 응답 시 Refresh Token으로 자동 갱신 후 재시도
- [ ] API 에러 타입 정의 및 공통 에러 처리
- [ ] 환경변수 \`NEXT_PUBLIC_API_URL\` 설정

## 🎯 완료 기준
- 인증된 요청/비인증 요청 분기 동작 확인
- 토큰 만료 시 자동 갱신 후 원래 요청 재시도 확인

## 📎 메타
- **WBS:** 1.4.3 | **공수:** 1일 | **담당:** D2
- **의존성:** #1.3.1" \
    "sprint-1,frontend,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# Sprint 2 — 인증 · 사용자 관리 (06/01 ~ 06/12)
# ══════════════════════════════════════════════════════════════
create_sprint2_issues() {
  local M="Sprint 2"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}🔐 Sprint 2 — 인증 · 사용자 관리 (06/01~06/12)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[2.1.1] 회원가입 API" \
"## 📋 작업 개요
신규 사용자 등록 엔드포인트 구현

## ✅ 작업 항목
- [ ] \`POST /v1/auth/register\` 엔드포인트
- [ ] 이메일 형식 및 중복 검증
- [ ] bcrypt(saltRounds=12) 비밀번호 해싱
- [ ] \`RegisterDto\`: email, name, password 유효성 검사
- [ ] 이메일 인증 토큰 생성 (6자리 OTP, Redis 10분 TTL)

## 🎯 완료 기준
- 중복 이메일 409 응답
- 비밀번호 평문 DB 저장 없음 확인
- 유효성 검사 실패 시 400 응답

## 📎 메타
- **WBS:** 2.1.1 | **공수:** 1.5일 | **담당:** D1" \
    "sprint-2,backend,D1,high-priority" "$M"

  create_issue "[2.1.2] 로그인 API (JWT 발급)" \
"## 📋 작업 개요
자격증명 검증 후 JWT Access/Refresh Token 발급

## ✅ 작업 항목
- [ ] \`POST /v1/auth/login\` 엔드포인트
- [ ] bcrypt 비밀번호 비교
- [ ] Access Token 발급 (1시간 만료)
- [ ] Refresh Token 발급 (7일 만료, Redis 저장)
- [ ] 로그인 실패 횟수 제한 (5회 초과 시 15분 잠금, Redis)

## 🎯 완료 기준
- 올바른 자격증명 → 200 + 토큰 반환
- 잘못된 자격증명 → 401 응답
- 5회 실패 후 429 응답

## 📎 메타
- **WBS:** 2.1.2 | **공수:** 1일 | **담당:** D1
- **의존성:** #2.1.1" \
    "sprint-2,backend,D1,high-priority" "$M"

  create_issue "[2.1.3] 토큰 갱신 API (Refresh Token)" \
"## 📋 작업 개요
만료된 Access Token을 Refresh Token으로 갱신

## ✅ 작업 항목
- [ ] \`POST /v1/auth/refresh\` 엔드포인트
- [ ] Refresh Token 유효성 검증 (서명 + Redis 존재 확인)
- [ ] 새 Access Token 발급
- [ ] Refresh Token 재발급 (Rotation 전략)
- [ ] 탈취된 Refresh Token 사용 시 모든 세션 무효화

## 🎯 완료 기준
- 유효한 Refresh Token → 새 Access Token 반환
- 만료/무효 Refresh Token → 401 응답

## 📎 메타
- **WBS:** 2.1.3 | **공수:** 1일 | **담당:** D1
- **의존성:** #2.1.2" \
    "sprint-2,backend,D1" "$M"

  create_issue "[2.1.4] 로그아웃 API (토큰 블랙리스트)" \
"## 📋 작업 개요
로그아웃 시 토큰 무효화 처리

## ✅ 작업 항목
- [ ] \`POST /v1/auth/logout\` 엔드포인트
- [ ] Access Token Redis 블랙리스트 등록 (남은 TTL로 만료 설정)
- [ ] Refresh Token Redis에서 삭제
- [ ] JwtAuthGuard에서 블랙리스트 확인 로직 추가

## 🎯 완료 기준
- 로그아웃 후 기존 Access Token으로 API 호출 시 401 응답
- Redis에서 블랙리스트 항목 확인 가능

## 📎 메타
- **WBS:** 2.1.4 | **공수:** 0.5일 | **담당:** D1
- **의존성:** #2.1.3" \
    "sprint-2,backend,D1" "$M"

  create_issue "[2.1.5] 사용자 프로필 API" \
"## 📋 작업 개요
로그인한 사용자의 프로필 조회 및 수정 API

## ✅ 작업 항목
- [ ] \`GET /v1/users/me\` — 내 프로필 조회
- [ ] \`PATCH /v1/users/me\` — 이름, 전화번호 수정
- [ ] \`POST /v1/users/me/addresses\` — 배송지 등록 (최대 5개)
- [ ] \`PATCH /v1/users/me/addresses/:id\` — 배송지 수정
- [ ] \`DELETE /v1/users/me/addresses/:id\` — 배송지 삭제

## 🎯 완료 기준
- 인증되지 않은 요청 → 401
- 다른 사용자 리소스 접근 시 403

## 📎 메타
- **WBS:** 2.1.5 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #2.1.2" \
    "sprint-2,backend,D1" "$M"

  create_issue "[2.1.6] 인증 서비스 단위 테스트" \
"## 📋 작업 개요
AuthService, UsersService Jest 단위 테스트 작성

## ✅ 작업 항목
- [ ] 회원가입: 정상, 중복 이메일, 유효성 실패 케이스
- [ ] 로그인: 정상, 잘못된 비밀번호, 미존재 이메일 케이스
- [ ] 토큰 갱신: 정상, 만료 토큰, 블랙리스트 케이스
- [ ] 로그아웃 후 토큰 무효화 케이스
- [ ] 테스트 커버리지 80% 이상

## 🎯 완료 기준
- \`pnpm --filter @mall/api test\` 통과
- 커버리지 리포트 80%+ 확인

## 📎 메타
- **WBS:** 2.1.6 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #2.1.5" \
    "sprint-2,testing,D1" "$M"

  create_issue "[2.2.1] 회원가입 페이지 UI" \
"## 📋 작업 개요
사용자 회원가입 폼 및 유효성 검사 UI 구현

## ✅ 작업 항목
- [ ] \`/register\` 페이지 — 이름, 이메일, 비밀번호, 비밀번호 확인 폼
- [ ] React Hook Form + Zod 유효성 검사
- [ ] 비밀번호 강도 표시 (약/보통/강)
- [ ] 가입 완료 후 이메일 인증 안내 페이지
- [ ] 이미 계정 있음 → 로그인 페이지 링크

## 🎯 완료 기준
- 유효성 오류 메시지 실시간 표시
- 가입 성공 후 인증 안내 페이지로 이동

## 📎 메타
- **WBS:** 2.2.1 | **공수:** 1.5일 | **담당:** D2
- **의존성:** #2.1.1" \
    "sprint-2,frontend,D2" "$M"

  create_issue "[2.2.2] 로그인 페이지 UI" \
"## 📋 작업 개요
사용자 로그인 폼 UI 구현

## ✅ 작업 항목
- [ ] \`/login\` 페이지 — 이메일, 비밀번호 폼
- [ ] 로그인 실패 에러 메시지 표시
- [ ] 비밀번호 표시/숨기기 토글
- [ ] 로딩 상태 중 버튼 비활성화
- [ ] 계정 없음 → 회원가입 링크

## 🎯 완료 기준
- 성공 시 이전 페이지 또는 메인으로 리다이렉트
- 로그인 상태에서 /login 접근 시 메인으로 리다이렉트

## 📎 메타
- **WBS:** 2.2.2 | **공수:** 1일 | **담당:** D2
- **의존성:** #2.1.2" \
    "sprint-2,frontend,D2" "$M"

  create_issue "[2.2.3] 인증 상태 전역 관리 (Zustand)" \
"## 📋 작업 개요
앱 전체 인증 상태를 관리하는 클라이언트 스토어 구현

## ✅ 작업 항목
- [ ] Zustand auth store: user, accessToken, isAuthenticated
- [ ] 토큰 localStorage 저장/조회/삭제
- [ ] 앱 초기화 시 토큰 유효성 확인
- [ ] Access Token 만료 전 자동 갱신 (만료 5분 전 백그라운드 갱신)
- [ ] 인증 상태 변경 시 Header 컴포넌트 즉시 반영

## 🎯 완료 기준
- 새로고침 후 로그인 상태 유지
- 탭 전환 후에도 인증 상태 동기화

## 📎 메타
- **WBS:** 2.2.3 | **공수:** 1일 | **담당:** D2
- **의존성:** #2.1.3" \
    "sprint-2,frontend,D2" "$M"

  create_issue "[2.2.4] Protected Route 미들웨어 구현" \
"## 📋 작업 개요
인증이 필요한 페이지 접근 제어

## ✅ 작업 항목
- [ ] Next.js \`middleware.ts\` 작성
- [ ] 비인증 상태에서 보호 경로 접근 시 \`/login\` 리다이렉트
- [ ] 보호 경로 목록 정의: \`/mypage\`, \`/orders\`, \`/checkout\`
- [ ] 로그인 후 원래 요청 URL로 복귀 (\`callbackUrl\` 파라미터)

## 🎯 완료 기준
- 비로그인 시 /orders 접근 → /login?callbackUrl=/orders 리다이렉트
- 로그인 후 원래 페이지로 복귀

## 📎 메타
- **WBS:** 2.2.4 | **공수:** 0.5일 | **담당:** D2
- **의존성:** #2.2.3" \
    "sprint-2,frontend,D2" "$M"

  create_issue "[2.2.5] 마이페이지 UI (프로필 + 배송지)" \
"## 📋 작업 개요
로그인한 사용자의 프로필 및 배송지 관리 UI

## ✅ 작업 항목
- [ ] \`/mypage\` 레이아웃 — 사이드 네비게이션 (프로필/주문내역/배송지)
- [ ] 프로필 수정 폼 (이름, 전화번호)
- [ ] 배송지 목록/추가/수정/삭제 UI
- [ ] 기본 배송지 지정 기능
- [ ] 변경 사항 저장 성공/실패 토스트 알림

## 🎯 완료 기준
- 배송지 최대 5개 등록 제한 UI 표시
- 수정 후 새로고침 시 변경사항 유지

## 📎 메타
- **WBS:** 2.2.5 | **공수:** 2일 | **담당:** D2
- **의존성:** #2.1.5" \
    "sprint-2,frontend,D2" "$M"

  create_issue "[2.3.1] 인증 플로우 통합 검증" \
"## 📋 작업 개요
Sprint 2 완료 시점 전체 인증 플로우 수동 통합 테스트

## ✅ 작업 항목
- [ ] 시나리오 1: 회원가입 → 이메일 인증 → 로그인 → 토큰 갱신 → 로그아웃
- [ ] 시나리오 2: 잘못된 비밀번호 5회 → 계정 잠금 → 잠금 해제 확인
- [ ] 시나리오 3: Protected Route 리다이렉트 → 로그인 → 원래 페이지 복귀
- [ ] API 응답 형식 표준화 확인 (모든 응답 ApiResponse 래핑 여부)
- [ ] 발견된 버그 이슈 등록 및 수정

## 🎯 완료 기준
- 3가지 시나리오 모두 정상 동작
- 버그 이슈 0개 (또는 다음 스프린트로 이관)

## 📎 메타
- **WBS:** 2.3.1 | **공수:** 0.5일 | **담당:** D1 + D2
- **의존성:** #2.2.5" \
    "sprint-2,testing,D1,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# Sprint 3 — 상품 관리 (06/15 ~ 06/26)
# ══════════════════════════════════════════════════════════════
create_sprint3_issues() {
  local M="Sprint 3"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}🛍️  Sprint 3 — 상품 관리 (06/15~06/26)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[3.1.1] 카테고리 CRUD API" \
"## 📋 작업 개요
계층형 카테고리 관리 API (관리자 전용)

## ✅ 작업 항목
- [ ] \`GET /v1/categories\` — 전체 카테고리 트리 조회
- [ ] \`POST /v1/categories\` — 카테고리 생성 (Admin)
- [ ] \`PATCH /v1/categories/:id\` — 수정 (Admin)
- [ ] \`DELETE /v1/categories/:id\` — 삭제 (하위 카테고리/상품 있으면 409, Admin)
- [ ] 부모-자식 계층 구조 지원 (parent_id nullable)

## 🎯 완료 기준
- 최대 2depth 카테고리 구조 정상 조회
- 일반 사용자 생성 요청 시 403

## 📎 메타
- **WBS:** 3.1.1 | **공수:** 1일 | **담당:** D1" \
    "sprint-3,backend,D1" "$M"

  create_issue "[3.1.2] 상품 CRUD API" \
"## 📋 작업 개요
상품 등록/수정/삭제 API (관리자 전용)

## ✅ 작업 항목
- [ ] \`POST /v1/products\` — 상품 등록 (Admin)
- [ ] \`PATCH /v1/products/:id\` — 수정 (Admin)
- [ ] \`DELETE /v1/products/:id\` — 삭제 / 소프트 삭제 (Admin)
- [ ] 재고 증감 API: \`PATCH /v1/products/:id/stock\`
- [ ] 이미지 URL 배열 처리 (최대 5개)
- [ ] \`CreateProductDto\` 유효성 검사

## 🎯 완료 기준
- 상품 생성 후 목록에서 조회 가능
- 재고 0 상품 '품절' 상태 자동 전환

## 📎 메타
- **WBS:** 3.1.2 | **공수:** 2일 | **담당:** D1
- **의존성:** #3.1.1" \
    "sprint-3,backend,D1,high-priority" "$M"

  create_issue "[3.1.3] 상품 목록 조회 API (검색 · 필터 · 정렬)" \
"## 📋 작업 개요
다양한 조건으로 상품을 조회하는 목록 API

## ✅ 작업 항목
- [ ] \`GET /v1/products\` — 페이지네이션 (page, limit)
- [ ] 카테고리 필터 (\`categoryId\` 쿼리 파라미터)
- [ ] 키워드 검색 (\`q\` — 상품명, 설명 ILIKE)
- [ ] 가격 범위 필터 (\`minPrice\`, \`maxPrice\`)
- [ ] 정렬: 최신순/가격낮은순/가격높은순/인기순
- [ ] 품절 상품 제외 옵션 (\`inStockOnly\`)

## 🎯 완료 기준
- 응답 시간 500ms 이하 (인덱스 적용 전)
- 페이지네이션 메타데이터 정확도 확인

## 📎 메타
- **WBS:** 3.1.3 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #3.1.2" \
    "sprint-3,backend,D1" "$M"

  create_issue "[3.1.4] 상품 상세 조회 API" \
"## 📋 작업 개요
단일 상품 상세 정보 조회

## ✅ 작업 항목
- [ ] \`GET /v1/products/:id\` — 상품 상세 + 카테고리 정보
- [ ] 조회수 증가 (Redis incr, 5분마다 DB 동기화)
- [ ] 관련 상품 추천 (동일 카테고리 랜덤 4개)
- [ ] 미존재 상품 404 응답

## 🎯 완료 기준
- 응답에 카테고리 정보 포함 확인
- 조회수 증가 동작 확인 (Redis → DB 동기화)

## 📎 메타
- **WBS:** 3.1.4 | **공수:** 1일 | **담당:** D1
- **의존성:** #3.1.3" \
    "sprint-3,backend,D1" "$M"

  create_issue "[3.1.5] Redis 캐싱 적용 (상품 목록/상세)" \
"## 📋 작업 개요
자주 조회되는 상품 API에 Redis 캐시 레이어 추가

## ✅ 작업 항목
- [ ] 상품 목록 캐시: 5분 TTL (카테고리/검색어 조합 키)
- [ ] 상품 상세 캐시: 10분 TTL
- [ ] 상품 수정/삭제 시 관련 캐시 무효화
- [ ] 재고 변경 시 해당 상품 캐시 즉시 무효화
- [ ] 캐시 히트율 모니터링 로그 추가

## 🎯 완료 기준
- 캐시 적용 후 응답 시간 50% 단축
- 상품 수정 후 목록 재조회 시 최신 데이터 반환

## 📎 메타
- **WBS:** 3.1.5 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #3.1.4" \
    "sprint-3,backend,D1" "$M"

  create_issue "[3.1.6] 상품 서비스 단위 테스트" \
"## 📋 작업 개요
ProductsService 단위 테스트 작성

## ✅ 작업 항목
- [ ] 상품 생성/수정/삭제 정상 케이스
- [ ] 재고 부족 상태 처리 케이스
- [ ] 캐시 히트/미스 케이스
- [ ] 검색/필터/정렬 조합 케이스
- [ ] 커버리지 80% 이상

## 🎯 완료 기준
- \`pnpm --filter @mall/api test\` 통과
- 캐시 관련 테스트 포함 확인

## 📎 메타
- **WBS:** 3.1.6 | **공수:** 1일 | **담당:** D1
- **의존성:** #3.1.5" \
    "sprint-3,testing,D1" "$M"

  create_issue "[3.2.1] 상품 목록 페이지 UI" \
"## 📋 작업 개요
상품 목록 페이지 구현

## ✅ 작업 항목
- [ ] 상품 카드 그리드 레이아웃 (2/3/4열 반응형)
- [ ] 카테고리 사이드바 필터
- [ ] 가격/재고/정렬 필터 UI (URL 쿼리 파라미터 반영)
- [ ] 무한 스크롤 (Intersection Observer)
- [ ] 상품 없음 빈 상태 UI
- [ ] Skeleton 로딩 상태

## 🎯 완료 기준
- 필터 변경 시 URL 파라미터 업데이트 및 북마크 가능
- 무한 스크롤로 다음 페이지 자동 로드

## 📎 메타
- **WBS:** 3.2.1 | **공수:** 2.5일 | **담당:** D2
- **의존성:** #3.1.3" \
    "sprint-3,frontend,D2,high-priority" "$M"

  create_issue "[3.2.2] 상품 검색 기능 UI" \
"## 📋 작업 개요
헤더 검색창 및 검색 결과 페이지

## ✅ 작업 항목
- [ ] 헤더 검색창: 디바운스 300ms 자동완성
- [ ] \`/search?q=키워드\` 검색 결과 페이지
- [ ] 검색어 하이라이팅
- [ ] 최근 검색어 localStorage 저장 (최대 10개)
- [ ] 검색 결과 없음 안내 UI

## 🎯 완료 기준
- 타이핑 후 300ms 뒤 API 호출 (불필요한 호출 방지)
- 검색 결과에서 상품명 키워드 하이라이팅

## 📎 메타
- **WBS:** 3.2.2 | **공수:** 1일 | **담당:** D2
- **의존성:** #3.1.3" \
    "sprint-3,frontend,D2" "$M"

  create_issue "[3.2.3] 상품 상세 페이지 UI" \
"## 📋 작업 개요
상품 상세 정보 및 구매 액션 UI

## ✅ 작업 항목
- [ ] 상품 이미지 갤러리 (썸네일 + 메인 이미지 전환)
- [ ] 상품명, 가격, 재고 상태, 설명 표시
- [ ] 수량 선택 (재고 한도 내)
- [ ] '장바구니 담기' 버튼 (로그인 필요 시 리다이렉트)
- [ ] '바로 구매' 버튼
- [ ] 관련 상품 섹션 (하단 4개)
- [ ] 품절 시 버튼 비활성화

## 🎯 완료 기준
- 재고 수량 초과 선택 불가
- 비로그인 장바구니 시도 → 로그인 페이지 리다이렉트

## 📎 메타
- **WBS:** 3.2.3 | **공수:** 2일 | **담당:** D2
- **의존성:** #3.1.4" \
    "sprint-3,frontend,D2,high-priority" "$M"

  create_issue "[3.2.4] 관리자 상품 관리 UI" \
"## 📋 작업 개요
관리자용 상품 등록/수정/재고 관리 페이지

## ✅ 작업 항목
- [ ] \`/admin/products\` — 상품 목록 테이블 (검색/필터/일괄삭제)
- [ ] \`/admin/products/new\` — 상품 등록 폼
- [ ] \`/admin/products/:id/edit\` — 상품 수정 폼
- [ ] 이미지 URL 다중 입력 UI
- [ ] 재고 수량 직접 수정 기능
- [ ] Admin 권한 가드 (일반 사용자 접근 차단)

## 🎯 완료 기준
- Admin 계정으로만 접근 가능
- 상품 등록 후 목록에 즉시 표시

## 📎 메타
- **WBS:** 3.2.4 | **공수:** 2일 | **담당:** D2
- **의존성:** #3.1.2" \
    "sprint-3,frontend,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# Sprint 4 — 장바구니 · 주문 (06/29 ~ 07/10)
# ══════════════════════════════════════════════════════════════
create_sprint4_issues() {
  local M="Sprint 4"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}🛒 Sprint 4 — 장바구니 · 주문 (06/29~07/10)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[4.1.1] 장바구니 API (Redis 기반)" \
"## 📋 작업 개요
Redis Hash를 이용한 세션별 장바구니 관리

## ✅ 작업 항목
- [ ] \`POST /v1/cart/items\` — 상품 추가 (재고 확인)
- [ ] \`PATCH /v1/cart/items/:productId\` — 수량 변경
- [ ] \`DELETE /v1/cart/items/:productId\` — 항목 삭제
- [ ] \`DELETE /v1/cart\` — 전체 비우기
- [ ] \`GET /v1/cart\` — 장바구니 조회 (상품 정보 조인)
- [ ] Redis Key: \`cart:{userId}\`, TTL 7일

## 🎯 완료 기준
- 상품 재고 초과 추가 시 400 응답
- 장바구니 합계 금액 정확도 확인

## 📎 메타
- **WBS:** 4.1.1 | **공수:** 2일 | **담당:** D1
- **의존성:** #2.1.2, #3.1.2" \
    "sprint-4,backend,D1,high-priority" "$M"

  create_issue "[4.1.2] 주문 전 재고 검증 미들웨어" \
"## 📋 작업 개요
장바구니 → 주문 전환 시 실시간 재고 검증

## ✅ 작업 항목
- [ ] 주문 생성 전 전체 장바구니 항목 재고 일괄 확인
- [ ] 재고 부족 항목 목록 응답 (어떤 상품이 부족한지 명시)
- [ ] 재고 예약 (Pessimistic Lock or Redis Set NX)
- [ ] 결제 미완료 시 5분 후 예약 자동 해제

## 🎯 완료 기준
- 동시 주문 시나리오에서 재고 초과 방지
- 예약 후 5분 내 미결제 시 재고 자동 복구

## 📎 메타
- **WBS:** 4.1.2 | **공수:** 1일 | **담당:** D1
- **의존성:** #4.1.1, #3.1.2" \
    "sprint-4,backend,D1,high-priority" "$M"

  create_issue "[4.1.3] 주문 생성 API (Saga 패턴)" \
"## 📋 작업 개요
분산 트랜잭션 Saga 패턴을 활용한 주문 생성 플로우

## ✅ 작업 항목
- [ ] \`POST /v1/orders\` — 주문 생성
- [ ] Saga Step 1: 재고 예약 확인
- [ ] Saga Step 2: 주문 레코드 생성 (PENDING 상태)
- [ ] Saga Step 3: 결제 요청 트리거 (이벤트 발행)
- [ ] 실패 시 보상 트랜잭션: 재고 예약 해제 + 주문 취소
- [ ] \`CreateOrderDto\` 유효성 검사 (배송지 필수)

## 🎯 완료 기준
- 주문 생성 → orderId 즉시 반환
- 중간 단계 실패 시 이전 상태로 완전 롤백

## 📎 메타
- **WBS:** 4.1.3 | **공수:** 2.5일 | **담당:** D1
- **의존성:** #4.1.2" \
    "sprint-4,backend,D1,high-priority" "$M"

  create_issue "[4.1.4] 주문 조회 · 취소 API" \
"## 📋 작업 개요
주문 목록/상세 조회 및 취소 API

## ✅ 작업 항목
- [ ] \`GET /v1/orders\` — 내 주문 목록 (페이지네이션, 상태 필터)
- [ ] \`GET /v1/orders/:id\` — 주문 상세 (항목, 결제, 배송 정보 포함)
- [ ] \`DELETE /v1/orders/:id\` — 주문 취소 (PENDING/PAYMENT_COMPLETED 상태만)
- [ ] 취소 보상 트랜잭션: 재고 복구 + 결제 환불 요청
- [ ] 타인 주문 조회/취소 시 403

## 🎯 완료 기준
- 배송 시작 후 취소 요청 시 409 응답
- 취소 후 재고 복구 확인

## 📎 메타
- **WBS:** 4.1.4 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #4.1.3" \
    "sprint-4,backend,D1" "$M"

  create_issue "[4.1.5] 주문 서비스 단위 테스트" \
"## 📋 작업 개요
OrdersService Saga 플로우 단위 테스트

## ✅ 작업 항목
- [ ] 정상 주문 생성 플로우 (Saga 전 단계 성공)
- [ ] 재고 부족 시 Saga 롤백 테스트
- [ ] 결제 실패 시 주문 취소 보상 트랜잭션 테스트
- [ ] 취소 불가 상태에서 취소 요청 거부 테스트
- [ ] 동시 주문 재고 경합 시나리오 테스트

## 🎯 완료 기준
- 모든 Saga 실패 케이스에서 롤백 완료 확인
- 커버리지 80% 이상

## 📎 메타
- **WBS:** 4.1.5 | **공수:** 1일 | **담당:** D1
- **의존성:** #4.1.4" \
    "sprint-4,testing,D1" "$M"

  create_issue "[4.2.1] 장바구니 UI" \
"## 📋 작업 개요
사용자 장바구니 페이지 및 미니 카트 구현

## ✅ 작업 항목
- [ ] \`/cart\` 페이지 — 장바구니 항목 목록
- [ ] 수량 조절 (+ / - 버튼, 직접 입력)
- [ ] 항목 삭제 / 전체 비우기
- [ ] 합계 금액 실시간 계산
- [ ] 재고 초과 수량 선택 시 경고
- [ ] Header 장바구니 아이콘 뱃지 (담긴 수량)

## 🎯 완료 기준
- 수량 변경 시 합계 즉시 업데이트
- 빈 장바구니 상태 UI (상품 목록으로 유도 링크)

## 📎 메타
- **WBS:** 4.2.1 | **공수:** 2일 | **담당:** D2
- **의존성:** #4.1.1" \
    "sprint-4,frontend,D2,high-priority" "$M"

  create_issue "[4.2.2] 주문서 작성 페이지 UI" \
"## 📋 작업 개요
배송지 선택 및 주문 최종 확인 페이지

## ✅ 작업 항목
- [ ] \`/checkout\` 페이지 — 3단계 스텝 (배송지 > 주문확인 > 결제)
- [ ] 배송지 선택 (저장된 배송지 목록) + 신규 배송지 입력
- [ ] 주문 상품 목록, 수량, 가격 요약
- [ ] 쿠폰/포인트 적용 UI (빈 구현, 다음 버전)
- [ ] 최종 결제 금액 표시

## 🎯 완료 기준
- 배송지 미선택 시 다음 단계 진행 불가
- 뒤로 가기 시 입력 내용 유지

## 📎 메타
- **WBS:** 4.2.2 | **공수:** 2일 | **담당:** D2
- **의존성:** #4.1.3, #4.2.1" \
    "sprint-4,frontend,D2,high-priority" "$M"

  create_issue "[4.2.3] 주문 목록 · 상세 페이지 UI" \
"## 📋 작업 개요
주문 내역 조회 및 상태 추적 UI

## ✅ 작업 항목
- [ ] \`/orders\` — 주문 목록 (최신순, 상태별 탭 필터)
- [ ] \`/orders/:id\` — 주문 상세 (상품, 배송지, 결제 정보)
- [ ] 주문 상태 배지 + 타임라인 (OrderStatusBadge 컴포넌트 활용)
- [ ] 취소 가능 상태에서만 취소 버튼 표시
- [ ] 취소 확인 모달

## 🎯 완료 기준
- 주문 상태에 따라 취소 버튼 노출/비노출 정확도
- 타임라인에서 현재 상태 강조 표시

## 📎 메타
- **WBS:** 4.2.3 | **공수:** 1.5일 | **담당:** D2
- **의존성:** #4.1.4" \
    "sprint-4,frontend,D2" "$M"

  create_issue "[4.2.4] 주문 플로우 통합 테스트" \
"## 📋 작업 개요
상품 선택부터 주문 완료까지 전체 플로우 통합 검증

## ✅ 작업 항목
- [ ] 시나리오: 상품 상세 → 장바구니 → 주문서 → 주문 생성 완료
- [ ] 재고 부족 시나리오 (주문 중 재고 소진)
- [ ] 주문 취소 시나리오 및 재고 복구 확인
- [ ] 동시 주문 시나리오 (두 사용자 동일 상품 마지막 재고 경쟁)
- [ ] 발견 버그 즉시 이슈 등록

## 🎯 완료 기준
- 4가지 시나리오 모두 정상 동작
- 재고 불일치 데이터 없음 확인

## 📎 메타
- **WBS:** 4.2.4 | **공수:** 1일 | **담당:** D1 + D2
- **의존성:** #4.2.3" \
    "sprint-4,testing,D1,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# Sprint 5 — 결제 · 배송 추적 (07/13 ~ 07/24)
# ══════════════════════════════════════════════════════════════
create_sprint5_issues() {
  local M="Sprint 5"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}💳 Sprint 5 — 결제 · 배송 추적 (07/13~07/24)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[5.1.1] 결제 PG 연동 (토스페이먼츠)" \
"## 📋 작업 개요
토스페이먼츠 API를 통한 결제 요청 및 승인 처리

## ✅ 작업 항목
- [ ] 토스페이먼츠 SDK 설치 및 API 키 설정
- [ ] \`POST /v1/payments/request\` — 결제창 데이터 생성
- [ ] \`POST /v1/payments/confirm\` — 결제 최종 승인 (paymentKey, orderId, amount 검증)
- [ ] 웹훅 수신 엔드포인트 \`POST /v1/payments/webhook\`
- [ ] 웹훅 서명 검증 (HMAC-SHA256)
- [ ] 결제 금액 위변조 방지 (DB 금액과 비교)

## 🎯 완료 기준
- 테스트 결제키로 결제 승인/실패 정상 처리
- 웹훅 위변조 시도 시 401 응답

## ⚠️ 선행 작업
토스페이먼츠 개발자 센터 가입 및 테스트 API 키 발급 필요 (Sprint 4에서 미리 신청)

## 📎 메타
- **WBS:** 5.1.1 | **공수:** 2.5일 | **담당:** D1
- **의존성:** #4.1.3" \
    "sprint-5,backend,D1,high-priority" "$M"

  create_issue "[5.1.2] 결제 성공 처리 플로우" \
"## 📋 작업 개요
결제 승인 후 후속 처리 (주문 상태, 재고, 배송 준비)

## ✅ 작업 항목
- [ ] 주문 상태 PAYMENT_COMPLETED로 업데이트
- [ ] 재고 예약 → 최종 차감 확정
- [ ] Payment 레코드 생성 (paidAt, 결제 방법, 거래 ID)
- [ ] 결제 완료 이벤트 발행 → 배송 서비스 트리거
- [ ] 구매 확인 이메일 발송 (비동기)

## 🎯 완료 기준
- 결제 완료 → 주문 상태 즉시 변경 확인
- 재고 최종 차감 정확도 검증

## 📎 메타
- **WBS:** 5.1.2 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #5.1.1" \
    "sprint-5,backend,D1" "$M"

  create_issue "[5.1.3] 결제 실패 · 취소 · 환불 처리" \
"## 📋 작업 개요
결제 실패 및 환불 보상 트랜잭션 처리

## ✅ 작업 항목
- [ ] 결제 실패 시 보상: 재고 예약 해제 + 주문 CANCELLED 처리
- [ ] \`POST /v1/payments/:id/cancel\` — 결제 취소/환불 API
- [ ] 토스페이먼츠 취소 API 연동
- [ ] 부분 환불 지원 (refundAmount)
- [ ] 환불 완료 후 주문 상태 업데이트

## 🎯 완료 기준
- 결제 실패 시 30초 내 재고 복구 확인
- 환불 요청 후 PG사 취소 완료 응답 확인

## 📎 메타
- **WBS:** 5.1.3 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #5.1.2" \
    "sprint-5,backend,D1" "$M"

  create_issue "[5.1.4] 결제 서비스 단위 테스트" \
"## 📋 작업 개요
PaymentService 테스트 (PG API Mocking)

## ✅ 작업 항목
- [ ] 결제 승인 정상 케이스 (Mock PG 응답)
- [ ] 결제 실패 케이스 및 보상 트랜잭션 검증
- [ ] 웹훅 서명 위변조 감지 테스트
- [ ] 결제 금액 불일치 방지 테스트
- [ ] 환불 정상/실패 케이스

## 🎯 완료 기준
- PG API 실제 호출 없이 테스트 완결
- 보안 관련 테스트 (위변조, 금액 불일치) 모두 포함

## 📎 메타
- **WBS:** 5.1.4 | **공수:** 1일 | **담당:** D1
- **의존성:** #5.1.3" \
    "sprint-5,testing,D1" "$M"

  create_issue "[5.2.1] 배송 생성 API" \
"## 📋 작업 개요
결제 완료 이벤트 수신 후 배송 레코드 자동 생성

## ✅ 작업 항목
- [ ] 결제 완료 이벤트 리스너 구현
- [ ] Delivery 레코드 생성 (PREPARING 상태)
- [ ] \`GET /v1/deliveries/:orderId\` — 배송 정보 조회
- [ ] 배송사 연동 준비 (Mock 배송사 API 인터페이스 정의)

## 🎯 완료 기준
- 결제 완료 후 자동으로 Delivery 레코드 생성 확인
- 배송 조회 API 정상 응답

## 📎 메타
- **WBS:** 5.2.1 | **공수:** 1일 | **담당:** D1
- **의존성:** #5.1.2" \
    "sprint-5,backend,D1" "$M"

  create_issue "[5.2.2] 배송 상태 추적 API" \
"## 📋 작업 개요
배송사 API 연동 및 실시간 배송 상태 업데이트

## ✅ 작업 항목
- [ ] 배송사 API 폴링 (30분 간격, 배송 중 상태만)
- [ ] \`PATCH /v1/deliveries/:id/status\` — 배송 상태 업데이트 (Webhook)
- [ ] 배송 이력 저장 (상태, 위치, 시간)
- [ ] 배송 완료 시 주문 상태 DELIVERED 업데이트
- [ ] 배송 지연 알림 트리거 (예상 도착일 초과 시)

## 🎯 완료 기준
- 배송 상태 이력 순서대로 조회 가능
- 배송 완료 후 주문 상태 자동 변경 확인

## 📎 메타
- **WBS:** 5.2.2 | **공수:** 1.5일 | **담당:** D1
- **의존성:** #5.2.1" \
    "sprint-5,backend,D1" "$M"

  create_issue "[5.3.1] 결제 UI (PG 결제창 연동)" \
"## 📋 작업 개요
토스페이먼츠 결제창 호출 및 결제 처리 UI

## ✅ 작업 항목
- [ ] 토스페이먼츠 JS SDK 로드 및 결제창 호출
- [ ] 결제 수단 선택 UI (카드/계좌이체/가상계좌)
- [ ] 결제 진행 중 로딩 오버레이
- [ ] 결제 성공 콜백: \`/orders/:id/complete\`로 이동
- [ ] 결제 실패 콜백: 에러 메시지 표시 + 재시도 버튼

## 🎯 완료 기준
- 테스트 결제창 정상 호출 및 응답 처리
- 결제 취소(X 버튼) 시 주문서 페이지 유지

## 📎 메타
- **WBS:** 5.3.1 | **공수:** 2.5일 | **담당:** D2
- **의존성:** #5.1.1" \
    "sprint-5,frontend,D2,high-priority" "$M"

  create_issue "[5.3.2] 결제 완료 · 실패 페이지 UI" \
"## 📋 작업 개요
결제 결과 안내 페이지

## ✅ 작업 항목
- [ ] \`/orders/:id/complete\` — 결제 성공 페이지 (주문번호, 예상 배송일)
- [ ] 결제 실패 페이지 — 실패 사유, 재시도/주문취소 버튼
- [ ] 성공 페이지에서 주문 상세로 이동 링크
- [ ] 성공 애니메이션 (체크 아이콘)

## 🎯 완료 기준
- 성공/실패 페이지 URL 직접 접근 시 적절히 처리
- 결제 중복 완료 방지 (이미 완료된 주문 재접근 처리)

## 📎 메타
- **WBS:** 5.3.2 | **공수:** 1일 | **담당:** D2
- **의존성:** #5.3.1" \
    "sprint-5,frontend,D2" "$M"

  create_issue "[5.3.3] 배송 추적 UI" \
"## 📋 작업 개요
주문 상세 페이지 내 배송 추적 컴포넌트

## ✅ 작업 항목
- [ ] 배송 상태 진행 타임라인 컴포넌트
- [ ] 현재 위치 및 최근 배송 이력 표시
- [ ] 예상 도착일 표시
- [ ] 배송사 + 운송장 번호 표시 (외부 배송 조회 링크)
- [ ] 배송 완료 시 구매 확정/후기 작성 버튼 (빈 구현)

## 🎯 완료 기준
- 배송 상태 변경 시 UI 자동 반영 (30초 폴링 or SSE)
- 각 상태별 타임라인 아이콘 정상 표시

## 📎 메타
- **WBS:** 5.3.3 | **공수:** 1.5일 | **담당:** D2
- **의존성:** #5.2.2" \
    "sprint-5,frontend,D2" "$M"

  create_issue "[5.3.4] 주문 · 결제 · 배송 알림 UI" \
"## 📋 작업 개요
상태 변경 시 사용자에게 토스트/배너 알림 표시

## ✅ 작업 항목
- [ ] Toast 알림 컴포넌트 (성공/오류/경고/정보 variant)
- [ ] 결제 완료 → 성공 토스트
- [ ] 배송 상태 변경 → 정보 토스트 (폴링 기반)
- [ ] 에러 발생 → 오류 토스트 (재시도 안내)
- [ ] 알림 스택 처리 (여러 개 동시 표시)

## 🎯 완료 기준
- 토스트 자동 3초 후 사라짐
- 여러 알림 동시 표시 시 스택 정렬

## 📎 메타
- **WBS:** 5.3.4 | **공수:** 1일 | **담당:** D2
- **의존성:** #5.3.3" \
    "sprint-5,frontend,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# Sprint 6 — 테스트 · 배포 · MVP 릴리즈 (07/27 ~ 08/07)
# ══════════════════════════════════════════════════════════════
create_sprint6_issues() {
  local M="Sprint 6"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}🚀 Sprint 6 — 테스트 · 배포 · MVP 릴리즈 (07/27~08/07)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  create_issue "[6.1.1] API 통합 테스트 (커버리지 80%+)" \
"## 📋 작업 개요
Supertest 기반 전체 API 엔드포인트 통합 테스트

## ✅ 작업 항목
- [ ] 인증 플로우 E2E (회원가입 → 로그인 → API 호출)
- [ ] 상품 CRUD 전체 케이스
- [ ] 주문 생성 → 결제 → 배송 상태 전체 플로우
- [ ] 에러 케이스 (401/403/404/409/422) 응답 검증
- [ ] Jest 커버리지 리포트 생성 (목표: 80% 이상)

## 🎯 완료 기준
- \`pnpm --filter @mall/api test:cov\` 커버리지 80% 이상
- CI에서 테스트 통과 필수 설정

## 📎 메타
- **WBS:** 6.1.1 | **공수:** 2일 | **담당:** D1
- **의존성:** Sprint 5 전체 완료" \
    "sprint-6,testing,D1,high-priority" "$M"

  create_issue "[6.1.2] E2E 테스트 자동화 (Playwright)" \
"## 📋 작업 개요
핵심 사용자 시나리오 5개 Playwright 자동화

## ✅ 작업 항목
- [ ] 시나리오 1: 회원가입 → 이메일 인증 → 로그인
- [ ] 시나리오 2: 상품 검색 → 상세 → 장바구니 담기
- [ ] 시나리오 3: 장바구니 → 주문서 → 결제 완료
- [ ] 시나리오 4: 주문 취소 및 재고 복구 확인
- [ ] 시나리오 5: 배송 상태 추적 조회
- [ ] CI 파이프라인에 E2E 테스트 연동

## 🎯 완료 기준
- 5개 시나리오 headless 모드에서 통과
- GitHub Actions에서 E2E 자동 실행

## 📎 메타
- **WBS:** 6.1.2 | **공수:** 2일 | **담당:** D2
- **의존성:** Sprint 5 전체 완료" \
    "sprint-6,testing,D2,high-priority" "$M"

  create_issue "[6.1.3] 성능 테스트 (k6)" \
"## 📋 작업 개요
주요 API 부하 테스트 및 병목 구간 파악

## ✅ 작업 항목
- [ ] k6 스크립트 작성 (상품 목록, 주문 생성, 결제 API)
- [ ] 부하 시나리오: 동시 100 VU × 5분
- [ ] 목표 지표: p95 응답시간 < 500ms, 오류율 < 1%
- [ ] 병목 구간 분석 및 최적화 (N+1 쿼리, 미싱 인덱스 등)
- [ ] 결과 리포트 작성

## 🎯 완료 기준
- 부하 테스트 목표 지표 달성
- 발견된 성능 이슈 수정 또는 다음 버전 이슈 등록

## 📎 메타
- **WBS:** 6.1.3 | **공수:** 1일 | **담당:** D1
- **의존성:** #6.1.1" \
    "sprint-6,testing,D1" "$M"

  create_issue "[6.1.4] 보안 점검 (OWASP Top 10)" \
"## 📋 작업 개요
MVP 출시 전 보안 취약점 점검

## ✅ 작업 항목
- [ ] SQL Injection: Prisma ORM 파라미터 바인딩 확인
- [ ] XSS: Next.js 출력 이스케이핑, CSP 헤더 설정
- [ ] JWT: 알고리즘 고정(HS256), 만료 검증, 블랙리스트
- [ ] CORS: 허용 Origin 화이트리스트 확인
- [ ] Rate Limiting: API 엔드포인트별 임계값 검증
- [ ] 민감 정보: 응답/로그에 비밀번호/카드번호 노출 없음 확인
- [ ] 결제 금액 위변조 방지 로직 재검증

## 🎯 완료 기준
- OWASP 체크리스트 전 항목 확인 완료
- Critical 취약점 0개

## 📎 메타
- **WBS:** 6.1.4 | **공수:** 1일 | **담당:** D1 + D2" \
    "sprint-6,testing,D1,D2,high-priority" "$M"

  create_issue "[6.2.1] Docker 이미지 최적화" \
"## 📋 작업 개요
프로덕션용 Docker 이미지 크기 최소화

## ✅ 작업 항목
- [ ] Multi-stage build 적용 (builder → runner)
- [ ] Next.js \`output: standalone\` 빌드 적용
- [ ] non-root 사용자 실행 (보안)
- [ ] \`.dockerignore\` 최적화
- [ ] 이미지 크기 목표: web < 200MB, api < 150MB
- [ ] 이미지 취약점 스캔 (Trivy 또는 Docker Scout)

## 🎯 완료 기준
- 이미지 크기 목표 달성
- Critical 이미지 취약점 0개

## 📎 메타
- **WBS:** 6.2.1 | **공수:** 1일 | **담당:** D1" \
    "sprint-6,devops,D1" "$M"

  create_issue "[6.2.2] Kubernetes 매니페스트 작성" \
"## 📋 작업 개요
프로덕션 Kubernetes 배포 설정

## ✅ 작업 항목
- [ ] \`k8s/web/\`: Deployment, Service, HPA (CPU 70% 기준 2~5 replica)
- [ ] \`k8s/api/\`: Deployment, Service, HPA
- [ ] \`k8s/postgres/\`: StatefulSet, PVC (10Gi)
- [ ] \`k8s/redis/\`: StatefulSet
- [ ] \`k8s/ingress.yaml\`: Nginx Ingress + TLS
- [ ] ConfigMap (비밀 아닌 환경변수), Secret (DB 비밀번호, JWT 키)
- [ ] Liveness/Readiness Probe 설정

## 🎯 완료 기준
- \`kubectl apply\` 오류 없이 적용
- HPA 스케일 아웃/인 동작 확인

## 📎 메타
- **WBS:** 6.2.2 | **공수:** 2일 | **담당:** D1
- **의존성:** #6.2.1" \
    "sprint-6,devops,D1,high-priority" "$M"

  create_issue "[6.2.3] GitHub Actions CD 파이프라인 구성" \
"## 📋 작업 개요
자동 배포 파이프라인 구축 (staging 자동 / production 수동 승인)

## ✅ 작업 항목
- [ ] \`.github/workflows/deploy-staging.yml\`: develop 브랜치 push → 자동 배포
- [ ] \`.github/workflows/deploy-production.yml\`: main 브랜치 → 수동 승인 후 배포
- [ ] Prisma migrate deploy Job (별도 분리, DB 백업 후 실행)
- [ ] 배포 후 헬스체크 (curl \`/health\`)
- [ ] 배포 실패 시 Slack 알림

## 🎯 완료 기준
- staging 자동 배포 10분 내 완료
- production 배포 시 Approver 수동 승인 필요

## 📎 메타
- **WBS:** 6.2.3 | **공수:** 1일 | **담당:** D1
- **의존성:** #6.2.2" \
    "sprint-6,devops,D1" "$M"

  create_issue "[6.2.4] 모니터링 설정 (Prometheus + Grafana)" \
"## 📋 작업 개요
서비스 운영 모니터링 대시보드 구성

## ✅ 작업 항목
- [ ] NestJS \`@nestjs/terminus\` 헬스체크 엔드포인트 (\`/health\`)
- [ ] Prometheus 메트릭 수집 설정 (prom-client)
- [ ] Grafana 대시보드: API 응답시간, 오류율, Redis 히트율, DB 커넥션
- [ ] 알림 규칙: 오류율 5% 초과 / 응답시간 1s 초과 → Slack 알림
- [ ] 로그 중앙화 (Winston → CloudWatch 또는 Loki)

## 🎯 완료 기준
- Grafana 대시보드에서 실시간 메트릭 확인
- 임계값 초과 시 Slack 알림 동작 확인

## 📎 메타
- **WBS:** 6.2.4 | **공수:** 1.5일 | **담당:** D2
- **의존성:** #6.2.3" \
    "sprint-6,devops,D2" "$M"

  create_issue "[6.3.1] 스테이징 배포 및 QA 검증" \
"## 📋 작업 개요
스테이징 환경 전체 기능 최종 QA

## ✅ 작업 항목
- [ ] 스테이징 환경 전체 기능 체크리스트 점검
- [ ] 모바일 반응형 UI 검증 (iOS Safari, Android Chrome)
- [ ] 결제 테스트 (토스페이먼츠 테스트 결제키)
- [ ] 성능 측정 (Lighthouse Score: Performance 80+)
- [ ] 발견 버그 즉시 수정 및 재배포

## 🎯 완료 기준
- 체크리스트 전 항목 통과
- Lighthouse Performance 점수 80점 이상

## 📎 메타
- **WBS:** 6.3.1 | **공수:** 1.5일 | **담당:** D1 + D2
- **의존성:** #6.2.3" \
    "sprint-6,testing,D1,D2,high-priority" "$M"

  create_issue "[6.3.2] 프로덕션 배포 (무중단 Rolling Update)" \
"## 📋 작업 개요
MVP 첫 프로덕션 배포

## ✅ 작업 항목
- [ ] DB 백업 확인 (배포 전)
- [ ] \`prisma migrate deploy\` 실행 (다운타임 없는 마이그레이션 확인)
- [ ] Kubernetes Rolling Update 배포
- [ ] 배포 후 헬스체크 및 핵심 기능 스모크 테스트
- [ ] 이상 발생 시 즉시 Rollback 절차 숙지

## 🎯 완료 기준
- 배포 중 기존 서비스 중단 없음 확인
- 배포 후 헬스체크 통과

## 📎 메타
- **WBS:** 6.3.2 | **공수:** 0.5일 | **담당:** D1
- **의존성:** #6.3.1" \
    "sprint-6,devops,D1,high-priority" "$M"

  create_issue "[6.3.3] MVP 릴리즈 문서화" \
"## 📋 작업 개요
MVP 출시에 필요한 운영 문서 작성

## ✅ 작업 항목
- [ ] \`README.md\` 업데이트 (로컬 실행 가이드, 아키텍처 다이어그램)
- [ ] 환경변수 문서화 (각 패키지 \`.env.example\` 주석 완비)
- [ ] Runbook 작성 (서비스 재시작, DB 복구, Rollback 절차)
- [ ] API 문서 최신화 (Swagger + Postman Collection export)
- [ ] GitHub Releases v1.0.0 태그 및 릴리즈 노트 작성

## 🎯 완료 기준
- 신규 팀원이 README만 보고 로컬 환경 실행 가능
- v1.0.0 GitHub Release 생성

## 📎 메타
- **WBS:** 6.3.3 | **공수:** 1일 | **담당:** D2
- **의존성:** #6.3.2" \
    "sprint-6,devops,D2" "$M"
}

# ══════════════════════════════════════════════════════════════
# 메인
# ══════════════════════════════════════════════════════════════
main() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║   Online Shopping Mall — GitHub Issues 자동 생성     ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Repository:${NC} $REPO"
  echo -e "  ${BOLD}Dry-run:${NC}    $DRY_RUN"
  echo -e "  ${BOLD}API delay:${NC}  ${DELAY}s"
  echo -e "  ${BOLD}Total:${NC}      레이블 16개 + 마일스톤 6개 + 이슈 64개"
  echo ""

  if ! $DRY_RUN; then
    echo -e "${YELLOW}⚠️  실제 GitHub에 이슈를 생성합니다. 계속하시겠습니까? [y/N]${NC}"
    read -r confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "취소되었습니다."; exit 0; }
  fi

  check_prerequisites
  create_labels
  create_milestones

  create_sprint1_issues
  create_sprint2_issues
  create_sprint3_issues
  create_sprint4_issues
  create_sprint5_issues
  create_sprint6_issues

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║   ✅ 완료! 총 ${TOTAL_CREATED}개 이슈 생성                        ║${NC}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  👉 이슈 목록:  ${CYAN}https://github.com/$REPO/issues${NC}"
  echo -e "  👉 마일스톤:   ${CYAN}https://github.com/$REPO/milestones${NC}"
  echo -e "  👉 프로젝트:   ${CYAN}https://github.com/$REPO/projects${NC}"
  echo ""
}

main
