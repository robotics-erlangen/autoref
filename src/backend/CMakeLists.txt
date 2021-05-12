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

add_library(backend
    include/amun/amun.h
    ../framework/src/amun/include/amun/amunclient.h

    amun.cpp
    ../framework/src/amun/amunclient.cpp
    ../framework/src/amun/networkinterfacewatcher.cpp
    ../framework/src/amun/networkinterfacewatcher.h
    ../framework/src/amun/receiver.cpp
    ../framework/src/amun/receiver.h
    ../framework/src/amun/optionsmanager.h
    ../framework/src/amun/optionsmanager.cpp
)
target_link_libraries(backend
    PRIVATE shared::core
    PRIVATE amun::processor
    PRIVATE amun::strategy
    PUBLIC shared::protobuf
    PUBLIC Qt5::Core
    PRIVATE Qt5::Network
)
target_include_directories(backend
    INTERFACE include
    INTERFACE ../framework/src/amun/include
    PRIVATE include/amun
    PRIVATE ../framework/src/amun
    PRIVATE ../framework/src/amun/include/amun
)

if(WIN32)
    target_link_libraries(backend PRIVATE wsock32)
endif()

add_library(autoref::backend ALIAS backend)
