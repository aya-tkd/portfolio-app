---
name: portfolio-issue-delivery
description: Lead a specified PortFolio-App GitHub Issue through design, implementation, automated testing, documentation, and PR preparation while enforcing the project's human approval gates. Use when the user asks to work through an Issue number.
---

# Portfolio Issue Delivery

Use this skill only in the repository containing this skill and for a specified parent Issue number.

## Read first

Read `AGENTS.md`, `docs/development/issue-workflow.md`, `docs/development/definition-of-done.md`, `docs/security/development-guidelines.md`, `docs/design/INDEX.md`, and all documents relevant to the target Issue.

Use [the phase guide](references/phase-guide.md) for phase-specific deliverables and stopping conditions.

## Lead role

Act as the Lead. Run PdM, domain, developer, and test review passes in sequence; they are review perspectives, not a claim that autonomous persistent agents are available. Record concise outcomes in the appropriate Sub-issue.

Keep the parent Issue as the unit of delivery. Its required Sub-issues are design, automated test, and session log.

## Human gates

- The user closes the design Sub-issue to approve the design. Do not begin implementation until it is closed.
- The user performs PR acceptance and merge. Do not merge a PR.
- Ask for direction before changes affecting authentication, authorization, secrets, publication, repository settings, external services, or costs.

## GitHub write boundary

The user's instruction to work on a specified Issue authorizes ordinary work records for that Issue: creating its reviewed Sub-issues, adding concise progress comments, and updating the parent Issue links. Use authenticated `gh` when available, without exposing credentials.

Before opening a PR, present the change summary and verification results. Open the PR only after the user requests or approves that operation. Do not modify unrelated Issues, Project settings, Rulesets, or repository settings.

## Local design mocks

During design review, create static HTML mocks only in `tmp/design-mocks/issue-<number>/`. They are for local review and must not use real patient data, APIs, authentication, or external services.

After design approval, move or recreate the approved mock under `docs/design/mocks/` and create or update the corresponding screen-operation and table design documents in the implementation PR.

## Completion

Before requesting PR creation, complete the Definition of Done, record the automated test evidence in the test Sub-issue, and ensure the session log contains material decisions and changes. After the user merges the PR, record the completion summary and improvement candidates, then close the session log Sub-issue.
