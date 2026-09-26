# SPDX-License-Identifier: GPL-3.0-or-later
#
# chess::view — a position as quads. It creates nothing on a device: the application owns the
# batcher and the texture and hands this library a place to write, so every test of what the
# board looks like runs without a graphics device.
chess_add_library(view
    SOURCES
        src/board_layout.cpp
        src/board_quads.cpp
    DEPENDS
        chess::sim
        atlas::renderer
        atlas::math
)

if(CHESS_BUILD_TESTS)
    add_subdirectory(tests)
endif()
