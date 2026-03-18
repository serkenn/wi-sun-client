FROM golang:1.23-bookworm AS builder

ARG SMARTMETER_REPO=https://github.com/serkenn/zabbix-smartmeter.git
ARG SMARTMETER_REF=master

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${SMARTMETER_REF}" "${SMARTMETER_REPO}" app

WORKDIR /src/app
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/zabbix-smartmeter .

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    gettext-base \
    jq \
    tini \
    zabbix-agent \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/zabbix-smartmeter /usr/local/bin/zabbix-smartmeter
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY smartmeter-metric.sh /usr/local/bin/smartmeter-metric
COPY smartmeter-scan.sh /usr/local/bin/smartmeter-scan
COPY zabbix_agentd.conf.template /etc/zabbix/zabbix_agentd.conf.template

RUN chmod +x \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/smartmeter-metric \
    /usr/local/bin/smartmeter-scan \
    /usr/local/bin/zabbix-smartmeter \
 && mkdir -p /var/cache/smartmeter /etc/zabbix/zabbix_agentd.d

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["zabbix_agentd", "-f", "-c", "/etc/zabbix/zabbix_agentd.conf"]

