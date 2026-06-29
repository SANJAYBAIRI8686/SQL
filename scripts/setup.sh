#!/bin/bash
# ============================================================================
# OMNISHOP DATABASE LOCAL SETUP & DIAGNOSTICS AUTOMATION
# Target OS: macOS / Linux (Requires Docker installed and running)
# Author: Senior Database Architect
# Purpose: Spins up a local transient PostgreSQL instance, provisions schemas,
#          ingests the bulk CSV datasets, compiles PL/pgSQL procedures, and 
#          executes verification checks on all 35+ sql queries.
# Usage: Run 'bash scripts/setup.sh' from the project root directory.
# ============================================================================

set -e

echo "===================================================================="
echo "OMNISHOP DATABASE LOCAL SETUP AUTOMATION"
echo "===================================================================="

# Check if docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

echo "1. Cleaning up any conflicting container instances..."
docker rm -f omnishop-temp-db >/dev/null 2>&1 || true

echo "2. Spawning Docker PostgreSQL alpine instance with local volume mount..."
docker run --name omnishop-temp-db \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres:alpine

echo "3. Polling database socket for readiness..."
until docker exec omnishop-temp-db pg_isready >/dev/null 2>&1; do
    echo "Awaiting Postgres socket connection..."
    sleep 1.5
done
echo "Database is ready to accept connections!"

echo "4. Deploying core database schema and B-Tree indexing constraints..."
docker exec -t omnishop-temp-db psql -U postgres -d postgres -f schema.sql

echo "5. Performing bulk CSV data ingestion via psql \copy..."
docker exec -t omnishop-temp-db psql -U postgres -d postgres -f scripts/load_data.sql

echo "6. Compiling PL/pgSQL stored procedures..."
docker exec -t omnishop-temp-db psql -U postgres -d postgres -f sql_queries/procedures/proc_process_order.sql
docker exec -t omnishop-temp-db psql -U postgres -d postgres -f sql_queries/procedures/proc_manage_customer.sql
docker exec -t omnishop-temp-db psql -U postgres -d postgres -f sql_queries/procedures/proc_generate_bi_report.sql

echo "7. Executing transactional database automations..."
docker exec -t omnishop-temp-db psql -U postgres -d postgres -c "CALL core.refresh_daily_sales_cache(30);"
docker exec -t omnishop-temp-db psql -U postgres -d postgres -c "CALL core.deactivate_customer_account(9490);"
docker exec -t omnishop-temp-db psql -U postgres -d postgres -c "CALL core.process_order_checkout(161);"

echo "8. Executing validation tests on all query scripts..."
find sql_queries -name "*.sql" -exec sh -c '
    echo "Validating {}..."
    docker exec omnishop-temp-db psql -U postgres -d postgres -P pager=off -f "/workspace/{}" > /dev/null
' \;

echo "===================================================================="
echo "OMNISHOP LOCAL INSTANCE SETUP COMPLETED SUCCESSFULLY!"
echo "Database state: POPULATED & ACTIVE"
echo "Container name: omnishop-temp-db"
echo "Port mapping:   localhost:5432"
echo "Connection credentials: PGPASSWORD=postgres psql -h localhost -U postgres"
echo "To clean up / delete container: docker rm -f omnishop-temp-db"
echo "===================================================================="
