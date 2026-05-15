/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: ['../../.eslintrc.js'],
  rules: {
    // 타입 정의 파일은 any 허용 안 함 (타입 정확성이 핵심)
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports' }],
    '@typescript-eslint/consistent-type-definitions': ['error', 'interface'],
  },
};
