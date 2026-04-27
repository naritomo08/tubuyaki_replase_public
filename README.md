# tubuyaki_replase_public

Laravel 版のつぶやきサイトを Elixir/Phoenix 版へ置き換えるためのプロジェクトです。

参考：

https://qiita.com/naritomo08/items/c0f139fa19295b9a0319

現在の Phoenix アプリ本体は `apps/tubuyaki` にあります。ルート直下の `docker-compose.yml` で Elixir/Phoenix 開発用コンテナ、PostgreSQL、Adminer を起動します。

## 構成

```text
tubuyaki_replase/
├── Dockerfile
├── docker-compose.yml
├── apps/
│   └── tubuyaki/              # Phoenix アプリ本体
├── data/
│   ├── postgres/volume/       # PostgreSQL 永続化データ
└── bin/                       # Docker 操作用スクリプト
```

## ソース入手

ソースは以下になります。



```bash
git clone https://github.com/naritomo08/tubuyaki_replase_public.git
cd tubuyaki_replase_public
```

## 起動方法

ルートディレクトリでコンテナを起動します。

```bash
docker compose up -d
```

`web` コンテナが `mix deps.get`、DB 作成、migration、`mix phx.server` を自動で実行します。

ブラウザで http://127.0.0.1:4000 を開きます。

## URL

- つぶやき一覧: http://127.0.0.1:4000/tweet
- ユーザー登録: http://127.0.0.1:4000/register
- ログイン: http://127.0.0.1:4000/login
- アカウント: http://127.0.0.1:4000/account
- 管理画面: http://127.0.0.1:4000/admin/users
- Adminer: http://127.0.0.1:8082

## 初回の使い方

1. `docker compose up -d` でコンテナを起動します。
2. http://127.0.0.1:4000/register からユーザー登録します。
3. 最初に登録したユーザーは管理者になります。
4. `/tweet` で投稿、画像付き投稿、編集、削除、いいねが使えます。
5. `/account` でプロフィール変更、パスワード変更、退会ができます。
6. 管理者は `/admin/users` でユーザー管理と集計確認ができます。

## 実装済み機能

- ユーザー登録、ログイン、ログアウト
- つぶやき一覧、投稿、編集、削除
- 画像付き投稿
- いいね
- アカウント管理
- 管理者向けユーザー管理
- PostgreSQL migration
- Phoenix controller test

Google OAuth 連携は導線のみ実装済みです。実際の Google 認証を有効にするには、`GOOGLE_CLIENT_ID` と `GOOGLE_CLIENT_SECRET` を使った OAuth フローの追加実装が必要です。

## DB

Phoenix アプリは PostgreSQL を使います。

開発用接続情報:

- ホスト: `postgres`
- ユーザー: `postgres`
- パスワード: `postgres`
- DB: `testsite_dev`

Adminer で確認する場合:

- URL: http://127.0.0.1:8082
- データベース種類: PostgreSQL
- サーバ: `postgres`
- ユーザ名: `postgres`
- パスワード: `postgres`
- データベース: `testsite_dev`

`8082` が使えない環境では、`ADMINER_PORT=任意のポート docker compose up -d` のように変更できます。

## よく使うコマンド

コンテナ起動:

```bash
docker compose up -d
```

コンテナ停止:

```bash
docker compose stop
```

コンテナ削除:

```bash
docker compose down
```

web コンテナに入る:

```bash
docker compose exec web /bin/bash
```

Phoenix サーバー起動:

```bash
docker compose up -d
```

テスト実行:

```bash
docker compose exec -T -e MIX_ENV=test web /bin/bash -lc "cd tubuyaki && mix test"
```

format:

```bash
docker compose exec -T web /bin/bash -lc "cd tubuyaki && mix format"
```

手動 migration:

```bash
docker compose exec -T web /bin/bash -lc "cd tubuyaki && mix ecto.migrate"
```
