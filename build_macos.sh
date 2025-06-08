#!/bin/bash
brew bundle install
./autogen.sh
TCLTK_PREFIX=`brew --prefix tcl-tk@8`
./configure \
    --enable-gtk3 \
    --prefix=`brew --prefix` \
    --with-tcl=$TCLTK_PREFIX/lib \
    --with-tk=$TCLTK_PREFIX/lib \
    CFLAGS="-I$TCLTK_PREFIX/include -I`brew --prefix`/include -g -O3" \
    CXXFLAGS="-std=c++11 -O3" \
    LDFLAGS="-L$TCLTK_PREFIX/lib -L`brew --prefix`/lib"
make -j8
