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

if(TARGET amun AND TARGET logfile AND TARGET plotter)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${PROTOBUF_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework/src/ra)

set(SOURCES
    autoref.cpp
    configdialog.cpp
    configdialog.h
    mainwindow.cpp
    mainwindow.h
    teamwidget.cpp
    teamwidget.h
    ../framework/src/ra/amunclient.cpp
    ../framework/src/ra/amunclient.h
    ../framework/src/ra/debugmodel.cpp
    ../framework/src/ra/debugmodel.h
    ../framework/src/ra/debugtreewidget.cpp
    ../framework/src/ra/debugtreewidget.h
    ../framework/src/ra/fieldwidget.cpp
    ../framework/src/ra/fieldwidget.h
    ../framework/src/ra/logwidget.cpp
    ../framework/src/ra/logwidget.h
    ../framework/src/ra/refereestatuswidget.cpp
    ../framework/src/ra/refereestatuswidget.h
    ../framework/src/ra/timingwidget.cpp
    ../framework/src/ra/timingwidget.h
    ../framework/src/ra/visualizationwidget.cpp
    ../framework/src/ra/visualizationwidget.h
)

set(UI_SOURCES
    configdialog.ui
    mainwindow.ui
    ../framework/src/ra/refereestatuswidget.ui
    ../framework/src/ra/timingwidget.ui
    ../framework/src/ra/visualizationwidget.ui
)

if(MINGW)
    set(SOURCES ${SOURCES} ${CMAKE_SOURCE_DIR}/src/framework/data/pkg/ra.rc)
endif(MINGW)

# add ra icon
if(APPLE)
    set(RA_ICON ${CMAKE_SOURCE_DIR}/src/framework/data/pkg/ra.icns)
    set_source_files_properties(${RA_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set(SOURCES ${SOURCES} ${RA_ICON})
endif(APPLE)

qt5_wrap_ui(UIC_SOURCES ${UI_SOURCES})

add_executable(autoref WIN32 MACOSX_BUNDLE ${SOURCES} ${UIC_SOURCES})
target_link_libraries(autoref amun logfile plotter protobuf ${OPENGL_LIBRARIES})
qt5_use_modules(autoref Widgets OpenGL)

# add plist file
if(APPLE)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/src/framework/data/pkg/MacBundleInfo.plist.in)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_ICON_FILE ra.icns)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER com.er-force.Autoref)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME Autoref)

    # required by LuaJIT for 64bit
    set(EXTRA_LINK_FLAGS "-pagezero_size 10000 -image_base 100000000")
    get_target_property(RA_LINK_FLAGS autoref LINK_FLAGS)
    if(NOT RA_LINK_FLAGS)
        set_target_properties(autoref PROPERTIES LINK_FLAGS ${EXTRA_LINK_FLAGS})
    else()
        set_target_properties(autoref PROPERTIES LINK_FLAGS "${RA_LINK_FLAGS} ${EXTRA_LINK_FLAGS}")
    endif()
endif(APPLE)

add_definitions(-DAUTOREF_DIR=\"${CMAKE_SOURCE_DIR}\")

endif()
