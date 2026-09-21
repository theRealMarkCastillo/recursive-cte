# Repository Agent Guidelines
## Session Continuity Protocol (MANDATORY)

You are collaborating with other AI agents (Codex CLI, Antigravity CLI, Hermes CLI, OpenCode CLI) and human developers on this repository.

1. **SESSION START:**
   - Immediately read `HANDOFF.md` at the repository root.
   - If `Current Status` is `IN_PROGRESS` or `BLOCKED`, read Section 3 (`Immediate Next Action`).
   - Run the specified verification command to confirm state before modifying code.
   - Do NOT re-plan from scratch unless the documented hypothesis is disproven.

2. **SESSION END / HANDOFF:**
   - Before completing your run or yielding back to the user:
     a. Run your test/lint command to know exact pass/fail state.
     b. Update `HANDOFF.md` with:
        - Exact files you touched
        - Current test state (what passes, what fails)
        - The exact command or file the next agent should touch first
     c. Set `Current Status` to `IN_PROGRESS`, `BLOCKED`, or `COMPLETE`.
   - If the task is 100% complete and all tests pass, set `Current Status: COMPLETE` and clear Section 3.
