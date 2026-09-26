# SPDX-License-Identifier: GPL-3.0-or-later
#
# atlas-chess: chess on the Atlas engine, built against an installed Atlas and nothing else.
#
# Configure with the Atlas SDK on CMAKE_PREFIX_PATH: the Atlas install prefix, and the vcpkg tree
# that Atlas was built with. The presets read both from the environment, as ATLAS_PREFIX and
# ATLAS_DEPS, which atlas-engine's `tools/sdk.py <preset>` prints. There is no vcpkg here: the
# third-party libraries are the ones Atlas was compiled against, by construction
# (atlas-engine docs/adr/0024-install-and-export.md, D9).
cmake_minimum_required(VERSION 3.28)
project(AtlasChess
    VERSION 0.1.0
    DESCRIPTION "Chess on the Atlas engine"
    HOMEPAGE_URL "https://github.com/happyc0der/atlas-chess"
    LANGUAGES CXX)

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(FATAL_ERROR
        "In-source builds are not supported. Use a preset: cmake --preset macos-debug")
endif()

option(CHESS_BUILD_TESTS "Build the tests and register them with CTest" ON)
option(CHESS_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
# Atlas is headers, not C++20 modules, and so is this. Left on, CMake scans every source for
# modules under Ninja with clang and needs clang-scan-deps to do it (ADR-0024 D9).
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

find_package(Atlas 0.27 REQUIRED COMPONENTS app)
message(STATUS "atlas-chess: Atlas ${Atlas_VERSION} from ${Atlas_DIR}")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(ChessBuild)

if(CHESS_BUILD_TESTS)
    # From the vcpkg tree beside the Atlas install, where it is because Atlas's manifest names it.
    find_package(Catch2 3 CONFIG REQUIRED)
    include(CTest)
    include(Catch)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)
endif()

add_subdirectory(sim)
add_subdirectory(view)
add_subdirectory(mod)

add_executable(atlas_chess src/main.cpp)
target_link_libraries(atlas_chess PRIVATE
    atlas::app_common atlas::app_lockstep atlas::app_mods
    chess::sim chess::view
    atlas::assets atlas::net atlas::platform atlas::renderer atlas::script atlas::rhi
    atlas::text atlas::tools)
set_target_properties(atlas_chess PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
chess_set_options(atlas_chess)
chess_copy_runtime_dlls(atlas_chess)
# Where the engine's own data is: the installed Atlas's share/atlas (ADR-0024 D8). Baked in as an
# absolute path, so this binary finds it only while that SDK is where it was built against.
target_compile_definitions(atlas_chess PRIVATE
    "ATLAS_CHESS_SHADER_DIR=\"${Atlas_DATA_DIR}/shaders\""
    "ATLAS_CHESS_ENGINE_STRINGS_DIR=\"${Atlas_DATA_DIR}/strings\"")

if(CHESS_BUILD_TESTS)
    add_subdirectory(tests)
endif()
