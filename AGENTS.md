# Repository Guidelines

## このリポジトリの役割

このリポジトリは、Balena Cloud 上の fleet `gh_serkenn/pi-wi-sun` に対して、Raspberry Pi 3 (using 64bit OS) へ配布するコンテナ群を管理するための開発者向けリポジトリです。中心となる機能は、Wi-SUN USB アダプタ経由でスマートメーター値を取得し、Zabbix Agent から参照できるようにすることです。

## 返答と言語方針

このリポジトリで作業するエージェントは日本語で返答してください。追加するドキュメント、作業メモ、README の説明も原則日本語で記述します。

## 現在の構成

- `docs/system.md`: システム全体像
- `docker-compose.yml`: balena マルチコンテナ定義
- `agent/`: Zabbix Agent と `zabbix-smartmeter` を組み合わせたサービス
- `balena.yml`: balena 用メタデータ
- `zabbix/`: Zabbix import 用テンプレート
- `.github/workflows/balena-deploy.yml`: GitHub Actions からの自動デプロイ
- `README.md`: 利用者・運用者向けの入口情報

## 変更時の基本ルール

- コンテナ構成、環境変数、デプロイ方法を変えたら `README.md` も同時に更新する
- Zabbix のアイテムキーやマクロを変えたら `agent/` と `zabbix/*.xml` を必ず同時に更新する
- Balena 固有の前提は `README.md` に書き、内部向けの判断理由やメモは `AGENTS.md` に書く
- `zabbix-smartmeter` の upstream 変更を取り込む場合は、影響する環境変数や Zabbix キーも確認する
- Raspberry Pi 3 (using 64bit OS) / `raspberrypi3-64` を前提に壊さない

## 運用メモ

- 現在は `agent` サービス 1 つで運用する
- `network_mode: host` と `privileged: true` を使っている
- Zabbix の通常アイテムはコンテナ視点になる場合があるため、用途を混同しない
- 各編集後には `README.md` を適切に作成・更新し、初見でもデプロイ手順が追える状態を保つ
