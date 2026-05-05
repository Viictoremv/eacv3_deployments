# Coverage Tools for Non-PHP Files

This folder contains utilities for analyzing coverage or usage of non-PHP
files such as Twig templates and SCSS assets. These scripts are used to
generate custom reports that can be consumed by CI tools such as Codecov.

## Files

### scan_non_php_files.php
Main analyzer script. Scans `.twig` and `.scss` files based on the patterns
defined in `patterns.json`, and produces a simple JSON report.

### patterns.json
Defines which folders to include or exclude during the scan. Useful if the
structure expands or if we want CI to ignore specific directories.

## Running the Script

```bash
php tools/coverage/scan_non_php_files.php
