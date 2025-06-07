#!/bin/bash
brew bundle install
./autogen.sh
./configure --prefix=`brew --prefix` --enable-judy --enable-struct-pack "CFLAGS=-I`brew --prefix`/include -O2 -g" LDFLAGS=-L`brew --prefix`/lib  --no-create --no-recursion --with-tcl=`brew --prefix tcl-tk`/lib --with-tk=`brew --prefix tcl-tk`/lib
make -j8
