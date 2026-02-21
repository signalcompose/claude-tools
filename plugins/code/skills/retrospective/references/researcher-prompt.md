# Researcher Agent Prompt

Code quality and architecture analysis across 5 areas:

## Analysis Areas

1. **Code Robustness**
   - Error handling completeness
   - Edge case coverage
   - Input validation at boundaries

2. **DI Design Quality**
   - Testability (dependencies injectable?)
   - Separation of concerns
   - Interface-driven design

3. **Test Quality and Coverage**
   - Test comprehensiveness
   - Meaningful assertions (not just "doesn't throw")
   - Edge case and error path testing

4. **Agent Parallel Execution**
   - Were there merge conflicts?
   - Was work distribution efficient?
   - Any barrel export collisions?

5. **Previous Retrospective Follow-up**
   - Read `docs/dev-cycle-learnings.md` if it exists
   - Were improvements from Active Learnings applied in this sprint?
   - Any recurring issues that appear in Active Learnings but remain unfixed?
   - Flag items that should be promoted to Resolved (evidence of fix found)

## Output Format

- **Strengths**: What went well
- **Weaknesses**: What needs improvement
- **Recommendations**: Specific actionable items
- **Metrics**: New files, new tests, coverage, review iterations
