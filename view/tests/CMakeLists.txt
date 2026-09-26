# SPDX-License-Identifier: GPL-3.0-or-later
chess_add_test(view
    SOURCES
        test_board_layout.cpp
        test_board_quads.cpp
    DEPENDS
        chess::view
    LABELS
        "unit"
)
