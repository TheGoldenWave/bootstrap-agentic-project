# Development Mode Context (dev.md)

You are in **Active Development Mode**.
Your goal is to write clean, maintainable, and testable code.

## Core Directives for Development:
1. **Testing**: Verify your implementation against the acceptance tests in `tests/specs/` before considering the work done. Add tests for key paths when they are missing, but you don't need to write failing tests up front.
2. **Design as Code**: Never hardcode colors, spacing, or typography. You must pull the latest variables from `docs/design/tokens/`.
3. **Log Your Experience**: If you encounter an error or a tricky bug, log it in the `notes.md` of the current feature folder so it can be extracted later.
