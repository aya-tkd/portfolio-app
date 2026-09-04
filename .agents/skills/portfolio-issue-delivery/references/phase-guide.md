# Issue Delivery Phase Guide

## 1. Prepare design

- Read the parent Issue, existing docs, and current repository state.
- Create reviewed design, test, and session-log Sub-issues if they do not exist.
- Move the parent Project Status to `設計レビュー` when the Project is configured.
- Write As-Is / To-Be, scope, data CRUD, state changes, settings impact, test plan, and unresolved decisions in the design Sub-issue.
- Run PdM, domain, and developer review passes and record their outcomes.
- Create a local static HTML mock under `tmp/design-mocks/issue-<number>/` when a UI change is involved.
- Stop and wait for the user to close the design Sub-issue.

## 2. Implement approved design

- Verify that the design Sub-issue is closed by the user.
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
- Do not move to PR preparation while required tests fail.

## 4. PR preparation

- Move the parent Project Status to `PR承認待ち` when the Project is configured.
- Complete the PR template, including `Closes #<parent issue number>`.
- Present a concise summary of code, docs, mocks, tests, and remaining limitations.
- Wait for the user's explicit authorization before opening a PR.

## 5. Completion and improvement

- The user reviews and merges the PR.
- Verify that the parent Issue is closed and set Project Status to `完了` when applicable.
- Write a concise completion summary and improvement candidates in the session-log Sub-issue, then close it.
- Create a separate process-improvement Issue only when the user approves it.
