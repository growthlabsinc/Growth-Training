module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2020,
  },
  extends: [
    "eslint:recommended",
  ],
  rules: {
    "no-unused-vars": ["warn", { "args": "none" }],
    "no-console": "off",
    "max-len": ["warn", { "code": 120 }],
  },
};
