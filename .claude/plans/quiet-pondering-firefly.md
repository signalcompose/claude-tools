# CVI Sandbox Auto-Detection Implementation Plan

## Context

### Problem
CVIプラグインのStop hook (`check-speak-called.sh`) は、sandboxが有効な時に `/cvi:speak` が呼ばれたかをチェックしてブロックします。しかし、sandboxが有効な場合、`/cvi:speak`コマンド自体がAudioQueueStart失敗エラー (`-66680`) で動作しないため、ユーザーは常にStop hookでブロックされます。

### Current Behavior
1. Sandbox有効 → `/cvi:speak`がエラーで失敗
2. Stop hook → `/cvi:speak`が呼ばれていないとブロック
3. 結果: ユーザーがStopできない、エラーが繰り返される

### Desired Behavior
1. Sandbox有効 → Stop hookがsandbox状態を自動検出
2. Sandbox有効時 → CVIチェックをスキップ（ブロックしない）
3. Sandbox無効時 → 従来通りCVIチェックを実行

### User Requirements
- **設定不要**: `SANDBOX_SKIP=on`のような手動設定は不要
- **自動検出**: sandbox状態を自動的に検出してスキップ
- **デフォルト動作**: sandboxが有効な場合は自動的にCVIをスキップ

## Investigation Results

### Sandbox State Detection Method

**Settings File Locations**:
1. `~/.claude/settings.json` - グローバル設定
2. `~/.claude/settings.local.json` - ローカル上書き（優先）

**Sandbox Configuration Format**:
```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

**Priority**: `settings.local.json` > `settings.json`

**Current User State**:
- `settings.json`: `"sandbox.enabled": true`
- `settings.local.json`: `"sandbox.enabled": false` (優先、現在無効)

### Existing Pattern in CVI Scripts

`check-speak-called.sh` の現在の実装パターン:
```bash
# Dependency check with graceful degradation
if ! command -v jq &> /dev/null; then
    exit 0  # Allow stop if jq not available
fi

# Read config with jq
if ! jq -e '.CVI_ENABLED' "$CONFIG_FILE" > /dev/null 2>&1; then
    exit 0  # Allow stop if config invalid
fi
```

このパターンを拡張してsandbox検出を追加します。

## Implementation Plan

### File to Modify

**Primary File**:
- `plugins/cvi/scripts/check-speak-called.sh`

**No Changes Required**:
- `~/.cvi/config` (設定ファイル不要)
- `plugins/cvi/hooks/hooks.json` (hook定義変更不要)

### Implementation Steps

#### Step 1: Add Sandbox Detection Function

`check-speak-called.sh` の冒頭に sandbox 検出関数を追加:

```bash
# Function: Detect if sandbox is enabled
# Returns: 0 if sandbox enabled, 1 if disabled or unknown
is_sandbox_enabled() {
    local SETTINGS_LOCAL="$HOME/.claude/settings.local.json"
    local SETTINGS_GLOBAL="$HOME/.claude/settings.json"

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        return 1  # Cannot detect, assume disabled
    fi

    # Priority 1: Check settings.local.json
    if [ -f "$SETTINGS_LOCAL" ]; then
        local sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$SETTINGS_LOCAL" 2>/dev/null)
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        elif [ "$sandbox_enabled" = "false" ]; then
            return 1  # Sandbox explicitly disabled
        fi
    fi

    # Priority 2: Check settings.json
    if [ -f "$SETTINGS_GLOBAL" ]; then
        local sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$SETTINGS_GLOBAL" 2>/dev/null)
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        fi
    fi

    # Default: Assume disabled if not specified
    return 1
}
```

#### Step 2: Add Early Exit on Sandbox Detection

既存のdependencyチェックの後、CVIチェック前に追加:

```bash
# Check if jq is available (existing code)
if ! command -v jq &> /dev/null; then
    exit 0
fi

# NEW: Skip CVI check if sandbox is enabled
if is_sandbox_enabled; then
    # Sandbox is enabled, skip /cvi:speak check
    # Allow stop without blocking
    exit 0
fi

# Existing CVI check logic continues...
```

#### Step 3: Add Debug Logging (Optional)

デバッグ用に sandbox 検出結果をログに記録（既存のログ関数があれば）:

```bash
if is_sandbox_enabled; then
    log_debug "Sandbox enabled, skipping CVI check"
    exit 0
fi
```

### Logic Flow

```
1. Hook実行開始
   ↓
2. jq コマンド存在チェック
   ↓ (なし)
   exit 0 (graceful degradation)
   ↓ (あり)
3. Sandbox状態検出
   ├─ settings.local.json 読み込み
   │  ├─ "enabled": true → exit 0 (スキップ)
   │  └─ "enabled": false → 次へ
   └─ settings.json 読み込み
      ├─ "enabled": true → exit 0 (スキップ)
      └─ "enabled": false / 未設定 → 次へ
   ↓
4. 既存のCVIチェックロジック実行
   ├─ /cvi:speak 呼ばれた → exit 0
   └─ /cvi:speak 未実行 → exit 2 (ブロック)
```

### Error Handling

1. **jq 不在**: graceful degradation（exit 0）
2. **設定ファイル不在**: sandbox無効とみなす（既存チェック実行）
3. **JSON パースエラー**: sandbox無効とみなす（`jq -r ... 2>/dev/null`）
4. **不明な値**: sandbox無効とみなす（デフォルト動作）

### Backward Compatibility

- ✅ 既存の動作を変更しない（sandbox無効時は従来通り）
- ✅ 設定ファイルがない環境でも動作（graceful degradation）
- ✅ jqがない環境でも動作（既存のチェックと同じ）

## Critical Files

| File Path | Purpose | Modification |
|-----------|---------|--------------|
| `plugins/cvi/scripts/check-speak-called.sh` | Stop hook implementation | Add sandbox detection + early exit |

## Verification Plan

### Test Case 1: Sandbox Enabled
```bash
# 1. Enable sandbox
echo '{"sandbox":{"enabled":true}}' > ~/.claude/settings.local.json

# 2. Trigger Stop hook without calling /cvi:speak
# Expected: Hook should exit with 0 (no blocking)

# 3. Verify log
# Expected: "Sandbox enabled, skipping CVI check"
```

### Test Case 2: Sandbox Disabled
```bash
# 1. Disable sandbox
echo '{"sandbox":{"enabled":false}}' > ~/.claude/settings.local.json

# 2. Trigger Stop hook without calling /cvi:speak
# Expected: Hook should exit with 2 (blocking)

# 3. Verify error message
# Expected: "CVI check failed: /cvi:speak not called"
```

### Test Case 3: Settings File Missing
```bash
# 1. Remove settings files
rm -f ~/.claude/settings.local.json

# 2. Trigger Stop hook without calling /cvi:speak
# Expected: Hook should use settings.json
# If settings.json has "enabled":true → skip
# If settings.json has "enabled":false → check
```

### Test Case 4: jq Not Available
```bash
# 1. Temporarily rename jq
sudo mv /usr/local/bin/jq /usr/local/bin/jq.bak

# 2. Trigger Stop hook
# Expected: Exit 0 (graceful degradation, existing behavior)

# 3. Restore jq
sudo mv /usr/local/bin/jq.bak /usr/local/bin/jq
```

### Integration Test
```bash
# Real-world scenario:
# 1. Enable sandbox: /sandbox
# 2. Complete a task without calling /cvi:speak
# 3. Verify: Stop request succeeds (no blocking)
# 4. Disable sandbox: /sandbox
# 5. Complete a task without calling /cvi:speak
# 6. Verify: Stop request fails (blocking with error message)
```

## Risk Assessment

**Low Risk**:
- 修正箇所が限定的（1ファイル、~20行追加）
- 既存ロジックを破壊しない（early exitパターン）
- エラーハンドリングが堅牢（graceful degradation）
- backward compatible（設定ファイルがなくても動作）

**Mitigation**:
- sandbox検出失敗時は既存チェックを実行（安全側に倒す）
- jq不在時は既存の動作（exit 0）を維持

## Future Enhancements

### Phase 2: User Notification
Sandbox有効時に、CVIが利用できない理由をユーザーに通知:
```bash
if is_sandbox_enabled; then
    echo "ℹ️  CVI is disabled in sandbox mode" >&2
    exit 0
fi
```

### Phase 3: MCP Server Migration
根本的な解決策として、CVIをMCPサーバに移行（既存プラン `giggly-painting-sedgewick.md` 参照）:
- MCPサーバは別プロセスで動作 → sandbox制限を受けない
- `/cvi:speak`コマンドも正常に動作するようになる

## Summary

Sandbox自動検出により、ユーザーは手動設定なしでCVIのエラーを回避できます。実装は既存パターンを踏襲し、堅牢なエラーハンドリングとbackward compatibilityを保証します。
