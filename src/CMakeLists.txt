# ***************************************************************************
# *   Copyright 2015 Michael Eischer                                        *
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

# firmware
add_subdirectory(framework/src/firmware)

# libs
add_subdirectory(config)
add_subdirectory(framework/src/core)
add_subdirectory(framework/src/protobuf)
add_subdirectory(framework/src/amun/processor)
add_subdirectory(framework/src/amun/strategy)
add_subdirectory(framework/src/visionlog)
add_subdirectory(backend)

# apps
add_subdirectory(framework/src/ra/logfile)
add_subdirectory(framework/src/ra/guihelper)
add_subdirectory(framework/src/ra/plotter)
add_subdirectory(framework/src/ra/widgets)
add_subdirectory(gui)
