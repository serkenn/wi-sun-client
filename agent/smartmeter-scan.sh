#!/bin/bash
set -euo pipefail

args=(
  --scan
  --id "${SMARTMETER_B_ROUTE_ID}"
  --password "${SMARTMETER_B_ROUTE_PASSWORD}"
  --device "${SMARTMETER_SERIAL_DEVICE:-/dev/ttyUSB0}"
  --verbosity "${SMARTMETER_VERBOSITY:-3}"
)

if [[ "${SMARTMETER_DSE:-true}" == "true" ]]; then
  args+=(--dse)
fi

exec /usr/local/bin/zabbix-smartmeter "${args[@]}"

