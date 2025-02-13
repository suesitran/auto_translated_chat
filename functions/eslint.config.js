const globals = require("globals");
const js = require("@eslint/js");

module.exports = [
  js.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2018,
      sourceType: "commonjs",
      globals: {
        ...globals.node
      }
    },
    rules: {
      "quotes": ["error", "double"],
      "max-len": ["error", {"code": 120}],
      "indent": ["error", 2],
      "comma-dangle": ["error", "only-multiline"],
      "camelcase": "error",
      "no-unused-vars": "warn"
    }
  }
]; 