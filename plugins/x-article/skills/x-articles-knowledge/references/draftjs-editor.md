# DraftJS エディタ仕様

X Articles のエディタは DraftJS ベースで構築されており、通常のクリップボード操作や DOM 操作と異なる挙動を示す。

---

## 成功したペーストパターン

### DataTransfer + ClipboardEvent（唯一の安定手法）

```javascript
function pasteHtmlToEditor(html) {
  const editorEl = document.querySelector('[contenteditable="true"]');
  if (!editorEl) throw new Error('エディタが見つかりません');

  // カーソルを末尾に移動
  const range = document.createRange();
  range.selectNodeContents(editorEl);
  range.collapse(false);
  const sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);
  editorEl.focus();

  // DataTransfer でペースト
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  dt.setData('text/plain', '');  // ← 必須: 省略すると一部環境でペースト無視
  const pasteEvent = new ClipboardEvent('paste', {
    bubbles: true,
    cancelable: true,
    clipboardData: dt,
  });
  editorEl.dispatchEvent(pasteEvent);
}
```

**ポイント**: `text/plain: ''` は**必ず設定**すること。省略すると ClipboardEvent が正しく処理されない環境がある。

---

## 失敗したパターン（使用禁止）

| パターン | 失敗理由 |
|----------|---------|
| ❌ `navigator.clipboard.writeText()` | 非同期 API のため DraftJS が onChange イベントを捕捉しない |
| ❌ `upload_image` / `create_file` ツールで HTML 生成 | エディタへの挿入手段がない（DOM への直接 innerHTML 代入はリアクティブ更新を壊す） |
| ❌ Base64 エンコードしたデータ URI | DraftJS は data: URI をセキュリティ上の理由でブロック |

---

## HTML タグ対応状況

| HTML タグ | DraftJS での動作 |
|-----------|----------------|
| `<h1>`, `<h2>`, `<h3>` | ✅ 見出しとして認識 |
| `<p>` | ✅ 段落として認識 |
| `<strong>`, `<em>` | ✅ ボールド・イタリック |
| `<ul>`, `<ol>`, `<li>` | ✅ リスト |
| `<blockquote>` | ✅ 引用 |
| `<a>` | ✅ リンク（href 属性も保持） |
| `<pre>`, `<code>` | ⚠️ エディタ UI では挿入不可（手動操作が必要） |
| `<table>` | ❌ X Articles は表未サポート |
| `<hr>` | ❌ セパレーターは手動挿入必要 |
| `<img>` | ❌ 画像は別途ファイルアップロード UI を使用 |

---

## カーソル位置の罠

### 実際に起きた事故の記録

- **事故 1**: カーソルがタイトル欄に残った状態でペーストしたため、本文がタイトルに混入した
  - 教訓: `range.collapse(false)` でコンテンツ末尾へ移動してから `editorEl.focus()` を呼ぶ
- **事故 2**: 複数セクションをまとめてペーストしたら途中から文字化け
  - 教訓: 3000 文字超のペーストは不安定。セクション単位（`## ` ヘッダーで分割）でペーストする

### カーソル末尾移動コード

```javascript
const range = document.createRange();
range.selectNodeContents(editorEl);
range.collapse(false);  // false = 末尾
const sel = window.getSelection();
sel.removeAllRanges();
sel.addRange(range);
editorEl.focus();
```

---

## 分割ペーストの必要性

3000 文字を超えるコンテンツを一度にペーストすると DraftJS が不安定になる（一部テキストの消失・順序崩れが発生）。

**対策**: マークダウンを `## ` ヘッダーでセクション分割し、セクションごとにペーストする。各ペースト後にスクリーンショットで確認。

---

## ブロック構造確認 JS スニペット

ペースト後の内部状態を確認する場合:

```javascript
// DraftJS の内部ブロック構造をコンソール出力
const editorState = window.__draftEditorState;  // デバッグ時のみ
if (editorState) {
  const blocks = editorState.getCurrentContent().getBlocksAsArray();
  blocks.forEach((b, i) => {
    console.log(i, b.getType(), b.getText().substring(0, 50));
  });
}
```

ブロックが重複している場合（同じテキストが 2 回ペーストされた場合）、JS でブロックを取得して削除する操作が必要になる（`publish` コマンドの自動検出フローで対応）。
