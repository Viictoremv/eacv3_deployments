#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./run-coverage.sh            # defaults to child
#   ./run-coverage.sh --app parent
#   ./run-coverage.sh /workspace/child

APP_DIR="/workspace/child"
if [[ "${1:-}" == "--app" ]]; then
  APP="${2:-child}"
  shift 2 || true
  case "$APP" in
    child)  APP_DIR="/workspace/child"  ;;
    parent) APP_DIR="/workspace/parent" ;;
    *) echo "❌ Unknown app: $APP (use child|parent)"; exit 2 ;;
  esac
elif [[ "${1:-}" == /* ]]; then
  APP_DIR="$1"; shift
fi

cd "$APP_DIR"

# Ensure directories exist
mkdir -p var/tests/coverage var/tests/junit

# Pick config file if present
PHPUNIT_CFG=""
if [[ -f phpunit.xml ]]; then
  PHPUNIT_CFG="--configuration phpunit.xml"
elif [[ -f phpunit.xml.dist ]]; then
  PHPUNIT_CFG="--configuration phpunit.xml.dist"
fi

# Sanity checks
[[ -x vendor/bin/phpunit ]] || { echo "❌ Missing vendor/bin/phpunit in $APP_DIR"; exit 1; }

echo "▶️ Running PHPUnit with coverage in: $APP_DIR"

# Run PHPUnit but don't let set -e kill the script on failures
set +e
XDEBUG_MODE=coverage \
XDEBUG_CONFIG="start_with_request=no" \
php -d xdebug.mode=coverage -d opcache.enable_cli=0 \
  vendor/bin/phpunit $PHPUNIT_CFG \
  --coverage-filter src \
  --coverage-html var/tests/coverage \
  --coverage-clover var/tests/coverage/clover.xml \
  --coverage-cobertura var/tests/coverage/cobertura.xml \
  --log-junit var/tests/junit/junit.xml \
  --no-progress
PHPUNIT_RC=$?
set -e

# Report locations (without subshell failures)
HTML="var/tests/coverage/index.html"
CLOVER="var/tests/coverage/clover.xml"
COBERTURA="var/tests/coverage/cobertura.xml"
JUNIT="var/tests/junit/junit.xml"

echo "✅ Reports generated (where produced):"
[[ -f "$HTML"      ]] && echo "   • HTML:       $HTML"        || echo "   • HTML:       (missing)"
[[ -f "$CLOVER"    ]] && echo "   • Clover XML: $CLOVER"      || echo "   • Clover XML: (missing)"
[[ -f "$COBERTURA" ]] && echo "   • Cobertura:  $COBERTURA"   || echo "   • Cobertura:  (missing)"
[[ -f "$JUNIT"     ]] && echo "   • JUnit:      $JUNIT"       || echo "   • JUnit:      (missing)"

# --- Generate static SVG coverage badge (only if Clover exists) -------
BADGE_DIR="badges"
BADGE_FILE="${BADGE_DIR}/coverage.svg"
mkdir -p "$BADGE_DIR"

if [[ -f "$CLOVER" ]]; then
  php -r '
  $clover = "'"$CLOVER"'";
  $badge  = "'"$BADGE_FILE"'";

  $xml = @simplexml_load_file($clover);
  if ($xml === false) { fwrite(STDERR, "❌ Failed to parse Clover XML\n"); exit(1); }

  $metrics = $xml->xpath("/coverage/project/metrics");
  if (!$metrics || !isset($metrics[0]["elements"], $metrics[0]["coveredelements"])) {
      fwrite(STDERR, "❌ Could not find metrics in Clover XML\n");
      exit(1);
  }

  $elements = (float)$metrics[0]["elements"];
  $covered  = (float)$metrics[0]["coveredelements"];
  $percent  = $elements > 0 ? round(($covered / $elements) * 100.0, 1) : 0.0;

  $color = "red";
  if    ($percent >= 90) { $color = "brightgreen"; }
  elseif($percent >= 75) { $color = "green"; }
  elseif($percent >= 60) { $color = "yellowgreen"; }
  elseif($percent >= 45) { $color = "yellow"; }
  elseif($percent >= 30) { $color = "orange"; }

  $hexMap = [
      "brightgreen" => "4c1",
      "green"       => "97CA00",
      "yellowgreen" => "a4a61d",
      "yellow"      => "dfb317",
      "orange"      => "fe7d37",
      "red"         => "e05d44",
  ];
  $hex = $hexMap[$color];

  $label = "PHPUnit Code Coverage";
  $value = $percent . "%";

  $w = function($t){ return 6 * strlen($t) + 10; };
  $lw = $w($label);
  $vw = $w($value);
  $total = $lw + $vw;

  $svg =
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$total\" height=\"20\" role=\"img\" aria-label=\"$label: $value\">".
      "<linearGradient id=\"s\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/>".
      "<stop offset=\"1\" stop-opacity=\".1\"/></linearGradient>".
      "<mask id=\"m\"><rect width=\"$total\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask>".
      "<g mask=\"url(#m)\">".
        "<rect width=\"$lw\" height=\"20\" fill=\"#555\"/>".
        "<rect x=\"$lw\" width=\"$vw\" height=\"20\" fill=\"#$hex\"/>".
        "<rect width=\"$total\" height=\"20\" fill=\"url(#s)\"/>".
      "</g>".
      "<g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\">".
        "<text x=\"".($lw/2)."\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">$label</text>".
        "<text x=\"".($lw/2)."\" y=\"14\">$label</text>".
        "<text x=\"".($lw+$vw/2)."\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">$value</text>".
        "<text x=\"".($lw+$vw/2)."\" y=\"14\">$value</text>".
      "</g>".
      "</svg>";

  if (file_put_contents($badge, $svg) === false) {
      fwrite(STDERR, "❌ Failed to write badge: $badge\n");
      exit(1);
  }
  echo "🪪 Coverage badge written to: $badge ($percent%)\n";
  ' || true

  echo "ℹ️  Add this to your README to show the badge:"
  echo "    [![Coverage](./${BADGE_FILE})](./var/tests/coverage/index.html)"
else
  echo "⚠️  Clover XML not found at $CLOVER — skipping badge."
fi

# Propagate PHPUnit’s exit code (so CI can fail if tests failed)
exit "$PHPUNIT_RC"