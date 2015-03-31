# Compiling Autoref

All should work on GNU/Linux (tested on Ubuntu 14.04 and Arch Linux), Mac OS X 10.10 and Windows >= 7.

## Obtain the framework
```
git submodule update --init
```

In order to build Autoref you will need:
 * cmake >= 2.8.9
 * g++ >= 4.6
 * qt >= 5.1.0
 * protobuf >= 2.0.0
 * luajit >= 2.0

Package names for Ubuntu 14.04: `cmake protobuf-compiler qtbase5-dev libluajit-5.1-dev g++`

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

Further details on how to select a specific Qt-Installation or use the
debugger can be found in the [framework repository](https://github.com/robotics-erlangen/framework/blob/master/COMPILE.md#unix).


## Windows
Get dependencies (tested using the given versions):
* cmake 3.0.2 - http://www.cmake.org/files/v3.0/cmake-3.0.2-win32-x86.exe
* mingw-get - http://sourceforge.net/projects/mingw/files/Installer/mingw-get-setup.ex
* Qt 5.3.2 OpenGL - http://download.qt-project.org/official_releases/qt/5.3/5.3.2/qt-opensource-windows-x86-mingw482_opengl-5.3.2.exe
* protobuf 2.6.1 - https://github.com/google/protobuf/releases/download/2.6.1/protobuf-2.6.1.tar.bz2
* luajit 2.0.3 - http://luajit.org/download/LuaJIT-2.0.3.tar.gz
* luasocket 3.0-rc? - https://github.com/diegonehab/luasocket/archive/master.zip

#### install cmake
use the installer, select add to PATH

#### install qt
run installer (use default install path! ), make sure to SELECT "Tools/MinGW 4.8"!

#### install mingw-get
Run installer (use default path C:\MinGW !) and install `msys-base, msys-patch`

Run `C:\mingw\msys\1.0\postinstall\pi.bat` set mingw path to `c:/Qt/Qt5.3.2/Tools/mingw482_32`

use `msys.bat` in `msys\1.0` to open msys console

**!!! USE MSYS TO COMPILE EVERYTHING !!!**

#### compile protobuf
```
mkdir build && cd build
../configure --prefix=/usr/local --without-zlib && make && make install
```

#### compile luajit
```
make && make install PREFIX=/usr/local && cp src/lua51.dll /usr/local/bin
```

#### compile luasocket2
```
make PLAT=mingw LUAINC_mingw=/usr/local/include/luajit-2.0 LUALIB_mingw=/usr/local/bin/lua51.dll
make install PLAT=mingw INSTALL_TOP_LDIR=../build/share INSTALL_TOP_CDIR=../build/lib
```

#### compile ra
```
mkdir build-win && cd build-win
cmake -G "MSYS Makefiles" -DCMAKE_PREFIX_PATH=/c/Qt/Qt5.3.2/5.3/mingw482_32/lib/cmake -DCMAKE_BUILD_TYPE=Release -DLUA_INCLUDE_DIR=C:/MinGW/msys/1.0/local/include/luajit-2.0 -DLUA_LIBRARIES=C:/MinGW/msys/1.0/local/bin/lua51.dll -DPROTOBUF_INCLUDE_DIR=C:/MinGW/msys/1.0/local/include -DPROTOBUF_LIBRARY=C:/MinGW/msys/1.0/local/lib/libprotobuf.dll.a ..
make
```

* copy config + data directory to `"builddir"/bin`
* copy libprotobuf-9.dll, lua51.dll from `C:\MinGW\msys\1.0\local\bin` to `"builddir"/bin`
* copy icudt52.dll, icuin52.dll, icuuc52.dll, libgcc_s_dw2-1.dll, libstdc++-6.dll, libwinpthread-1.dll,
	Qt5Core.dll, Qt5Gui.dll, Qt5Network.dll, Qt5OpenGL.dll, Qt5Widgets.dll from `C:/Qt/Qt5.3.2/5.3/mingw482_32/bin` to `"builddir"/bin`
* copy qwindows.dll from `C:/Qt/Qt5.3.2/5.3/mingw482_32/plugins/platforms` to `"builddir"/bin/platforms`
	copy the folders of `luasocket2/build/lib` to `"builddir"/bin`

Finished!


## Mac OS X
Get dependencies using [Homebrew](http://brew.sh):
```
brew install git luajit protobuf
```

Download Qt 5 from http://qt-project.org and install

Build using:
```
cd path/to/framework
mkdir build-mac && cd build-mac
cmake -DCMAKE_PREFIX_PATH=~/Qt/5.3/clang_64/lib/cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

(If starting autoref.app the normal way doesn't work launch it from Qt Creator)
