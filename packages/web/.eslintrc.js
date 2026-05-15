/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: [
    '../../.eslintrc.js',
    'next/core-web-vitals', // Next.js 권장 규칙 + React Hooks + accessibility
  ],
  rules: {
    // Next.js App Router: Server Component에서 async 함수 허용
    '@typescript-eslint/require-await': 'off',

    // next/image, next/link 사용 강제
    '@next/next/no-img-element': 'error',

    // React 17+ JSX transform — import React 불필요
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
  },
};
