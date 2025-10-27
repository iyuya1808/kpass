# KPass Proxy Server - VPS デプロイメントガイド

## 概要

このガイドでは、KPass Proxy ServerをエックスサーバーのVPSにデプロイする手順を説明します。

## サーバー情報

- **サーバー名**: kpass-proxy-server
- **IPアドレス**: 85.131.245.64
- **OS**: Ubuntu 25.04
- **ホスト名**: x85-131-245-64.static.xvps.ne.jp

## 前提条件

- Node.js 18.0.0以上がインストールされていること
- npm 10.0.0以上がインストールされていること
- SSHアクセスが可能であること

## デプロイ手順

### Step 1: サーバーへの接続

```bash
ssh username@85.131.245.64
```

### Step 2: 必要なツールのインストール確認

```bash
# Node.js バージョン確認
node --version

# npm バージョン確認
npm --version

# Git のインストール（必要に応じて）
sudo apt update
sudo apt install git -y
```

### Step 3: アプリケーションディレクトリの作成

```bash
# アプリケーション用ディレクトリを作成
mkdir -p ~/kpass-proxy-server
cd ~/kpass-proxy-server
```

### Step 4: ファイルのアップロード

以下の方法のいずれかでファイルをアップロードしてください：

#### 方法A: SCP を使用

ローカルマシンから実行：

```bash
cd /path/to/KPASS
scp -r proxy-server/* username@85.131.245.64:~/kpass-proxy-server/
```

#### 方法B: Git を使用（推奨）

1. GitHubリポジトリを作成
2. コードをプッシュ
3. サーバーでクローン：

```bash
git clone your-repository-url.git ~/kpass-proxy-server
cd ~/kpass-proxy-server
```

### Step 5: 依存関係のインストール

```bash
cd ~/kpass-proxy-server
npm install --production
```

### Step 6: 環境変数の設定

`.env` ファイルを作成：

```bash
nano ~/kpass-proxy-server/.env
```

以下の内容を設定：

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=your-very-secure-random-secret-key-minimum-32-characters
ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*,http://85.131.245.64:*
LOG_LEVEL=info
```

**重要**: `JWT_SECRET` は強力なランダム文字列に変更してください。

### Step 7: PuppeteerのChromeインストール

```bash
# Puppeteer用のChromeをインストール
npx puppeteer browsers install chrome
```

### Step 8: ログディレクトリの作成

```bash
mkdir -p ~/kpass-proxy-server/logs
```

### Step 9: PM2を使用したプロセス管理のセットアップ

#### PM2のインストール

```bash
npm install -g pm2
```

#### PM2でアプリケーションを起動

```bash
cd ~/kpass-proxy-server
pm2 start src/index.js --name kpass-proxy
```

#### PM2の設定を保存

```bash
pm2 save
pm2 startup
```

### Step 10: ファイアウォールの設定（必要な場合）

```bash
sudo ufw allow 3000/tcp
sudo ufw reload
```

### Step 11: 動作確認

```bash
# サーバーが起動しているか確認
curl http://localhost:3000/health

# 外部からアクセスできるか確認
curl http://85.131.245.64:3000/health
```

## サービスの管理

### PM2コマンド

```bash
# ステータス確認
pm2 status

# ログ確認
pm2 logs kpass-proxy

# 再起動
pm2 restart kpass-proxy

# 停止
pm2 stop kpass-proxy

# 開始
pm2 start kpass-proxy

# 削除
pm2 delete kpass-proxy
```

## Nginxリバースプロキシの設定（オプション）

ドメインを使用する場合、Nginxを設定してリバースプロキシとして使用できます。

### Nginxのインストール

```bash
sudo apt install nginx -y
```

### Nginx設定ファイルの作成

```bash
sudo nano /etc/nginx/sites-available/kpass-proxy
```

以下の内容を設定：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 設定を有効化

```bash
sudo ln -s /etc/nginx/sites-available/kpass-proxy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## SSL/TLS証明書の設定（Let's Encrypt）

HTTPSを使用する場合：

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

## トラブルシューティング

### アプリケーションが起動しない

```bash
# ログを確認
pm2 logs kpass-proxy

# ポートが使用中でないか確認
sudo lsof -i :3000

# 環境変数が正しく設定されているか確認
cd ~/kpass-proxy-server
cat .env
```

### Puppeteerエラー

```bash
# Chromeを再インストール
cd ~/kpass-proxy-server
npx puppeteer browsers install chrome
```

### ファイアウォールの問題

```bash
# UFWの状態を確認
sudo ufw status

# ポート3000を許可
sudo ufw allow 3000/tcp
```

## 自動更新設定（Git使用時）

```bash
# 更新スクリプトを作成
nano ~/update-kpass.sh
```

```bash
#!/bin/bash
cd ~/kpass-proxy-server
git pull
npm install --production
pm2 restart kpass-proxy
```

```bash
chmod +x ~/update-kpass.sh
```

## セキュリティチェックリスト

- [ ] `.env` ファイルが適切に保護されている
- [ ] `JWT_SECRET` が強力なランダム文字列である
- [ ] ファイアウォールが適切に設定されている
- [ ] 不要なポートが開いていない
- [ ] SSL/TLSが有効になっている（本番環境）
- [ ] 定期的なログローテーションが設定されている

## お問い合わせ

問題が発生した場合は、ログファイルを確認してください：

```bash
tail -f ~/kpass-proxy-server/logs/combined.log
tail -f ~/kpass-proxy-server/logs/error.log
```

