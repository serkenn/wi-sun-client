# pi-wi-sun

このリポジトリは、Balena Cloud で管理する `gh_serkenn/pi-wi-sun` fleet 向けに、Raspberry Pi 3 (using 64bit OS) へデプロイするコンテナを管理するものです。

現在の構成は、Wi-SUN USB アダプタからスマートメーター値を取得する [`zabbix-smartmeter`](https://github.com/serkenn/zabbix-smartmeter) を Zabbix Agent コンテナへ組み込み、Zabbix から `UserParameter` 経由で取得できるようにしています。

## 構成

- `docs/system.md`: 全体構成メモ
- `docker-compose.yml`: balena 用サービス定義
- `agent/`: Zabbix Agent + zabbix-smartmeter のコンテナ実装
- `balena.yml`: balena アプリ情報と対応デバイス定義
- `zabbix/zabbix_smartmeter_template.xml`: Zabbix import 用テンプレート
- `.github/workflows/balena-deploy.yml`: GitHub Actions からの自動デプロイ

## 使うサービス

- Zabbix Agent
- `serkenn/zabbix-smartmeter`
- fleet: `gh_serkenn/pi-wi-sun`
- device type: `raspberrypi3-64`

## Balena Cloud への手動デプロイ

balena の公式ドキュメントでは、fleet へのデプロイ方法として `balena push` が推奨されています。まず balena CLI をインストールし、ログインします。

```bash
balena login
balena push gh_serkenn/pi-wi-sun --source .
```

`docker-compose.yml` をルートに置いたマルチコンテナ構成なので、そのまま fleet 向け release としてビルド・配布されます。

## 必須の Balena 環境変数

balenaCloud ダッシュボードの fleet または service variables に、少なくとも以下を設定してください。

- `ZABBIX_SERVER`: Zabbix Server または Proxy の IP / ホスト名
- `SMARTMETER_B_ROUTE_ID`: B ルート ID
- `SMARTMETER_B_ROUTE_PASSWORD`: B ルートパスワード

必要に応じて以下も設定します。

- `ZABBIX_SERVER_ACTIVE`: Active check 先。未設定時は `ZABBIX_SERVER`
- `ZABBIX_HOSTNAME`: Zabbix 上のホスト名。未設定時は `pi-wi-sun`
- `SMARTMETER_SERIAL_DEVICE`: 既定値 `/dev/ttyUSB0`
- `SMARTMETER_CHANNEL`: スキャン済みチャネル
- `SMARTMETER_IPADDR`: スキャン済み IPv6 アドレス
- `SMARTMETER_DSE`: `true` / `false`。UDG-1-WSNE は `true`
- `SMARTMETER_CACHE_TTL`: 同一取得結果のキャッシュ秒数。既定値 `5`

## Zabbix テンプレート

共有された Zabbix テンプレートは [`zabbix/zabbix_smartmeter_template.xml`](/Users/serken/Desktop/3/zabbix/zabbix_smartmeter_template.xml) として同梱しています。Zabbix UI から import して利用してください。

このテンプレートの主アイテムは次です。

- `smartmeter.get[{$SMARTMETER.DEVICE},{$SMARTMETER.ID},{$SMARTMETER.PASSWORD},{$SMARTMETER.CHANNEL},{$SMARTMETER.IP}]`

依存アイテムとして以下を作成します。

- `smartmeter.power`
- `smartmeter.current.r`
- `smartmeter.current.t`

テンプレートのマクロは balena の環境変数と対応させると管理しやすいです。

- `{$SMARTMETER.DEVICE}` <-> `SMARTMETER_SERIAL_DEVICE`
- `{$SMARTMETER.ID}` <-> `SMARTMETER_B_ROUTE_ID`
- `{$SMARTMETER.PASSWORD}` <-> `SMARTMETER_B_ROUTE_PASSWORD`
- `{$SMARTMETER.CHANNEL}` <-> `SMARTMETER_CHANNEL`
- `{$SMARTMETER.IP}` <-> `SMARTMETER_IPADDR`

## Zabbix Agent から取得できるキー

- `smartmeter.json`
- `smartmeter.power`
- `smartmeter.current.r`
- `smartmeter.current.t`
- `smartmeter.total.normal`
- `smartmeter.total.reverse`

複数キーを短時間に問い合わせても、コンテナ内で数秒キャッシュするためメーターへの連続アクセスを抑えます。

## 初回スキャン

チャネルや IP アドレスを固定したい場合は、デプロイ後にコンテナへ入ってスキャンします。

```bash
balena ssh <device-uuid> agent
/usr/local/bin/smartmeter-scan
```

取得できた `channel` と `ipaddr` を `SMARTMETER_CHANNEL` / `SMARTMETER_IPADDR` として balenaCloud に設定してください。

## GitHub Actions による自動デプロイ

`main` ブランチへ push するたびに `.github/workflows/balena-deploy.yml` が `balena push gh_serkenn/pi-wi-sun --source .` を実行します。事前に GitHub repository secrets に以下を追加してください。

- `BALENA_API_TOKEN`: balenaCloud の API key

設定手順:

1. balenaCloud の Preferences から API key を作成する
2. GitHub の `Settings > Secrets and variables > Actions` で `BALENA_API_TOKEN` を登録する
3. `main` へ push するか、Actions の `workflow_dispatch` で手動実行する

## 運用メモ

- `network_mode: host` にしているため、Agent は Pi の 10050/TCP で待ち受けます
- `privileged: true` にして USB シリアルを扱いやすくしています
- 標準の Linux テンプレートを当てると、コンテナ内部の情報を返す項目があります。必要なら host 監視用の追加調整を入れてください
