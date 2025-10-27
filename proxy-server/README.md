# KPass Proxy Server

Proxy APIサーバーfor K-LMS (Canvas LMS) 認証とセッション管理

## 概要

このProxyサーバーは、K-LMSのShibboleth認証を自動化し、FlutterアプリからCanvas APIへのアクセスを可能にします。

### 主な機能

- **Puppeteerによる自動ログイン**: K-LMSのShibboleth認証フローを自動化
- **セッション管理**: ユーザーごとのセッションを保持し、定期的に延命
- **Canvas APIプロキシ**: 認証されたリクエストをCanvas APIに中継
- **JWT認証**: FlutterアプリとProxyサーバー間の安全な通信

## セットアップ

### 前提条件

- Node.js 18.0.0以上
- npm 10.0.0以上

### インストール

```bash
cd proxy-server
npm install
```

### 環境設定

`.env`ファイルを作成（`.env.example`を参考）:

```env
NODE_ENV=development
PORT=3000
JWT_SECRET=your-secret-key
ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*
```

## 起動方法

### 開発環境

```bash
npm run dev
```

### 本番環境

```bash
npm start
```

サーバーが起動すると `http://localhost:3000` でアクセス可能になります。

## API エンドポイント

### 認証

#### POST /api/auth/login
K-LMSにログイン

**リクエスト:**
```json
{
  "username": "your-keio-id",
  "password": "your-password"
}
```

**レスポンス:**
```json
{
  "success": true,
  "token": "jwt-token",
  "user": {
    "id": 12345,
    "name": "Your Name",
    "email": "your@keio.jp"
  }
}
```

#### POST /api/auth/logout
ログアウト

**ヘッダー:**
```
Authorization: Bearer <token>
```

#### GET /api/auth/validate
セッション検証

**ヘッダー:**
```
Authorization: Bearer <token>
```

#### GET /api/auth/user
ユーザー情報取得

**ヘッダー:**
```
Authorization: Bearer <token>
```

### Canvas API

すべてのエンドポイントは認証が必要です（Authorizationヘッダー）。

#### GET /api/courses
コース一覧取得

#### GET /api/courses/:id
コース詳細取得

#### GET /api/courses/:id/assignments
課題一覧取得

#### GET /api/calendar_events
カレンダーイベント取得

#### GET /api/users/self
現在のユーザー情報取得

## セッション管理

- セッションは5分ごとに自動検証され延命されます
- 60分間アクセスがないセッションは自動的に削除されます
- Puppeteerを使用してCanvas APIを呼び出し、セッションを維持します

## セキュリティ

- すべてのリクエストにRate Limitingが適用されています
- パスワードはbcryptでハッシュ化されて保存されます
- JWT トークンは24時間有効です
- CORS設定により許可されたオリジンからのみアクセス可能です

## トラブルシューティング

### Puppeteerが起動しない

Chromeがインストールされていない場合、以下のコマンドでインストールしてください:

```bash
npx puppeteer browsers install chrome
```

### ログイン失敗

- K-LMSの認証情報が正しいか確認してください
- ネットワーク接続を確認してください
- ログファイル (`logs/combined.log`) を確認してください

### セッションが切れる

- Proxyサーバーが起動しているか確認してください
- セッション延命タスクが正常に動作しているか確認してください

## ログ

ログは `logs/` ディレクトリに保存されます:

- `combined.log`: すべてのログ
- `error.log`: エラーログのみ

## 開発

### デバッグモード

環境変数 `LOG_LEVEL=debug` を設定すると、詳細なログが出力されます。

### テスト

```bash
npm test
```

## ライセンス

MIT

