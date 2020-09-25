# Macro which contains all bits and pieces to create the regression tests.
# This creates both a standalone target 'regression', and it integrates with
# 'ctest'. The first is prefered, as it is more verbose, and takes care of
# dependencies correctly.
#
# create_regression()
#
macro(create_regression)
    # Find all the files in the regression folder; they need to be copied to the
    # build folder before we can run the regression
    file(GLOB_RECURSE REGRESSION_SOURCE_FILES ${CMAKE_SOURCE_DIR}/regression/*)
    foreach(REGRESSION_SOURCE_FILE IN LISTS REGRESSION_SOURCE_FILES)
        string(REGEX REPLACE "^${CMAKE_SOURCE_DIR}/regression/" "${CMAKE_BINARY_DIR}/ai/" REGRESSION_BINARY_FILE "${REGRESSION_SOURCE_FILE}")
        string(REGEX REPLACE "^${CMAKE_SOURCE_DIR}/regression/" "" REGRESSION_SOURCE_FILE_NAME "${REGRESSION_SOURCE_FILE}")

        if("${REGRESSION_SOURCE_FILE_NAME}" STREQUAL "regression.cfg")
            continue()
        endif()

        add_custom_command(OUTPUT ${REGRESSION_BINARY_FILE}
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${REGRESSION_SOURCE_FILE}
                        ${REGRESSION_BINARY_FILE}
                MAIN_DEPENDENCY ${REGRESSION_SOURCE_FILE}
                COMMENT "Copying ${REGRESSION_SOURCE_FILE_NAME} regression file"
        )

        list(APPEND REGRESSION_BINARY_FILES ${REGRESSION_BINARY_FILE})
    endforeach()

    # Copy the regression configuration in a special folder, so all autogenerated
    # folders end up in the same place after running regression.
    add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/regression/regression.cfg
            COMMAND ${CMAKE_COMMAND} -E copy
                    ${CMAKE_SOURCE_DIR}/regression/regression.cfg
                    ${CMAKE_BINARY_DIR}/regression/regression.cfg
            MAIN_DEPENDENCY ${CMAKE_SOURCE_DIR}/regression/regression.cfg
            COMMENT "Copying ${REGRESSION_SOURCE_FILE_NAME} regression file"
    )
    list(APPEND REGRESSION_BINARY_FILES ${CMAKE_BINARY_DIR}/regression/regression.cfg)

    # Create a new target which copies all regression files
    add_custom_target(regression_files
            ALL  # this is needed because 'make test' doesn't resolve dependencies, and otherwise this is never executed
            DEPENDS
            ${REGRESSION_BINARY_FILES}
    )

    enable_testing()

    # Find all the tests we have, and create a target for them
    file(GLOB REGRESSION_TESTS ${CMAKE_SOURCE_DIR}/regression/*)
    foreach(REGRESSION_TEST IN LISTS REGRESSION_TESTS)
        get_filename_component(REGRESSION_TEST_NAME "${REGRESSION_TEST}" NAME)

        if("${REGRESSION_TEST_NAME}" STREQUAL "regression.cfg")
            continue()
        endif()

        add_custom_target(regression_${REGRESSION_TEST_NAME}
                COMMAND ${CMAKE_COMMAND}
                        -DOPENTTD_EXECUTABLE=$<TARGET_FILE:openttd>
                        -DEDITBIN_EXECUTABLE=${EDITBIN_EXECUTABLE}
                        -DREGRESSION_TEST=${REGRESSION_TEST_NAME}
                        -P "${CMAKE_SOURCE_DIR}/cmake/scripts/Regression.cmake"
                DEPENDS openttd regression_files
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMENT "Running regression test ${REGRESSION_TEST_NAME}"
                )

        # Also make sure that 'make test' runs the regression
        add_test(NAME regression_${REGRESSION_TEST_NAME}
                COMMAND ${CMAKE_COMMAND}
                        -DOPENTTD_EXECUTABLE=$<TARGET_FILE:openttd>
                        -DEDITBIN_EXECUTABLE=${EDITBIN_EXECUTABLE}
                        -DREGRESSION_TEST=${REGRESSION_TEST_NAME}
                        -P "${CMAKE_SOURCE_DIR}/cmake/scripts/Regression.cmake"
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

        list(APPEND REGRESSION_TARGETS regression_${REGRESSION_TEST_NAME})
    endforeach()

    # Create a new target which runs the regression
    add_custom_target(regression
            DEPENDS ${REGRESSION_TARGETS})
endmacro()
