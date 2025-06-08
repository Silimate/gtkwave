#!/bin/bash
sudo yum -y update
sudo yum -y install meson gperf flex glib2-devel gcc gcc-c++ gtk2-devel \
                    gobject-introspection-devel desktop-file-utils tcl \
                    tk-devel bzip2-devel xorg-x11-server-Xvfb
./autogen.sh
./configure
make -j8
