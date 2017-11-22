# Compiling Autoref

All programs should work on GNU/Linux (tested on Ubuntu 16.04 and Arch Linux), Mac OS X 10.12 and Windows >= 7.

## Obtain the framework
```
git submodule update --init
```

In order to build Autoref you will need:
 * cmake >= 2.8.12
 * g++ >= 4.6
 * qt >= 5.1.0
 * protobuf >= 2.0.0

Package names for Ubuntu 16.04: `cmake protobuf-compiler qtbase5-dev g++`

## Linux
The recommended way of building a project with CMake is by doing an
out-of-source build. This can be done like this:

```
mkdir build
cd build
cmake ..
make
```

Autoref can be started from the build/bin/ directory.

Further details on how to select a specific Qt-Installation or using the
debugger can be found in the [framework repository](https://github.com/robotics-erlangen/framework/blob/master/COMPILE.md#unix).


## Windows
Get dependencies (tested using the given versions):
* cmake 3.2.2 - http://www.cmake.org/files/v3.2/cmake-3.2.2-win32-x86.exe
* mingw-get - http://sourceforge.net/projects/mingw/files/Installer/mingw-get-setup.exe
* ninja - https://github.com/martine/ninja/releases/download/v1.6.0/ninja-win.zip
* Qt 5 - http://download.qt.io/official_releases/online_installers/qt-opensource-windows-x86-online.exe
* protobuf 2.6.1 - https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.bz2

#### install cmake
use the installer, select add to PATH

#### install qt
run installer (use default install path! ), install "Qt 5.5 > MinGW 4.9.2" and "Tools > MinGW 4.9.2"

#### install mingw-get
Run installer (use default path C:\MinGW !) and install `msys-base, msys-patch`

Run `C:\mingw\msys\1.0\postinstall\pi.bat` set mingw path to `c:/Qt/Tools/mingw492_32`

use `msys.bat` in `msys\1.0` to open msys console

#### install ninja
Extract `ninja.exe` to `C:\MinGW\msys\1.0\bin`

**!!! USE MSYS TO COMPILE EVERYTHING !!!**

#### compile protobuf
```
mkdir build && cd build
../configure --prefix=/usr/local --without-zlib && make && make install
```

#### compile ra
```
mkdir build-win && cd build-win
cmake -GNinja -DCMAKE_PREFIX_PATH=/c/Qt/5.5/mingw492_32/lib/cmake -DCMAKE_BUILD_TYPE=Release -DPROTOBUF_INCLUDE_DIR=C:/MinGW/msys/1.0/local/include -DPROTOBUF_LIBRARY=C:/MinGW/msys/1.0/local/lib/libprotobuf.dll.a ..
ninja
cp -r ../data ../src/framework/data bin
cp project_luajit-prefix/lib/lua51.dll bin
cp /usr/local/bin/{libprotobuf-9}.dll /c/Qt/5.5/mingw492_32/bin/{icudt54,icuin54,icuuc54,libgcc_s_dw2-1,libstdc++-6,libwinpthread-1,Qt5Core,Qt5Gui,Qt5Network,Qt5OpenGL,Qt5Widgets}.dll bin
mkdir bin/platforms && cp /c/Qt/5.5/mingw492_32/plugins/platforms/qwindows.dll bin/platforms
```

Finished!


## Mac OS X
Get dependencies using [Homebrew](http://brew.sh):
```
brew install cmake git protobuf
```
Run the following command and install Xcode and/or the Command Line Developer Tools if prompted to do so.
```
xcode-select --install
```
Start Xcode once afterwards to ensure that everything gets setup. Starting Xcode may also be necessary after an update.

Download Qt 5 from http://qt-project.org and install it.
WARNING: DO NOT install Qt 5.4.0-5.5.0; Qt 5.5.1 is ok

Build using:
```
cd path/to/framework
mkdir build-mac && cd build-mac
cmake -DCMAKE_PREFIX_PATH=~/Qt/5.5/clang_64/lib/cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

(If starting autoref.app the normal way doesn't work launch it from Qt Creator)
