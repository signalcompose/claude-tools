# Agent Prompt Template

Always include the following constraints in every Team Agent prompt:

```
- ESM project ("type": "module") — .js extensions required in imports
- TypeScript strict mode
- Vitest for testing — MUST import { describe, it, expect } from 'vitest'
  (match existing test files' import pattern, do NOT rely on globals)
- TDD two-stage workflow:
  1. Write test file FIRST, run tests to confirm they fail (Red)
  2. Write implementation to make tests pass (Green)
  3. Verify with: npx vitest run <test-file>
- no-console rule (console.warn/error OK)
- @typescript-eslint/no-unused-vars with _ prefix exception
- Update barrel exports in index.ts
- Run tests after implementation: npx vitest run <test-file>
- For time-dependent tests: use long timeouts + manual state manipulation
  for deterministic results (avoid race conditions with tiny timeouts)
```
