add_test(NAME luacheck-base
    COMMAND luacheck -q .
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/base")

add_test(NAME luacheck-autoref
    COMMAND luacheck -q .
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/autoref")

# show what went wrong by default
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    USES_TERMINAL)

# currently not copied (as the dependcies are not set) since these tests are not run right now
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/run_autoref_tests.py
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cmake/run_autoref_tests.py ${CMAKE_BINARY_DIR}/run_autoref_tests.py
    DEPENDS ${CMAKE_SOURCE_DIR}/cmake/run_autoref_tests.py
)
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/autoreftesthelper.lua
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/cmake/autoreftesthelper.lua ${CMAKE_BINARY_DIR}/autoreftesthelper.lua
    DEPENDS ${CMAKE_SOURCE_DIR}/cmake/autoreftesthelper.lua
)
