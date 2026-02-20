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
   - Were improvements from last retrospective applied?
   - Any recurring issues?

## Output Format

- **Strengths**: What went well
- **Weaknesses**: What needs improvement
- **Recommendations**: Specific actionable items
- **Metrics**: New files, new tests, coverage, review iterations
