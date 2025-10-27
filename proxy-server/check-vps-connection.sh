#!/bin/bash

echo "=== VPS接続確認 ==="
echo ""

VPS_IP="85.131.245.64"
SSH_KEY="$HOME/.ssh/kpass-vps.pem"

# ポート22の接続確認
echo "ポート22の接続確認中..."
timeout 3 nc -zv $VPS_IP 22 2>&1 || echo "ポート22: 接続できません"

# ポート3000の接続確認
echo ""
echo "ポート3000の接続確認中..."
curl -s --connect-timeout 3 http://$VPS_IP:3000/api/health || echo "ポート3000: 接続できません"

# SSH接続試行（複数のユーザー名で）
echo ""
echo "SSH接続を試行中..."
for USER in ubuntu root admin kpass; do
    echo "ユーザー: $USER"
    ssh -i "$SSH_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$USER@$VPS_IP" "whoami" 2>&1 | head -1
done

echo ""
echo "=== 確認完了 ==="
