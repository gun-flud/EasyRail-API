import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  // 1. Ігноровані шляхи
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**', '*.config.js', '*.config.mjs'],
  },

  // 2. Базові рекомендації JS + TypeScript
  js.configs.recommended,
  ...tseslint.configs.recommended,

  // 3. Специфічні правила для Fastify + TypeScript (NodeNext)
  {
    files: ['src/**/*.ts', 'tests/**/*.ts'],
    rules: {
      // Заборона невикористаних змінних (крім тих, що починаються з _)
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      // Забороняє випадкове залишення викликів `any`
      '@typescript-eslint/no-explicit-any': 'warn',
      // Стимулює використовувати явні 'import type'
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'separate-type-imports' },
      ],
      // Консоль дозволяємо лише warn/error, для іншого використовуємо Fastify logger
      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
    },
  },

  // 4. Вимкнення правил форматування на користь Prettier (має йти останнім)
  prettierConfig,
);