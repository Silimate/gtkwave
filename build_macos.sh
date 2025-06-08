#!/bin/bash
brew bundle install
./autogen.sh
TCLTK_PREFIX=`brew --prefix tcl-tk@8`
./configure \
    --enable-stubs \
    --prefix=`brew --prefix` \
    --with-tcl=$TCLTK_PREFIX/lib \
    --with-tk=$TCLTK_PREFIX/lib \
    "CFLAGS=-I`brew --prefix`/include -I$TCLTK_PREFIX/include -g" \
    "CXXFLAGS=-std=c++11" \
    "LDFLAGS=-L`brew --prefix`/lib -L$TCLTK_PREFIX/lib" \
make -j8
