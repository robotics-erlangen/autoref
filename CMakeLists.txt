# ***************************************************************************
# *   Copyright 2015 Michael Eischer, Philipp Nordhus                       *
# *   Robotics Erlangen e.V.                                                *
# *   http://www.robotics-erlangen.de/                                      *
# *   info@robotics-erlangen.de                                             *
# *                                                                         *
# *   This program is free software: you can redistribute it and/or modify  *
# *   it under the terms of the GNU General Public License as published by  *
# *   the Free Software Foundation, either version 3 of the License, or     *
# *   any later version.                                                    *
# *                                                                         *
# *   This program is distributed in the hope that it will be useful,       *
# *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
# *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
# *   GNU General Public License for more details.                          *
# *                                                                         *
# *   You should have received a copy of the GNU General Public License     *
# *   along with this program.  If not, see <http://www.gnu.org/licenses/>. *
# ***************************************************************************

cmake_minimum_required(VERSION 3.11.0)
project(erforce)
enable_testing()
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_SOURCE_DIR}/src/framework/cmake")
if(POLICY CMP0071) # compatibility with CMake 3.10.0
    cmake_policy(SET CMP0071 OLD)
endif()

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG(-std=gnu++20 HAVE_C20)
if (NOT HAVE_C20)
    message(FATAL_ERROR "Your compiler does not understand -std=c++20, consider updating your compiler")
endif()
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=gnu++20")
SET(CMAKE_CXX_STANDARD 20)
SET(CMAKE_CXX_STANDARD_REQUIRED YES)
SET(CMAKE_CXX_EXTENSIONS ON)

if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to Release")
    set(CMAKE_BUILD_TYPE "Release")
endif()

if(MINGW)
    find_program(WINDRES_EXECUTABLE NAMES windres)
    set(CMAKE_RC_COMPILER_INIT ${WINDRES_EXECUTABLE})
    enable_language(RC)
    set(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> <FLAGS> -O coff <DEFINES> \"-I${CMAKE_SOURCE_DIR}/data/pkg\" -i <SOURCE> -o <OBJECT>")
    # make sure MinGW doesn't screw up packing the radiocommands
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mno-ms-bitfields")
endif(MINGW)

if(APPLE)
    # the option "S" prevents execution of ranlib
    SET(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> Sqc <TARGET> <LINK_FLAGS> <OBJECTS>")
    SET(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> Sqc <TARGET> <LINK_FLAGS> <OBJECTS>")
    # silence ranlib "has no symbols"-warning
    SET(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols <TARGET>")
    SET(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols <TARGET>")
endif()

add_custom_target(download)

include(EnvHelper)

find_package(OpenGL REQUIRED)
find_package(Threads REQUIRED)
sanitize_env()
find_package(Protobuf 3.3.0)
restore_env()

# if protobouf is not found the version string is empty and apparently ifs in cmake do not follow short-circuit logic,
# which means below it evaluates the if condition to "... OR VERSION_GREATER_EQUAL 4.25.0" and then cmake dies
# this is stupid, but can't be helped
if (NOT ${PROTOBUF_FOUND})
    set(Protobuf_VERSION 4.25.0)
endif()

if(NOT ${PROTOBUF_FOUND}
        # protobuf version 4.25.0 leads to weird linker errors, not sure if versions greater than that cause the same issues
        OR ${Protobuf_VERSION} VERSION_GREATER_EQUAL 4.25.0
        OR NOT TARGET protobuf::protoc)
    include(BuildProtobuf)
endif()

set(CMAKE_AUTOMOC ON)
find_package(Qt5Core REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5OpenGL REQUIRED)

if(NOT APPLE)
    # file open dialogs crash on mac
    find_package(Jemalloc)
endif()
include(BuildEigen)
include(BuildLuaJIT2)
include(BuildGoogleTest)
include(BuildSourceMap)
include(GetGameController)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_subdirectory(src)

if(UNIX AND NOT APPLE)
    configure_file(data/pkg/autoref.desktop.in autoref.desktop)
    add_custom_target(install-menu
        COMMAND xdg-desktop-menu install --novendor ${CMAKE_BINARY_DIR}/autoref.desktop
        COMMENT "Installing menu entries" VERBATIM
    )
endif()

include(AddTests)

