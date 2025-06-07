#!/bin/bash
brew bundle install
./autogen.sh
./configure CXXFLAGS="-std=c++11" --enable-stubs --prefix=`brew --prefix` --enable-judy --enable-struct-pack "CFLAGS=-I`brew --prefix`/include -O2 -g" LDFLAGS="-L`brew --prefix`/lib -L`brew --prefix tcl-tk@8`/lib -ltcl8.6 -ltk8.6" --with-tcl=`brew --prefix tcl-tk@8`/lib --with-tk=`brew --prefix tcl-tk@8`/lib
make -j8
