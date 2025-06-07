#!/bin/bash
brew bundle install
./autogen.sh
TCLTK_PREFIX=`brew --prefix tcl-tk`
./configure CXXFLAGS="-std=c++11" \
    --enable-stubs \
    --enable-gtk3 \
    --prefix=`brew --prefix` \
    --enable-judy \
    --enable-struct-pack \
    --with-tcl=$TCLTK_PREFIX/lib \
    --with-tk=$TCLTK_PREFIX/lib \
    "CFLAGS=-I`brew --prefix`/include -I$TCLTK_PREFIX/include -O2 -g" \
    "LDFLAGS=-L`brew --prefix`/lib -L$TCLTK_PREFIX/lib" \
    "LIBS=-ltcl9.0 -ltk9.0 -L$TCLTK_PREFIX/lib"
make -j8
