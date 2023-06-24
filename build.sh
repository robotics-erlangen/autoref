#!/usr/bin/env bash
git submodule update --init --recursive
mkdir build
cd build
cmake ..
make -j"$(nproc)"
cd ..