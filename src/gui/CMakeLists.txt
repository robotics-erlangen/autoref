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

add_executable(autoref WIN32 MACOSX_BUNDLE
    autoref.cpp
    autorefteamwidget.cpp
    autorefteamwidget.h
    ballspeedplotter.cpp
    ballspeedplotter.h
    configdialog.cpp
    configdialog.h
    infoboard.cpp
    infoboard.h
    mainwindow.cpp
    mainwindow.h
    teamscorewidget.cpp
    teamscorewidget.h
    ../framework/src/ra/optionswidget.cpp
    ../framework/src/ra/optionswidget.h
)

set(UI_SOURCES
    configdialog.ui
    mainwindow.ui
    ballspeedplotter.ui
    infoboard.ui
    teamscorewidget.ui
    ../framework/src/ra/optionswidget.ui
)
qt5_wrap_ui(UIC_SOURCES ${UI_SOURCES})
target_sources(autoref PRIVATE ${UIC_SOURCES})

if(MINGW)
    target_sources(autoref PRIVATE ${CMAKE_SOURCE_DIR}/data/pkg/autoref.rc)
endif(MINGW)

# add autoref icon
if(APPLE)
    set(AUTOREF_ICON ${CMAKE_SOURCE_DIR}/data/pkg/autoref.icns)
    set_source_files_properties(${AUTOREF_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    target_sources(autoref PRIVATE ${AUTOREF_ICON})
endif(APPLE)

target_link_libraries(autoref
    autoref::backend
    shared::core
    shared::config
    shared::protobuf
    ra::guihelper
    ra::logfile
    ra::plotter
    ra::widgets
    ${OPENGL_LIBRARIES}
    ${CMAKE_THREAD_LIBS_INIT}
    Qt5::Widgets
    Qt5::OpenGL
)
target_include_directories(autoref
    PRIVATE "${CMAKE_CURRENT_BINARY_DIR}"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}"
    PRIVATE "../framework/src/ra/plotter"
    PRIVATE "../framework/src/ra"
)
target_compile_definitions(autoref
  PRIVATE -DAUTOREF_DIR=\"${CMAKE_SOURCE_DIR}\"
)

if (TARGET lib::jemalloc)
    target_link_libraries(autoref lib::jemalloc)
endif()

# add plist file
if(APPLE)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/src/framework/data/pkg/MacBundleInfo.plist.in)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_ICON_FILE autoref.icns)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_GUI_IDENTIFIER com.er-force.Autoref)
    set_target_properties(autoref PROPERTIES MACOSX_BUNDLE_BUNDLE_NAME Autoref)
endif(APPLE)
