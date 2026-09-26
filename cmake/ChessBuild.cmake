# SPDX-License-Identifier: GPL-3.0-or-later
#
# How chess is compiled: its warnings, its determinism flags, its tests.
#
# A copy of what atlas-engine's cmake/CompilerWarnings.cmake and cmake/AtlasModule.cmake do for the
# engine's own targets, taken at atlas-engine 249d66575897 (M27). An installed Atlas carries its
# usage requirements — include paths, the language standard, MSVC's /std:c++latest — but not the
# flags it compiles itself with, and two of them matter here for more than style:
#
#   -ffp-contract=off / /fp:precise  No fused multiply-add. Chess's state is integers, so nothing
#                                    it hashes depends on this today; a game with a float in its
#                                    state would diverge between arm64 and x86_64 without it
#                                    (atlas-engine docs/DETERMINISM.md). A rule of the SDK's
#                                    contract (ADR-0024 D9), which the package states and does
#                                    not impose.
#   -Werror / /WX                    Warnings are errors here as there.
#
# The two may drift. Each is checked against its own code.

include(CheckCXXCompilerFlag)
check_cxx_compiler_flag(-Wno-missing-designated-field-initializers
                        CHESS_HAS_NO_MISSING_DESIGNATED_FIELD_INIT)

function(chess_set_options target)
    set_target_properties(${target} PROPERTIES
        CXX_STANDARD 23
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF)
    if(MSVC)
        target_compile_options(${target} PRIVATE
            /W4 /permissive- /utf-8 /Zc:__cplusplus /Zc:preprocessor /EHsc
            /w14062 /w14265 /w14640 /w14826 /w14905 /w14906 /w14928
            /fp:precise)
        if(CHESS_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE /WX)
        endif()
        target_compile_definitions(${target} PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN UNICODE _UNICODE)
    else()
        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wsign-conversion -Wnon-virtual-dtor
            -Wold-style-cast -Wcast-align -Woverloaded-virtual -Wnull-dereference
            -Wdouble-promotion -Wformat=2 -Wimplicit-fallthrough -Wextra-semi
            -ffp-contract=off
            $<$<CONFIG:Debug,RelWithDebInfo>:-fno-omit-frame-pointer>)
        if(CHESS_HAS_NO_MISSING_DESIGNATED_FIELD_INIT)
            target_compile_options(${target} PRIVATE -Wno-missing-designated-field-initializers)
        endif()
        if(CHESS_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE -Werror)
        endif()
    endif()
    # Atlas's platform and rhi both link SDL3 privately, so it appears twice on a link line, and
    # Apple's linker says so while ignoring it. Nothing to fix.
    if(APPLE)
        target_link_options(${target} PRIVATE -Wl,-no_warn_duplicate_libraries)
    endif()
endfunction()

# On the Windows triplet SDL3 and its neighbours are DLLs, and an executable finds them beside
# itself. Everywhere else every library is static and the list is empty, which `cmake -E true`
# absorbs rather than leaving copy_if_different with nothing to copy.
function(chess_copy_runtime_dlls target)
    if(WIN32)
        add_custom_command(TARGET ${target} POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E
                    $<IF:$<BOOL:$<TARGET_RUNTIME_DLLS:${target}>>,copy_if_different,true>
                    $<TARGET_RUNTIME_DLLS:${target}> $<TARGET_FILE_DIR:${target}>
            COMMAND_EXPAND_LISTS)
    endif()
endfunction()

# A library of chess's own: chess_<name>, aliased chess::<name>, headers under include/.
function(chess_add_library name)
    cmake_parse_arguments(ARG "" "" "SOURCES;DEPENDS" ${ARGN})
    add_library(chess_${name} STATIC ${ARG_SOURCES})
    add_library(chess::${name} ALIAS chess_${name})
    target_include_directories(chess_${name}
        PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
        PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
    target_link_libraries(chess_${name} PUBLIC ${ARG_DEPENDS})
    chess_set_options(chess_${name})
endfunction()

# A Catch2 test executable. Discovered when the tests run rather than when they build, because a
# freshly linked binary may not be runnable at build time on Apple Silicon; run from the project
# root, so a relative asset path means what it means when the binary is run by hand.
function(chess_add_test name)
    cmake_parse_arguments(ARG "" "" "SOURCES;DEPENDS;INCLUDE_DIRS;LABELS" ${ARGN})
    if(NOT CHESS_BUILD_TESTS)
        return()
    endif()
    set(target chess_test_${name})
    add_executable(${target} ${ARG_SOURCES})
    target_link_libraries(${target} PRIVATE Catch2::Catch2WithMain ${ARG_DEPENDS})
    target_include_directories(${target} PRIVATE ${ARG_INCLUDE_DIRS})
    chess_set_options(${target})
    chess_copy_runtime_dlls(${target})
    if(NOT ARG_LABELS)
        set(ARG_LABELS unit)
    endif()
    catch_discover_tests(${target}
        DISCOVERY_MODE PRE_TEST
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTIES LABELS "${ARG_LABELS}")
endfunction()
