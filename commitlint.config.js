/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 새 기능
        'fix',      // 버그 수정
        'docs',     // 문서 변경
        'style',    // 포맷, 세미콜론 등 (코드 변경 없음)
        'refactor', // 리팩토링 (기능/버그 수정 아님)
        'test',     // 테스트 추가/수정
        'chore',    // 빌드 설정, 패키지 업데이트 등
        'perf',     // 성능 개선
        'ci',       // CI 설정 변경
        'build',    // 빌드 시스템 변경
        'revert',   // 커밋 되돌리기
      ],
    ],
    // 제목은 소문자로 시작 (대문자 스타일 금지)
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    // 제목 최대 길이
    'subject-max-length': [2, 'always', 72],
    // 제목 끝에 마침표 금지
    'subject-full-stop': [2, 'never', '.'],
    // 빈 본문 줄 강제 (헤더 다음 한 줄 빈 줄)
    'body-leading-blank': [2, 'always'],
    // footer 빈 줄
    'footer-leading-blank': [1, 'always'],
  },
};
