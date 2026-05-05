/* eslint-disable no-console */
/* eslint-env node */
/* global process, console */
/// <reference types="vitest" />
import { loadEnv } from "vite";
import { defineConfig } from "vitest/config";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync, readFileSync } from "node:fs";

// Project root directory (where vitest.config.ts is located)
const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Load orphaned templates from coverage report and exclude from coverage tracking
 * Auto-generates the report if missing or outdated
 * @returns Array of template paths to exclude, empty array on error
 */
function getOrphanedTemplates (): string[] {
 const reportPath = resolve(__dirname, './build/coverage/orphaned-templates.md');
 const templatesDir = resolve(__dirname, './templates');

 // Check if report exists and is up-to-date
 const reportExists = existsSync(reportPath);
 let isReportOutdated = false;

 if (reportExists) {
  try {
   const reportStat = require('fs').statSync(reportPath);
   const templatesStat = require('fs').statSync(templatesDir);

   // Check if templates directory is newer than report
   isReportOutdated = templatesStat.mtime > reportStat.mtime;

   if (isReportOutdated) {
    console.log('📅 Orphaned templates report is outdated, regenerating...');
   }
  } catch (error) {
   console.warn('⚠️  Error checking report freshness:', error instanceof Error ? error.message : error);
   isReportOutdated = true;
  }
 }

 // Auto-generate report if missing or outdated
 if (!reportExists || isReportOutdated) {
  console.log('🔄 Generating orphaned templates report...');

  try {
   const { execSync } = require('child_process');
   execSync('php scripts/coverage-extraction/generate-orphaned-templates-report.php', {
    cwd: __dirname,
    stdio: 'inherit'
   });
   console.log('✅ Orphaned templates report generated successfully');
  } catch (error) {
   console.error('❌ Failed to generate orphaned templates report:', error instanceof Error ? error.message : error);
   console.warn('   Continuing with empty exclude list...');
   return [];
  }
 }

 if (!existsSync(reportPath)) {
  console.warn('⚠️  Orphaned templates report not found after generation attempt');
  console.warn('   Run manually: npm run coverage:find-orphaned');
  return [];
 }

 try {
  const content = readFileSync(reportPath, 'utf-8');
  const templateRegex = /`templates\/([^`]+\.twig)`/g;
  const matches = [...content.matchAll(templateRegex)];
  const templates = matches.map(match => `templates/${match[1]}`).filter((template): template is string => template !== undefined);

  if (templates.length > 0) {
   console.log(`✓ Excluding ${templates.length} orphaned templates from coverage`);
  }

  return templates;
 } catch (error) {
  console.error('❌ Error loading orphaned templates report:', error instanceof Error ? error.message : error);
  return [];
 }
}

/**
 * Validate Twig provider module exists
 * @returns Path to provider if valid, undefined otherwise
 */
function getTwigProviderPath (): string | undefined {
 const providerPath = './scripts/coverage-extraction/vitest-twig-provider.ts';
 const fullPath = resolve(__dirname, providerPath);

 if (!existsSync(fullPath)) {
  console.warn('⚠️  Twig coverage provider not found:', fullPath);
  console.warn('   Twig coverage will be disabled');
  return undefined;
 }

 return providerPath;
}

export default defineConfig(({ mode = 'development' }) => {
 const env = loadEnv(mode, process.cwd(), 'VITE_');
 const IS_DEV_ENV = mode === "development";
 const IS_CI_ENV = Boolean(env.CI) || mode === "ci";

 const orphanedTemplates = getOrphanedTemplates();
 const twigProviderPath = getTwigProviderPath();

  if (!IS_CI_ENV) {
  console.log("\n🔧 Vitest Environment Configuration:");
  console.log(`   Mode: ${mode ?? 'development'}`);
  console.log(`   CI: ${IS_CI_ENV}`);
  console.log(`   Orphaned templates excluded: ${orphanedTemplates.length}`);
  console.log(`   Twig Provider: ${twigProviderPath ? '✓' : '✗'} (${twigProviderPath ?? 'not found'})`);
  }

 return {
  esbuild: {
   include: ["**/*.js", "**/*.jsx", "**/*.mjs", "**/*.ts", "**/*.tsx"]
  },

  test: {
   environment: "jsdom",

   include: [
    "testing/__vitest_only/**/*.{spec,test}.{js,ts}",
    "testing/accessibility/**/*.{spec,test}.{js,ts}",
    "testing/e2e/**/*.{spec,test}.{js,ts}",
    "testing/monitoring/**/*.{spec,test}.{js,ts}",
    "testing/standards/WEB01/**/*.{spec,test}.{js,ts}",
    "testing/standards/WEB02/**/*.{spec,test}.{js,ts}",
    "testing/standards/WEB03/**/*.{spec,test}.{js,ts}",
    "testing/standards/WEB04/**/*.{spec,test}.{js,ts}",
    "testing/standards/WEB05/**/*.{spec,test}.{js,ts}",
    "testing/tools/**/*.{spec,test}.{js,ts}",
    "testing/unit/**/*.{spec,test}.{js,ts}",
    "testing/utilities/**/*.{spec,test}.{js,ts}",
   ],

   setupFiles: ['./testing/vitest.setup.ts'],
   globals: false,

   coverage: {
    enabled: true,
    provider: "v8",
    ignoreEmptyLines: true,
    reporter: ["text", "json", "html", "lcov"],
    reportsDirectory: "./build/coverage-vite",
    cleanOnRerun: false,

    include: [
     "assets/**/*.{js,ts}",
     "scripts/**/*.{js,ts}"
    ],

    exclude: [
     "node_modules/**",
     "dist/**",
     "**/*.d.ts",
     "**/*.config.*",
     "**/coverage/**",
     "templates/bundles/**",
     ...orphanedTemplates,
    ],

    // Twig provider (only if exists)
    ...(twigProviderPath && {
     customProviderModule: twigProviderPath,
     twigOptions: {
      templatesDir: 'templates',
      coverageDataFile: 'var/coverage/twig-rendered.json',
      playwrightResultsFile: 'coverage/playwright/results.json',
      symfonyProfilerDir: 'var/cache/test/profiler',
      includePatterns: [
       'templates/**/*.twig',
       'templates/**/*.html.twig'
      ],
      excludePatterns: [
       'templates/_dev/**/*',
       'templates/test/**/*'
      ],
      thresholds: {
       global: 85,
       perFile: 75
      }
     }
    }),

    thresholds: {
     global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
     }
    },

    all: true,
    skipFull: false
   },

   logHeapUsage: true,
   passWithNoTests: false,
   watch: false,
   silent: false,
   testTimeout: 30000,
   hookTimeout: 30000,
   teardownTimeout: 10000,
   isolate: true,
   pool: "threads",

   poolOptions: {
    threads: {
     singleThread: false,
     maxThreads: 40,
     minThreads: 1
    }
   },

   allowOnly: IS_DEV_ENV && !IS_CI_ENV,

   typecheck: {
    enabled: false
   },

   env: {
    IS_DEV_ENV: IS_DEV_ENV.toString()
   }
  }
 };
});
