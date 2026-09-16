#!/usr/bin/env bash
# RePlate Supabase stress test
# Tests the REST API and Edge Functions under concurrent load.
#
# Usage:
#   chmod +x stress_test.sh
#   SUPABASE_URL=https://cahwspfvdgnkigxuezee.supabase.co \
#   SUPABASE_ANON_KEY=<your-anon-key> \
#   ./stress_test.sh
#
# Set CONCURRENCY (default 20) and ITERATIONS (default 50) as env vars to tune.

set -euo pipefail

BASE_URL="${SUPABASE_URL:-https://cahwspfvdgnkigxuezee.supabase.co}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"
CONCURRENCY="${CONCURRENCY:-20}"
ITERATIONS="${ITERATIONS:-50}"

if [[ -z "$ANON_KEY" ]]; then
  echo "ERROR: Set SUPABASE_ANON_KEY before running." >&2
  exit 1
fi

AUTH="Authorization: Bearer $ANON_KEY"
API="$BASE_URL/rest/v1"

pass=0; fail=0; total_time=0

log() { printf '%s\n' "$*"; }
ok()  { ((pass++)) || true; }
err() { ((fail++)) || true; log "  FAIL: $*"; }

# ── helper: time a curl call ──────────────────────────────────────────────────
ms() { python3 -c "import time; print(int(time.time()*1000))"; }

timed_curl() {
  local label="$1"; shift
  local start elapsed status
  start=$(ms)
  status=$(curl -s -o /dev/null -w '%{http_code}' \
    -H "apikey: $ANON_KEY" -H "$AUTH" -H "Content-Type: application/json" \
    "$@") || status=0
  elapsed=$(( $(ms) - start ))
  total_time=$(( total_time + elapsed ))
  if [[ "$status" == "200" || "$status" == "201" ]]; then
    ok; printf '  %-50s %sms  HTTP %s\n' "$label" "$elapsed" "$status"
  else
    err "$label — HTTP $status (${elapsed}ms)"
  fi
}

# ── parallel burst helper ─────────────────────────────────────────────────────
burst() {
  local label="$1"; shift
  local pids=()
  for (( i=0; i<CONCURRENCY; i++ )); do
    timed_curl "$label #$i" "$@" &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done
}

# =============================================================================
log ""
log "═══════════════════════════════════════════════════════"
log "  RePlate Supabase Stress Test"
log "  Base URL   : $BASE_URL"
log "  Concurrency: $CONCURRENCY parallel requests per burst"
log "  Iterations : $ITERATIONS sequential rounds"
log "═══════════════════════════════════════════════════════"
log ""

# ── 1. Health check ───────────────────────────────────────────────────────────
log "▶ 1. Health check"
timed_curl "GET /rest/v1/ (schema ping)" "$API/"
log ""

# ── 2. Read food_listings (customer home feed) ────────────────────────────────
log "▶ 2. Customer home feed — food_listings read ($CONCURRENCY concurrent)"
burst "GET food_listings?status=active" \
  "$API/food_listings?status=eq.active&order=created_at.desc&limit=50&select=*"
log ""

# ── 3. Read restaurants table ─────────────────────────────────────────────────
log "▶ 3. Restaurant directory read ($CONCURRENCY concurrent)"
burst "GET restaurants?select=*" \
  "$API/restaurants?select=id,name,cuisine,address,rating&limit=50"
log ""

# ── 4. Sequential listing reads (simulates scrolling / pagination) ────────────
log "▶ 4. Sequential listing reads ($ITERATIONS requests)"
for (( i=0; i<ITERATIONS; i++ )); do
  timed_curl "GET food_listings page $i" \
    "$API/food_listings?select=*&status=eq.active&limit=20&offset=$(( i*20 ))"
done
log ""

# ── 5. Restaurants read under load ($ITERATIONS × $CONCURRENCY) ──────────────
log "▶ 5. Restaurants read — $ITERATIONS rounds × $CONCURRENCY concurrent"
for (( i=0; i<ITERATIONS; i++ )); do
  burst "restaurants burst $i" \
    "$API/restaurants?select=id,name,cuisine,address&limit=50"
done
log ""

# ── 6. Profiles table read (auth-gated, anon key only sees public rows) ───────
log "▶ 6. Profiles table (anon access — expects 200 or 401)"
status=$(curl -s -o /dev/null -w '%{http_code}' \
  -H "apikey: $ANON_KEY" -H "$AUTH" \
  "$API/profiles?select=id,name&limit=10") || status=0
log "  GET profiles — HTTP $status"
if [[ "$status" == "200" || "$status" == "401" || "$status" == "403" ]]; then
  ok
else
  err "unexpected status $status for profiles table"
fi
log ""

# ── Summary ───────────────────────────────────────────────────────────────────
total=$(( pass + fail ))
avg=$(( total > 0 ? total_time / total : 0 ))

log "═══════════════════════════════════════════════════════"
log "  Results: $pass passed / $fail failed / $total total"
log "  Avg response time: ${avg}ms"
log "═══════════════════════════════════════════════════════"
log ""

if [[ "$fail" -gt 0 ]]; then
  log "  ⚠  $fail request(s) failed — check Supabase logs."
  exit 1
else
  log "  ✓  All requests succeeded."
fi
