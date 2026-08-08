## XSH language proposals

None.

## xsht friction

`print "dir=" $dir` inserts a space between command-word arguments, producing
`dir= /srv/app` instead of the required `dir=/srv/app`. Exact-output tasks must
compose the line with an f-string (`print f"dir=${dir}"`) or an expression
shared into a single value. This is a documented print behavior, but it is an
easy trap when mirroring a fixed `key=value` layout.
