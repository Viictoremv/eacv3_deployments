<?php

use App\Kernel;

/**
 * BEGIN: QIS CUSTOMIZATIONS
 */
if(is_array($_ENV) && array_key_exists("APP_ENV", $_ENV) && $_ENV["APP_ENV"] !== "prod") {
 if(file_exists("/home/admin/.qis_ip_allow")) {
  $allowIps = explode("\n", file_get_contents("/home/admin/.qis_ip_allow"));

  // if a list of allowed IPs has been established and the environment isn't production, deny access to all other IPs
  if(is_iterable($allowIps) && !in_array($_SERVER["REMOTE_ADDR"], $allowIps)) {
   error_log(__FILE__ . ", line " . __LINE__ . ": Request from " . $_SERVER["REMOTE_ADDR"] . " blocked\nRequest URI: [" . $_SERVER["REQUEST_URI"] . "]\nRequest method: [" . $_SERVER["REQUEST_METHOD"] . "]\nUser agent: [" . $_SERVER["HTTP_USER_AGENT"] . "]\n\n", 3, __DIR__ . "/../logs/_blocked_requests.log");
   exit;
  } // end if
 } // end if
} // end if
/**
 * END: QIS CUSTOMIZATIONS
 */

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context) {
    return new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);
};
