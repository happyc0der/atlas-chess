# SPDX-License-Identifier: GPL-3.0-or-later
chess_add_test(mod
    SOURCES
        test_opponent_module.cpp
        test_rules.cpp
        test_opponent.cpp
    DEPENDS
        atlas::script
        atlas::simulation
        chess::sim
        chess_mod_rules
    INCLUDE_DIRS
        # The rules library's test harness, beside this test.
        "${CMAKE_CURRENT_SOURCE_DIR}/../../sim/tests"
    LABELS
        "unit"
)
