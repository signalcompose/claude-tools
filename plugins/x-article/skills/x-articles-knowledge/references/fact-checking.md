# ファクトチェックガイド

記事公開前に外部 URL とコマンド名を検証するための手順。

---

## URL 確認方法

```bash
# 基本的な確認（タイムアウト 5 秒）
curl -sI --max-time 5 "https://example.com/article" | head -5

# 出力例（正常）
HTTP/2 200
content-type: text/html
...

# 出力例（リダイレクト）
HTTP/1.1 301 Moved Permanently
location: https://new-location.example.com/

# 出力例（404）
HTTP/1.1 404 Not Found
```

**注意**: 複数 URL を連続確認する場合は 1 秒間隔を空けること（レート制限回避）。

```bash
# 複数 URL のバッチ確認
for url in \
  "https://url1.example.com" \
  "https://url2.example.com"; do
  echo "--- $url ---"
  curl -sI --max-time 5 "$url" | head -2
  sleep 1
done
```

**Sandbox 注意**: `curl` コマンドは sandbox 環境でブロックされる場合がある。
`dangerouslyDisableSandbox: true` で実行すること。

---

## マーケットプレイス名・コマンド名の正確性チェック

### 確認が必要な項目

1. **Claude Code コマンド名**: `/plugin install`, `/plugin update` 等
2. **プラグイン名**: `x-article`, `cvi`, `ypm` 等（ハイフン区切り）
3. **X (Twitter) 関連の正式名称**: 「X Articles」（旧称「Twitter Spaces」は別機能）
4. **技術用語**: DraftJS, DataTransfer, ClipboardEvent 等（キャピタライゼーションに注意）

### 実際の失敗例

| 誤った表記 | 正しい表記 | 注記 |
|-----------|----------|------|
| `@claude-plugin-directory` | `@claude-plugins-official` | X のアカウント名を誤記 |
| `/plugins install` | `/plugin install` | コマンド名の単複ミス |
| `Twitter Article` | `X Article` / `X Articles` | リブランディング後の名称 |
| `DraftJs` | `DraftJS` | 大文字小文字 |

---

## レビュー結果の報告形式

```
## ファクトチェック結果

### Critical（修正必須）
- [URL] https://xxx.example.com → ❌ 404 Not Found
  修正案: 最新の URL に差し替えが必要

### Important（修正推奨）
- コマンド名 `/plugins install` → `/plugin install` に修正が必要

### Minor（任意）
- 「Twitter Article」→「X Article」への表記統一を推奨
```

---

## チェックリスト

- [ ] 記事内のすべての外部 URL が有効（200 or 301/302）か
- [ ] Claude Code コマンド名が正確か（単複・スペルを確認）
- [ ] プラグイン名が公式名称と一致しているか
- [ ] 固有名詞のキャピタライゼーションが正しいか
- [ ] 「Twitter」→「X」のリブランディングに対応した名称か
