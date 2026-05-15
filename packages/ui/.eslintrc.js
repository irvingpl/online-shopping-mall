/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: ['../../.eslintrc.js', 'plugin:react/recommended', 'plugin:react-hooks/recommended'],
  settings: {
    react: { version: 'detect' },
  },
  rules: {
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react/display-name': 'warn',
    // 컴포넌트 props 타입은 TypeScript로 관리
    'react/no-unknown-property': 'error',
  },
};
