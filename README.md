# atlas-chess

Chess on the [Atlas](https://github.com/happyc0der/atlas-engine) engine, built against an
installed Atlas and nothing else.

It is the first game built outside the engine's own tree. Atlas's charter declares v1.0 when *"a
game project links the engine, loads data, and runs a deterministic simulation without patching
engine internals"*. This repository is that test. Chess was written inside the engine's tree from
M18 to M26 as a probe (atlas-engine ADR-0018), and moved here in M27 once the engine could be
installed as a package (ADR-0024). Its history up to the move is in atlas-engine; the first commit
here names the engine commit it came from.

## What it is

- **Every rule**, draws included: castling, en passant, promotion, check, checkmate, stalemate, the
  fifty-move rule, threefold repetition and insufficient material. The move generator is checked
  against the published perft counts, and the Opera Game's final position is a golden hash.
- **A board in a window**, two people at one screen, or two processes over a socket in lockstep.
  Both sides finish the session where the game ends.
- **An opponent that is a sandboxed mod**: freestanding C compiled to WebAssembly, with its own
  rules and a two-ply search that does a fixed amount of work per tick.

The rules library, `chess::sim`, may link only `atlas::simulation`, and the build checks it.

## Building

It needs an **Atlas SDK**: the engine's install prefix, and the vcpkg tree the engine was built
with. The commit it is built against is pinned in `atlas.ref`.

With atlas-engine cloned beside this repository:

```sh
git clone --recurse-submodules https://github.com/happyc0der/atlas-engine atlas
cd atlas
git checkout "$(cat ../atlas-chess/atlas.ref)" && git submodule update
./external/vcpkg/bootstrap-vcpkg.sh -disableMetrics
cmake --preset macos-debug -DATLAS_BUILD_TESTS=OFF
cmake --build --preset macos-debug
eval "$(python3 tools/sdk.py macos-debug | sed 's/^/export /')"   # ATLAS_PREFIX, ATLAS_DEPS

cd ../atlas-chess
cmake --preset macos-debug
cmake --build --preset macos-debug
ctest --preset macos-debug
```

Replace `macos-debug` with `linux-clang-debug` or `windows-msvc-debug` for the other platforms;
the presets have the same names in both repositories. **The compiler, triplet and build type must
match the engine's**, and Atlas's package configuration stops the configure with the reason if
they do not. `sdk.py` prints the rules for the SDK it installed.

## Playing

```sh
./build/macos-debug/bin/atlas_chess                               # two people, one screen
./build/macos-debug/bin/atlas_chess --mod chess_opponent.wasm     # against the mod
./build/macos-debug/bin/atlas_chess --listen 7777                 # host a game as white...
./build/macos-debug/bin/atlas_chess --connect 127.0.0.1:7777      # ...and join it as black
./build/macos-debug/bin/atlas_chess --headless --moves e2e4,e7e5,g1f3
./build/macos-debug/bin/atlas_chess --version                     # names the engine commit
```

## Layout

| Path | What |
|---|---|
| `sim/` | `chess::sim`: tables, the move command, the rules, FEN, the views the mod reads |
| `view/` | `chess::view`: a position as quads, with no graphics device |
| `mod/` | the opponent in C, and its rules compiled natively for the tests |
| `src/` | `atlas_chess`, the composition root |
| `tests/integration/` | whole-program cases, run by CTest |
| `tools/gen_chess_textures.py` | the piece sheet's generator |
| `mods.json` | the mod list for Atlas's `build_mods.py` |
| `atlas.ref` | the atlas-engine commit this is built against |

**References to ADRs and milestones** (ADR-0018, M26 and so on) in comments and here are
atlas-engine's, under its `docs/adr/` and `docs/reports/`.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
