import { defineConfig, devices } from "@playwright/test";
import { config as dotenvConfig } from "dotenv";
// import path from "path";

// Load environment variables from env files. (Add env files as needed.)
dotenvConfig({ path: [".env.dev.local", ".env"] });

// Ensure that the environment variables are loaded before running tests
if (!process.env.APP_ENV) {
  throw new Error("APP_ENV is not defined in the environment variables.\n\nPlease ensure you have an .env file in the root of your project.\nYou can create one by running:\n\n  npx dotenv-cli init\n\nThen, add the necessary environment variables, including APP_ENV.");
}

export const testFileTypes: Record<string, string> = {
  PNG: 'testing/files/test.png',
  PPTX: 'testing/files/test.pptx',
  TXT: 'testing/files/test.txt',
  XLSX: 'testing/files/test.xlsx',
  CSV: 'testing/files/test.csv',
  PDF: 'testing/files/test.pdf',
  JPG: 'testing/files/test.jpg'
};

export default defineConfig({
  globalSetup: "./testing/global.setup.ts",
  testDir: "./testing",
  testMatch: [
    "examples/**/*.spec.{ts,js}",
    "UATTestSuites/**/*.spec.{ts,js}",
    "setup/**/*.setup.{ts,js}",
    "**/*.playwright.spec.{ts,js}"
  ],
  testIgnore: [
    "**/__vitest_only/**",
    "**/*.test.{ts,js}",
    "**/*.unit.test.{ts,js}",
    "**/*.integration.test.{ts,js}"
  ],
  timeout: 300000,
  expect: {
    timeout: 10000
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  ...(process.env.CI ? { workers: 1 } : {}),
  use: {
    //actionTimeout: 15000,
    baseURL: process.env.ENVIRONMENT_URL || "http://localhost:3000",
    headless: true,
    trace: "on-first-retry",
    screenshot: "on",
    video: "retain-on-failure"
  },
  reporter: [
    ["html", { outputFolder: "./reports/playwright-report", open: "never" }],
    ["json", { outputFile: "./reports/test-results.json" }],
    ["junit", { outputFile: "./reports/junit.xml" }],
    ["list"]
  ],
  projects: [
    { //Script used to purely clear out all auth storage file in /.auth before running tests
      name: 'setup:clear-auth-storage',
      testMatch: ['setup/clear-auth-storage.js'],
    },
    {
      name: "Google Chrome",
      testMatch: [
        "examples/**/*.spec.{ts,js}",
        "UATTestSuites/**/*.spec.{ts,js}",
        "DONE_UAT_TESTS/**/*.spec.{ts,js}",
        "setup/**/*.setup.{ts,js}",
        "**/*.playwright.spec.{ts,js}"
      ],
      use: { ...devices["Desktop Chrome"], channel: "chrome" },
      dependencies: ['setup:clear-auth-storage']
    },
    {
      name: "Microsoft Edge",
      testMatch: [
        "examples/**/*.spec.{ts,js}",
        "UATTestSuites/**/*.spec.{ts,js}",
        "setup/**/*.setup.{ts,js}",
        "**/*.playwright.spec.{ts,js}"
      ],
      use: { ...devices["Desktop Edge"], channel: "msedge" },
      dependencies: ['setup:clear-auth-storage']
    }
  ]

});
