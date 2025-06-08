#!/bin/bash
brew bundle install
./autogen.sh
TCLTK_PREFIX=`brew --prefix tcl-tk@8`
./configure \
    --enable-stubs \
    --prefix=`brew --prefix` \
    --with-tcl=$TCLTK_PREFIX/lib \
    --with-tk=$TCLTK_PREFIX/lib \
    CFLAGS="-I`brew --prefix`/include -g -O3" \
    CXXFLAGS="-std=c++11 -O3" \
    LDFLAGS="-L`brew --prefix`/lib"
make -j8
