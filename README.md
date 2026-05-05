# Early Access System v3

[![Build DB Image](https://github.com/Early-Access-Care-LLC/eacv3/actions/workflows/DatabaseContainerBuild.yaml/badge.svg)](https://github.com/Early-Access-Care-LLC/eacv3/actions/workflows/DatabaseContainerBuild.yaml)
[![Build Web Image](https://github.com/Early-Access-Care-LLC/eacv3/actions/workflows/WebContainerBuild.yaml/badge.svg)](https://github.com/Early-Access-Care-LLC/eacv3/actions/workflows/WebContainerBuild.yaml)
[![PHPUnit Code Coverage](https://github.com/Early-Access-Care-LLC/eacv3/blob/master/badges/coverage.svg)](https://app.codecov.io/github/Early-Access-Care-LLC/eacv3/tree/master/src)
[![codecov](https://codecov.io/github/Early-Access-Care-LLC/eacv3/branch/master/graph/badge.svg?token=DI6NDYYF9J)](https://codecov.io/github/Early-Access-Care-LLC/eacv3)

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Relationships](#component-relationships)
3. [DataTables Implementation Guide](#datatables-implementation-guide)
4. [Testing Strategy](#testing-strategy)
5. [Key Areas](#key-areas)
6. [Installation](#installation)
7. [Usage](#usage)
8. [Coverage & Documentation Scripts](#coverage--documentation-scripts)
9. [Documentation](#documentation)

## Architecture Overview

The Early Access System v3 is built using the Symfony framework, leveraging Twig
templating for frontend rendering and various Symfony and Node packages for
backend and frontend functionality. The codebase is structured as follows:

- **src/**: Contains PHP backend code, including controllers, services, and
  entities.
- **templates/**: Houses Twig templates for rendering views.
- **tests/**: Includes PHPUnit test suites for backend testing.
- **testing/**: Contains additional test suites and utilities.

## Component Relationships

The application follows a standardized layout pattern:

- **Controllers**: Handle HTTP requests and responses, interact with services,
  and pass data to Twig templates.
- **Twig Templates**: Render views using data provided by controllers.
- **Services**: Encapsulate business logic and interact with the database.
- **Entities**: Represent database tables and are used by services and
  controllers.

## DataTables Implementation Guide

DataTables are used extensively for displaying and interacting with tabular
data. Key points:

- **Initialization**: DataTables are initialized in JS files and linked to Twig
  templates.
- **Configuration**: Options such as pagination, sorting, and filtering are
  standardized.
- **Integration**: PHP controllers provide JSON endpoints for DataTables AJAX
  requests.

## Testing Strategy

The testing approach includes:

- **Unit Tests**: Located in the `tests/` directory, focusing on individual
  components.
- **Integration Tests**: Found in the `testing/` directory, ensuring components
  work together.

## Key Areas

### Controllers

Controllers handle HTTP requests and responses, interact with services, and pass
data to Twig templates. They are located in the `src/Controller/` directory.

### Entities

Entities represent database tables and are used by services and controllers.
They are located in the `src/Entity/` directory.

### Services

Services encapsulate business logic and interact with the database. They are
located in the `src/Service/` directory.

### Attributes

Attributes provide metadata for entity properties and other components. They are
located in the `src/Attribute/` directory.

### Event Listeners and Subscribers

Event listeners and subscribers handle application events and are located in the
`src/EventListener/` and `src/EventSubscriber/` directories.

### Twig Templates

Twig templates are used for rendering views and are located in the `templates/`
directory.

### Utilities

Utility classes provide helper functions and are located in the `src/Util/`
directory.

### Tests

Tests ensure the functionality and reliability of the application. They are
located in the `tests/` directory and include unit, integration, and end-to-end
tests.

## Coverage & Documentation Scripts

The main script for generating documentation and reports is
`scripts/artifact-generation/generate-documentation.php`.

For comprehensive documentation on all artifact generation scripts, see the
[Artifact Generation Guide](scripts/artifact-generation/README.md).

### Twig Coverage Report

To generate a markdown report that visualizes Twig template coverage, run the
following command:

```bash
php scripts/artifact-generation/generate-documentation.php --report=twig-coverage
```

This will generate a `twig-coverage-graph.md` file, which contains a Mermaid
diagram of the template relationships and coverage data.

### Other Reports

The `generate-documentation.php` script can also generate other documentation
artifacts. For more information, refer to the
[Artifact Generation Guide](scripts/artifact-generation/README.md) or the
[Script Guide](scripts/README.md).

## Documentation

Refer to the following documentation for more details:

- [Coding Standards](docs/standards/README.md)
- [Development](docs/development/README.md)
- [Diagrams](docs/diagrams/README.md)
- [Entities](docs/entities/README.md)
- [Script Guide](scripts/README.md)
- [Testing](docs/testing/README.md)
