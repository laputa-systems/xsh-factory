Create one file named `render.xsh` in the task working directory.

The program accepts exactly three path arguments — TEMPLATE, VALUES, and
OUTPUT — and is invoked as:

    xsh render.xsh TEMPLATE VALUES OUTPUT

The VALUES file holds one `KEY=value` pair per line. Split each line on its
first `=`; the KEY is the part before it and the value is everything after it
(the value may itself contain `=` or spaces, and may be empty). Ignore lines
with no `=` and lines whose KEY is empty. Read TEMPLATE and replace every
literal occurrence of `@KEY@` with that KEY's value, for every KEY defined in
VALUES. A placeholder whose KEY is not defined is left exactly as written.
Write the substituted text byte-for-byte to OUTPUT. When TEMPLATE or VALUES
does not exist, exit nonzero and do not create OUTPUT. Values never contain
`@`, so substitution is unambiguous and order-independent. The evaluator
supplies several different template/value pairs, so do not hard-code one
result.

The behavior is defined by this oracle command, run by the evaluator on the
same inputs:

```sh
awk 'NR==FNR{i=index($0,"="); if(i>0){k=substr($0,1,i-1); v[k]=substr($0,i+1)}}
     NR>FNR{line=$0; for(k in v) gsub("@"k"@", v[k], line); print line}' VALUES TEMPLATE
```

The evaluator invokes the candidate equivalently to
`xsh render.xsh TEMPLATE VALUES OUTPUT` and compares the written OUTPUT
byte-for-byte with the oracle's stdout.

The program must read and write files through XSH `fs`/text APIs. It must not
start subprocesses, invoke an external command, add diagnostic text to stdout,
or modify the inputs. Keep stdout silent; OUTPUT is the only deliverable.

Use the handbook and the available `xsht` checks as the reference. A normal
development loop is:

    xsht api api:fs.read_text
    xsht api method:Str.split
    xsht api method:Str.replace
    xsht api method:Map.keys
    xsht check render.xsh
    xsht fmt render.xsh
    xsht lint render.xsh
    xsh render.xsh template.txt values.txt rendered.txt
