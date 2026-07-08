#!/bin/sh
# Check the environment variables required by the /to-xxx slash commands

ok=0
fail=0

check() {
  name=$1
  val=$2
  commands=$3

  if [ -z "$val" ]; then
    echo "  ✗ $name — not set (used by: $commands)"
    fail=$((fail + 1))
  elif [ ! -d "$val" ]; then
    echo "  ✗ $name=$val — path not found (used by: $commands)"
    fail=$((fail + 1))
  else
    echo "  ✓ $name=$val"
    ok=$((ok + 1))
  fi
}

echo "Claude /to-xxx environment variable check"
echo "─────────────────────────────"
check "BLOG_DIR"    "$BLOG_DIR"    "/blog, /blog-improve"
check "VAULT_DIR" "$VAULT_DIR" "/notes, /notes-cleanup"
check "DEVKIT_DIR"  "$DEVKIT_DIR"  "/notes-cleanup (publish cheatsheets/notes)"
echo "─────────────────────────────"
echo "  Result: ${ok} ok, ${fail} problem(s)"

[ "$fail" -eq 0 ]
