# ブラウザ自動化ガイド

`publish` コマンドで X Articles を自動投稿するためのブラウザ操作パターン。

---

## エディタ要素の特定

```javascript
// メインエディタ要素の取得
const editorEl = document.querySelector('[contenteditable="true"]');
// ※ タイトル入力欄も contenteditable なので、位置で区別する場合:
const editors = document.querySelectorAll('[contenteditable="true"]');
const bodyEditor = editors[editors.length - 1];  // 通常、本文が最後
```

---

## カーソル末尾移動コード

```javascript
function moveCursorToEnd(el) {
  const range = document.createRange();
  range.selectNodeContents(el);
  range.collapse(false);  // false = 末尾に collapse
  const sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);
  el.focus();
}
```

---

## DataTransfer + ClipboardEvent フルコード

```javascript
async function pasteToEditor(html, editorEl) {
  // 1. カーソルを末尾に移動
  moveCursorToEnd(editorEl);

  // 2. 少し待つ（DraftJS の状態更新を待つ）
  await new Promise(r => setTimeout(r, 100));

  // 3. DataTransfer でペースト
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  dt.setData('text/plain', '');  // ← 必須: 省略すると一部環境でペースト無視
  const event = new ClipboardEvent('paste', {
    bubbles: true,
    cancelable: true,
    clipboardData: dt,
  });
  editorEl.dispatchEvent(event);

  // 4. ペースト後の安定待機（DraftJS の DOM 更新を待つ。分割ペースト時は 600ms 以上推奨）
  await new Promise(r => setTimeout(r, 600));
}
```

---

## ペースト後のスクリーンショット確認フロー

各セクションのペースト後に必ず実施:

1. **スクリーンショット取得** (`take_screenshot` または `browser_screenshot`)
2. **内容確認**: 正しく挿入されたか目視確認
3. **重複検出**: 同じ内容が 2 回表示されていないか確認
4. **重複あり場合**: 以下の JS で最後のブロックを削除

```javascript
// 重複ブロックの削除（DraftJS）
// ※ MCP のコード実行で動かす場合
const editorEl = document.querySelector('[contenteditable="true"]');
const children = Array.from(editorEl.children);
// 最後の子要素（重複分）を削除
if (children.length > 0) {
  children[children.length - 1].remove();
}
```

---

## MCP 接続失敗時のリトライ手順

Claude in Chrome MCP は初回接続時に「No Chrome extension connected」エラーが発生することがある。

### リトライ手順（3段階）

**Stage 1: 単純リトライ（まずこれ）**
```
# 拡張の初期化タイミング問題の場合は単純リトライで解決することが多い
1. `tabs_context_mcp` を再度実行する
2. 成功したら次のステップへ
```

**Stage 2: 新規タブグループで再接続**
```
# セッションをまたいでタブグループが不整合の場合
1. `tabs_context_mcp` の `createIfEmpty: true` オプションで新規タブグループを作成
2. 新しいタブグループIDで `tabs_context_mcp` を再実行
```

**Stage 3: switch_browser → ユーザー案内（最終手段）**
```
# Stage 1・2 で解決しない場合
1. `switch_browser` を呼んでブラウザを切り替える
2. ユーザーに Chrome 拡張の「Connect」ボタンを押してもらうよう案内する
3. `tabs_context_mcp` を再実行する
4. それでも失敗する場合は「MCP 全滅時の手動案内」セクションへ
```

**新規セッションのベストプラクティス**: 新しいセッションを開始するときは常に `tabs_context_mcp(createIfEmpty: true)` で新規タブグループを作成すること。前セッションのタブグループが残存していると接続の不整合が起きやすい。

---

## タブ管理の注意点

Claude in Chrome MCP を使用する場合、複数タブが開いていると意図しないタブで操作が実行される可能性がある。

```
# タブ確認手順（Claude in Chrome MCP）
1. mcp__Claude_in_Chrome__get_tabs でタブ一覧を取得
2. X Articles のタブ ID を確認
3. mcp__Claude_in_Chrome__switch_tab でそのタブを選択してから操作
```

---

## Claude in Chrome MCP の利用確認

```
# MCP ツールが利用可能か確認する擬似コード
if 'mcp__Claude_in_Chrome__' で始まるツールが存在:
  → Claude in Chrome MCP を使用（優先）
elif 'mcp__playwright__' で始まるツールが存在:
  → Playwright MCP を使用（フォールバック）
else:
  → 手動案内 + JS スニペット出力
```

### Claude in Chrome を優先する理由

- ユーザーの実ブラウザを使うため、X に**既にログイン済み**
- Chrome 拡張（1Password 等）が有効 → ユーザーが必要に応じてログイン支援しやすい
- Playwright は別プロセスで新ブラウザを起動するため拡張が無効

---

## Playwright フォールバック時の注意

Playwright で X にログインが必要な場合、Chrome の既存プロファイルを引き継ぐ方法:

```bash
# ユーザーの Chrome プロファイルを指定（macOS の例）
# ※ Chrome を事前に完全終了させる必要あり
playwright open \
  --browser chromium \
  --save-storage=auth.json \
  "https://x.com/login"
```

ただし、1Password 等の拡張機能が Playwright では動作しない点をユーザーに明示すること。

---

## MCP 全滅時の手動案内

両 MCP が利用できない場合、以下の JS スニペットを出力してユーザーに手動実行を依頼:

```javascript
// X Articles エディタで F12 → Console に貼り付けて実行
// 1. エディタ要素の確認
const el = document.querySelector('[contenteditable="true"]');
console.log('エディタ:', el ? '見つかりました' : '見つかりません');

// 2. ペースト実行（html 変数を実際のHTMLに置換）
const html = `<p>ここに貼り付けたい HTML を記述</p>`;
const dt = new DataTransfer();
dt.setData('text/html', html);
dt.setData('text/plain', '');
el.dispatchEvent(new ClipboardEvent('paste', { bubbles: true, cancelable: true, clipboardData: dt }));
```

### Claude in Chrome MCP のセットアップ案内

Claude in Chrome MCP をインストールするには:
1. Chrome ウェブストアで「Claude in Chrome」を検索してインストール
2. Claude Code の MCP 設定で `claude-in-chrome` サーバーを追加
3. Claude Code を再起動して MCP 接続を確認
