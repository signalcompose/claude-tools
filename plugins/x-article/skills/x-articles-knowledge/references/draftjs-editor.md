# DraftJS エディタ仕様

X Articles のエディタは DraftJS ベースで構築されており、通常のクリップボード操作や DOM 操作と異なる挙動を示す。

---

## javascript_tool での async/await の扱い

`javascript_tool`（Claude in Chrome MCP のコード実行）は**トップレベルの `await` をサポートしない**。

```javascript
// ❌ SyntaxError: await is only valid in async functions
await new Promise(r => setTimeout(r, 100));
document.querySelector('[contenteditable]').dispatchEvent(event);
```

```javascript
// ✅ async IIFE（Immediately Invoked Function Expression）で包む
(async () => {
  await new Promise(r => setTimeout(r, 100));
  document.querySelector('[contenteditable]').dispatchEvent(event);
})();
```

**このドキュメント内のすべてのコードスニペットを `javascript_tool` で実行する場合は、必ず `(async () => { ... })()` で包むこと。**

---

## 成功したペーストパターン

### DataTransfer + ClipboardEvent（唯一の安定手法）

```javascript
// ※ javascript_tool で実行する場合は (async () => { ... })() で包むこと
async function pasteHtmlToEditor(html) {
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

  // DraftJS の DOM 更新を待つ（600ms 以上）
  await new Promise(r => setTimeout(r, 600));
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
| `<hr>` | ⚠️ HTML ペースト不可。ツールバーの「挿入」メニューからブラウザ自動化で挿入可能（下記参照） |
| `<img>` | ❌ 画像は別途ファイルアップロード UI を使用 |

---

## セパレーター（仕切り線）の挿入

HTML の `<hr>` をペーストしても DraftJS は仕切り線として認識しない。ツールバーの「挿入」メニュー経由でブラウザ自動化が可能。

### 挿入手順（ブラウザ自動化）

1. **スクリーンショットを撮ってツールバーを確認**する（UIが変わる可能性があるため毎回確認推奨）
2. ツールバー内の「挿入」または「＋」ボタンを探してクリック
3. 表示されたメニューから「区切り線」「Divider」「Separator」等をクリック

```javascript
// 汎用的なツールバーボタン探索パターン
// ※ X Articles の UI 変更に追従するため、テキスト検索を使う
(async () => {
  // ツールバー内のボタンをすべて列挙してデバッグ確認
  const buttons = Array.from(document.querySelectorAll('[role="button"], button'));
  const insertBtn = buttons.find(b =>
    b.textContent.trim().match(/^(Insert|挿入|\+)$/) ||
    b.getAttribute('aria-label')?.match(/insert|separator|divider/i)
  );
  if (!insertBtn) {
    console.log('利用可能なボタン:', buttons.map(b => b.textContent.trim() || b.getAttribute('aria-label')));
    throw new Error('「挿入」ボタンが見つかりません。スクリーンショットで UI を確認してください');
  }
  insertBtn.click();
  await new Promise(r => setTimeout(r, 500));

  // メニューからセパレーターを探す
  const menuItems = Array.from(document.querySelectorAll('[role="menuitem"], [role="option"]'));
  const separatorItem = menuItems.find(item =>
    item.textContent.match(/separator|divider|区切り/i)
  );
  if (!separatorItem) throw new Error('セパレーターメニュー項目が見つかりません');
  separatorItem.click();
  await new Promise(r => setTimeout(r, 300));
})();
```

**ポイント**: テキストマッチで要素を探すことで、X Articles の DOM 構造変更に対してある程度耐性を持たせている。セレクターが合わない場合はスクリーンショットを撮ってボタンの実際の aria-label やテキストを確認すること。

**フォールバック**: 自動化が難しい場合は `[ここに仕切りを手動挿入]` フラグをドラフトに残し、ユーザーに手動挿入を依頼する。

---

## ペースト分割戦略

長文記事では適切な単位でペーストを分割しないと DraftJS が不安定になる。

### 推奨分割方針

| 条件 | 方針 |
|------|------|
| 1セクション ≤ 3000文字 | セクション単位でそのままペースト |
| 1セクション > 3000文字 | セクション内を段落グループ（500〜1000文字）で分割 |
| 連続セクション合計 ≤ 3000文字 | Section 2 以降をまとめて1回でペーストしてもOK |
| 連続セクション合計 > 3000文字 | 2〜3セクションずつに分割してペースト |

### 分割時の注意

- **各ペーストの間に 600ms 以上の待機**を入れること（DraftJS の DOM 更新待ち）
- 分割ペーストでも Section 2 以降のルール（`\u200B` プレフィックス）は**変わらず必要**
- 1ペーストあたりの目安: **2〜3セクション** または **3000文字以内**

### 長文記事（10セクション以上）のベストプラクティス

1. 事前にセクションをリストアップして文字数を計算する
2. グループ分けを決めてから連続ペーストを開始する
3. 各グループのペースト後にスクリーンショットで確認してから次へ進む

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

## h2 ブロック認識の制約と回避策

### 問題

ペースト時に HTML の**最初のブロック要素**は、カーソルのある既存段落に追記される（ブロック境界が無視される）。これにより `<h2>テストセクション</h2>` を独立してペーストすると直前の段落と結合してしまう。

### 確認済みの回避策（ゼロ幅スペース方式）

Section 1 は単独でペーストし、Section 2 以降はゼロ幅スペース `\u200B` のダミー先頭ブロックを使って**まとめて1回でペースト**する:

```javascript
// ※ javascript_tool で実行する場合は (async () => { ... })() で包むこと
// Section 1（最初）: 通常ペースト
await pasteHtmlToEditor('<h2>For English Readers</h2><p>This article...</p><p>TL;DR...</p>');

// Section 2 以降: \u200B のダミー先頭ブロック + 残り全セクション1回でペースト
await pasteHtmlToEditor('<p>\u200B</p><h2>テストセクション</h2><p>これは...</p><h2>まとめ</h2><p>パブリッシュ...</p>');
```

**動作原理**:
- `<p>\u200B</p>` の `\u200B`（ゼロ幅スペース）が直前段落に追記されるが不可視なので視覚的影響なし
- `<h2>テストセクション</h2>` は2番目以降の要素なので正しく新規ブロックとして認識
- 以降のすべての h2・段落も同様に正しく認識される

### 3000文字超への対応

3000 文字を超える場合はセクションを分割する。その際も各ペーストには `<p>\u200B</p>` プレフィックスが必要（Section 1 を除く）。

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
