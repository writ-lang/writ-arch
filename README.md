# writ-arch

<img src="docs/images/writ-mark-200.png" alt="writ" width="120" align="left" hspace="16" vspace="4">

**Design system architectures by exhaustion, with
[writ](https://github.com/writ-lang/writ).**

An architecture brief is usually answered by judgement: someone reads it,
decides what it must have meant, and draws a diagram. writ-arch does it
mechanically. A catalogue of candidate components and the brief's requirements
become a writ model; `writ check` enumerates **every** architecture that fits;
and five small tools turn the result into what a team needs.

<br clear="left">

## The loop

```
  catalogue/*.md ──writ-bank──▶ model.writ ──writ check──▶ every valid design
                                                               │
       ┌───────────────┬───────────────┬───────────────────────┤
  writ-assume     writ-interview      writ-c4               writ-adr
  facts to        questions for       C4 diagrams           decision records,
  confirm         the brief's author  (D2 / SVG)            with proofs
       └───────────────┴──── answers sharpen the catalogue, and it runs again
```

| Tool | Turns | Into |
|---|---|---|
| `writ-bank` | a Markdown catalogue of parts | the writ model |
| `writ-assume` | the catalogue's unconfirmed (`?`) cells | the few that actually change an answer |
| `writ-interview` | `writ check` findings | questions for whoever wrote the brief |
| `writ-c4` | one chosen design | a C4 diagram where every box is derived from the model |
| `writ-adr` | the derivations | decision records: what was chosen, what was rejected, on which requirement |

All the meaning lives in writ; these are generators and formatters over its
output, in POSIX `sh` and `awk`.

## What it finds

On the worked example — 50 TB of PDFs to classify, feed to AI and surface in a
CRM — 96 of 2,916 component combinations satisfy the brief. More useful are
the two questions nobody had asked:

```console
$ writ-interview example/corpus.writ --claims example/corpus.claims
OPEN QUESTIONS — the brief is silent, and the model refuses to guess
  1. the brief is silent: are the 50TB of PDFs digital-native or scanned?

CONTRADICTIONS — a stated requirement the brief does not actually get
  2. re-runnable classification implies persisted text
     counterexample: hold-object-store -> enumerate-event-stream
                     -> extract-llm-vision -> classify-rules-engine
```

Half of the 96 designs meet every *stated* requirement yet discard extracted
text, so "re-run the classification" would mean reprocessing the whole corpus.

And `writ-assume` turns "verify 33 catalogue claims" into "confirm these four":
it flips each unconfirmed cell and reports only those that change a verdict.

## Run it

Needs `writ` on `PATH` (and `d2` for SVG):

```sh
./demo.sh          # the whole pipeline on the worked example
./run-tests.sh     # the tools' tests
./install.sh       # -> ~/.local
```

## Limits

The catalogue is the weakest link: writ proves what follows from it, right or
wrong. Keep it small — the eight to twelve candidates a team would really
consider for one decision, written by the people who will run them — and use
`writ-assume` to find the cells worth checking. writ has no arithmetic, so
capacity and cost belong in a dedicated solver, with results imported as facts.

## License

Copyright (C) 2026 Alex Kunich. [AGPL-3.0-or-later](LICENSE), like writ. Your
catalogues and models, and everything the tools generate from them, are yours:
see [LICENSE.exception](LICENSE.exception). Patches welcome —
[CONTRIBUTING.md](CONTRIBUTING.md).
