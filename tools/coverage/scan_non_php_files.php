<?php

$config = json_decode(file_get_contents(__DIR__ . '/patterns.json'), true);

$includeDirs = $config['include'] ?? [];
$extensions  = $config['extensions'] ?? ['.twig', '.scss'];
$excludeDirs = $config['exclude'] ?? [];

$results = [];
$totalLines = 0;

foreach ($includeDirs as $dir) {
    scanDirectory($dir, $extensions, $excludeDirs, $results, $totalLines);
}

$report = [
    "generated_at" => date('c'),
    "total_files" => count($results),
    "total_lines" => $totalLines,
    "files" => $results
];

file_put_contents(__DIR__ . '/coverage-report.json', json_encode($report, JSON_PRETTY_PRINT));

echo "Coverage report generated at: " . __DIR__ . "/coverage-report.json\n";


/**
 * Recursive directory scanner
 */
function scanDirectory($dir, $extensions, $excludeDirs, &$results, &$totalLines)
{
    if (!is_dir($dir)) {
        return;
    }

    $items = scandir($dir);

    foreach ($items as $item) {
        if ($item === '.' || $item === '..') {
            continue;
        }

        $path = $dir . '/' . $item;

        // Skip excluded folders
        foreach ($excludeDirs as $ex) {
            if (strpos($path, $ex) !== false) {
                continue 2;
            }
        }

        if (is_dir($path)) {
            scanDirectory($path, $extensions, $excludeDirs, $results, $totalLines);
        } else {
            foreach ($extensions as $ext) {
                if (str_ends_with($item, $ext)) {
                    $lines = count(file($path));
                    $results[] = [
                        "file" => $path,
                        "lines" => $lines
                    ];
                    $totalLines += $lines;
                }
            }
        }
    }
}
