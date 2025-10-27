#!/bin/bash

# VPSデプロイスクリプト
VPS_IP="85.131.245.64"
VPS_USER="ubuntu"
SSH_KEY="$HOME/.ssh/kpass-vps.pem"
ARCHIVE_FILE="kpass-proxy-v2.tar.gz"
REMOTE_PATH="~/kpass-proxy-server"

echo "=== KPass Proxy Server デプロイ ==="
echo "VPS: $VPS_IP"
echo ""

# 1. アーカイブファイルの存在確認
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "❌ アーカイブファイルが見つかりません: $ARCHIVE_FILE"
    exit 1
fi

echo "✅ アーカイブファイルを確認: $ARCHIVE_FILE"
echo ""

# 2. SSH接続テスト
echo "📡 SSH接続をテスト中..."
ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "echo 'SSH接続成功'" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ SSH接続に失敗しました"
    echo ""
    echo "接続を確認してください:"
    echo "  - ユーザー名: $VPS_USER"
    echo "  - IPアドレス: $VPS_IP"
    echo "  - SSH鍵: $SSH_KEY"
    exit 1
fi

echo "✅ SSH接続成功"
echo ""

# 3. ファイルをアップロード
echo "📤 アーカイブファイルをアップロード中..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$ARCHIVE_FILE" "$VPS_USER@$VPS_IP:~/"

if [ $? -ne 0 ]; then
    echo "❌ ファイルアップロードに失敗しました"
    exit 1
fi

echo "✅ ファイルアップロード成功"
echo ""

# 4. VPS上でデプロイを実行
echo "🚀 VPS上でデプロイを実行中..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" << 'REMOTE_SCRIPT'
set -e

REMOTE_PATH="$HOME/kpass-proxy-server"
ARCHIVE_FILE="kpass-proxy-v2.tar.gz"

echo "現在のディレクトリ: $(pwd)"
echo ""

# 既存のサービスを停止（存在する場合）
if command -v pm2 &> /dev/null; then
    echo "PM2でサービスを停止中..."
    pm2 stop kpass-proxy 2>/dev/null || echo "サービスは実行されていません"
    pm2 delete kpass-proxy 2>/dev/null || echo "サービスは存在しません"
fi

# プロキシサーバーディレクトリの作成
mkdir -p "$REMOTE_PATH"
cd "$REMOTE_PATH"

echo "ディレクトリ: $REMOTE_PATH"
echo ""

# 既存のsrcディレクトリをバックアップ
if [ -d "src" ]; then
    echo "既存のコードをバックアップ中..."
    BACKUP_DIR="src.backup.$(date +%Y%m%d_%H%M%S)"
    mv src "$BACKUP_DIR"
    echo "✅ バックアップ完了: $BACKUP_DIR"
fi

# アーカイブを展開
echo "アーカイブを展開中..."
cd "$HOME"
tar -xzf "$ARCHIVE_FILE" -C "$REMOTE_PATH/"

echo "✅ アーカイブ展開完了"
echo ""

# 依存関係のインストール
cd "$REMOTE_PATH"
echo "依存関係をインストール中..."
npm install --production

echo "✅ 依存関係のインストール完了"
echo ""

# 環境変数ファイルの確認
if [ ! -f ".env" ]; then
    echo "⚠️  .envファイルが見つかりません。作成してください。"
else
    echo "✅ .envファイルを確認"
fi

# プロキシサーバーを再起動
if command -v pm2 &> /dev/null; then
    echo "PM2でサービスを起動中..."
    pm2 start src/index.js --name kpass-proxy
    pm2 save
    echo "✅ サービス起動完了"
else
    echo "⚠️  PM2がインストールされていません。手動で起動してください。"
fi

echo ""
echo "=== デプロイ完了 ==="
echo ""

# ヘルスチェック
echo "ヘルスチェックを実行中..."
sleep 3
curl -s http://localhost:3000/api/health || echo "⚠️  ヘルスチェックに失敗しました"

REMOTE_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ デプロイ成功!"
    echo ""
    echo "VPSの状態を確認:"
    echo "  pm2 status"
    echo "  pm2 logs kpass-proxy"
    echo ""
    echo "テスト:"
    echo "  curl http://85.131.245.64:3000/api/health"
else
    echo ""
    echo "❌ デプロイに失敗しました"
    exit 1
fi
