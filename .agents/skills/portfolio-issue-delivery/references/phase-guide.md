# Issue Delivery Phase Guide

## 1. Prepare design

- Read the parent Issue, existing docs, and current repository state.
- Follow the workflow's start/resume checks and create or reuse the Issue branch before tracked changes. Confirm the technology choice and required setup scope; proposals are not approved architecture.
- Create reviewed design, test, and session-log Sub-issues if they do not exist.
- Move the parent Project Status to `設計レビュー` when the Project is configured.
- Write As-Is / To-Be, scope, data CRUD, state changes, settings impact, test plan, and unresolved decisions in the design Sub-issue.
- Run PdM, domain, and developer review passes and record their outcomes.
- Create a local static HTML mock under `tmp/design-mocks/issue-<number>/` when a UI change is involved.
- Stop and wait for the user to close the design Sub-issue.
- Before requesting Close, identify the design revision, mock files, unresolved decisions, and review findings. Follow the workflow's approval validity rules.

## 2. Implement approved design

- Verify that the design Sub-issue is closed by the user.
- Confirm the Close approved the current design revision, not cancellation or an older design. Preserve the approval reference.
- Move the parent Project Status to `実装` when the Project is configured.
- Implement only the approved scope.
- Create or update the authoritative documents in `docs/design/` alongside code:
  - one document for each changed screen or operation;
  - one document for each changed table;
  - affected HTML mocks and both design indexes.
- If a material change is needed, record it in the design and session-log Sub-issues and return to design review before continuing.

## 3. Test

- Move the parent Project Status to `自動テスト` when the Project is configured.
- Derive automated tests from the approved acceptance criteria and design.
- Run requirement traceability, design consistency, code-quality/security, and automated-test passes.
- Record commands, results, failures, and resolutions in the test Sub-issue.
- Map AC IDs to tests and record the tested commit or dirty state and environment. Test visible behavior, boundaries, and relevant regressions; distinguish not-run from pass. UI changes need actual rendered-screen verification in addition to the mock when the runtime is available.
- Do not move to PR preparation while required tests fail.

## 4. PR preparation

- Complete the PR template, including `Closes #<parent issue number>`.
- Present a concise summary of code, docs, mocks, tests, and remaining limitations.
- Honor existing authorization for commit, push, and PR creation; ask only if absent. Inspect intended files and secrets before publishing. Set `PR承認待ち` only after the verified PR exists and required checks pass.
- On PR feedback, record the change, reopen test work when evidence is stale, and rerun affected verification. Material design changes return to human design approval.

## 5. Completion and improvement

- The user reviews and merges the PR.
- Verify that the parent Issue is closed and set Project Status to `完了` when applicable.
- Write a concise completion summary and improvement candidates in the session-log Sub-issue, then close it.
- Create a separate process-improvement Issue only when the user approves it.
- Record the delivered behavior, design tradeoff, verification links, human decisions, and a concise Web-learning takeaway. Leave branch/commit and next-step information for resumption whenever work pauses.
