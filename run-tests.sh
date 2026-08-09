#!/bin/sh
# End-to-end tests for the four tools: a catalogue becomes a model, the model
# is checked, and the answers become diagrams, questions and decision records.
#
# The oracle for most of these is the model itself — a diagram assertion checks
# that a box `pol derive` produced reached the D2, never that a particular
# architecture is good. The one test with a real oracle is `regen`: the
# committed model must be byte-identical to what the catalogue regenerates, so
# a hand-edit of generated output is a failure rather than a surprise later.
#
# Usage:  run-tests.sh [NAME | all | list]      `pol` is taken from $POL.
set -u

here=$(cd "$(dirname "$0")" && pwd)
POL=${POL:-pol}
POL_LIB=$here/lib
export POL_LIB
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf '  [ok]   %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  [FAIL] %s\n' "$1"; }
has() { if printf '%s\n' "$2" | grep -qF "$3"; then ok "$1"; else bad "$1 — missing: $3"; fi; }
lacks() { if printf '%s\n' "$2" | grep -qF "$3"; then bad "$1 — unexpected: $3"; else ok "$1"; fi; }
exit_is() { if [ "$2" = "$3" ]; then ok "$1 (exit $3)"; else bad "$1 — exit $2, want $3"; fi; }

M=$here/example/corpus.pol
C=$here/example/corpus.claims
R=$here/example/corpus.rules

bank() {
  echo "== pol-bank — a catalogue of parts becomes a model =="
  echo "   Q: can 40 lines of table become the ~180 datums a bank needs?"
  out=$(POL_BANK_SRC=catalogue/corpus "$here/bin/pol-bank" "$here/catalogue/corpus" \
    "$here/example/corpus.extras.pol" 2>&1)
  st=$?
  exit_is "bank: generates cleanly" "$st" 0
  has "bank: one span junction per (part, stage)" "$out" "p-object-store-hold"
  has "bank: and per (part, dependency)" "$out" "r-crm-api-catalog"
  has "bank: one pick move per part" "$out" "(pick extract-ocr-service ocr-service extract rr)"
  has "bank: technology roster collected from the rows" "$out" "(technology s3"
  has "bank: boundary roster too" "$out" "(boundary platform processing serving crm)"
  n=$(printf '%s\n' "$out" | grep -c '^(pick ')
  if [ "$n" -eq 19 ]; then ok "bank: 19 parts, 19 moves"; else bad "bank: expected 19 pick moves, got $n"; fi
}

regen() {
  echo "== The committed model is GENERATED, and stays that way =="
  echo "   Q: has anyone hand-edited output that a catalogue owns?"
  tmp=$(mktemp)
  POL_BANK_SRC=catalogue/corpus "$here/bin/pol-bank" "$here/catalogue/corpus" \
    "$here/example/corpus.extras.pol" >"$tmp" 2>/dev/null
  if diff -q "$tmp" "$M" >/dev/null 2>&1; then
    ok "regen: corpus.pol is byte-identical to what the catalogue produces"
  else
    bad "regen: corpus.pol has drifted from catalogue/corpus — re-run pol-bank"
    diff "$M" "$tmp" | head -10 | sed 's/^/     | /'
  fi
  rm -f "$tmp"
}

check() {
  echo "== The generated model, checked =="
  echo "   Q: which architectures satisfy the brief, and what does it not say?"
  out=$("$POL" check "$M" --claims "$C" 2>&1)
  st=$?
  printf '%s\n' "$out" | grep -v 'reached by' | sed 's/^/     | /'
  exit_is "check: reports findings" "$st" 1
  # 184 = the prefixes of 96 designs. It is also EXACTLY what the same model
  # scores without any of the C4 presentation arrows, which is the point: they
  # are all `fixed`, and a design space is the product of the MUTABLE cells.
  has "check: 184 situations — presentation fields cost nothing" "$out" "states: 184"
  has "check: 96 architectures satisfy the brief" "$out" "dead ends: 96"
  has "check: one of them can be realised" "$out" "holds  realisable"
  has "check: no partial choice strands the build" "$out" "holds  no-dead-end"
  has "check: the brief is silent somewhere" "$out" "gaps: 1"
  has "check: re-runnable classification is not affordable everywhere" "$out" "fails  rerun-is-affordable"
  has "check: the CRM is never coupled at the database" "$out" "holds  crm-stays-loose"
}

c4() {
  echo "== pol-c4 — a design becomes a C4 diagram =="
  echo "   Q: does every box and arrow come out of the model?"
  out=$("$here/bin/pol-c4" "$M" "$R" 183 --level container 2>&1)
  st=$?
  exit_is "c4: container level emits" "$st" 0
  has "c4: parts are grouped by their boundary" "$out" "platform: \"platform\" {"
  has "c4: a box carries stage, part and technology" "$out" "enumerate\\ndb-index\\n[postgres]"
  has "c4: the external CRM is drawn differently" "$out" "style.stroke-dash: 3"
  has "c4: actors appear as people" "$out" "shape: person"
  # THE POINT of a separate flow span: the catalogue fans out to serving AND to
  # the CRM. The build ladder is a chain and would have drawn serve-ai -> surface.
  has "c4: runtime flow, not the build ladder — catalog to serving" "$out" \
    "platform.catalog -> serving.serve_ai: \"batch\""
  has "c4:    ...and catalog to the CRM, which the ladder does not have" "$out" \
    "platform.catalog -> crm.surface: \"api\""
  lacks "c4:    the ladder's serve-ai -> surface edge is absent" "$out" \
    "serving.serve_ai -> crm.surface"

  ctx=$("$here/bin/pol-c4" "$M" "$R" 183 --level context 2>&1)
  has "c4: context level collapses us to one system" "$ctx" "system: \"The system\""
  has "c4:    and keeps the external system separate" "$ctx" "system -> surface: \"api\""

  bad_out=$("$here/bin/pol-c4" "$M" "$R" 0 --level container 2>&1)
  bst=$?
  exit_is "c4: an unfinished state is refused, not half-drawn" "$bst" 1
  has "c4:    and it says how to find a finished one" "$bad_out" "derive"

  if command -v d2 >/dev/null 2>&1; then
    if "$here/bin/pol-c4" "$M" "$R" 183 --level container --svg "$here/example/out/container-183.svg" >/dev/null 2>&1 &&
       "$here/bin/pol-c4" "$M" "$R" 183 --level context --svg "$here/example/out/context-183.svg" >/dev/null 2>&1; then
      ok "c4: d2 renders both levels to SVG"
    else bad "c4: d2 failed to render"; fi
  else
    printf '  [skip] c4: d2 not installed — SVG rendering not exercised\n'
  fi
}

interview() {
  echo "== pol-interview — findings become questions for the author of the brief =="
  echo "   Q: what did the brief fail to say, and where does it contradict itself?"
  out=$("$here/bin/pol-interview" "$M" --claims "$C" 2>&1)
  printf '%s\n' "$out" | sed 's/^/     | /'
  has "interview: it counts what it answered and what it asks" "$out" "It raises 2 for you"
  has "interview: A. the open question is the gap's own words" "$out" "digital-native or scanned"
  has "interview:    named, and placed in the space" "$out" "reachable in 2 moves"
  has "interview: B. the contradiction reads as the brief wrote it" "$out" \
    "re-runnable classification implies persisted text"
  # The witness is a ROUTE. Truncating it to the first move names a storage
  # choice and reads as nonsense; the whole path is what identifies the design.
  has "interview:    with the WHOLE counterexample route" "$out" "extract-llm-vision"
  has "interview:    through to the move that exposes it" "$out" "classify-rules-engine"
  has "interview:    and it asks which way to resolve it" "$out" "relax the"
}

adr() {
  echo "== pol-adr — the design becomes decision records that cannot drift =="
  echo "   Q: why this part, and what was rejected on which requirement?"
  out=$("$here/bin/pol-adr" "$M" "$R" 183 2>&1)
  st=$?
  exit_is "adr: emits" "$st" 0
  has "adr: the decision carries technology and boundary" "$out" \
    "\`object-store\` [s3], a container in the \`platform\` boundary"
  has "adr: A. a rejection names the requirement it failed" "$out" \
    "cannot survive the data volume"
  has "adr:    scanned pages exclude a plain PDF library" "$out" "cannot read scanned pages"
  has "adr:    reproducibility excludes the LLM classifier" "$out" "not reproducible across runs"
  has "adr:    and coupling excludes the direct database link" "$out" "couples too tightly"
  has "adr: B. each record carries its proof" "$out" "blueprint 183 hold object-store"
}

scenarios="bank regen check c4 interview adr"
case "${1:-all}" in
list) echo "$scenarios" | tr ' ' '\n' ;;
all) n=0; for s in $scenarios; do [ "$n" = 0 ] || echo; "$s"; n=1; done ;;
*) case " $scenarios " in *" $1 "*) "$1" ;; *) echo "unknown test: $1" >&2; exit 2 ;; esac ;;
esac

echo
echo "-------- $pass checks passed, $fail failed --------"
[ "$fail" -eq 0 ]
