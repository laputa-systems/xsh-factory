# Task Review

Keep both section headings. Replace `None.` with concise, evidence-based
findings when the session exposed a reusable language proposal or xsht
friction. Do not invent an issue; leave `None.` when the section has no
finding.

## XSH language proposals

None.

## xsht friction

- `xsht fmt` rewrote a single-line display string containing `\n` escapes
  (`f"host=${host}\nport=${port}\n..."`) into a multiline `f"""..."""` literal.
  The byte output was identical, but the transformation from a one-line
  escaped form to an indented multiline block was unexpected and made the
  intended exact byte layout harder to eyeball. Worth noting since exact-text
  tasks are common.
- The compact runtime rejects `proc main(argv: List[Str])` and requires the
  spread form `proc main(...argv: List[Str])`; the check error message
  ("proc main must use the spread form") is clear once seen, but it is a
  non-obvious requirement for a one-argument CLI.
