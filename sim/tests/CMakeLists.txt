# SPDX-License-Identifier: GPL-3.0-or-later
chess_add_test(sim
    SOURCES
        test_tables.cpp
        test_world.cpp
        test_position.cpp
        test_fen.cpp
        test_perft.cpp
        test_rules.cpp
        test_golden.cpp
        test_mod_views.cpp
    DEPENDS
        chess::sim
    LABELS
        "unit;determinism"
)
