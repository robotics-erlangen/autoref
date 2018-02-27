add_test(NAME luacheck-base
    COMMAND luacheck -q .
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/base")

add_test(NAME luacheck-autoref
    COMMAND luacheck -q .
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/autoref")

# show what went wrong by default
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    USES_TERMINAL)
