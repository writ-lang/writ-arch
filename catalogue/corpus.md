# Component catalogue — a 50TB document corpus

*The brief: 50TB of files, mostly PDFs. Classify them, configurably and
re-runnably. Make what they contain available to AI. Surface it in the CRM that
already exists.*

This file **is** the knowledge base. `pol-bank` reads the tables below and emits
a Pol model; nothing else about the architecture is written by hand. Prose like
this paragraph is ignored by the parser, so a catalogue can explain itself in
place and still be machine-read.

**Columns are matched by NAME, not position.** Reorder them freely, and add
columns the tools do not know about — a `notes` column is read by people and
skipped by `pol-bank`. An empty cell or `-` means *vacant*: no answer, which is
not the same as `no`.

**Identifier columns must be single tokens** (`kebab-case`). Values in `name`,
`provides`, `requires`, `tech`, `within`, `stage`, `actor` and the flow columns
become entity names in the model, and Pol names cannot contain spaces. Free text
belongs in `notes`, which never enters the model.

<!-- HTML comments work too, for a remark that should not render at all. -->

## Stages

The pipeline, in the order a *designer* fills it. Each `needs-` column is a
requirement from the brief, and each is answered by exactly one component
attribute in the next table.

| stage | next | needs-bulk | needs-scan | needs-rerun | needs-loose | notes |
|---|---|---|---|---|---|---|
| hold | enumerate | yes | no | no | no | 50TB has to physically live somewhere |
| enumerate | extract | yes | no | no | no | listing 50TB is itself a scale problem |
| extract | classify | no | yes | no | no | "mostly PDFs" — assume some are scanned |
| classify | catalog | no | no | yes | no | the brief says "be able to rerun" |
| catalog | serve-ai | no | no | no | no | queryable metadata |
| serve-ai | surface | no | no | no | no | "available for AI" |
| surface | done | no | no | no | yes | an EXISTING CRM — do not couple hard |
| done | - | no | no | no | no | terminal; a filled ladder has no move left |

## Components

The bank. `provides` and `requires` accept comma-separated lists.

Constraint columns (`bulk`, `scans`, `rerun`, `persists`, `couples`) decide what
may fill what. Presentation columns (`level`, `tech`, `external`, `within`) are
drawn by `pol-c4` and constrain nothing — they are `fixed` arrows and add no
situations at all.

| name | provides | requires | bulk | scans | rerun | persists | couples | level | tech | external | within | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| object-store | hold | - | yes? | - | - | yes? | - | container | s3 | no | platform | |
| nas | hold | - | no? | - | - | yes? | - | container | nfs | no | platform | will not take 50TB affordably |
| bucket-list | enumerate | - | no? | - | - | no? | - | component | sdk-list | no | platform | listing millions of keys is too slow |
| event-stream | enumerate | - | yes? | - | - | no? | - | container | kafka | no | platform | |
| db-index | enumerate | hold | yes? | - | - | yes? | - | container | postgres | no | platform | |
| pdf-lib | extract | - | - | no? | - | no? | - | component | pdfium | no | processing | digital-native PDFs only |
| ocr-service | extract | - | - | yes? | - | yes? | - | container | tesseract | no | processing | |
| llm-vision | extract | - | - | yes? | - | no? | - | container | vision-llm | no | processing | streams; keeps nothing |
| rules-engine | classify | - | - | - | yes? | yes? | - | component | drools | no | processing | |
| llm-classifier | classify | - | - | - | no? | yes? | - | container | chat-llm | no | processing | not reproducible without pinned model+params |
| ml-model | classify | - | - | - | yes? | yes? | - | container | sklearn | no | processing | |
| lakehouse | catalog | - | - | - | - | yes? | - | container | iceberg | no | platform | |
| rdbms | catalog | - | - | - | - | yes? | - | container | postgres | no | platform | |
| doc-store | catalog | - | - | - | - | yes? | - | container | opensearch | no | platform | |
| vector-index | serve-ai | extract | - | - | - | yes? | - | container | pgvector | no | serving | needs the text, not just the labels |
| dataset-export | serve-ai | catalog | - | - | - | yes? | - | component | parquet | no | serving | |
| crm-api | surface | catalog | - | - | - | no? | contract? | container | rest | yes | crm | |
| ipaas | surface | catalog | - | - | - | no? | loose? | container | mulesoft | yes | crm | |
| direct-db | surface | catalog | - | - | - | no? | tight? | container | jdbc | yes | crm | writing another system's tables |

## Flows

Where data moves **at run time** — which is not the order stages are filled.
`catalog` fans out to serving *and* to the CRM; the build ladder is a chain.
Drawing the ladder instead would give a diagram that was merely plausible.

| from | to | via | notes |
|---|---|---|---|
| hold | enumerate | batch | |
| enumerate | extract | stream | |
| extract | classify | stream | |
| classify | catalog | batch | |
| catalog | serve-ai | batch | |
| catalog | surface | api | the fan-out the ladder does not have |

## Actors

C4's context level draws people. An actor with no stage to drive is a brief that
forgot to say what the user actually does.

| actor | drives | notes |
|---|---|---|
| data-owner | hold | owns the 50TB |
| ml-engineer | serve-ai | consumes it for training |
| sales-user | surface | sees it in the CRM |
