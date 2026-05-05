import { defineConfig } from 'checkly'

/**
 * Gating-only Checkly config (SDLC pipeline driven)
 * - No schedules/frequencies (runs are triggered by GitHub Actions)
 * - Uses AKS Private Location only
 * - Test sources live under /testing
 */
const config = defineConfig({
    projectName: 'Early Access System - v3',
    logicalId: 'easv3',
    repoUrl: 'https://github.com/Early-Access-Care-LLC/eacv3',

    checks: {
        // IMPORTANT: Private (AKS) execution only
        // This must match the Private Location slug in Checkly
        privateLocations: ['eas-nonprod-aks'],

        // Common metadata
        tags: ['website', 'api', 'frontend', 'sdlc-gate'],

        // Keep your current runtime unless you intentionally change it
        runtimeId: '2024.02',

        // Values should be provided by the pipeline (GitHub Secrets / env)
        // Do not hardcode environment names/URLs here.
        environmentVariables: [
            {
                key: 'ENVIRONMENT',
                value: '{{ENVIRONMENT}}'
            },
            {
                key: 'ENVIRONMENT_URL',
                value: '{{ENVIRONMENT_URL}}'
            },
            {
                key: 'API_TOKEN',
                value: '{{API_TOKEN}}'
            }
        ],

        // Playwright browser checks (from existing repo structure)
        browserChecks: {
            testMatch: '**/testing/e2e/**/*.check.ts'
        },

        // Multi-step checks
        multiStepChecks: {
            testMatch: '**/testing/multi-step/**/*.check.ts'
        }
    },

    // CLI behavior when running locally / in CI
    // (No runLocation needed since we use Private Locations only.)
    cli: {
        reporters: ['list'],
        retries: 0
    }
})

export default config