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

cmake_minimum_required(VERSION 2.8.9)
project(erforce)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/src/framework/cmake")
if(POLICY CMP0020)
    cmake_policy(SET CMP0020 NEW) # remove if CMake >= 2.8.11 required
endif()
if(POLICY CMP0043) # compatibility with CMake 3.0.1
    cmake_policy(SET CMP0043 OLD)
endif()

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -std=gnu++11")

if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to Release")
    set(CMAKE_BUILD_TYPE "Release")
endif()

find_package(OpenGL)
find_package(Threads)
find_package(Protobuf)

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
find_package(Qt5Core REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5OpenGL REQUIRED)
set(QT_FOUND TRUE)

find_package(LuaJIT2)

include(ExternalProject)
ExternalProject_Add(bullet
    URL http://www.robotics-erlangen.de/downloads/libraries/bullet-2.82-r2704.tgz
    URL_MD5 70b3c8d202dee91a0854b4cbc88173e8
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
        -DBUILD_CPU_DEMOS:BOOL=OFF
        -DBUILD_DEMOS:BOOL=OFF
        -DBUILD_EXTRAS:BOOL=OFF
        -DBUILD_AMD_OPENCL_DEMOS:BOOL=OFF
        -DBUILD_INTEL_OPENCL_DEMOS:BOOL=OFF
        -DBUILD_MINICL_OPENCL_DEMOS:BOOL=OFF
        -DBUILD_NVIDIA_OPENCL_DEMOS:BOOL=OFF
        -DUSE_GLUT:BOOL=OFF
        -DUSE_GRAPHICAL_BENCHMARK:BOOL=OFF
        -DINSTALL_LIBS:BOOL=ON
)

externalproject_get_property(bullet install_dir)
set_target_properties(bullet PROPERTIES EXCLUDE_FROM_ALL true)
set(BULLET_FOUND TRUE)
set(BULLET_INCLUDE_DIRS "${install_dir}/include/bullet")
set(BULLET_LIBRARIES
    "${install_dir}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}BulletDynamics${CMAKE_STATIC_LIBRARY_SUFFIX}"
    "${install_dir}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}BulletCollision${CMAKE_STATIC_LIBRARY_SUFFIX}"
    "${install_dir}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}LinearMath${CMAKE_STATIC_LIBRARY_SUFFIX}"
)

ExternalProject_Add(eigen
    URL http://www.robotics-erlangen.de/downloads/libraries/eigen-3.1.4.tar.bz2
    URL_MD5 15a7914c3768d51a3637fb3d64556a28
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
)

externalproject_get_property(eigen install_dir)
set_target_properties(eigen PROPERTIES EXCLUDE_FROM_ALL true)
set(EIGEN_FOUND TRUE)
set(EIGEN_INCLUDE_DIR "${install_dir}/include/eigen3")

if(MINGW)
    set(CMAKE_RC_COMPILER_INIT windres)
    enable_language(RC)
    set(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> <FLAGS> -O coff <DEFINES> -I${CMAKE_SOURCE_DIR}/data/pkg -i <SOURCE> -o <OBJECT>")
endif(MINGW)


configure_file(src/config.h.in src/config.h)
include_directories(${CMAKE_BINARY_DIR}/src)
include_directories(${CMAKE_BINARY_DIR}/src/framework/src)
include_directories(${CMAKE_SOURCE_DIR}/src/framework/src)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
add_subdirectory(src)
