##! Stable host-agent entrypoint contract for exact dispatch authorization.

use factory.dispatch as dispatch

## Delegates runner admission to the canonical dispatch identity check.
export pure authorized(plan: Any, invocation: Any) -> Bool {
  return dispatch.invocation_authorized(plan, invocation)
}
