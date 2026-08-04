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
