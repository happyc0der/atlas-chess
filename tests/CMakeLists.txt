# SPDX-License-Identifier: GPL-3.0-or-later
#
# The whole program: real games, whose final positions are facts about chess, played through the
# application's own command line; and the checks that keep the committed assets current.
set(_chess_checks "${CMAKE_CURRENT_SOURCE_DIR}/integration/chess_checks.py")
set(_chess_cases
    version
    help
    scholars_mate
    loyds_stalemate
    threefold_repetition
    declined_move_stops_the_script
    move_after_the_end_is_declined
    fen_is_validated
    same_game_same_hash
    text_check
    engine_data_dir
    # Two processes over a real socket.
    socket_game_to_checkmate
    socket_partner_leaving_ends_the_game
    socket_sides_must_start_alike
    # The chess opponent, a sandboxed mod written in C.
    mod_plays_itself_to_the_end
    mod_answers_a_person
    mod_options_are_checked
)
foreach(case IN LISTS _chess_cases)
    add_test(NAME "chess_${case}"
             COMMAND "${Python3_EXECUTABLE}" "${_chess_checks}"
                     --binary "$<TARGET_FILE:atlas_chess>" --case "${case}")
    set_tests_properties("chess_${case}" PROPERTIES
        LABELS "integration" WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
endforeach()

# Under SDL's dummy video driver: a window, and nothing on a screen.
foreach(case IN ITEMS window_under_dummy_driver mod_plays_in_a_window)
    add_test(NAME "chess_${case}"
             COMMAND "${Python3_EXECUTABLE}" "${_chess_checks}"
                     --binary "$<TARGET_FILE:atlas_chess>" --case "${case}")
    set_tests_properties("chess_${case}" PROPERTIES
        LABELS "display;integration" WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
endforeach()

# The piece sheet against its generator, byte for byte: the PNG carries no compressed data.
add_test(NAME chess_textures_current
         COMMAND "${Python3_EXECUTABLE}"
                 "${PROJECT_SOURCE_DIR}/tools/gen_chess_textures.py" --check)
set_tests_properties(chess_textures_current PROPERTIES LABELS "lint")

# The opponent against its manifest, with the installed Atlas's own build_mods.py and the
# atlas_mod.h in its include directory (ADR-0023, ADR-0024 D8): inputs and module always, bytes
# where the toolchain is the manifest's, and the game it plays wherever a toolchain exists.
add_test(NAME chess_mods_built_current
         COMMAND "${Python3_EXECUTABLE}" "${Atlas_DATA_DIR}/tools/build_mods.py"
                 --mods mods.json --root "${PROJECT_SOURCE_DIR}" --check
                 "--play-with=$<TARGET_FILE:atlas_chess>")
set_tests_properties(chess_mods_built_current PROPERTIES LABELS "lint")
