# task-usagerep dry run

Ran on host with XSH build at /Users/josh/usr/bin/xsh and xsht.

```
$ xsht check evaluator.xsh
exit=0
$ xsht check executor.xsh
exit=0
$ xsht check evaluate.xsh
exit=0
```

All three package scripts parse cleanly with xsht check (exit 0).
Not exercised: live container trial with /work, /session, /export paths, a real agent session, and candidate-vs-oracle byte matching.
