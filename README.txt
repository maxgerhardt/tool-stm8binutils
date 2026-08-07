BUILDING BINARIES
Building the binaries is basically the process of downloading the sources and applying the patches. There are helper scripts to assist with the process.

Also note you need some libraries for TUI mode to work. Among those are ncursesw.

First set your installation directory if you want it in a specific location. Otherwise skip this step to keep the default (/usr/local).

export PREFIX=<path>

To download, patch and configure:

./patch_binutils.sh
./configure_binutils.sh

Next step is the regular building and install:

cd binutils-2.30
make
make install
cd .

See https://stm8-binutils-gdb.sourceforge.io/ for installation and usage.
