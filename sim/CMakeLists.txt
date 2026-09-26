# SPDX-License-Identifier: GPL-3.0-or-later
#
# chess::sim — the whole of chess as simulation state and one command, and nothing else: no
# window, no socket, no text. It links atlas::simulation and that is checked below rather than
# trusted, for the reason atlas-engine's ADR-0018 D3 gives: the rules of chess reach the engine
# through its simulation contract and nothing else, which is the claim this game exists to test.
chess_add_library(sim
    SOURCES
        src/tables.cpp
        src/world.cpp
        src/position.cpp
        src/fen.cpp
        src/rules.cpp
        src/mod_views.cpp
    DEPENDS
        atlas::simulation
)

get_target_property(_chess_sim_links chess_sim LINK_LIBRARIES)
foreach(item IN LISTS _chess_sim_links)
    if(item MATCHES "^atlas::" AND NOT item STREQUAL "atlas::simulation")
        message(FATAL_ERROR
            "chess_sim may link only atlas::simulation; it links ${item}. The rules of chess "
            "reach the engine through its simulation contract and nothing else (ADR-0018 D3).")
    endif()
endforeach()

if(CHESS_BUILD_TESTS)
    add_subdirectory(tests)
endif()
