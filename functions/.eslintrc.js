module.exports = {
  env: {
    es2022: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2022,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    // Разработка ведётся на Windows (CRLF), переносы строк не проверяем.
    "linebreak-style": "off",
  },
  // Локальные админ-скрипты не деплоятся и не линтуются.
  ignorePatterns: ["seed_bots.js", "index.js.bak"],
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};