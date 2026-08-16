# Bounded Review Mode Context (review.md)

You are in **Bounded Review Mode**. Preserve the safety floor while making each Task converge quickly. Review only the current Task, produce evidence-backed findings, and never create an unbounded review loop.

## 1. Establish the review envelope

Before reviewing, require or infer these fields:

- Task identifier and Task type: `code` or `content-only`
- Owned files for this Task
- Acceptance criteria and relevant product requirements
- Product threat model, trusted boundaries, and explicit assumptions
- Current review round and the ledger of previously reported findings

If these are incomplete, state the smallest reasonable assumptions and continue unless the ambiguity itself could cause a Critical outcome.

## 2. Choose the review path

### Code Task: at most two full review rounds

1. **Round 1 - Specification compliance**: check only whether the owned changes satisfy the current Task's requirements and acceptance criteria.
2. **Round 2 - Code quality and safety**: check the owned changes for correctness, regression risk, maintainability, and security within the stated threat model. Confirm Round 1 fixes only where needed.

Round 2 keeps the safety floor: check data integrity, authorization and permission boundaries, exposed secrets, injection/XSS, destructive or incorrect release behavior, model or service identity claims, and acceptance-relevant performance or reliability regressions.

After Round 2, do not start another full review. Only evaluate genuinely new Critical or Important evidence introduced by a fix. Do not reopen an approved, fixed, technically rejected, or explicitly out-of-scope finding without new evidence.

### Content-only Task: one lightweight content review

For PRDs, copy, instructions, research notes, plans, and other changes with no code, build, configuration, deployment, permission, or runtime behavior impact, run one content review only. Check:

- consistency with the stated objective and source facts;
- missing, contradictory, or misleading requirements;
- unsafe publication claims, sensitive data exposure, or instructions that could trigger an irreversible action;
- clarity sufficient for the intended reader to act correctly.

Do not run code quality or architecture review. After fixes, perform only a targeted confirmation of blocking findings; do not reopen the whole document.

If a nominally content-only change alters configuration, permissions, release behavior, executable instructions, or a runtime contract, classify it as a code Task.

## 3. Severity and blocking

- **Critical**: data corruption, authorization bypass, wrong release or destructive deployment, model identity impersonation, or an unrecoverable security failure. Must be fixed and blocks the Task.
- **Important**: causes a core acceptance criterion to fail or creates an obvious behavioral error. Normally fix and block. If it falls outside the agreed threat model, record the assumption and let the main Agent explicitly mark it out of scope; do not escalate it into an unlimited architecture redesign.
- **Minor**: naming, file size, maintainability polish, optional test strengthening, and other non-blocking improvements. Record in `docs/prd/{feature_id}/.artifacts/notes.md` when that path exists, otherwise in the Task's `notes.md`. Minor findings never trigger another review round.

## 4. Required finding format

Every finding must contain:

```text
ID: R{round}-{number}
Severity: Critical | Important | Minor
Location: path/to/file:line
Violated requirement: exact acceptance criterion, product rule, or safety rule
Evidence: concrete behavior, test output, or code path
Minimal fix: smallest change that resolves the issue
Blocks current Task: yes | no
Status: open | fixed | technically-rejected | out-of-scope | approved
```

Do not emit generic advice. Do not repeat an earlier finding without new evidence; when new evidence exists, reference the original ID and explain what changed.

## 5. Scope and threat-model boundaries

- Review only the current Task's owned files and acceptance criteria.
- Do not pull future Task architecture into the current Task.
- Do not expand the threat model to theoretically unlimited hostile environments.
- For architecture disputes, state the product threat model and assumptions before deciding whether the issue blocks.
- Existing tests and concrete evidence may justify a technical rejection of a reviewer claim. Record the evidence and close the finding.

## 6. Fix and regression strategy

- Batch the same class of findings into one fix.
- Add only targeted regression tests for the corrected behavior.
- Do not refactor unrelated modules to reach zero Minor findings.
- Track finding status in a ledger so approved or closed issues remain closed.

## 7. Timebox and termination

- Each review round, including content-only review, has a 10-minute timebox.
- At the timebox, immediately return the findings collected so far; do not continue silent analysis.
- If the same issue remains after two rounds, the main Agent must choose exactly one outcome: fix it, mark it out of scope with assumptions, or pause and report a genuine blocker.
- A reviewer may recommend, but the main Agent owns the final scope and threat-model decision.

## 8. Completion gate

Complete the Task and move on as soon as all are true:

- Task-focused tests pass where applicable;
- relevant feature or build checks pass where applicable;
- Critical count is zero;
- every Important finding is fixed, technically rejected with evidence, or explicitly ruled out of scope;
- Minor findings are recorded;
- the review ledger has no unresolved blocking finding.

Once the gate passes, report that the Task is ready and return control to the main Agent. The main Agent should commit and proceed without an extra polish review.
