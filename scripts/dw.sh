#!/usr/bin/env bash
#
# RetailDW workshop helper.
#
#   ./scripts/dw.sh up        start the SQL Server container
#   ./scripts/dw.sh build     build the database project (produces the dacpac)
#   ./scripts/dw.sh publish   publish the dacpac to the local container
#   ./scripts/dw.sh seed      truncate + load staging batch 1
#   ./scripts/dw.sh etl       run etl.LoadFactSales for the POS source system
#   ./scripts/dw.sh smoke     run the smoke test
#   ./scripts/dw.sh reset     drop and rebuild the database from scratch
#   ./scripts/dw.sh sql "..." run an ad-hoc query
#   ./scripts/dw.sh baseline  up + build + publish + seed + etl + smoke
#
set -euo pipefail
set +H 2>/dev/null || true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="127.0.0.1,14330"
DB="RetailDW"
SA_USER="sa"
SA_PASS="${MSSQL_SA_PASSWORD:-Workshop_Dev2026#}"

export PATH="$PATH:$HOME/.dotnet/tools"

winpath() { # winpath <path> - sqlcmd/sqlpackage are Windows binaries
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

q() { # q <database> <query>
  sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -b -d "$1" -Q "$2"
}

f() { # f <database> <file>
  sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -b -d "$1" -i "$(winpath "$2")"
}

cmd_up() {
  docker compose -f "$ROOT/docker-compose.yml" up -d
  echo "waiting for SQL Server..."
  for _ in $(seq 1 30); do
    if sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -l 3 -Q "SELECT 1" >/dev/null 2>&1; then
      echo "SQL Server is ready on $SERVER"
      return 0
    fi
    sleep 3
  done
  echo "SQL Server did not become ready in time" >&2
  return 1
}

cmd_build() {
  dotnet build "$ROOT/RetailDW/RetailDW.sqlproj"
}

cmd_publish() {
  local dacpac
  dacpac="$(winpath "$ROOT/RetailDW/bin/Debug/RetailDW.dacpac")"
  MSYS_NO_PATHCONV=1 sqlpackage \
    /Action:Publish \
    /SourceFile:"$dacpac" \
    /TargetServerName:"$SERVER" \
    /TargetDatabaseName:"$DB" \
    /TargetUser:"$SA_USER" \
    /TargetPassword:"$SA_PASS" \
    /TargetTrustServerCertificate:True
}

cmd_seed() { f "$DB" "$ROOT/data/01-staging-batch-1.sql"; }

cmd_etl() {
  q "$DB" "DECLARE @l INT;
           EXEC etl.LoadFactSales @SourceSystem = N'POS', @LoadId = @l OUTPUT;
           SELECT LoadId, Status, RowsInserted, RowsUpdated, RowsRejected
           FROM dbo.LoadLog ORDER BY LoadId;"
}

cmd_smoke() { f "$DB" "$ROOT/tests/smoke-test.sql"; }

cmd_reset() {
  q "master" "IF DB_ID('$DB') IS NOT NULL
              BEGIN
                  ALTER DATABASE [$DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                  DROP DATABASE [$DB];
              END"
  cmd_publish
}

cmd_baseline() {
  cmd_up
  cmd_build
  cmd_publish
  cmd_seed
  cmd_etl
  cmd_smoke
}

case "${1:-}" in
  up)       cmd_up ;;
  build)    cmd_build ;;
  publish)  cmd_publish ;;
  seed)     cmd_seed ;;
  etl)      cmd_etl ;;
  smoke)    cmd_smoke ;;
  reset)    cmd_reset ;;
  baseline) cmd_baseline ;;
  sql)      q "$DB" "${2:?usage: dw.sh sql \"<query>\"}" ;;
  *)        sed -n '3,14p' "${BASH_SOURCE[0]}" ; exit 1 ;;
esac
