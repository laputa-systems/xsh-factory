# CTO factory improvement

## Status

validated

The explicit-image build fast path was validated by the following cycle. The
qualified image was present for the target platform, the stale cache stamp no
longer forced a rebuild, and both discovery phases crossed the XSH build
boundary and completed their worker/manager closeouts.

## Change

`factory/control.xsh::toolchain_build_required` and
`factory/controllers/eval.xsh` now distinguish an operator-supplied,
platform-matched `XSH_TEST_IMAGE` from the repository default. A present
explicit image skips a stale default-image rebuild unless the operator forces
one; absent or invalid images still fail closed and require a build. Native
coverage is in `tests/factory_control_test.xsh` and
`tests/tools_test.xsh`.

## Throughput requirement

No engineer row was eligible: Run 9's queue had two `Open.` tickets and zero
`Approved.` rows, so fresh-engineer target and delivery target were both zero.
This was an infrastructure validation cycle, not a missed eligible delivery.

## Provider-health attribution

No Pi worker started in Run 9, so provider telemetry is not applicable. Run 9
cost `$0.00`, with zero workers and zero assistant turns.

## Baseline metric

Run 8 attempted two ticketless discovery builds and failed before Pi because
the default image lacked `linux/random.h` and `libunwind`; see
`../run-1786230105277/phases/01-eval/xsh-build.stderr` and its paired phase.
The explicit-image skip was implemented before Run 9, but Run 9 reused the
old tag `xsh-test-throughput-1786225102047`, which Run 8's failed Docker
rebuild had overwritten with the same broken contents. Both Run 9 phases
therefore failed before worker admission.

## Target metric

With a newly qualified image supplied explicitly, both ticketless discovery
phases must pass their local XSH build and complete worker plus manager
closeout, with no `xsh-build.stderr` failure and no Docker rebuild caused only
by a stale cache stamp.

## Validation

Validated by Run 10, `run-1786230602946`: the command supplied
`XSH_TEST_IMAGE=xsh-test-throughput-qualified-1786230433596` and
`XSH_TEST_IMAGE_BUILD=0`; both phases passed, root outcomes were
`product=pass`, `evaluator=pass`, `infrastructure=pass`, and the qualified
image was verified as
`sha256:d3bccbbc5302186bd642455fc7174c3e9d145db8c3102b534ac41672ff894892`
for `linux/arm64`. Run 10 used four workers, 97 assistant turns, and
`$0.052743888`; no build failure occurred.

## Revert condition

If an explicit present image still triggers a default rebuild, or either phase
again fails before Pi with the qualified image, inspect platform identity and
headers first. The safe inverse is to require a fresh validated toolchain
image (`force_rebuild=true`) rather than silently trusting a tag.

## Next-cycle disposition

Validated. The evidence is `../run-1786230602946/report.json`, both phase
reports, the empty Run 10 build stderr files, the image inspection above, and
the 144-test native suite run after the follow-on handbook-gate repair.
