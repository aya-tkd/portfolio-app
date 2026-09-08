---
name: portfolio-issue-delivery
description: Lead a PortFolio-App Issue through design, implementation, tests, local acceptance preparation, and post-merge feedback. Use for Issue delivery or completion follow-ups when the target Issue is identifiable; preserve human approval gates.
---

# Portfolio Issue Delivery

Use this skill only in the repository containing this skill and for an identified parent Issue. A completion follow-up may identify it through the current conversation and merged PR; ask if ambiguous.

## Read first

Read `AGENTS.md`, `docs/development/issue-workflow.md`, `docs/development/definition-of-done.md`, `docs/security/development-guidelines.md`, `docs/design/INDEX.md`, and all documents relevant to the target Issue.

Use [the phase guide](references/phase-guide.md) for phase-specific deliverables and stopping conditions.

## Lead role

Act as the Lead. Follow the review roles in `docs/development/issue-workflow.md`. Use independent reviewers when available; otherwise disclose role-based self-review. Record evidence, findings, resolutions, and remaining issues rather than only approval votes.

Keep the parent Issue as the unit of delivery. Its required Sub-issues are design, automated test, and session log.

## Human gates

- Verify the user's approval-purpose Close against the current design revision and mock. A closed, cancelled, or superseded Issue alone is not approval. Material changes require reopening and renewed design approval as defined in the workflow.
- The user performs PR acceptance and merge. Do not merge a PR.
- Ask for direction before changes affecting authentication, authorization, secrets, publication, repository settings, external services, or costs.

## GitHub write boundary

Use `docs/development/issue-workflow.md` as the authority for GitHub writes, branch lifecycle, and resuming interrupted work. An instruction to deliver the Issue includes its scoped work records and branch creation. Verify repository identity and reuse existing Sub-issues and PRs. Use authenticated `gh` when available, without exposing credentials; use UTF-8 `--body-file` for multiline bodies and verify writes.

Before opening a PR, complete the change summary and verification results. Honor existing authorization for commit, push, and PR creation without asking again; if absent, ask after preparing the reviewable result. Do not modify unrelated Issues, Project settings, Rulesets, or repository settings. Never approve or merge the PR.

## Local design mocks

During design review, create static HTML mocks only in `tmp/design-mocks/issue-<number>/`. They are for local review and must not use real patient data, APIs, authentication, or external services.

After design approval, preserve the reviewed mock under `docs/design/<area>/mocks/<screen>.html` and update the corresponding screen-operation and table documents in the implementation PR. Follow `docs/design/INDEX.md`; update existing documents rather than creating a new copy per Issue.

## Learning and portfolio

Read `docs/ai/working-agreement.md` and `docs/learning/user-technical-profile.md`. Tie one or two Web concepts to the actual change, explain the request-to-DB-to-screen path with concrete files, and offer an optional prediction or review question. The user delegates implementation; do not require manual coding or exams. Do not infer mastery from an OK or a completed task.

Make the portfolio evidence traceable: user problem, observable behavior, design decision, meaningful test evidence, AI work, and human judgment. Keep README implementation status and local setup accurate when changed. Record only concise technical learning evidence, never private chat context.

## Completion

Before requesting PR creation, complete the Definition of Done, record the automated test evidence in the test Sub-issue, and ensure the session log contains material decisions and changes. After the user merges the PR, record the completion summary and improvement candidates, then close the session log Sub-issue.

On a merge/completion follow-up, automatically perform the bounded Skills/Docs feedback loop in the issue workflow. Do not wait for a separate improvement request, invent changes, broaden permissions, or reuse the merged branch. Report the feedback evidence, changes, validation, and publication status.
