# pol-arch

**Designing system architectures by exhaustion — a systems-engineering layer
over [pol](https://github.com/sajonaro/pol).**

An architecture brief is normally answered by judgement: an architect reads a
few paragraphs, decides what they must have meant, and draws a diagram. The
diagram is then the only record, it agrees with nothing, and the questions the
brief failed to answer are discovered during implementation.

This repository does the same job mechanically. A **component bank** and the
brief's requirements become a Pol model; `pol check` enumerates *every*
architecture the constraints permit; and four tools turn the result into the
artifacts a team actually needs — a C4 diagram, a list of questions for whoever
wrote the brief, and decision records that cannot drift from the design.

Nothing here is a new language. **Every semantic lives in Pol**, and these are
generators and formatters over `pol derive` output. That is deliberate: a second
language with its own meaning would put a compiler between you and the proof.

## The workflow

```
  a brief, in prose
        │
        ▼
  catalogue/*.tbl  ──pol-bank──▶  a .pol model
        │                              │
        │                         pol check
        │                              │
        │            ┌─────────────────┼──────────────────┐
        │            ▼                 ▼                  ▼
        │      pol-interview       pol-c4             pol-adr
        │            │                 │                  │
        │     questions for      C4 diagrams        decision records
        │      the author         (D2 / SVG)         with proofs
        │            │
        └────────────┘   answers sharpen the catalogue, and it runs again
```

The loop is the point. `pol-interview` is not a report at the end — it is the
step that sends you back to the brief with things nobody had noticed.

## The four tools

| | reads | writes |
|---|---|---|
| **`pol-bank`** | a catalogue of parts, as tables | the model's datums — rosters, spans, one move per part |
| **`pol-interview`** | `pol check` findings | the questions to put back to whoever wrote the brief |
| **`pol-c4`** | `pol derive` rows | a C4 diagram in D2, at context or container level |
| **`pol-adr`** | `pol derive` rows and proof trees | decision records, each with what was rejected and why |

### `pol-bank` — because a form cannot map over a roster

A Pol form is rename-and-paste: no recursion, no computation, and it cannot map
over its `&rest`. So it cannot turn *"component X provides capability Y"* into
the named span junction that fact requires, nor emit one `pick` move per part.
None of that is a defect in Pol — it is what keeps a model a finite
presentation. It is a defect in what a **human** should be asked to type: a bank
of 150 parts is roughly 4,000 datums, ~750 of them globally unique junction
names invented by hand.

Forty lines of table become the whole instance:

```console
$ pol-bank catalogue/corpus example/corpus.extras.pol > example/corpus.pol
```

`run-tests.sh` asserts the committed model is **byte-identical** to what the
catalogue regenerates, so hand-editing generated output fails a test rather than
being discovered much later.

### `pol-interview` — the step that pays for the exercise

```console
$ pol-interview example/corpus.pol --claims example/corpus.claims
THE MODEL ANSWERED 3 of its questions. It raises 2 for you.

  184 situations reachable, 96 dead ends.

OPEN QUESTIONS — the brief is silent, and the model refuses to guess

  1. the brief is silent: are the 50TB of PDFs digital-native or scanned?
     the extract choice depends on it
     declared at:   gap `pdf-kind-unknown`, reachable in 2 moves

CONTRADICTIONS — a stated requirement the brief does not actually get

  2. re-runnable classification implies persisted text
     property:      rerun-is-affordable
     counterexample: 1. hold-object-store -> 2. enumerate-event-stream
                     -> 3. extract-llm-vision -> 4. classify-rules-engine
     to decide:     is the counterexample acceptable (relax the
                    requirement), or is it a real defect (add a constraint)?
```

Neither question was thought of by anybody. The first is a declared `gap` — the
model saying its rules genuinely run out, rather than guessing past a hole. The
second is a `never` property with a witness: a stack meeting every **stated**
requirement whose extract stage discards its output, so "re-run the
classification" silently means re-processing the whole corpus. **48 of the 96
designs have it** — half the answer set looks correct and is not.

It works on any Pol model, not only architecture ones: run it on the
knights-and-knaves puzzle and the paradox comes out as an open question.

### `pol-c4` — diagrams that cannot lie

```console
$ pol-c4 example/corpus.pol example/corpus.rules 183 --level container --svg out.svg
```

Every box, group, arrow and label is a row out of `pol derive`. **If the diagram
is wrong, the model is wrong** — which is the one property a hand-drawn
architecture diagram can never have. Boundaries become D2 containers, external
systems are drawn dashed, technology rides in the box label, actors are people,
and edges carry their protocol.

**The edges are runtime data flow, not the build ladder.** `cap.next` is the
order a *designer* fills stages in; the `flow` span is the order *data* moves.
In the worked example the catalogue fans out to both serving and the CRM, while
the ladder is a chain — so drawing the ladder would have produced a diagram that
was merely plausible. The two are never the same thing.

### `pol-adr` — records that re-derive

Each decision gets its technology and boundary, the alternatives that were
rejected, **the requirement each one failed**, and the derivation tree as proof:

| rejected | because |
|---|---|
| `nas` | cannot survive the data volume (`needs-bulk`) |
| `pdf-lib` | cannot read scanned pages (`needs-scan`) |
| `llm-classifier` | not reproducible across runs (`needs-rerun`) |
| `direct-db` | couples too tightly (`needs-loose`) |

`pol derive --why` alone will not do this. The proof tree for a chosen part
shows only that it *was* chosen; what was rejected and on which requirement is a
different derivation.

## `lib/arch.lib.pol` — and one distinction that matters

The vocabulary splits its fields in two, and confusing them is how a diagramming
need silently becomes a design constraint:

- **Constraint fields** (`bulk`, `scans`, `rerunnable`, `persists`, `couples`)
  are read by `fits`. They decide which parts may fill which stage, so they
  **shrink** the search space.
- **Presentation fields** (`level`, `tech`, `external`, `within`) are read by
  `pol-c4` and by nothing in the library. Every one is `fixed`, so they add
  **no situations at all** — a design space is the product of the *mutable*
  cells. The worked example scores the same 184 situations with them as without.

Add a presentation field freely. Add a constraint field only when you mean to
rule something out.

## Running it

Needs [`pol`](https://github.com/sajonaro/pol) on `PATH`; `d2` only for SVG.

```sh
./install.sh              # -> ~/.local   (bin on PATH, lib on POL_LIB)
./run-tests.sh            # 43 checks over the four tools
./run-tests.sh list       # the individual tests
```

The tools are POSIX `sh` and `awk` — no runtime, no packages, nothing to
install beyond `pol` itself.

## What this does not claim

**The catalogue is the project, and it is the weakest link.** The component
attributes in `catalogue/corpus` were written by hand as a demonstration. `pol`
proves what follows from them exhaustively, and will do so just as faithfully if
they are wrong. The rigour on offer is *internal consistency*, not truth — a
real bank is a curation problem, and no amount of tooling substitutes for it.

**Quantities remain out of scope.** Pol has no arithmetic. Ordinal scales and
precomputed `fixed` arrows carry a long way (a latency budget composes fine over
a finite quantale), but capacity planning, cost in currency and availability
arithmetic belong in a solver built for them, with the answers imported here as
facts.

**`pol-c4` draws one design at a time.** The model enumerates 96; choosing among
them is a judgement the tool deliberately does not make.

## Related

| | |
|---|---|
| **[pol](https://github.com/sajonaro/pol)** | the language, the engine, the CLI |
| **[pol-problems](https://github.com/sajonaro/pol-problems)** | worked models, including `arch/` — the same search without the C4 vocabulary, kept as the teaching version |
| **[pol-vscode](https://github.com/sajonaro/pol-vscode)** | the editor client |

## License

Copyright (C) 2026 Alex Kunich. **GNU Affero General Public License, version 3
or later** ([LICENSE](LICENSE)), matching `pol` itself. A catalogue or model you
write is your own work, not a derivative of these tools.
