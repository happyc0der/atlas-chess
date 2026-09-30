<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Deferred

Everything consciously not built, with the reason and what would have to become true for it to be
worth doing. The entries made while chess lived in atlas-engine (M18 to M26) are recorded there,
in its `docs/DEFERRED.md`, as they were made; they are carried on here in brief, and a change to
one is made here.

## Carried from atlas-engine

**The rules.**
- **The claimable draws.** The fifty-move rule and threefold repetition end the game
  automatically; chess lets a player claim them, and forces them at seventy-five moves or
  fivefold. Trigger: a person asking to play on.
- **Resignation and a draw by agreement.** Each a second command type and a small interface
  question — who may offer, when it lapses. Trigger: a person playing who wants either.
- **Standard algebraic notation, and PGN.** The library reads and writes coordinates and FEN.
  Trigger: importing games from outside.
- **A deeper perft in CI.** The tests run the published positions to depths a debug build
  finishes quickly. Trigger: a generation bug the shallow depths miss.

**The application.**
- **Choosing a promotion by click.** A clicked promotion is a queen; `--moves` can name any piece.
  Trigger: somebody wanting a knight.
- **Undo, takeback and a move list; clocks, an opening book, a rating.** A takeback over a socket
  is an agreement between players, which is a protocol of its own. Trigger: a person who wants
  them.
- **Saving and loading a game.** There is neither, so the check that a save naming the mod loads
  only with the mod attached (atlas-engine ADR-0023 D6) has no call site; the table rule is proved
  in a test. Trigger: a person who wants to keep a game.
- **A dropped player's side.** The engine can drop a peer (ADR-0022); with two players chess has
  nobody to play on with and ends the session. Trigger: a variant with more than two sides.

**The opponent.**
- **Over a socket.** `--mod` plays a local game. Trigger: a person who wants to share or watch a
  game against the mod from another machine.
- **Saving mid-search.** A save does not hold the mod's memory, so a game saved while it thinks
  resumes its search at a different tick. Trigger: saving at arbitrary ticks with the mod playing.
- **A stronger search.** Two plies on material; no quiescence, move ordering, transposition table,
  or repetition awareness. Trigger: a person who finds it too easy, and a measurement first.
- **An incremental position update.** Copy-make is enough for two plies at 1.16 M instructions in
  the worst tick measured. Trigger: a deeper search, in the mod.
- **Behaviour compared on macOS and Windows.** Only the Linux lanes install LLVM 23, so only they
  rebuild the opponent and play it against the committed module. Trigger: a difference between
  platforms in how a module plays.

## M27 — out of the engine's tree

- **A benchmark.** `bench_chess` depended on atlas-engine's benchmark harness, which is not
  installed; its M22 numbers stay in atlas-engine's `docs/PERFORMANCE.md`. Trigger: a change here
  whose cost matters, which needs a harness first.
- **Sanitizer lanes.** A sanitizer build of Atlas refuses to install (ADR-0024 D7), and a
  sanitized chess over an uninstrumented engine would report only half of anything. Trigger: a
  race or a memory error suspected in chess itself.
- ~~**clang-tidy.**~~ **Runs since M32**, by the trigger this entry named: the first change larger
  than a pin move. `tools/tidy.sh` and a CI job analyse the C++ with clang-tidy 23. The copied
  configuration's header filter named the engine's headers, so no chess header had ever been
  analysed; it now names chess's own. The first run found five things: one in a header, four in
  tests, all fixed. The original text follows. The configuration is copied and nothing runs it;
  formatting is checked.
- **The opponent's C is not analysed**: `mod/*.c`, `mod/rules.h` and
  `sim/include/atlas/chess/mod_view.h`. It is freestanding C compiled to WebAssembly, and
  atlas-engine does not analyse its own mods either; the rules are checked by perft and against
  `chess_sim` instead. Trigger: a bug in the opponent that analysis would have found.
- **A relocatable data path.** The engine's shaders and strings are found by an absolute path baked
  in at configure, so a binary works only beside the SDK it was built against. Trigger: shipping
  a binary to another machine.
- **The integration harness is a copy** of atlas-engine's `tests/integration/harness.py`, taken at
  M27. Trigger: the two drifting in a way that matters, which would argue for installing it.
