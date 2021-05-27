# ***************************************************************************
# *   Copyright 2021 Paul Bergmann                                          *
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


add_executable(autoref-cli WIN32 MACOSX_BUNDLE
    autorefcli.cpp
    ../framework/src/amuncli/testtools/include/testtools/testtools.h
    ../framework/src/amuncli/testtools/testtools.cpp
)

target_include_directories(autoref-cli
    PRIVATE ../framework/src/amuncli/testtools/include/testtools
)

target_link_libraries(autoref-cli
    PRIVATE autoref::backend
    PRIVATE amun::seshat
    PRIVATE shared::core
    PRIVATE Qt5::Core
)

target_compile_definitions(autoref-cli
    PRIVATE -DAUTOREF_DIR=\"${CMAKE_SOURCE_DIR}\"
)

if (TARGET lib::jemalloc)
    target_link_libraries(autoref-cli PRIVATE lib::jemalloc)
endif()
