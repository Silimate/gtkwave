#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y meson gperf flex desktop-file-utils libgtk-3-dev libbz2-dev libjudy-dev libgirepository1.0-dev
./autogen.sh
./configure --enable-fsdb
make -j8
