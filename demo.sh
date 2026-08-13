#!/bin/sh
# Copyright (C) 2026 Alex Kunich
# SPDX-License-Identifier: AGPL-3.0-or-later
# demo.sh — the whole pipeline, end to end, on the worked example.
#
# A brief in prose becomes a catalogue; the catalogue becomes a model; the model
# is enumerated and proved; and the proof becomes questions, a diagram and
# decision records. Every artifact after stage 1 is derived — nothing below is
# written by a human except the catalogue itself.
#
# Usage:  ./demo.sh          `pol` on PATH; `d2` optional, for the SVG.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
POL_LIB=$here/lib; export POL_LIB
cd "$here"

CAT=catalogue/corpus.md
M=example/corpus.pol
C=example/corpus.claims
R=example/corpus.rules
X=example/corpus.extras.pol

step() { printf '\n\033[1m━━━ %s ━━━\033[0m\n\n' "$1"; }

step "0.  THE INPUT — a brief, and the parts we are willing to consider"
sed -n '3,5p' "$CAT"
printf '\ncomponents offered: %s   stages to fill: %s\n' \
  "$(awk '/^## Components/,/^## Flows/' "$CAT" | grep -c '^| [a-z]' )" \
  "$(awk '/^## Stages/,/^## Components/' "$CAT" | grep -c '^| [a-z]')"
echo
echo "a few rows of the catalogue — note the \`?\`, meaning nobody has confirmed this:"
awk '/^## Components/,/^## Flows/' "$CAT" | grep '^| \(object-store\|llm-vision\|direct-db\) ' \
  | cut -c1-110 | sed 's/^/  /'

step "1.  pol-bank — the catalogue becomes a model"
./bin/pol-bank "$CAT" "$X" > "$M"
printf 'wrote %s\n' "$M"
printf '  %s arrow-value pairs, %s span junctions, %s moves — none of it typed by hand\n' \
  "$(grep -oE '\([a-z0-9-]+ [a-z0-9-]+\)' "$M" | wc -l | tr -d ' ')" \
  "$(grep -oE '\b[pr]-[a-z0-9-]+\b' "$M" | sort -u | wc -l | tr -d ' ')" \
  "$(grep -c '^(pick' "$M" | tr -d ' ')"

step "2.  pol check — enumerate every architecture the constraints permit"
pol check "$M" --claims "$C" 2>&1 | grep -v 'reached by' || true

step "3.  pol-interview — what the brief failed to say"
./bin/pol-interview "$M" --claims "$C"

step "4.  pol-assume — which unconfirmed facts is this standing on?"
./bin/pol-assume "$CAT" "$C" "$X"

step "5.  pol-c4 — one design, drawn"
S=$(pol derive "$M" "$R" finished 2>/dev/null | awk 'NR>1{print $1; exit}')
echo "drawing finished design #$S (of $(pol derive "$M" "$R" finished 2>/dev/null | awk 'NR==1{print $2}' | tr -d '(') total)"
echo
./bin/pol-c4 "$M" "$R" "$S" --level container | sed -n '/^platform:/,$p' | head -24
if command -v d2 >/dev/null 2>&1; then
  mkdir -p example/out
  ./bin/pol-c4 "$M" "$R" "$S" --level container --svg example/out/container-$S.svg >/dev/null
  ./bin/pol-c4 "$M" "$R" "$S" --level context   --svg example/out/context-$S.svg   >/dev/null
  printf '\nrendered: example/out/container-%s.svg  example/out/context-%s.svg\n' "$S" "$S"
fi

step "6.  pol-adr — why this part, and what was rejected"
./bin/pol-adr "$M" "$R" "$S" | sed -n '/^## 1\./,/^## 3\./p' | head -30

step "DONE"
N=$(./bin/pol-assume "$CAT" "$C" "$X" | awk '/decide something/ {print $1; exit}')
cat <<EOF
Everything from stage 2 onward was derived; the only human input was the
catalogue. Stage 4 narrowed it to the $N claims that actually decide the answer —
the shortest honest to-do list this process can produce. It cannot tell you
whether those $N are TRUE. Only somebody who operates the system can.
EOF
