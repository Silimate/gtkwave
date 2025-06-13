#!/bin/bash

# Install all other dependencies
brew bundle install

# Reinstall tcl-tk without CoreFoundation if tclsh is linked to CoreFoundation
if otool -L $(which tclsh) | grep 2503.1.0; then
    brew reinstall --formula --build-from-source ./tcl-tk@8.rb
fi

# Reinstall gtk+3 to enable broadway backend (shared library) if broadwayd is not found
if [[ ! -f `brew --prefix`/bin/broadwayd ]]; then
    brew reinstall --formula --build-from-source ./gtk+3.rb
fi

# Build gtkwave
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
