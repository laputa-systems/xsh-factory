# Handbook promotion ledger

This ledger is the machine-readable disposition boundary for handbook lineage.
A candidate hash listed as `promoted` has been incorporated into the rolling
`runtime/handbook.md` by an explicit CTO decision. A candidate not listed here
must remain visible as unresolved work in the CTO briefing; controllers must
not silently discard it.

## One-time CTO consolidation — 2026-08-03

The CTO personally consolidated every distinct historical candidate lesson into
`runtime/handbook.md` under the user-authorized one-time exception. Duplicate
candidate snapshots are represented by the same hash and need no second entry.

| Candidate SHA-256 | Disposition |
| --- | --- |
| `002ebd6d7b2c61d7c1ec43980237d031f39db04f50eeea0e05ea2f3e431dff76` | promoted |
| `34e31f13f389f27921def680ea641b77ff0a5d506a11c111f7a43cad3cf4fd1e` | promoted |
| `385e6673d59c6053c32e0334d80f805ba742b890ad7b9cab386a06f5631b4454` | promoted |
| `3ecd38d00d4710b66ff6b5c734488d61a4bfbba034253a419b563498c973736b` | promoted |
| `4749771c5866b65791cd35ab362b6fd57aafbb6cd0ed4562143962b7d353e63d` | promoted |
| `590db2cbbfac215a18a194b84bf697b096841143499305d47d7895a56db3414e` | promoted |
| `6e7475c8abe13e94d04e8d5cbdad8a0c2333f1830ceb65997b498fcb2bf70d0f` | promoted |
| `6eecf5ed6bf558b7f444feb5cf1bf9dc077518560712c292ca6a9a8e7f809505` | promoted |
| `723f38ea0c7e4328027d2a13d496598b25c748a75279edb968d8738d43176ed8` | promoted |
| `8bc9ece7c67975e9bb9c99883e6950db4d9ad34f4b0e258beef47cf4307dcc9c` | promoted |
| `91ed23575157eefb62053b0fd2d8a3e77d9752ff828e704453b9a3890f117bd9` | promoted |
| `99930d56888f076fb3a58c92e805bff24585948147acf251802f157c72143635` | promoted |
| `9ddfee29877c4d89e3f6fa9a7ace99578f439eb89ff722dfdb2f89d9bde1c556` | promoted |
| `aaf3ad9cbf929ad2eec9811a6ff53fac4bfec2a5dfb498f6a2035fc2815f305d` | promoted |
| `b323e668a5478e61511db241276f85f09d2671aa76540b079727b5858baee5d4` | promoted |
| `c7c9dd9abb6d50dac60562757a1824900f24d4bc2d38014d5cbf869f56bb0723` | promoted baseline snapshot |
| `d17efbc1eac3dbaa39c68a7b03154a7d42531e660162048eeb0b37bd551a3bb0` | promoted |
| `f98a930a743e0d4905af6aae21813ad71a3365ef57dfc50bad6af0ccafe12be3` | promoted |
| `97c5d804c42c7742c9edfea4480163828d864279391d391df77aa60ee4a40e83` | promoted — CTO exception; comment syntax incorporated |

Future candidates require a new explicit CTO disposition and must not be
auto-promoted merely because a lineage file exists.

## Explicit CTO disposition — 2026-08-03

| Candidate SHA-256 | Disposition |
| --- | --- |
| `d0bc39f423d8202e60101d3e2bfa3cf1fcc247725097d23fb644115560767d9d` | deferred pending cross-eval replay; not promoted |

| `0014e368e601214f6b47a41d94009d9e142b683a53dd656fbd4e6d97b23d3f20` | deferred pending cross-eval replay; not promoted |

| `d9a2e262a449a28552b523f7a0d34c3542e7932f6c60a0761de28798229e8d35` | deferred pending strict-decimal replay; not promoted |
| `5ccd1f5e396aea7304bedf2f00a1dca82cdac847858eb0ec886d4dd416045e70` | deferred pending strict-decimal replay; not promoted |
| `315d310efe3e48088d0a1325a66b8f11a484c5ec835cdff68e795ca1081e359a` | deferred pending cross-eval text-split replay; not promoted |
| `c9b0e03d8c6b050ebf605b2383f3f6dd02a5eae00f74e9094ec17e6efc90130c` | deferred pending cross-eval path-shadow replay; not promoted |
| `52ffa03dfce9c88479993f3121347d1175f088d4dfc925f116f789d15da037f5` | deferred pending cross-eval dynamic-path replay; not promoted |
| `7859f910afad43d0933889e31bcb47aa695af008d7a1ddba91a51b64c8972c6a` | deferred pending strict-validation replay; not promoted |
| `36c2f9f168239719b87f05204cd580568d70a30565f557d973f812c7d621b6d3` | deferred pending cross-eval replay; not promoted |
| `68103e5a56564d6af075c8a99311f3e38fe3bbbc5260eec73ba6e596579b6a40` | deferred pending cross-eval replay; not promoted |
| `dbb77ccc4b1e335af741f29e875ee4b42d1e49cb2a02a1093d841ae994f86886` | deferred pending cross-eval replay; not promoted |

The `68103e5a…` candidate (task-ecount reeval) adds a concise stream-block-tail
rule (an `if/else` alone is not a block tail; bind it to a `let`). Recurring in
both trials, but single-run evidence; recorded as deferred, not promoted.

The `dbb77ccc…` candidate (envcfg) repeats the word-form boolean-operator rule
(consistent with the deferred boolean-operator sentence above) and adds a
do-not-shadow-standard-module-name note. Single-run hypothesis; recorded as
deferred, not promoted.

The `36c2f9f1…` candidate adds word-form boolean-operator guidance (`or`/`and`,
rejecting shell `||`/`&&`). It is valid and reproducible (envcfg trial 2 hit the
`||` rejection), but it is a single-eval hypothesis and the ledger already treats
the analogous boolean-operator sentence as deferred pending a second
conditional-writing eval replay. Recorded as deferred, not promoted.

The `d9a2e262…` candidate records a concrete regex-plus-expected-error idiom
for byte-exact decimal validation. The source eval passed all ten cases, but
the manager explicitly marks the guidance provisional after one trial; replay
evidence is required before changing the shared handbook.

The `0014e368…` candidate adds the reproducible compact-runtime `main`
spread-form guidance and repeats the word-operator guidance. Its source
manager report requires replay through `task-tags` and `task-ecount` before
promotion, so this cycle must treat it as deferred rather than as an approved
handbook snapshot.

The boolean-operator sentence is valid and remains visible in the originating
lineage, but the source run explicitly required a second conditional-writing
eval and the linked diagnostics-ticket replay before promotion. The next CTO
may promote it after that falsification evidence exists.

## Explicit CTO disposition — 2026-08-04

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b217df0fd5ac8e2a4428d1e1060c228f50a2cad3e236cc51800e8e62a868b096` | deferred pending a matched cross-run replay; not promoted |

The candidate adds a reusable warning about binding names that shadow standard
modules. The source trial passed, but the candidate was observed in one
`task-envcfg` session. Keep the approved handbook unchanged during the prompt
efficiency comparison and revisit this candidate after cross-run evidence.

## Explicit CTO disposition — 2026-08-04

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b9fcbfcc26179af38457947e54c306b31c469ba2e25ac01a597aa3083af9133a` | deferred pending matched cross-run replay; not promoted |

The candidate combines the already-deferred boolean word-form lesson with an
`in` membership lint preference. The current trial passed, but the worker had
one sample and the candidate is not needed to compare prompt revisions. Keep
the approved handbook unchanged and require replay before promotion.

## Explicit CTO disposition — 2026-08-04

| Candidate SHA-256 | Disposition |
| --- | --- |
| `e6f210b0f8f1fa2a605a5d30c145635b13e5e7743fd97974f2dbdce0f115d81b` | deferred pending the merged `fail` API/product replay; not promoted |

The `task-envcfg` cycle reproduced the already-tracked `fail` discoverability
gap on the pre-API-registration build. The candidate warning is superseded by
the merged API registration at XSH commit `2d423c1`; keep the approved handbook
unchanged until a post-merge replay shows whether any warning remains useful.

## Explicit CTO disposition — 2026-08-04

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b67607ea2dc717d2430ea3a82de6cf2e16a0b54a94ef59595aa00b8a715933e0` | deferred pending a replay that consumes the candidate handbook; not promoted |
| `a7033f98f53404ae6b368f7310ed3b269ef14628cd3b4eeb3cbbd2b07ea3993a` | deferred pending cross-eval replay; not promoted |

## Explicit CTO disposition — 2026-08-04

| Candidate SHA-256 | Disposition |
| --- | --- |
| `f798afbe919db07698e6d7c18eabb0c8a992a116906d0beaf94fd9af15b0a007` | deferred pending matched cross-run replay; not promoted |

The `task-envcfg` source trial observed standard-module shadowing once and
produced a candidate warning. The trial passed, but the evidence is
single-session and the candidate needs a matched replay before changing the
approved handbook. Keep `runtime/handbook.md` unchanged.

## Explicit CTO disposition — pre-cycle organization request

| Candidate SHA-256 | Disposition |
| --- | --- |
| `96634c8a5b07ead167b1cb0e2bbffa367bd14d4bd2258990ee073061654f5e7d` | deferred pending linked `task-bigfiles` replay and a second stream-stage eval; not promoted |

The candidate records the named-option-before-block rule from the
`task-bigfiles` worker. It is useful, but the source cycle explicitly called
for replay before promotion. Keep the approved handbook unchanged until the
linked product replay and an independent stream-stage eval provide that
evidence.

## Explicit CTO disposition — run-1785888600805

| Candidate SHA-256 | Disposition |
| --- | --- |
| `92ef0ee8ddb324bf22a15d9c2df67a6dd7ffc4d922cb5c06314fb7cdfc9b2954` | deferred pending strict-decimal replay; not promoted |

The `task-bigfiles` manager candidate records a reusable strict-decimal
validation idiom. The source trial passed, but the manager requires replay
before promotion. Keep the approved handbook unchanged until that replay
provides falsifying evidence.

## Explicit CTO disposition — run-1785888999833

| Candidate SHA-256 | Disposition |
| --- | --- |
| `3541dd94e5b3544bf8cdfc59178f9384572b66cc0d3d17c49345affb382edb92` | deferred pending post-merge replay and a second descending-stream eval; not promoted |

The linked replay candidate refines the option-before-block guidance and adds
the `!expr` negation spelling. The replay passed, but the manager explicitly
requires post-merge and cross-eval evidence before promotion.

## Explicit CTO disposition — run-1785893827191

| Candidate SHA-256 | Disposition |
| --- | --- |
| `1a0947d69748eee9f546a19743aa3a76f780f7c8a6d2f4302a5621cd85426efc` | deferred pending matched replay; not promoted |

The `task-colsum` candidate records one-trial Int-to-text/f-string guidance. The trial passed, but it is a single-session hypothesis and the candidate itself requests replay through another exact-output eval before promotion. Keep the approved handbook unchanged.

## Explicit CTO disposition — run-1785894766939

| Candidate SHA-256 | Disposition |
| --- | --- |
| `d518acbe39c324e0402b1f13e5692309c3f960e52f98d3662ddf90b3c86ebe15` | deferred pending cross-eval stream replay; not promoted |

The linked replay candidate recommends explicit absent-value terminals or `error.fail` instead of sentinel conversion and records pipeline-sugar friction. The product replay passed, but the candidate requests an additional fail-on-condition and stream replay; keep the approved handbook unchanged until that evidence exists.

## Explicit CTO disposition — run-1785896401695

| Candidate SHA-256 | Disposition |
| --- | --- |
| `3b56a781606faa1ae0eb811af09d10094080152dae78d9f057cca7de101e126b` | approved baseline unchanged |

Both phase candidates in this run are byte-identical to the approved handbook. No new handbook content was staged; the pipeline guidance belongs to the merged product contract and requires a future cross-eval replay before any handbook change.

## Explicit CTO disposition — run-1785899099112

| Candidate SHA-256 | Disposition |
| --- | --- |
| `a1b5fef60a1e56c8d1f0eec8e91ae99f5d963a15ca7c374bd20ca8c8c35995f5` | deferred pending `task-histogram-002` product/replay decision; not promoted |

The histogram worker's grouped-key `sort-by` guidance was not promoted because the same run produced a restriction failure and a product ticket for the checker behavior. A product replay must determine whether the existing `sort-by` surface can support concrete group keys before handbook guidance is changed.

## Explicit CTO disposition — run-1785900054828

| Candidate SHA-256 | Disposition |
| --- | --- |
| `a537a12ca4d6bf49d71787c5cf2fedcc1fcf5dbd4452e8df783d106cef284f01` | deferred pending cross-eval arithmetic replay; not promoted |

The candidate records the reusable integer-division rule (`/` truncates for non-negative Int values; `//` is not an operator). The source trial passed, but the manager requested replay through another arithmetic eval before changing the shared handbook.

## Explicit CTO disposition — run-1785949651175

| Candidate SHA-256 | Disposition |
| --- | --- |
| `079e1f989d60d158191ded5d44a33d70a668665abbba5f45f8e77bef9e5ab666` | deferred pending matched replay; not promoted |

The `task-svcstat` worker's boolean-operator candidate is a single-trial
hypothesis. The approved handbook remains unchanged until a matched replay in
a second conditional-writing eval establishes that the guidance generalizes.

## Explicit CTO disposition — run-1785958228987

| Candidate SHA-256 | Disposition |
| --- | --- |
| `4542f413f8d314ec90005700608fce925b93e418cfbc445c4b3d811bad5e0912` | deferred pending evaluator repair and matched replay; not promoted |

The `task-findexec` worker produced a correct artifact and a general boolean
operator observation, but the package evaluator failed before a manifest with
`missing-field: status`. Preserve the candidate without changing the shared
handbook until the evaluator is repaired and the claim is replayed.

## Explicit CTO disposition — run-1785960125254

| Candidate SHA-256 | Disposition |
| --- | --- |
| `6a7e2d443ca6c8f75e3e7d15a7e1fd9c583cca7492fa968df4d0019beb893f9a` | deferred pending matched replay; not promoted |

The `task-findexec` candidate records a useful filesystem path-return
contract, but it is single-trial guidance. The evaluator contract has now
been repaired and the candidate remains unpromoted until a matched replay
provides falsifying evidence.

## Explicit CTO disposition — run-1785960825554

| Candidate SHA-256 | Disposition |
| --- | --- |
| `aef69dd11420b141a3935620d983b6f80d2cca82c426a26556ebb36f8a4582b2` | deferred pending matched replay; not promoted |

The candidate restates the boolean word-form rule already
captured in earlier deferred candidates. The fresh run passed, but it remains
unpromoted until the required matched predicate-heavy replay establishes
whether the guidance generalizes beyond this eval.

## Explicit CTO disposition — pre-cycle-1

| Candidate SHA-256 | Disposition |
| --- | --- |
| `aef69dd11420b141a3935620d983b6f80d2cca82c426a26556ebb36f8a4582b2` | deferred pending matched predicate-heavy replay; not promoted |

The `task-findexec` worker reproduced the boolean word-form rule, but the
candidate is a single-eval hypothesis and requests a matched replay before
changing the approved handbook. The product ticket is admitted independently;
the handbook remains unchanged.

## Explicit CTO disposition — pre-cycle validation

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7f039da70ba9aec1d15de50d81588d33060f6beaa19daeb564f94356296684f2` | deferred pending cross-eval replay; not promoted |

The `task-histogram` candidate records the `/` integer-division spelling and
the `Regex.matches` receiver. Both are plausible reusable guidance, but the
source run is single-eval evidence and the candidate has not yet been
consumed by a matched replay. Keep the approved handbook unchanged until the
organization cycle provides the required cross-eval evidence.

## Explicit CTO disposition — run-1785965138991

| Candidate SHA-256 | Disposition |
| --- | --- |
| `91d37b46ef5a14af294741f8e23a533f83201228a055ebd03363ceafe8891c3a` | deferred pending cross-eval replay; not promoted |

The failed organization validation run's `task-histogram` candidate adds
postfix-`?` context and integer-division guidance. It is useful but comes from
one eval and was not consumed by a matched replay. Keep it deferred and leave
the approved handbook unchanged.

## Explicit CTO disposition — run-1785966217772

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7fbf3ec053e94133b71d56450a58b61b8548f3f1dc46d7196c5c83a870270d8b` | deferred pending cross-eval replay; not promoted |

The second worktree-boundary validation run produced no product change and
staged only a single-eval naming observation. Defer it pending cross-eval
replay; the approved handbook remains unchanged.

## Explicit CTO disposition — run-1785967096286

| Candidate SHA-256 | Disposition |
| --- | --- |
| `ea3761e9563ed8ae34b9a9e758f04e71a739fc6d29b731fc91101f25caa3172b` | deferred pending cross-eval replay; not promoted |

The operator-convention candidate is single-eval evidence from another
infrastructure-blocked organization run. Defer it pending cross-eval replay;
do not change the approved handbook.

## Explicit CTO disposition — run-1785967719321

| Candidate SHA-256 | Disposition |
| --- | --- |
| `bf3a0c802847dfd9d940c1cb7317854fb6b49b26d2a530dd7863c630030b03b0` | deferred pending cross-eval replay; not promoted |

The run was blocked by the same unresolved engineer-launch boundary and
produced no product commit. Defer its single-eval numeric-validation
candidate pending cross-eval replay; leave the approved handbook unchanged.

## Explicit CTO disposition — run-1785968539139

| Candidate SHA-256 | Disposition |
| --- | --- |
| `9d08733bc2c243823f0256c5955e6738726d5b73d10e194e12cf908365df27dd` | deferred pending cross-eval replay; not promoted |

The trial's exact-read restriction lesson is evaluator-specific single-run
evidence and the cycle was infrastructure-blocked. Defer it pending replay;
leave the approved handbook unchanged.

## Explicit CTO disposition — run-1785969469053

| Candidate SHA-256 | Disposition |
| --- | --- |
| `9ab17a881bc35fe0ed4693348ef99348cffd8bdb125e6ba6a33c4c8f9f347bac` | deferred pending cross-eval replay; not promoted |

The candidate is single-eval operator and argument-result guidance from an
organization run whose engineer dispatch remained blocked. Defer it pending
cross-eval replay and keep the approved handbook unchanged.

## Explicit CTO disposition — run-1785970204681

| Candidate SHA-256 | Disposition |
| --- | --- |
| `72824b0dcc111c1f9e0ea505cfa2260a002719fa8a012759a5ddda8adc89e4f7` | deferred pending cross-eval replay; not promoted |

The candidate is a single-eval division note from a run where engineer
dispatch remained blocked. Defer it pending replay; do not alter the approved
handbook.

## Explicit CTO disposition — run-1785971171503

| Candidate SHA-256 | Disposition |
| --- | --- |
| `72824b0dcc111c1f9e0ea505cfa2260a002719fa8a012759a5ddda8adc89e4f7` | deferred pending cross-eval replay; not promoted |

This attempt did not start paid work because the temporary diagnostic itself
failed syntax validation. It adds no product evidence; retain the prior
single-eval disposition and keep the approved handbook unchanged.

## Explicit CTO disposition — run-1785971528057

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7b949371cfe85e2e6860ba4f4a1deecf9914aa9237374c5290286cf49c98488b` | deferred pending cross-eval replay; not promoted |

The run remained infrastructure-blocked and produced no product signal.
Defer its single-eval candidate pending replay; keep the approved handbook
unchanged.

## Explicit CTO disposition — run-1785972040960

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7b949371cfe85e2e6860ba4f4a1deecf9914aa9237374c5290286cf49c98488b` | deferred pending cross-eval replay; not promoted |

This attempt only exposed a controller diagnostic-path collision while the
engineer remained blocked. It adds no product evidence; keep the handbook
unchanged.

## Explicit CTO disposition — run-1785972040960

| Candidate SHA-256 | Disposition |
| --- | --- |
| `9b0d6f75be6d6e7e5113236917274101167e06391e26fb8a6b8aac5072902cb6` | deferred pending cross-eval replay; not promoted |

No product signal was produced while dispatch diagnostics were being repaired;
defer the candidate and keep the approved handbook unchanged.

## Explicit CTO disposition — run-1785972584122

| Candidate SHA-256 | Disposition |
| --- | --- |
| `9b0d6f75be6d6e7e5113236917274101167e06391e26fb8a6b8aac5072902cb6` | deferred pending cross-eval replay; not promoted |

The diagnostic isolated a missing engineer `FACTORY_EVAL_ID` environment
binding, not a product issue. Defer the candidate and keep the approved
handbook unchanged.

## Explicit CTO disposition — run-1785972584122

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b7c5a5c2f2c8bc3d6b5bb3be20b2a5cb7ecf53e9f80a1e112ef8cbbd5fe5e1de` | deferred pending cross-eval replay; not promoted |

The run surfaced only the missing ticket review gate while the engineer
dispatch remained blocked. Defer its single-eval candidate pending replay.

## Explicit CTO disposition — run-1785972584122 candidate

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7c9669c0f07d4667045a37e79d1539db809e030708f1c20d0a426ca1b1948898` | deferred pending cross-eval replay; not promoted |

The candidate belongs to the blocked run's single eval and remains deferred.

## Explicit CTO disposition — run-1785973336705

| Candidate SHA-256 | Disposition |
| --- | --- |
| `7c9669c0f07d4667045a37e79d1539db809e030708f1c20d0a426ca1b1948898` | deferred pending cross-eval replay; not promoted |

Dispatch reached the assignment gate but exposed a raw-vs-canonical worktree
string mismatch. No product work started; defer the candidate.

## Explicit CTO disposition — run-1785973336705

| Candidate SHA-256 | Disposition |
| --- | --- |
| `0d895fe92547465c597f257c6e56cf1d52587c825d4ed0f165b7381e57f8cd6c` | deferred pending cross-eval replay; not promoted |

The run produced no product evidence after reaching the assignment gate.
Defer its candidate pending replay.

## Explicit CTO disposition — run-1785973900575

| Candidate SHA-256 | Disposition |
| --- | --- |
| `edab528c77fd443a36a85006ce5f94c0603c4bfce0c0e2455c5fa23300f498f3` | deferred pending cross-eval replay; not promoted |
| `d8065b5ae7970ba17c1b6ba3098f3fc0663816eb98ad9d310dd5f186cf226443` | deferred pending cross-eval replay; not promoted |

The successful organization cycle staged single-trial handbook candidates
about typed filesystem permissions and integer arithmetic. Both remain
deferred pending the specified cross-eval replays; the approved handbook is
unchanged.

## Explicit CTO disposition — run-1786052381421

| Candidate SHA-256 | Disposition |
| --- | --- |
| `2432f72a72c677e165aab6e7f0ddce7d29e95e045310617413c75b4f8a1cb515` | deferred pending cross-eval replay; not promoted |

The task-grep candidate adds general guidance for standard-module shadowing
and the `in` membership operator, but it has only one eval's evidence. Defer
promotion until the specified nearby text-search replays complete; keep the
approved handbook unchanged.

## Explicit CTO disposition — run-1786124624556

| Candidate SHA-256 | Disposition |
| --- | --- |
| `1c4fa79ffd580b7e07ccd2476d1274220c3b51c08ad09601cbe0089524aa8cfb` | deferred pending cross-eval replay; not promoted |

The `task-bigfiles` manager observed the hidden-dotfile behavior in one trial
and explicitly required an independent filesystem replay before promotion.
The approved handbook remains unchanged; the candidate is rejected for this
cycle's admission purposes until that evidence exists.

## Explicit CTO disposition — run-1786126514242

| Candidate SHA-256 | Disposition |
| --- | --- |
| `ce6a8e8d17a6ed1788b44a86eb37c75156fc29fe55f0509b45295beb24450646` | deferred pending cross-eval replay; not promoted |

The focused `task-histogram` replay passed 9/9 and supplied useful arithmetic
and record-literal guidance, but it is single-eval evidence. Keep the approved
handbook unchanged until the named histogram replay and a second
record/division-heavy eval confirm reduced discovery friction.

## Explicit CTO disposition — run-1786128115649

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b8850d2021ac99f587cdd368ab9b40132d73b52b79f35ab5647cd02e6162db75` | deferred pending cross-eval replay; not promoted |

The first `task-dupcheck` trial passed all eight cases and supplied a useful
positional-only API guidance candidate, but it is single-eval evidence. Keep
the approved handbook unchanged until `task-dupcheck` and a second
defaulted-parameter eval confirm the guidance generalizes.

## Explicit CTO disposition — run-1786136684797

| Candidate SHA-256 | Disposition |
| --- | --- |
| `417e9281eb2d40e6d5e17a03dfcd06085764a4c3357df074580a44c91e34d2b7` | deferred pending cross-eval replay; not promoted |
| `51468c5c14cb9152128239fc804c521fac8389aa428f53cf20b97d282886c814` | deferred pending cross-eval replay; not promoted |
| `83b0202d30fbfb80eb0755582bfd015f69adf5d538ecd1d5c360ee6b2e08dba3` | deferred pending cross-eval replay; not promoted |

The `task-jsonfilter`, `task-manifest`, and `task-pathparts` managers staged
single-eval handbook candidates. Defer all three until the named replays and
independent nearby evals confirm generalization; the approved handbook stays
unchanged.

## Explicit CTO disposition — run-1786135120835

| Candidate SHA-256 | Disposition |
| --- | --- |
| `76be68bc0027fb110bdddf0b8b2950072238472dfcd77a80867021ab819b4f7d` | deferred pending cross-eval replay; not promoted |
| `5f8e62935443becb4cef30adc28ce72aa0a697ce96df0c0d3b56fc4f3893457b` | deferred pending cross-eval replay; not promoted |
| `b2069c71aa8f20b8e34b0cec2d2415f5152d81492feaa47a24df5c46a0a3dbb8` | deferred pending cross-eval replay; not promoted |

The `task-grep`, `task-iniget`, and `task-intsum` managers each supplied a
short handbook improvement, but each candidate has only one eval's evidence.
Keep the approved handbook unchanged until the named replays and independent
nearby evals confirm that the guidance generalizes.

## Explicit CTO disposition — run-1786131191668

| Candidate SHA-256 | Disposition |
| --- | --- |
| `2c9a519882a9c0dff1c84e45788d5ed7bd4dbf92f01292047880511a75c92aac` | deferred pending cross-eval replay; not promoted |

The `task-ecount` manager's function-return and `List.get` guidance is useful
but has only one eval's evidence. Keep the approved handbook unchanged until
the named replay against the candidate and an independent filesystem or
composition eval confirm that it generalizes.

## Explicit CTO disposition — run-1786133266290

| Candidate SHA-256 | Disposition |
| --- | --- |
| `5e85b8d4324282bdc301608747b7d27d067933578ed59d6226ebdd4675556d1a` | deferred pending cross-eval replay; not promoted |

The paired `task-findexec` discovery produced useful general filesystem
permission and hidden-entry guidance, but it remains single-eval evidence.
Keep the approved handbook unchanged until the named `task-findexec` replay and
an independent filesystem-tree eval confirm the guidance.

## Explicit CTO disposition — run-1786128115649

| Candidate SHA-256 | Disposition |
| --- | --- |
| `b8850d2021ac99f587cdd368ab9b40132d73b52b79f35ab5647cd02e6162db75` | deferred pending cross-eval replay; not promoted |

The first `task-dupcheck` trial passed all eight cases and supplied a useful
positional-only API guidance candidate, but it is single-eval evidence. Keep
the approved handbook unchanged until `task-dupcheck` and a second
defaulted-parameter eval confirm the guidance generalizes.
