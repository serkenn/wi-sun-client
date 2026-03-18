#!/bin/bash
set -euo pipefail

mkdir -p /var/cache/smartmeter /etc/zabbix/zabbix_agentd.d

if [[ -z "${ZABBIX_HOSTNAME:-}" ]]; then
  if [[ -n "${BALENA_DEVICE_UUID:-}" ]]; then
    export ZABBIX_HOSTNAME="${BALENA_DEVICE_UUID}"
  else
    export ZABBIX_HOSTNAME="pi-wi-sun"
  fi
fi

if [[ -z "${ZABBIX_SERVER:-}" ]]; then
  echo "ZABBIX_SERVER is required" >&2
  exit 1
fi

if [[ -z "${SMARTMETER_B_ROUTE_ID:-}" || -z "${SMARTMETER_B_ROUTE_PASSWORD:-}" ]]; then
  echo "SMARTMETER_B_ROUTE_ID and SMARTMETER_B_ROUTE_PASSWORD are required" >&2
  exit 1
fi

export ZABBIX_SERVER_ACTIVE="${ZABBIX_SERVER_ACTIVE:-${ZABBIX_SERVER}}"
export SMARTMETER_SERIAL_DEVICE="${SMARTMETER_SERIAL_DEVICE:-/dev/ttyUSB0}"
export SMARTMETER_CACHE_TTL="${SMARTMETER_CACHE_TTL:-5}"
export SMARTMETER_VERBOSITY="${SMARTMETER_VERBOSITY:-1}"
export SMARTMETER_DSE="${SMARTMETER_DSE:-true}"
export ZABBIX_AGENT_LISTEN_PORT="${ZABBIX_AGENT_LISTEN_PORT:-10050}"
export ZABBIX_AGENT_LISTEN_IP="${ZABBIX_AGENT_LISTEN_IP:-0.0.0.0}"

envsubst \
  < /etc/zabbix/zabbix_agentd.conf.template \
  > /etc/zabbix/zabbix_agentd.conf

cat <<'EOF' > /etc/zabbix/zabbix_agentd.d/smartmeter.conf
UserParameter=smartmeter.get[*],/usr/local/bin/smartmeter-metric get "$1" "$2" "$3" "$4" "$5"
UserParameter=smartmeter.json,/usr/local/bin/smartmeter-metric json
UserParameter=smartmeter.power,/usr/local/bin/smartmeter-metric value
UserParameter=smartmeter.current.r,/usr/local/bin/smartmeter-metric r
UserParameter=smartmeter.current.t,/usr/local/bin/smartmeter-metric t
UserParameter=smartmeter.total.normal,/usr/local/bin/smartmeter-metric total_normal
UserParameter=smartmeter.total.reverse,/usr/local/bin/smartmeter-metric total_reverse
EOF

exec "$@"
