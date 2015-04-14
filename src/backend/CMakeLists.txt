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

if(TARGET processor AND TARGET strategy)

include_directories(${PROTOBUF_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/amun)

set(SOURCES
    amun.cpp
    amun.h
    ../framework/src/amun/networkinterfacewatcher.cpp
    ../framework/src/amun/networkinterfacewatcher.h
    ../framework/src/amun/receiver.cpp
    ../framework/src/amun/receiver.h
)

add_library(amun ${SOURCES})
target_link_libraries(amun processor strategy)
qt5_use_modules(amun Core Network)

if(WIN32)
    target_link_libraries(amun wsock32)
endif()

endif()
