// Stylelint configuration based on Early Access Care coding standards
// Implements rules from WEB01 (Organization) and WEB03 (Frontend) standards

export default {
  extends: [
    "stylelint-config-standard-scss",
    "stylelint-config-prettier-scss"
  ],
  rules: {
    // WEB01 - Organization Standards
    "indentation": 2, // Single space indentation (2 spaces)
    "linebreaks": "unix", // Unix line terminators
    "string-quotes": "double", // Double quotes preference
    "no-tabs": true, // No tab characters

    // WEB03 - Frontend Standards
    "selector-class-pattern": [
      "^[a-z][a-z0-9-]*(__[a-z][a-z0-9-]*)?(-{1,2}[a-z][a-z0-9-]*)?$",
      {
        "message": "Class names should follow BEM methodology or kebab-case convention"
      }
    ],

    // SCSS variable usage enforcement
    "scss/dollar-variable-pattern": "^[a-z][a-zA-Z0-9]*$",
    "scss/at-mixin-pattern": "^[a-z][a-zA-Z0-9]*$",
    "scss/at-function-pattern": "^[a-z][a-zA-Z0-9]*$",

    // Prevent hardcoded values that should use variables
    "color-hex-length": "long",
    "color-named": "never",
    "length-zero-no-unit": true,

    // SCSS organization rules
    "scss/at-import-partial-extension": "never",
    "scss/at-use-no-unnamespaced": true,
    "scss/dollar-variable-no-missing-interpolation": true,
    "scss/no-duplicate-dollar-variables": true,

    // File size warning (handled by custom plugin)
    "max-line-length": [120, {
      "ignore": ["comments"]
    }],

    // Formatting rules
    "block-closing-brace-newline-after": "always",
    "block-closing-brace-newline-before": "always",
    "block-opening-brace-newline-after": "always",
    "block-opening-brace-space-before": "always",
    "declaration-colon-space-after": "always",
    "declaration-colon-space-before": "never",
    "declaration-block-semicolon-newline-after": "always",
    "declaration-block-semicolon-space-before": "never",
    "declaration-block-trailing-semicolon": "always",

    // Property ordering
    "order/properties-alphabetical-order": true,

    // Prevent common mistakes
    "no-duplicate-selectors": true,
    "no-empty-source": null,
    "no-invalid-double-slash-comments": true,
    "property-no-unknown": true,
    "selector-pseudo-class-no-unknown": true,
    "selector-pseudo-element-no-unknown": true,
    "selector-type-no-unknown": true,

    // Bootstrap and framework compatibility
    "selector-no-vendor-prefix": null,
    "property-no-vendor-prefix": null,
    "value-no-vendor-prefix": null,

    // Custom property patterns
    "custom-property-pattern": "^[a-z][a-z0-9-]*$",

    // Media query rules
    "media-feature-name-no-unknown": true,
    "media-query-list-comma-newline-after": "always-multi-line",
    "media-query-list-comma-space-after": "always-single-line",
    "media-query-list-comma-space-before": "never",

    // Comment rules
    "comment-empty-line-before": ["always", {
      "except": ["first-nested"],
      "ignore": ["stylelint-commands"]
    }],
    "comment-whitespace-inside": "always"
  },

  plugins: [
    "stylelint-order",
    "stylelint-scss"
  ],

  ignoreFiles: [
    "node_modules/**/*",
    "dist/**/*",
    "build/**/*",
    "vendor/**/*"
  ]
};