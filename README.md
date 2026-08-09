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
wrote the brief, decision records that cannot drift from the design, and a short
list of the unverified facts the whole thing is standing on.

Nothing here is a new language. **Every semantic lives in Pol**, and these are
generators and formatters over `pol derive` output. That is deliberate: a second
language with its own meaning would put a compiler between you and the proof.

## The workflow

```
  a brief, in prose
        │
        ▼
  catalogue/*.md   ──pol-bank──▶  a .pol model
        │                              │
        │                         pol check
        │                              │
        │       ┌──────────┬───────────┼──────────┐
        │       ▼          ▼           ▼          ▼
        │  pol-assume  pol-interview pol-c4   pol-adr
        │       │          │           │          │
        │  the facts   questions   C4 diagrams  decision
        │  to confirm  for the      (D2/SVG)    records
        │       │       author                 with proofs
        │       │          │
        └───────┴──────────┘  answers sharpen the catalogue, and it runs again
```

The loop is the point. `pol-interview` is not a report at the end — it is the
step that sends you back to the brief with things nobody had noticed.

## The five tools

| | reads | writes |
|---|---|---|
| **`pol-bank`** | a catalogue of parts, as a Markdown page | the model's datums — rosters, spans, one move per part |
| **`pol-assume`** | the catalogue's unconfirmed cells | the few whose truth actually decides the answer |
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

A page of tables becomes the whole instance:

```console
$ pol-bank catalogue/corpus.md example/corpus.extras.pol > example/corpus.pol
```

**Why Markdown.** A catalogue is a curated knowledge base people argue about,
not a pipeline feed. It wants to render in a pull request, so a reviewer can
challenge "is `llm-classifier` really not reproducible?" without running
anything — and it wants prose. Tables carry the facts; every heading, paragraph
and `<!-- HTML comment -->` on the page is ignored, and a `notes` column
documents a row without entering the model.

**Columns are matched by name, not position.** Reorder them freely; add columns
the tools do not know about. A required column that goes missing is a fatal
error naming the column and the section, not a quietly wrong model — and
`run-tests.sh` reverses every column of the components table and asserts the
output is unchanged.

**Identifier columns must stay single tokens.** Values in `name`, `provides`,
`tech`, `within` and friends become *entity names* in the model, and Pol names
cannot contain spaces — so `apache-spark`, never `Apache Spark`. Slugifying and
keeping display labels outside the model would break the one property `pol-c4`
sells: that everything on the diagram is derived. Free text belongs in `notes`.

`run-tests.sh` asserts the committed model is **byte-identical** to what the
catalogue regenerates, so hand-editing generated output fails a test rather than
being discovered much later.

### `pol-assume` — the answer to "who could possibly verify this catalogue?"

This is the weakest joint in the whole idea, and it deserves stating plainly.
Everywhere else in the stack a mistake announces itself: a bad guard changes the
state count, a bad rule fails the cross-check, a bad claim fails to hold. **A
wrong catalogue cell fails nothing.** It produces a plausible model that proves
wrong things with exactly the confidence it would have had if the cell were
right. The catalogue is unfalsifiable input to a falsifying machine.

Asking anyone to verify every cell does not work — a real bank is hundreds of
claims and nobody will check them. But most of those claims *do not matter*:
flip them and every verdict is identical. So mark unconfirmed cells with a
trailing `?`, and let the tool find the few that decide anything:

```console
$ pol-assume catalogue/corpus.md example/corpus.claims example/corpus.extras.pol
ASSUMPTIONS THIS DESIGN STANDS ON

  33 unconfirmed claims in the catalogue.
  4 of them decide something. 29 do not.

LOAD-BEARING — confirm these before anyone builds from this design

  1. object-store.bulk = yes
     were it `no` instead:
       realisable LOST
       no-dead-end LOST
  3. llm-vision.persists = no
     were it `yes` instead:
       rerun-is-affordable gained
  4. direct-db.couples = tight
     were it `loose` instead:
       crm-stays-loose LOST
```

It flips each assumed cell, rebuilds, and asks `pol compare` whether any
property moved. **"Verify 33 claims" becomes "confirm these four"** — and the
four are computed, not guessed. Presentation columns are excluded by
construction rather than by choice: nothing in the library reads them, so no
flip of one could move a verdict.

Read it as an indictment of the worked example, too. This repository's headline
finding rests on two cells about `llm-vision` that were invented in seconds, and
the tool says so.

> **The bug worth knowing about.** The first version of this reported *"0 of
> them decide something"* — because every comparison had errored, and an error
> read as "no change". A tool that reports safety because it crashed is worse
> than no tool. A broken run is now fatal and loud, and `run-tests.sh` asserts
> it.

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
./run-tests.sh            # 62 checks over the five tools
./run-tests.sh list       # the individual tests
```

The tools are POSIX `sh` and `awk` — no runtime, no packages, nothing to
install beyond `pol` itself.

## What this does not claim

**The catalogue is the project, and it is the weakest link.** The component
attributes in `catalogue/corpus.md` were written by hand as a demonstration —
every one is marked `?`, because every one is unverified. `pol` proves what
follows from them exhaustively, and will do so just as faithfully if they are
wrong. The rigour on offer is *internal consistency*, not truth.

`pol-assume` narrows that from fatal to manageable — it turns "verify
everything" into "confirm these four" — but it cannot tell you whether the four
are *true*. Only somebody who operates the system can, and no amount of tooling
substitutes for that.

**A catalogue is per-decision, not an encyclopedia.** The tempting reading of
`pol-bank` is that you should build a comprehensive bank of 150 components. Do
not: nobody can author or check that. The version that works is the eight to
twelve candidates a team would genuinely consider for *one* decision, written by
the people who will operate them. At that size every row is checkable, which is
the only size at which any of this is honest.

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
