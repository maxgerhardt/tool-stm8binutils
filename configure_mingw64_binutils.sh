mkdir -p mingw64_binutils
cd mingw64_binutils
../binutils-2.30/configure --host=x86_64-w64-mingw32 --target=stm8-none-elf32 --program-prefix=stm8- --with-system-readline \
--with-libexpat-prefix=/usr/x86_64-w64-mingw32/sys-root/mingw/ LDFLAGS=-static
