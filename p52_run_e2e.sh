#!/usr/bin/env bash
set -euo pipefail

# P52 destructive operations are allowed only in an explicit Laravel testing environment.
if [[ "${APP_ENV:-}" != "testing" ]]; then
  echo "ERROR: Set APP_ENV=testing before running P52 E2E." >&2
  exit 2
fi

if [[ "${P52_ALLOW_DB_RESET:-0}" != "1" ]]; then
  echo "ERROR: Set P52_ALLOW_DB_RESET=1 to allow migrate:fresh. Use a disposable test database." >&2
  exit 2
fi

if [[ ! -f artisan ]]; then
  echo "ERROR: Run this script from the Laravel application root where artisan exists." >&2
  exit 2
fi

php artisan optimize:clear
php artisan migrate:fresh --seed --force
php artisan priyasa:api-certify --strict
php artisan priyasa:api-contract --output=docs/openapi.routes.json
php artisan test --testsuite=Feature --testdox

# Optional real HTTP smoke test. Set P52_BASE_URL when the application is running separately.
if [[ -n "${P52_BASE_URL:-}" ]]; then
  php -r '
    $base=rtrim(getenv("P52_BASE_URL"), "/");
    $paths=["/api/v1/storefront/bootstrap"];
    foreach($paths as $p){
      $ctx=stream_context_create(["http"=>["method"=>"GET","ignore_errors"=>true,"timeout"=>15]]);
      $body=@file_get_contents($base.$p,false,$ctx);
      $status=$http_response_header[0]??"unknown";
      if($body===false){fwrite(STDERR,"HTTP smoke failed: $p\n"); exit(1);}
      echo "$status $p\n";
    }
  '
fi

echo "P52 E2E suite completed."
