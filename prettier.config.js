/** @type {import('prettier').Config} */
export default {
 // Basic formatting
 printWidth: 100,
 tabWidth: 2,
 useTabs: false,
 semi: true,
 singleQuote: false, // Following WEB01 standard for double quotes
 quoteProps: 'as-needed',

 // Trailing commas
 trailingComma: 'none', // Following WEB01 standard

 // Brackets and spacing
 bracketSpacing: true,
 bracketSameLine: true,
 arrowParens: 'avoid',

 // Line endings
 endOfLine: 'lf', // Unix line terminators as per WEB01

 // Prose formatting
 proseWrap: 'preserve',

 // HTML formatting
 htmlWhitespaceSensitivity: 'css',

 // Embedded language formatting
 embeddedLanguageFormatting: 'auto',

 // File-specific overrides
 overrides: [
  {
   files: '*.json',
   options: {
    printWidth: 80,
    tabWidth: 2
   }
  },
  {
   files: '*.md',
   options: {
    printWidth: 80,
    proseWrap: 'always'
   }
  },
  {
   files: '*.yml',
   options: {
    tabWidth: 2,
    singleQuote: true
   }
  },
  {
   files: '*.scss',
   options: {
    singleQuote: false,
   },
  },
  {
   files: '*.yaml',
   options: {
    tabWidth: 2,
    singleQuote: true
   }
  }
 ]
};