##! Stable run entrypoint contract: parse, admit, then delegate one mode.

use factory.request as request
use factory.policy as policy

## Parses a request without creating a run or spawning a child.
export pure parse_request(text: Str) -> Result[Any] { return request.parse(text) }

## Performs the pure admission gate used by the top-level launcher.
export pure admit_request(cycle: Any, repository: policy.RepositoryState, portfolio: policy.PortfolioState) -> Result[Any] {
  return policy.admit(cycle, repository, portfolio)
}
