---
name: portfolio-ui-consistency-review
description: Independently review an implemented PortFolio-App screen against its approved design, mock, shared UI patterns, and acceptance criteria.
---

# Portfolio UI Consistency Review

Use this review skill for UI changes during the automated-test phase of `portfolio-issue-delivery`. Review the screen as implemented, not only its source or mock.

## Required inputs

- Parent Issue acceptance criteria and the approved design revision / design Sub-issue.
- Screen-operation design document and its approved HTML mock.
- Reference screen documents or screenshots and the shared components/styles the design says to follow.
- Rendered implementation screenshots at the same viewport dimensions, using representative data density. Include relevant interaction states and scroll positions for long or pane-based layouts.
- Test evidence or running local UI when available.

If a required item is missing, list it and mark the review `incomplete`; do not infer visual agreement from source code or a successful functional test.

Use fictional data in screenshots and evidence; do not request or expose real patient or personal information.

## Review steps

1. Confirm the implementation is being compared with the currently approved design revision. Identify its source and any post-approval change that may need renewed human review.
2. Compare the mock and implementation at matching viewport sizes. Compare the implementation with named existing screens/components where consistency is expected.
3. Check screen frame and entry/return flow; information hierarchy; component reuse; labels and button captions; alignment and widths; wrapping and horizontal overflow; panel height and scrolling; error placement; and visibility/reachability of primary and close actions.
4. Trace every screen requirement and applicable AC to visible evidence or a test. Mark missing, ambiguous, or unobservable requirements explicitly.
5. Separate functional failures from visual/design mismatches. A passing interaction test does not establish visual fidelity.

## Output

Return:

- Status: `pass`, `findings`, or `incomplete`.
- Compared design revision, mock, reference screens, viewport(s), and evidence files.
- Findings with severity, exact screen area/state, expected behavior from the source design, observed behavior, and a practical correction.
- AC/design coverage gaps and required follow-up.

Do not modify application or design files. Do not redefine approved requirements or silently waive a mismatch. Escalate potentially material design changes to the delivery Lead for the existing design-approval process.
