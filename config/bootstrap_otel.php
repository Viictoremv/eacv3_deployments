<?php

// OpenTelemetry SDK auto-initialization and instrumentation loader
// This file is loaded via auto_prepend_file PHP directive

// Only initialize if SDK is not disabled and extension is loaded
if (getenv('OTEL_SDK_DISABLED') !== 'true' && extension_loaded('opentelemetry')) {
    error_log('[OTel Bootstrap] Starting initialization...');
    
    // Require composer autoloader first
    if (!class_exists('Composer\Autoload\ClassLoader')) {
        require_once __DIR__ . '/../vendor/autoload.php';
        error_log('[OTel Bootstrap] Loaded composer autoloader');
    }
    
    // Initialize SDK using OpenTelemetry's autoloader
    // This configures everything from OTEL_* environment variables
    if (class_exists('OpenTelemetry\SDK\SdkAutoloader')) {
        \OpenTelemetry\SDK\SdkAutoloader::autoload();
        error_log('[OTel Bootstrap] SDK autoloader initialized');
    } else {
        error_log('[OTel Bootstrap] WARNING: SdkAutoloader class not found!');
    }
    
    // Now load auto-instrumentation registration files
    // These must be loaded AFTER SDK initialization
    $autoInstrumentations = [
        'symfony' => __DIR__ . '/../vendor/open-telemetry/opentelemetry-auto-symfony/_register.php',
        'pdo' => __DIR__ . '/../vendor/open-telemetry/opentelemetry-auto-pdo/_register.php',
    ];
    
    foreach ($autoInstrumentations as $name => $file) {
        if (file_exists($file)) {
            try {
                require_once $file;
                error_log("[OTel Bootstrap] Loaded $name auto-instrumentation");
            } catch (\Throwable $e) {
                error_log("[OTel Bootstrap] WARNING: Failed to load $name: " . $e->getMessage());
            }
        } else {
            error_log("[OTel Bootstrap] WARNING: $name instrumentation file not found: $file");
        }
    }
    
    error_log('[OTel Bootstrap] Initialization complete');
} else {
    error_log('[OTel Bootstrap] Skipped - SDK disabled or extension not loaded');
}