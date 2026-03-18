#!/bin/bash
set -euo pipefail

mode="${1:-json}"
shift || true

ttl="${SMARTMETER_CACHE_TTL:-5}"
device="${SMARTMETER_SERIAL_DEVICE:-/dev/ttyUSB0}"
broute_id="${SMARTMETER_B_ROUTE_ID:-}"
broute_password="${SMARTMETER_B_ROUTE_PASSWORD:-}"
channel="${SMARTMETER_CHANNEL:-}"
ipaddr="${SMARTMETER_IPADDR:-}"
dse="${SMARTMETER_DSE:-true}"
verbosity="${SMARTMETER_VERBOSITY:-1}"

case "$mode" in
  get)
    device="${1:-$device}"
    broute_id="${2:-$broute_id}"
    broute_password="${3:-$broute_password}"
    channel="${4:-$channel}"
    ipaddr="${5:-$ipaddr}"
    output_key="json"
    ;;
  json)
    output_key="json"
    ;;
  *)
    output_key="$mode"
    ;;
esac

cache_key="$(printf '%s|%s|%s|%s|%s' "$device" "$broute_id" "$channel" "$ipaddr" "$dse" | sha256sum | awk '{print $1}')"
cache_file="/var/cache/smartmeter/${cache_key}.json"
tmp_file="$(mktemp)"

cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT

refresh_cache() {
  local args=(
    --json
    --id "${broute_id}"
    --password "${broute_password}"
    --device "${device}"
    --verbosity "${verbosity}"
  )

  if [[ "$dse" == "true" ]]; then
    args+=(--dse)
  fi

  if [[ -n "$channel" ]]; then
    args+=(--channel "$channel")
  fi

  if [[ -n "$ipaddr" ]]; then
    args+=(--ipaddr "$ipaddr")
  fi

  /usr/local/bin/zabbix-smartmeter "${args[@]}" > "$tmp_file"
  mv "$tmp_file" "$cache_file"
}

if [[ ! -s "$cache_file" ]]; then
  refresh_cache
else
  now="$(date +%s)"
  mtime="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")"
  age="$((now - mtime))"
  if (( age >= ttl )); then
    refresh_cache
  fi
fi

if [[ "$output_key" == "json" ]]; then
  cat "$cache_file"
  exit 0
fi

jq -er --arg key "$output_key" '.[$key]' "$cache_file"
