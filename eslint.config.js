/* eslint-disable no-inline-comments */
/* eslint-disable no-warning-comments */
// ESLint configuration based on Early Access Care coding standards
// Implements rules from WEB01 (Organization) and WEB03 (Frontend) standards

import jsdoc from "eslint-plugin-jsdoc";
import tseslint from "typescript-eslint";

export default [
 {
  files: ["**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx"],
  languageOptions: {
   ecmaVersion: 2022,
   sourceType: "module",
   parserOptions: {
    ecmaFeatures: {
     jsx: true
    }
   }
  },
  plugins: {
   jsdoc
  },
  rules: {
   // WEB01 - Organization Standards
   "indent": ["warn", 1],
   "quotes": ["info", "single"], // Double quotes preference
   "no-tabs": "error", // No tab characters

   // Function documentation requirement
   "jsdoc/require-jsdoc": ["warn", {
    "require": {
     "FunctionDeclaration": true,
     "MethodDefinition": true,
     "ClassDeclaration": true
    }
   }],

   "no-warning-comments": ["info", {
    "terms": ["todo", "fixme", "xxx"],
    "location": "anywhere"
   }],

   // WEB03 - Frontend Standards
   "camelcase": ["warn", { "properties": "always" }], // camelCase variables
   "no-inline-comments": "warn", // Discourage inline comments

   // Code quality rules
   "no-console": "warn",
   "no-debugger": "error",
   "no-unused-vars": "error",
   "no-undef": "error",
   "semi": ["error", "always"],
   "comma-dangle": ["error", "never"],

   // Best practices
   "eqeqeq": "error",
   "no-eval": "error",
   "no-implied-eval": "error",
   "no-new-func": "error",
   "no-script-url": "error",

   // Spacing and formatting
   "space-before-function-paren": ["error", "always"],
   "space-in-parens": ["error", "never"],
   "object-curly-spacing": ["error", "always"],
   "array-bracket-spacing": ["error", "never"],
   "comma-spacing": ["error", { "before": false, "after": true }],
   "key-spacing": ["error", { "beforeColon": false, "afterColon": true }],

   // Brace style (One True Brace style)
   "brace-style": ["error", "1tbs", { "allowSingleLine": true }]
  }
 },
 {
  files: ["**/*.ts", "**/*.tsx"],
  languageOptions: {
   parser: tseslint.parser
  },
  plugins: {
   "@typescript-eslint": tseslint.plugin
  },
  rules: {
   // TypeScript specific rules
   "@typescript-eslint/no-unused-vars": "error",
   "@typescript-eslint/explicit-function-return-type": "warn",
   "@typescript-eslint/no-explicit-any": "warn",
   "prefer-const": "error"
  }
 }
];
