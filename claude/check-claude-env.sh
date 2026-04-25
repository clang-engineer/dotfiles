#!/bin/sh
# /to-xxx 슬래시 커맨드에 필요한 환경변수 점검

ok=0
fail=0

check() {
  name=$1
  val=$2
  commands=$3

  if [ -z "$val" ]; then
    echo "  ✗ $name — 미설정 (사용: $commands)"
    fail=$((fail + 1))
  elif [ ! -d "$val" ]; then
    echo "  ✗ $name=$val — 경로 없음 (사용: $commands)"
    fail=$((fail + 1))
  else
    echo "  ✓ $name=$val"
    ok=$((ok + 1))
  fi
}

echo "Claude /to-xxx 환경변수 점검"
echo "─────────────────────────────"
check "BLOG_DIR"    "$BLOG_DIR"    "/to-post, /to-todo, /done-todo"
check "TOOLBOX_DIR" "$TOOLBOX_DIR" "/to-til, /to-cheatsheet, /to-script"
echo "─────────────────────────────"
echo "  결과: ${ok}개 정상, ${fail}개 문제"

[ "$fail" -eq 0 ]
