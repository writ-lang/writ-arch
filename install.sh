#!/bin/sh
# Copyright (C) 2026 Alex Kunich
# SPDX-License-Identifier: AGPL-3.0-or-later
# Install the four tools and the domain library. Plain cp; nothing to build.
#   ./install.sh [PREFIX]      default ~/.local
set -eu
prefix=${1:-$HOME/.local}
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$prefix/bin" "$prefix/share/pol/lib"
for t in pol-bank pol-assume pol-interview pol-c4 pol-adr; do
  cp "$here/bin/$t" "$prefix/bin/$t"; chmod +x "$prefix/bin/$t"
done
cp "$here/lib/arch.lib.pol" "$prefix/share/pol/lib/arch.lib.pol"
echo "installed to $prefix"
echo "  bin: pol-bank pol-assume pol-interview pol-c4 pol-adr"
echo "  lib: arch.lib.pol   (pol's resolver searches \$POL_LIB and the copy beside the binary)"
command -v pol >/dev/null 2>&1 || echo "  note: pol is not on PATH — install it first: github.com/sajonaro/pol"
