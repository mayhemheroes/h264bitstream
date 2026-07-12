#!/usr/bin/env bash
#
# mayhem/test.sh — RUN h264bitstream's upstream functional test suite (the
# golden-output known-answer tests from Makefile.unix's `test:` target).
# build.sh already built /mayhem/h264_analyze; this only RUNS it and diffs its
# output against the committed golden `samples/*.out` files. A no-op / exit(0)
# patch produces empty output → diff fails → test.sh fails.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

ANALYZE=/mayhem/h264_analyze
if [ ! -x "$ANALYZE" ]; then
  echo "!! $ANALYZE missing — build.sh did not produce the test binary" >&2
  emit_ctrf "h264-golden" 0 1
  exit 1
fi

# Golden known-answer tests: parse each sample stream and diff against its
# committed reference dump (samples/<name>.out).
SAMPLES=(JM_cqm_cabac x264_test riverbed-II-360p-48961)
passed=0; failed=0
tmp="$(mktemp -d)"
for s in "${SAMPLES[@]}"; do
  in="$SRC/samples/$s.264"; ref="$SRC/samples/$s.out"
  if [ ! -f "$in" ] || [ ! -f "$ref" ]; then
    echo "SKIP $s (missing sample)"; failed=$((failed+1)); continue
  fi
  "$ANALYZE" "$in" > "$tmp/$s.out" 2>/dev/null || true
  if diff -u "$ref" "$tmp/$s.out" > "$tmp/$s.diff" 2>&1; then
    echo "PASS $s"; passed=$((passed+1))
  else
    echo "FAIL $s"; sed -n '1,20p' "$tmp/$s.diff"; failed=$((failed+1))
  fi
done
rm -rf "$tmp"

emit_ctrf "h264-golden" "$passed" "$failed"
