# tubuyaki

Laravel 版つぶやきサイトを置き換える Phoenix アプリです。

この README は Phoenix アプリ単体のメモです。Docker を含むプロジェクト全体の起動方法は、ルートの `README.md` を参照してください。

## アプリ構成

```text
apps/tubuyaki/
├── lib/testsite/                 # コンテキスト、Ecto schema
├── lib/testsite_web/             # Router、Controller、HTML template
├── priv/repo/migrations/         # DB migration
├── priv/static/uploads/          # 投稿画像の保存先
├── config/                       # Phoenix 設定
└── test/                         # controller test
```

## 開発サーバー

Docker の `web` コンテナ内で起動します。

```bash
cd /apps/tubuyaki
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

ブラウザで http://127.0.0.1:4000 を開きます。

## 主要ルート

- `GET /` - `/tweet` へリダイレクト
- `GET /tweet` - つぶやき一覧
- `GET /register` / `POST /register` - ユーザー登録
- `GET /login` / `POST /login` - ログイン
- `DELETE /logout` - ログアウト
- `GET /account` - アカウント画面
- `GET /admin/users` - 管理者向けユーザー管理

## DB

開発環境では PostgreSQL を使用します。

- ホスト: `postgres`
- ユーザー: `postgres`
- パスワード: `postgres`
- DB: `testsite_dev`

テスト環境では `testsite_test` を使用します。

## テスト

```bash
cd /apps/tubuyaki
MIX_ENV=test mix test
```

## 補足

- 最初に登録したユーザーは管理者になります。
- 投稿画像は `priv/static/uploads/` に保存されます。
- Google OAuth 連携は導線のみ実装済みで、実認証には追加設定と実装が必要です。
