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

if(TARGET amun AND TARGET logfile)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${PROTOBUF_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra/plotter)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/amun/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/amun/include/amun)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra/widgets/include/widgets)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/core/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra/guihelper/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra/guihelper/include/guihelper)

set(SOURCES
    autoref.cpp
    configdialog.cpp
    configdialog.h
    mainwindow.cpp
    mainwindow.h
    teamscorewidget.cpp
    teamscorewidget.h
    teamwidget.cpp
    teamwidget.h
    ballspeedplotter.cpp
    ballspeedplotter.h
    infoboard.cpp
    infoboard.h
    ../framework/src/amun/amunclient.cpp
    ../framework/src/amun/include/amun/amunclient.h
    ../framework/src/ra/widgets/debugmodel.cpp
    ../framework/src/ra/widgets/debugmodel.h
    ../framework/src/ra/widgets/debugtreewidget.cpp
    ../framework/src/ra/widgets/include/widgets/debugtreewidget.h
    ../framework/src/ra/widgets/fieldwidget.cpp
    ../framework/src/ra/widgets/include/widgets/fieldwidget.h
    ../framework/src/ra/widgets/savesituation.cpp
    ../framework/src/ra/widgets/savesituation.h
    ../framework/src/ra/guihelper/guitimer.cpp
    ../framework/src/ra/guihelper/include/guihelper/guitimer.h
    ../framework/src/ra/widgets/logwidget.cpp
    ../framework/src/ra/widgets/include/widgets/logwidget.h
    ../framework/src/ra/optionswidget.cpp
    ../framework/src/ra/optionswidget.h
    ../framework/src/ra/widgets/refereestatuswidget.cpp
    ../framework/src/ra/widgets/include/widgets/refereestatuswidget.h
    ../framework/src/ra/widgets/timingwidget.cpp
    ../framework/src/ra/widgets/include/widgets/timingwidget.h
    ../framework/src/ra/widgets/visualizationwidget.cpp
    ../framework/src/ra/widgets/include/widgets/visualizationwidget.h
    ../framework/src/ra/plotter/plotterwidget.cpp
    ../framework/src/ra/plotter/plotterwidget.h
    ../framework/src/ra/plotter/plot.cpp
    ../framework/src/ra/plotter/plot.h
    ../framework/src/ra/plotter/leaffilterproxymodel.cpp
    ../framework/src/ra/plotter/leaffilterproxymodel.h
    ../framework/src/ra/plotter/texturecache.cpp
    ../framework/src/ra/plotter/texturecache.h
)

set(UI_SOURCES
    configdialog.ui
    mainwindow.ui
    ballspeedplotter.ui
    infoboard.ui
    teamscorewidget.ui
    ../framework/src/ra/optionswidget.ui
    ../framework/src/ra/widgets/refereestatuswidget.ui
    ../framework/src/ra/widgets/timingwidget.ui
    ../framework/src/ra/widgets/visualizationwidget.ui
)

if(MINGW)
    set(SOURCES ${SOURCES} ${CMAKE_SOURCE_DIR}/data/pkg/autoref.rc)
endif(MINGW)

# add ra icon
if(APPLE)
    set(RA_ICON ${CMAKE_SOURCE_DIR}/data/pkg/autoref.icns)
    set_source_files_properties(${RA_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set(SOURCES ${SOURCES} ${RA_ICON})
endif(APPLE)

qt5_wrap_ui(UIC_SOURCES ${UI_SOURCES})

add_executable(autoref WIN32 MACOSX_BUNDLE ${SOURCES} ${UIC_SOURCES})
target_link_libraries(autoref amun logfile protobuf ${OPENGL_LIBRARIES})
qt5_use_modules(autoref Widgets OpenGL)

# add plist file
if(APPLE)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/src/framework/data/pkg/MacBundleInfo.plist.in)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_ICON_FILE autoref.icns)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER com.er-force.Autoref)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME Autoref)

    # required by LuaJIT for 64bit
    set(EXTRA_LINK_FLAGS "-pagezero_size 10000 -image_base 100000000")
    get_target_property(AUTOREF_LINK_FLAGS autoref LINK_FLAGS)
    if(NOT AUTOREF_LINK_FLAGS)
        set_target_properties(autoref PROPERTIES LINK_FLAGS ${EXTRA_LINK_FLAGS})
    else()
        set_target_properties(autoref PROPERTIES LINK_FLAGS "${AUTOREF_LINK_FLAGS} ${EXTRA_LINK_FLAGS}")
    endif()
endif(APPLE)

add_definitions(-DAUTOREF_DIR=\"${CMAKE_SOURCE_DIR}\")

endif()
