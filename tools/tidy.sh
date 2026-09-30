#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Run clang-tidy over chess's C++ using a preset's compile_commands.json.
#
#   tools/tidy.sh [preset]     default preset: macos-debug
#
# A copy of atlas-engine's tools/tidy.sh (M32), cut down to this repository's layout. The engine's
# headers come from the SDK and are not analysed here: .clang-tidy's header filter names chess's
# own headers only, and they are analysed where they are.
#
# Not analysed: the opponent's C in mod/ (mod/*.c, mod/rules.h, sim/include/atlas/chess/mod_view.h).
# It is freestanding C compiled to WebAssembly, as the engine's own mods are, and the engine does
# not analyse those either; DEFERRED.md records it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

PRESET="${1:-macos-debug}"
BUILD_DIR="${REPO_ROOT}/build/${PRESET}"
COMPILE_DB="${BUILD_DIR}/compile_commands.json"

if [[ ! -f "${COMPILE_DB}" ]]; then
    echo "error: ${COMPILE_DB} not found." >&2
    echo "  Configure first: cmake --preset ${PRESET}, with ATLAS_PREFIX and ATLAS_DEPS set" >&2
    exit 1
fi

find_tool() {
    local name="$1"
    if [[ -n "${ATLAS_CLANG_TIDY:-}" && "${name}" == "clang-tidy" ]]; then
        echo "${ATLAS_CLANG_TIDY}"
        return
    fi
    for candidate in \
        "/opt/homebrew/opt/llvm/bin/${name}" \
        "/usr/local/opt/llvm/bin/${name}" \
        "$(command -v "${name}" 2>/dev/null || true)"
    do
        if [[ -n "${candidate}" && -x "${candidate}" ]]; then
            echo "${candidate}"
            return
        fi
    done
    echo ""
}

CLANG_TIDY_BIN="$(find_tool clang-tidy)"
if [[ -z "${CLANG_TIDY_BIN}" ]]; then
    echo "error: clang-tidy not found. Install LLVM, or set ATLAS_CLANG_TIDY." >&2
    exit 1
fi

# The wrapper must match the binary it drives: a version 19 run-clang-tidy driving a version 23
# clang-tidy once resolved the configuration to nothing and reported "No checks enabled" in the
# engine — a linter that passes by doing nothing. So the wrapper is the chosen clang-tidy's
# sibling, and without one this analyses a file at a time.
RUN_CLANG_TIDY_BIN=""
if [[ -n "${ATLAS_RUN_CLANG_TIDY:-}" ]]; then
    RUN_CLANG_TIDY_BIN="${ATLAS_RUN_CLANG_TIDY}"
elif [[ "${CLANG_TIDY_BIN}" =~ ^(.*/)?clang-tidy(-[0-9]+)?$ ]]; then
    sibling="$(dirname "${CLANG_TIDY_BIN}")/run-clang-tidy${BASH_REMATCH[2]:-}"
    if [[ -x "${sibling}" ]]; then
        RUN_CLANG_TIDY_BIN="${sibling}"
    fi
fi

if [[ -n "${RUN_CLANG_TIDY_BIN}" ]]; then
    echo "run-clang-tidy: ${RUN_CLANG_TIDY_BIN}"
else
    echo "run-clang-tidy: none matching ${CLANG_TIDY_BIN}; analysing one file at a time"
fi

# Homebrew's clang-tidy does not know where Apple's SDK lives, and without it a parse fails and
# reports a flood of cascading false positives rather than an honest error.
RUN_EXTRA_ARGS=()
TIDY_EXTRA_ARGS=()
if [[ "$(uname -s)" == "Darwin" ]]; then
    SDK_PATH="$(xcrun --show-sdk-path 2>/dev/null || true)"
    if [[ -n "${SDK_PATH}" ]]; then
        RUN_EXTRA_ARGS+=("-extra-arg=-isysroot" "-extra-arg=${SDK_PATH}")
        TIDY_EXTRA_ARGS+=("--extra-arg=-isysroot" "--extra-arg=${SDK_PATH}")
    fi
fi

# Two passes. Production sources take .clang-tidy; tests take tools/clang-tidy-tests.yml, which
# inherits it, switches off the checks a test framework makes meaningless, and widens the header
# filter to the headers only tests include.
PRODUCTION_FILES=()
while IFS= read -r file; do
    [[ -n "${file}" ]] && PRODUCTION_FILES+=("${file}")
done < <(
    find "${REPO_ROOT}/sim/src" "${REPO_ROOT}/view/src" "${REPO_ROOT}/src" \
         -type f -name '*.cpp' 2>/dev/null | sort
)

TEST_FILES=()
while IFS= read -r file; do
    [[ -n "${file}" ]] && TEST_FILES+=("${file}")
done < <(
    find "${REPO_ROOT}/sim/tests" "${REPO_ROOT}/view/tests" "${REPO_ROOT}/mod/tests" \
         -type f -name '*.cpp' 2>/dev/null | sort
)

echo "clang-tidy: $("${CLANG_TIDY_BIN}" --version | grep -m1 -i 'version')"
echo "analysing ${#PRODUCTION_FILES[@]} production and ${#TEST_FILES[@]} test file(s) from preset '${PRESET}'"

# analyse <config-file-or-empty> <file>...
analyse() {
    local config="$1"
    shift
    [[ $# -eq 0 ]] && return 0

    local config_args=()
    [[ -n "${config}" ]] && config_args+=("-config-file=${config}")

    # ${a[@]+"${a[@]}"}: under `set -u`, macOS's bash 3.2 treats an empty array as unbound.
    if [[ -n "${RUN_CLANG_TIDY_BIN}" ]]; then
        "${RUN_CLANG_TIDY_BIN}" \
            -p "${BUILD_DIR}" \
            -clang-tidy-binary "${CLANG_TIDY_BIN}" \
            -quiet \
            ${config_args[@]+"${config_args[@]}"} \
            ${RUN_EXTRA_ARGS[@]+"${RUN_EXTRA_ARGS[@]}"} \
            "$@"
    else
        local file
        for file in "$@"; do
            "${CLANG_TIDY_BIN}" -p "${BUILD_DIR}" \
                ${config_args[@]+"${config_args[@]}"} \
                ${TIDY_EXTRA_ARGS[@]+"${TIDY_EXTRA_ARGS[@]}"} "${file}"
        done
    fi
}

analyse "" "${PRODUCTION_FILES[@]}"
analyse "${REPO_ROOT}/tools/clang-tidy-tests.yml" "${TEST_FILES[@]}"

# A source with no compile command is passed and skipped, silently, with the exit code of a clean
# run. Say so rather than pass by doing nothing.
uncovered=0
for file in "${PRODUCTION_FILES[@]}" "${TEST_FILES[@]}"; do
    if ! grep -qF "${file}" "${COMPILE_DB}"; then
        echo "not analysed, no compile command: ${file#"${REPO_ROOT}"/}"
        uncovered=$((uncovered + 1))
    fi
done
if [[ "${uncovered}" -gt 0 ]]; then
    echo "clang-tidy: ${uncovered} source(s) were not analysed" >&2
    exit 1
fi
echo "clang-tidy clean"
