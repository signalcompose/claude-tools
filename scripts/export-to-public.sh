#!/bin/bash
set -e

PRIVATE_REPO="/Users/yamato/Src/proj_YPM/YPM-yamato"
PUBLIC_REPO_URL="https://github.com/signalcompose/YPM.git"
EXPORT_DIR="/tmp/ypm-public-export-$(date +%s)"

echo "🔍 Exporting YPM to public repository..."
echo "Private repo: $PRIVATE_REPO"
echo "Public repo: $PUBLIC_REPO_URL"
echo "Export dir: $EXPORT_DIR"

# Step 1: Fresh cloneを作成
echo "📦 Cloning private repository..."
git clone "$PRIVATE_REPO" "$EXPORT_DIR"
cd "$EXPORT_DIR"

# Step 2: Developブランチをcheckout
git checkout develop

# Step 3: 機密ファイルを履歴から削除
echo "🧹 Filtering sensitive files from history..."
git filter-repo \
  --path PROJECT_STATUS.md --invert-paths \
  --path config.yml --invert-paths \
  --path CLAUDE.md --invert-paths \
  --force

# Step 4: コミットメッセージから機密情報を削除
echo "✏️  Sanitizing commit messages..."
git filter-repo --message-callback '
import re

# プロジェクト名を[project]に置換
projects = [b"oshireq", b"orbitscore", b"picopr", b"TabClear", b"DUNGIA", b"godot-mcp", b"YPM-yamato"]
for proj in projects:
    message = message.replace(proj, b"[project]")

# プロジェクト数を[N]に置換
message = re.sub(rb"\d+プロジェクト", rb"[N]プロジェクト", message)
message = re.sub(rb"\d+ projects", rb"[N] projects", message)

# 時刻情報を削除
message = re.sub(rb"\d+分前", rb"[時間]前", message)
message = re.sub(rb"\d+日前", rb"[日数]前", message)

return message
' --force

# Step 5: Public repoにpush
echo "🚀 Pushing to public repository..."
git remote add public "$PUBLIC_REPO_URL"
git push public develop:main --force

echo ""
echo "✅ Export completed successfully!"
echo "⚠️  Please verify the public repository manually:"
echo "    https://github.com/signalcompose/YPM"
echo ""
echo "Next steps:"
echo "1. Check commit history: cd $EXPORT_DIR && git log --oneline"
echo "2. Verify no sensitive information: git show"
echo "3. Clean up: rm -rf $EXPORT_DIR"
