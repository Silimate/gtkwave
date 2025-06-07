#!/bin/bash
brew bundle install
./autogen.sh
./configure CXXFLAGS="-std=c++11" --enable-gtk3 --prefix=`brew --prefix` --enable-judy --enable-struct-pack "CFLAGS=-I`brew --prefix`/include -O2 -g" LDFLAGS=-L`brew --prefix`/lib --with-tcl=`brew --prefix tcl-tk@8`/lib --with-tk=`brew --prefix tcl-tk@8`/lib
make -j8
