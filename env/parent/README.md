# Parent App Environment Variables

This folder contains the required `.env.local.override` file for Symfony.

## Required Vars

| Key              | Description                            |
|------------------|----------------------------------------|
| APP_ENV          | Symfony environment (dev, prod)        |
| APP_DEBUG        | Enable debug mode                      |
| DATABASE_URL     | MySQL connection string                |
| MAILER_DSN       | Symfony Mailer DSN                     |
| MAILER_SENDER    | Sender email address                   |
| MAILER_FROM_NAME | Full From field display name           |

## Usage

These values are injected into the parent container at runtime.

Run `scripts/fetch-env-files.sh` to download from Azure Storage.