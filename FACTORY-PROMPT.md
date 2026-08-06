# Englishlint policy for XSH Factory

Use this policy when you review or write Markdown in `xsh-factory`. Read the
repository contract before you change documentation.

## Purpose

Clear documentation reduces agent discovery, controller mistakes, and boundary
ambiguity. Prefer precise operational guidance over uniform prose.

This policy is an unofficial practical aid inspired by ASD-STE100. It does not
certify compliance.

## Document classes

The factory uses two document classes.

### Maintained guidance

<!-- englishlint: ignore-next-line ENG012 -->
This class includes `README.md`, `NORTH-STAR.md`, `FACTORY.md`, `CTO.md`,
`FACTORY-PROMPT.md`, `docs/**`, `roles/**`, and `runtime/**`.

Improve clarity in this class when the contract stays unchanged. Treat Englishlint
errors as repair candidates before the next paid cycle.

### Contracts and evidence

This class includes `cycle-*.md`, `tickets/**`, `evals/**`, and `templates/**`.

These files can contain exact commands, evaluator cases, historical decisions,
placeholders, and machine-facing protocols. Treat style findings as review
warnings. Change them only when the contract or evidence needs correction.

## Writing rules

Classify each passage before you edit it.

- Procedures use imperative sentences of 20 words or fewer.
- Descriptions use simple tenses and sentences of 25 words or fewer.
- Descriptive paragraphs contain no more than six sentences.
- Write one instruction per sentence.
- Put conditions before commands.
- Use active voice when the responsible actor is known.
- Preserve passive voice for intentional states and protocol transitions.
- Avoid present perfect tense and dangling `-ing` clauses.
- Use complete grammar and do not use contractions.
- Use American English spelling unless the repository requires another form.
- Replace `e.g.` with `for example` and `i.e.` with `that is`.
- Delete filler such as `simply`, `just`, `robust`, and `powerful`.

Use modals precisely.

- Use `must` for requirements.
- Use `can` for capabilities.
- Use `may` only for explicit permission or bounded authority.
- Use `could` or `might` only for uncertainty, alternatives, or hypotheses.
- State a condition directly instead of using hypothetical `would`.

<!-- englishlint: ignore-next-line ENG012 -->
Use one term for one concept unless the terms have different contract meanings.
The default glossary prefers `check`, `configuration`, and `delete`.
Do not replace `validate` when it names a formal gate, or `verify` when it
names independent evidence.

## Preserve contracts and evidence

Never rewrite code blocks, inline code, commands, flags, identifiers, or paths.
Never rewrite URLs, product names, API names, configuration keys, quoted errors,
log lines, JSON, YAML, evaluator cases, or exact-output requirements.

Preserve status markers such as `Open.`, `Approved.`, `Merged.`, `Draft.`, and
`not-ready.` Preserve historical decisions and quoted agent evidence.

Explain exact technical values in surrounding prose. Do not change an example's
modal when the change can alter its contract.

Review warnings in grouped contracts as evidence, not as prose defects. Preserve
paragraphs that describe one evaluator case or one historical observation.

## Active-cycle review

<!-- englishlint: ignore-next-line ENG012 -->
Before a paid cycle, inspect the latest run handoff and the files that control
admission. Review `README.md`, `FACTORY.md`, `CTO.md`, `roles/**`,
`runtime/handbook.md`, and active assignment or report templates.

Run the nearest native factory check before editing documentation:

```text
xsht test
```

Run Englishlint on the active directories. Review the full repository separately:

```text
englishlint roles
englishlint runtime
englishlint templates
englishlint .
```

Fix findings in this order:

1. Errors in role prompts and active guidance.
2. Errors in `README.md`, `FACTORY.md`, and `CTO.md`.
3. Errors that obscure ownership, state, permissions, or stop conditions.
4. Warnings that reduce repeated agent guesswork.
5. Historical and contract findings that need no contract change.

Do not pursue zero findings as a cycle goal. Record remaining findings when the
contract explains them or when remediation exceeds the bounded change.

## Avoid duplicated instructions

Keep each contract in one owner document. Add a cross-reference instead of a
second explanation.

Role files own stable behavior. Assignment templates own cycle paths and exact
identity. Report templates own headings and result values. Controllers own
state transitions and deterministic gates.

When an existing document states the required behavior, tighten or delete that
prose. Do not create a competing instruction in another document.

## Suppressions

Use an inline suppression only when the finding is intentionally correct:

```markdown
<!-- englishlint: ignore-next-line ENG014 -->
The ticket is marked `Merged.` after reconciliation.
```

Use a file-level suppression only for a document with a clearly different
purpose. Explain the reason in the change record. Do not add a suppression only
to make Englishlint exit zero.

## Do not edit active work

If another agent changes the same document, do not reformat or rewrite it. Report
findings with paths and line numbers instead.
