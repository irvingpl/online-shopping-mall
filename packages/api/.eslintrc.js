/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: ['../../.eslintrc.js'],
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
  },
  rules: {
    // NestJS 데코레이터 패턴: 클래스 프로퍼티 선언 허용
    '@typescript-eslint/no-explicit-any': 'warn',

    // DI 주입 파라미터는 사용하지 않는 것처럼 보일 수 있음
    '@typescript-eslint/no-unused-vars': [
      'error',
      { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
    ],

    // NestJS 비동기 메서드에서 void 반환 허용
    '@typescript-eslint/no-floating-promises': 'error',

    // Promise 반환 메서드에 async 강제
    '@typescript-eslint/promise-function-async': 'error',
  },
};
