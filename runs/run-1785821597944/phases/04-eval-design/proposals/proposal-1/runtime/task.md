Create one file named `iniget.xsh` in the task working directory.

The program accepts exactly three command-line arguments: a path to an INI
file, the name of a section, and the name of a key. It reads the INI file with
the typed `ini` module and prints the value of `key` in `section`, followed by
a newline.

Rules:

- Read the file through the `ini` module (for example `ini.decode(text)`); do
  not parse the INI by hand.
- Section and key names are the exact strings given as arguments. Every
  evaluator fixture writes section headers and keys in lowercase, so a direct
  lookup matches.
- The file is a normal INI document: `[section]` headers, `key = value` lines
  (whitespace around the `=` is optional), `#` and `;` comment lines, and blank
  lines. Values are trimmed of surrounding whitespace.
- Print the value on its own line (the value followed by a newline) and nothing
  else on stdout.
- If the section or the key does not exist, the program must exit nonzero and
  print nothing to stdout.
- If the file is malformed (for example a key repeated in the same section) or
  cannot be read, the program must exit nonzero and print nothing to stdout.

The program must use XSH typed values and the `ini` module. It must not start
subprocesses, invoke an external command, or add diagnostics to stdout. The
evaluator supplies several hidden INI files and argument triples, so do not
hard-code a value.

Complete `review.md` using the supplied headings.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht check iniget.xsh
    xsht fmt iniget.xsh
    xsht lint iniget.xsh
    xsh iniget.xsh config.ini server host
