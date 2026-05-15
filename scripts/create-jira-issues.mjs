#!/usr/bin/env node
/**
 * Online Shopping Mall — Jira 티켓 자동 생성 스크립트
 *
 * 사용법:
 *   node scripts/create-jira-issues.mjs
 *   node scripts/create-jira-issues.mjs --dry-run
 *
 * 필수 환경변수 (.env.jira 파일 또는 실제 환경변수):
 *   JIRA_BASE_URL   https://your-domain.atlassian.net
 *   JIRA_EMAIL      your@email.com
 *   JIRA_API_TOKEN  Atlassian API 토큰 (https://id.atlassian.com/manage-profile/security/api-tokens)
 *   JIRA_PROJECT    프로젝트 키 (예: MALL)
 *
 * 의존성: Node.js 18+ (fetch 내장)
 */

import { readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');

// ── 환경변수 로드 (.env.jira 우선) ──────────────────────────
const envFile = resolve(ROOT, '.env.jira');
if (existsSync(envFile)) {
  for (const line of readFileSync(envFile, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const [key, ...rest] = trimmed.split('=');
    process.env[key.trim()] = rest.join('=').trim().replace(/^["']|["']$/g, '');
  }
}

const CONFIG = {
  baseUrl: process.env.JIRA_BASE_URL?.replace(/\/$/, ''),
  email: process.env.JIRA_EMAIL,
  apiToken: process.env.JIRA_API_TOKEN,
  project: process.env.JIRA_PROJECT,
};

const DRY_RUN = process.argv.includes('--dry-run');
const DELAY_MS = 300;

// ── 색상 출력 ────────────────────────────────────────────────
const c = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};
const log = {
  info: (msg) => console.log(`${c.blue}ℹ${c.reset}  ${msg}`),
  ok: (msg) => console.log(`${c.green}✓${c.reset}  ${msg}`),
  warn: (msg) => console.log(`${c.yellow}⚠${c.reset}  ${msg}`),
  error: (msg) => console.error(`${c.red}✗${c.reset}  ${msg}`),
  section: (msg) => console.log(`\n${c.bold}${c.cyan}━━ ${msg} ━━${c.reset}`),
  dry: (msg) => console.log(`${c.yellow}[DRY-RUN]${c.reset} ${msg}`),
};

// ── WBS 데이터 ───────────────────────────────────────────────
/**
 * @typedef {{ key: string, summary: string, description: string, issueType: string, epicKey?: string }} Issue
 */

const EPICS = [
  {
    key: 'API',
    summary: '[Epic] Backend API 개발',
    description:
      'NestJS 기반 쇼핑몰 백엔드 API 전체 구현. 인증, 상품, 주문, 결제, 배송, 사용자 도메인을 포함합니다.',
  },
  {
    key: 'WEB',
    summary: '[Epic] Frontend Web 개발',
    description:
      'Next.js App Router 기반 쇼핑몰 프론트엔드 구현. 상품, 장바구니, 주문, 마이페이지를 포함합니다.',
  },
  {
    key: 'INFRA',
    summary: '[Epic] 인프라 및 개발 환경 구성',
    description: 'Docker Compose, CI/CD, 환경변수 관리 등 개발 인프라 설정입니다.',
  },
];

/** @type {Array<Omit<Issue, 'epicKey'> & { epic: string }>} */
const STORIES = [
  // ── API Epic ──────────────────────────────────────────────
  {
    epic: 'API',
    summary: '상품 목록/상세 조회 API 구현',
    issueType: 'Story',
    description: `h3. 개요
상품 목록 조회 및 상세 조회 REST API를 구현합니다.

h3. 작업 내용
* GET /v1/products — 상품 목록 조회 (페이지네이션, 카테고리 필터)
* GET /v1/products/:id — 상품 상세 조회
* ProductsService 구현
* ProductsController 구현
* Prisma Product 모델 연동
* Swagger 문서 작성

h3. 완료 조건
* 단위 테스트 통과
* Swagger UI에서 API 확인 가능`,
  },
  {
    epic: 'API',
    summary: '상품 관리 API 구현 (CRUD)',
    issueType: 'Story',
    description: `h3. 개요
관리자용 상품 생성/수정/삭제 API를 구현합니다.

h3. 작업 내용
* POST /v1/products — 상품 생성 (Admin)
* PATCH /v1/products/:id — 상품 수정 (Admin)
* DELETE /v1/products/:id — 상품 삭제 (Admin)
* CreateProductDto, UpdateProductDto 작성
* Admin 권한 가드 적용
* 재고 관리 로직`,
  },
  {
    epic: 'API',
    summary: '주문 생성 및 목록 조회 API 구현',
    issueType: 'Story',
    description: `h3. 개요
주문 생성 및 주문 목록/상세 조회 API를 구현합니다.

h3. 작업 내용
* POST /v1/orders — 주문 생성
* GET /v1/orders — 내 주문 목록 조회
* GET /v1/orders/:id — 주문 상세 조회
* OrdersService, OrdersController 구현
* 주문 시 재고 차감 로직
* CreateOrderDto 작성`,
  },
  {
    epic: 'API',
    summary: '주문 상태 변경 API 구현',
    issueType: 'Story',
    description: `h3. 개요
주문 취소 및 관리자 상태 변경 API를 구현합니다.

h3. 작업 내용
* PATCH /v1/orders/:id/cancel — 주문 취소
* PATCH /v1/orders/:id/status — 주문 상태 변경 (Admin)
* 상태 전이 유효성 검사 (OrderStatus enum)
* 취소 시 재고 복구 로직`,
  },
  {
    epic: 'API',
    summary: '결제 처리 API 구현',
    issueType: 'Story',
    description: `h3. 개요
주문에 대한 결제 처리 API를 구현합니다.

h3. 작업 내용
* POST /v1/orders/:id/payment — 결제 요청
* GET /v1/orders/:id/payment — 결제 정보 조회
* PaymentService, PaymentController 구현
* PaymentMethod (CARD, BANK_TRANSFER, VIRTUAL_ACCOUNT) 처리
* 결제 완료 시 OrderStatus → PAYMENT_COMPLETED 변경`,
  },
  {
    epic: 'API',
    summary: '배송 추적 API 구현',
    issueType: 'Story',
    description: `h3. 개요
주문에 대한 배송 정보 조회 및 상태 업데이트 API를 구현합니다.

h3. 작업 내용
* GET /v1/orders/:id/delivery — 배송 정보 조회
* PATCH /v1/orders/:id/delivery — 배송 상태 업데이트 (Admin)
* DeliveryService, DeliveryController 구현
* DeliveryStatus 단계별 전이 검증
* 운송장 번호/택배사 관리`,
  },
  {
    epic: 'API',
    summary: '사용자 프로필 API 구현',
    issueType: 'Story',
    description: `h3. 개요
로그인한 사용자의 프로필 조회 및 수정 API를 구현합니다.

h3. 작업 내용
* GET /v1/users/me — 내 프로필 조회
* PATCH /v1/users/me — 프로필 수정
* UsersService, UsersController 구현
* JWT 인증 가드 적용
* 비밀번호 변경 기능`,
  },

  // ── WEB Epic ──────────────────────────────────────────────
  {
    epic: 'WEB',
    summary: '상품 목록/상세 페이지 구현',
    issueType: 'Story',
    description: `h3. 개요
Next.js App Router 기반 상품 목록 및 상세 페이지를 구현합니다.

h3. 작업 내용
* /products — 상품 목록 페이지
* /products/[id] — 상품 상세 페이지
* @mall/ui Card, Badge 컴포넌트 활용
* API 연동 (packages/web/src/lib/api.ts)
* 로딩/에러 상태 처리`,
  },
  {
    epic: 'WEB',
    summary: '장바구니 기능 구현',
    issueType: 'Story',
    description: `h3. 개요
클라이언트 사이드 장바구니 기능을 구현합니다.

h3. 작업 내용
* 장바구니 상태 관리 (Context API 또는 Zustand)
* 상품 추가/수량 변경/삭제
* /cart 장바구니 페이지
* 장바구니 아이콘 및 수량 뱃지
* 로컬스토리지 유지`,
  },
  {
    epic: 'WEB',
    summary: '주문/결제 페이지 구현',
    issueType: 'Story',
    description: `h3. 개요
장바구니에서 주문/결제로 이어지는 플로우를 구현합니다.

h3. 작업 내용
* /checkout — 주문 정보 입력 페이지 (배송지, 결제 수단)
* /orders/[id] — 주문 완료/상세 페이지
* 주문 생성 API 연동
* 결제 수단 선택 UI
* 폼 유효성 검사`,
  },
  {
    epic: 'WEB',
    summary: '마이페이지 - 주문 내역 구현',
    issueType: 'Story',
    description: `h3. 개요
사용자 마이페이지와 주문 내역 조회 기능을 구현합니다.

h3. 작업 내용
* /my/orders — 주문 내역 목록
* /my/orders/[id] — 주문 상세 및 배송 추적
* 주문 취소 기능
* OrderStatusBadge 컴포넌트 활용
* 인증 미들웨어 (미로그인 시 리다이렉트)`,
  },

  // ── INFRA Epic ────────────────────────────────────────────
  {
    epic: 'INFRA',
    summary: 'Docker Compose 환경 구성 완성',
    issueType: 'Task',
    description: `h3. 개요
로컬 개발 환경을 위한 Docker Compose 설정을 완성합니다.

h3. 작업 내용
* PostgreSQL 컨테이너 설정
* Redis 컨테이너 설정 (캐시/세션)
* API 서버 컨테이너 설정
* Web 서버 컨테이너 설정
* .env.example 환경변수 정리
* docker-compose up 단일 명령으로 전체 실행`,
  },
];

// ── Jira REST API 클라이언트 ─────────────────────────────────
function makeAuthHeader() {
  const token = Buffer.from(`${CONFIG.email}:${CONFIG.apiToken}`).toString('base64');
  return `Basic ${token}`;
}

async function jiraRequest(method, path, body) {
  const url = `${CONFIG.baseUrl}/rest/api/3${path}`;
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: makeAuthHeader(),
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  if (!res.ok) {
    let detail = text;
    try {
      const json = JSON.parse(text);
      detail = json.errorMessages?.join(', ') || JSON.stringify(json.errors) || text;
    } catch {}
    throw new Error(`HTTP ${res.status}: ${detail}`);
  }
  return text ? JSON.parse(text) : null;
}

async function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ── 프로젝트 메타 조회 (이슈 타입 ID 확인) ──────────────────
async function getProjectMeta() {
  const data = await jiraRequest('GET', `/issue/createmeta?projectKeys=${CONFIG.project}&expand=projects.issuetypes`);
  const project = data.projects?.[0];
  if (!project) throw new Error(`프로젝트 '${CONFIG.project}'를 찾을 수 없습니다.`);

  const types = {};
  for (const t of project.issuetypes ?? []) {
    types[t.name] = t.id;
  }
  return types;
}

// ── Epic 생성 ────────────────────────────────────────────────
async function createEpic(epic, issueTypeId, epicNameFieldId) {
  const body = {
    fields: {
      project: { key: CONFIG.project },
      summary: epic.summary,
      description: {
        type: 'doc',
        version: 1,
        content: [{ type: 'paragraph', content: [{ type: 'text', text: epic.description }] }],
      },
      issuetype: { id: issueTypeId },
      ...(epicNameFieldId ? { [epicNameFieldId]: epic.summary } : {}),
    },
  };

  const result = await jiraRequest('POST', '/issue', body);
  return result.key;
}

// ── Story/Task 생성 ──────────────────────────────────────────
async function createStory(story, issueTypeId, epicLinkFieldId, epicKey) {
  const body = {
    fields: {
      project: { key: CONFIG.project },
      summary: story.summary,
      description: {
        type: 'doc',
        version: 1,
        content: story.description.split('\n\n').map((para) => ({
          type: 'paragraph',
          content: [{ type: 'text', text: para }],
        })),
      },
      issuetype: { id: issueTypeId },
      ...(epicLinkFieldId && epicKey ? { [epicLinkFieldId]: epicKey } : {}),
    },
  };

  const result = await jiraRequest('POST', '/issue', body);
  return result.key;
}

// ── 커스텀 필드 ID 조회 (Epic Name, Epic Link) ───────────────
async function getCustomFields() {
  const fields = await jiraRequest('GET', '/field');
  const epicName = fields.find((f) => f.name === 'Epic Name')?.id;
  const epicLink = fields.find((f) => f.name === 'Epic Link')?.id;
  return { epicName, epicLink };
}

// ── 설정 검증 ────────────────────────────────────────────────
function validateConfig() {
  const missing = ['baseUrl', 'email', 'apiToken', 'project'].filter((k) => !CONFIG[k]);
  if (missing.length > 0) {
    log.error(`필수 환경변수가 없습니다: ${missing.map((k) => `JIRA_${k.toUpperCase()}`).join(', ')}`);
    console.log(`
${c.bold}설정 방법:${c.reset}
  1. 프로젝트 루트에 .env.jira 파일 생성:

     JIRA_BASE_URL=https://your-domain.atlassian.net
     JIRA_EMAIL=your@email.com
     JIRA_API_TOKEN=your-api-token
     JIRA_PROJECT=MALL

  2. API 토큰 발급: https://id.atlassian.com/manage-profile/security/api-tokens
`);
    process.exit(1);
  }
}

// ── 메인 ────────────────────────────────────────────────────
async function main() {
  console.log(`\n${c.bold}${c.cyan}╔══════════════════════════════════════════╗${c.reset}`);
  console.log(`${c.bold}${c.cyan}║  Online Shopping Mall — Jira 티켓 생성   ║${c.reset}`);
  console.log(`${c.bold}${c.cyan}╚══════════════════════════════════════════╝${c.reset}\n`);

  if (DRY_RUN) {
    log.warn('DRY-RUN 모드: 실제 티켓을 생성하지 않습니다.\n');
  }

  validateConfig();

  log.info(`Jira: ${CONFIG.baseUrl}`);
  log.info(`프로젝트: ${CONFIG.project}`);
  log.info(`Epic ${EPICS.length}개 + Story/Task ${STORIES.length}개 생성 예정\n`);

  if (DRY_RUN) {
    log.section('생성될 티켓 목록');
    for (const epic of EPICS) {
      log.dry(`[Epic] ${epic.summary}`);
      for (const story of STORIES.filter((s) => s.epic === epic.key)) {
        log.dry(`  └ [${story.issueType}] ${story.summary}`);
      }
    }
    console.log(`\n${c.green}총 ${EPICS.length + STORIES.length}개 티켓이 생성됩니다.${c.reset}\n`);
    return;
  }

  // 프로젝트 메타 및 커스텀 필드 조회
  log.section('프로젝트 정보 조회');
  let issueTypes, customFields;
  try {
    [issueTypes, customFields] = await Promise.all([getProjectMeta(), getCustomFields()]);
  } catch (err) {
    log.error(`프로젝트 정보 조회 실패: ${err.message}`);
    process.exit(1);
  }

  log.ok(`이슈 타입: ${Object.keys(issueTypes).join(', ')}`);
  if (customFields.epicName) log.ok(`Epic Name 필드: ${customFields.epicName}`);
  if (customFields.epicLink) log.ok(`Epic Link 필드: ${customFields.epicLink}`);

  const epicTypeId = issueTypes['Epic'];
  if (!epicTypeId) {
    log.error("'Epic' 이슈 타입을 프로젝트에서 찾을 수 없습니다.");
    log.warn(`사용 가능한 타입: ${Object.keys(issueTypes).join(', ')}`);
    process.exit(1);
  }

  // Epic 생성
  log.section('Epic 생성');
  const epicKeyMap = {};
  for (const epic of EPICS) {
    try {
      const key = await createEpic(epic, epicTypeId, customFields.epicName);
      epicKeyMap[epic.key] = key;
      log.ok(`${key} — ${epic.summary}`);
    } catch (err) {
      log.error(`Epic 생성 실패 [${epic.key}]: ${err.message}`);
    }
    await delay(DELAY_MS);
  }

  // Story/Task 생성
  log.section('Story / Task 생성');
  let created = 0;
  let failed = 0;

  for (const story of STORIES) {
    const typeId = issueTypes[story.issueType] ?? issueTypes['Story'] ?? issueTypes['Task'];
    if (!typeId) {
      log.warn(`이슈 타입 '${story.issueType}' 없음, 건너뜀: ${story.summary}`);
      failed++;
      continue;
    }

    const epicKey = epicKeyMap[story.epic];
    try {
      const key = await createStory(story, typeId, customFields.epicLink, epicKey);
      log.ok(`${key} — ${story.summary}${epicKey ? ` (${epicKey})` : ''}`);
      created++;
    } catch (err) {
      log.error(`생성 실패: ${story.summary}\n   ${err.message}`);
      failed++;
    }
    await delay(DELAY_MS);
  }

  // 결과 요약
  console.log(`\n${c.bold}━━ 완료 ━━${c.reset}`);
  log.ok(`Epic: ${Object.keys(epicKeyMap).length}/${EPICS.length}개 생성`);
  log.ok(`Story/Task: ${created}/${STORIES.length}개 생성`);
  if (failed > 0) log.warn(`실패: ${failed}개`);
  console.log(`\n${c.blue}Jira Board: ${CONFIG.baseUrl}/jira/software/projects/${CONFIG.project}/boards${c.reset}\n`);
}

main().catch((err) => {
  log.error(`예상치 못한 오류: ${err.message}`);
  process.exit(1);
});
