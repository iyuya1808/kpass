# Proxy API移行ガイド

## 概要

このガイドでは、K-LMS認証システムを直接WebView方式からProxy APIサーバー経由方式への移行について説明します。

## アーキテクチャの変更

### 変更前（WebView直接認証）
```
Flutter App → WebView → K-LMS (Shibboleth) → Canvas API直接呼び出し
```

**問題点:**
- セッションが1時間で切れる
- アクセストークンも1時間で失効
- 毎回ログインが必要

### 変更後（Proxy API経由）
```
Flutter App → Proxy API Server → Puppeteer → K-LMS → Canvas API
           ↓                    ↓
    認証情報送信          セッション維持・Cookie管理
```

**メリット:**
- Proxyサーバーがセッションを維持
- 定期的にセッションを延命（5分ごと）
- ユーザーは一度ログインすれば継続利用可能

## セットアップ手順

### 1. Proxy APIサーバーのセットアップ

```bash
cd proxy-server
npm install
```

`.env`ファイルを作成:
```env
NODE_ENV=development
PORT=3000
JWT_SECRET=your-secret-key-change-this
ALLOWED_ORIGINS=http://localhost:*
```

サーバーを起動:
```bash
npm start
```

### 2. Flutterアプリの依存関係更新

```bash
cd ..
flutter pub get
```

これにより、`webview_flutter`が削除され、新しいProxy API経由のコードが有効になります。

### 3. アプリの実行

```bash
flutter run
```

## 使い方

### 1. ログイン

アプリを起動すると、新しいログイン画面が表示されます:

- **ユーザー名**: 慶應ID
- **パスワード**: K-LMSのパスワード

入力後、「ログイン」ボタンをクリックします。

### 2. 初回ログイン

初回ログイン時は、Puppeteerがバックグラウンドでブラウザを起動し、K-LMSにログインします。
これには10-20秒程度かかる場合があります。

### 3. セッション継続

一度ログインすれば、セッションはProxyサーバー側で管理されます。
アプリを再起動しても、セッションが有効な間はログインが維持されます。

## 主な変更点

### Flutter側

#### 削除されたファイル
- `lib/features/auth/data/services/auth_service.dart` - WebView認証サービス

#### 新規作成されたファイル
- `lib/core/services/proxy_api_client.dart` - Proxy API通信クライアント
- `lib/features/auth/data/services/proxy_auth_service.dart` - Proxy API認証サービス
- `lib/features/auth/presentation/screens/credential_login_screen.dart` - ユーザー名・パスワード入力画面

#### 変更されたファイル
- `lib/features/auth/presentation/providers/auth_provider.dart` - Proxy API認証に変更
- `lib/features/auth/presentation/screens/login_screen.dart` - 新しいログイン画面に変更
- `lib/core/services/canvas_api_client.dart` - Proxy API経由に変更
- `lib/core/services/secure_storage_service.dart` - Proxyトークン保存機能追加
- `pubspec.yaml` - webview_flutter削除

### Proxy Server側

#### 新規作成されたファイル
- `proxy-server/src/index.js` - メインサーバー
- `proxy-server/src/auth/puppeteer-auth.js` - Puppeteer認証ロジック
- `proxy-server/src/auth/session-manager.js` - セッション管理
- `proxy-server/src/api/auth-routes.js` - 認証エンドポイント
- `proxy-server/src/api/canvas-routes.js` - Canvas APIプロキシ
- `proxy-server/src/utils/logger.js` - ログ管理
- `proxy-server/src/utils/security.js` - セキュリティ関連

## トラブルシューティング

### Proxyサーバーに接続できない

**症状:**
- ログイン時に「Network connection error」エラー

**解決方法:**
1. Proxyサーバーが起動しているか確認:
   ```bash
   curl http://localhost:3000/health
   ```
2. `proxy-server`ディレクトリで`npm start`を実行

### ログイン失敗

**症状:**
- 「Invalid username or password」エラー

**解決方法:**
1. K-LMSの認証情報が正しいか確認
2. Proxyサーバーのログを確認:
   ```bash
   tail -f proxy-server/logs/combined.log
   ```
3. K-LMSに直接ログインできるか確認

### セッションが切れる

**症状:**
- しばらく使っていないとログアウトされる

**原因:**
- セッションタイムアウト（デフォルト60分）
- Proxyサーバーが停止している

**解決方法:**
1. Proxyサーバーが起動しているか確認
2. もう一度ログインする

### Puppeteerエラー

**症状:**
- ログイン時に「Authentication service unavailable」エラー

**解決方法:**
1. Chromeブラウザをインストール:
   ```bash
   cd proxy-server
   npx puppeteer browsers install chrome
   ```
2. Proxyサーバーを再起動

## パフォーマンス

### 初回ログイン
- **WebView方式**: 約5-10秒
- **Proxy API方式**: 約10-20秒（Puppeteerの起動が必要）

### 2回目以降
- **WebView方式**: 約5-10秒（毎回ログイン必要）
- **Proxy API方式**: 約1-2秒（セッション維持されている）

### データ取得
- **WebView方式**: 直接API呼び出し
- **Proxy API方式**: Proxy経由（わずかな遅延あり）

## セキュリティ

### 認証情報の保存
- パスワードは**保存されません**
- Proxy APIから取得したJWTトークンのみFlutterアプリに保存
- Proxyサーバー側でセッションCookieを管理

### 通信の暗号化
- 開発環境: HTTP（ローカルのため）
- 本番環境: HTTPS推奨

### トークンの有効期限
- JWTトークン: 24時間
- セッション: 60分間アクセスなしで失効

## 本番環境デプロイ

### Proxyサーバーのデプロイ

1. Heroku / Railway / Render などにデプロイ
2. 環境変数を設定:
   ```env
   NODE_ENV=production
   PORT=3000
   JWT_SECRET=strong-random-secret
   ALLOWED_ORIGINS=https://your-app-domain.com
   ```

### Flutter側の設定変更

`lib/core/services/proxy_api_client.dart`の`_baseUrl`を変更:
```dart
static const String _baseUrl = 'https://your-proxy-server.com/api';
```

## まとめ

Proxy API方式への移行により:
- ✅ セッションが自動的に維持される
- ✅ ユーザーは一度ログインすれば継続利用可能
- ✅ セキュアな認証フロー
- ⚠️ 初回ログインに時間がかかる（許容範囲内）
- ⚠️ Proxyサーバーの管理が必要

全体として、ユーザーエクスペリエンスが大幅に向上しました。

