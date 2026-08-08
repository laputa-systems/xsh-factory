# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

The default for `hidden` in `fs.files`/`fs.walk` is `false` and silently omits
hidden (dot) entries. The module purpose/contract text does not state this
behavior, so a "recursively find the regular files" program that uses the
default quietly misses dotfiles; it is only discoverable by building a fixture
with a hidden file and comparing runs with and without `hidden: true`. A
proposal: document the hidden-filter default in the contract, or make the
"find all regular files" intent explicit.

## xsht friction

None.

## xsht friction

None.
