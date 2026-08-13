#!/bin/sh
# Copyright (C) 2026 Alex Kunich
# SPDX-License-Identifier: AGPL-3.0-or-later
# Install the four tools and the domain library. Plain cp; nothing to build.
#   ./install.sh [PREFIX]      default ~/.local
set -eu
prefix=${1:-$HOME/.local}
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$prefix/bin" "$prefix/share/writ/lib"
for t in writ-bank writ-assume writ-interview writ-c4 writ-adr; do
  cp "$here/bin/$t" "$prefix/bin/$t"; chmod +x "$prefix/bin/$t"
done
cp "$here/lib/arch.lib.writ" "$prefix/share/writ/lib/arch.lib.writ"
echo "installed to $prefix"
echo "  bin: writ-bank writ-assume writ-interview writ-c4 writ-adr"
echo "  lib: arch.lib.writ   (writ's resolver searches \$WRIT_LIB and the copy beside the binary)"
command -v writ >/dev/null 2>&1 || echo "  note: writ is not on PATH — install it first: github.com/writ-lang/writ"
