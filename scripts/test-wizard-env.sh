#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Load only the wizard library, before the example stage performs any work.
source <(sed '/^# STAGES:/,$d' "$repo_root/skills/engineering/wizard/template.sh")

ENV_FILE=$(mktemp)
trap 'rm -f "$ENV_FILE"' EXIT

assert_existing() {
  local expected="$1" actual
  actual=$(_existing API_KEY)
  [[ "$actual" == "$expected" ]] || {
    printf 'expected <%s>, got <%s>\n' "$expected" "$actual" >&2
    return 1
  }
}

printf 'API_KEY="dummy-value"\n' > "$ENV_FILE"
assert_existing 'dummy-value'
write_env API_KEY "$(_existing API_KEY)" >/dev/null
assert_existing 'dummy-value'
[[ $(cat "$ENV_FILE") == "API_KEY='dummy-value'" ]]

for value in '"dummy-value"' "it's here" 'dollar$back\slash'; do
  write_env API_KEY "$value" >/dev/null
  assert_existing "$value"
done

for encoded in '"dollar$value"' '"back\slash"' '"escaped\"quote"'; do
  printf 'API_KEY=%s\n' "$encoded" > "$ENV_FILE"
  if _existing API_KEY >/dev/null; then
    printf 'unexpectedly decoded <%s>\n' "$encoded" >&2
    exit 1
  fi
done

printf 'wizard env decoding OK\n'
