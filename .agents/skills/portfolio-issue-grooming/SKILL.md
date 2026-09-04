---
name: portfolio-issue-grooming
description: Convert conversational requirements for this PortFolio-App repository into a reviewable feature Issue draft, including acceptance criteria, scope boundaries, and proposed Sub-issues. Use when the user wants to groom or create a development Issue.
---

# Portfolio Issue Grooming

Use this skill only in the repository containing this skill.

## Read first

Read `AGENTS.md`, `docs/project/product-requirements.md`, `docs/development/issue-workflow.md`, and any design documents relevant to the request. Treat them as the source of truth for scope and process.

## Outcome

Turn the user's conversational request into a parent Issue draft for one coherent, deliverable unit of work. Preserve the user's terminology, but make the objective, acceptance criteria, exclusions, and open decisions unambiguous.

Use [the parent Issue format](references/parent-issue.md). Propose three Sub-issues: design, automated test, and session log. Do not split the parent Issue into implementation Sub-issues unless the work cannot be delivered safely as one unit.

## Workflow

1. Identify the user outcome, actors, business flow, and requested change.
2. Compare the request with the approved product scope and identify conflicts, hidden assumptions, and non-goals.
3. Draft the parent Issue and proposed labels. Include only acceptance criteria that can be verified.
4. List decisions that require the user's answer. Ask only questions that materially affect scope, behavior, or safety.
5. Create or update GitHub Issues only when the user explicitly requests that write operation. Use the authenticated `gh` CLI when available; never request, display, or store a token.

## GitHub write boundary

An explicit request such as `Issueを作成して` authorizes creating the reviewed parent Issue and its three reviewed Sub-issues. It does not authorize implementation, PR creation, merge, repository settings changes, or unrelated Issue changes.

After creation, link the Sub-issues to the parent Issue and set the parent Project Status to `未着手` when the configured Project is available. If a Project is not configured, report that status update as pending instead of inventing a label-based substitute.

## Safety and public-repository rules

- Do not include real patient data, personal data, credentials, tokens, or internal URLs in Issues.
- Keep medical scope limited to the approved learning and workflow-management system; do not imply clinical decision-making or production medical use.
- Do not create a design, test, or log Sub-issue from an unreviewed draft.
- Do not close Issues or move design approval forward. The user closes the design Sub-issue to approve the design.
