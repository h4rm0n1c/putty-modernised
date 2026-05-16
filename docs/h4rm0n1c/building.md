# Building h4rm0n1c PuTTY fork

This fork is built on Linux using MinGW-w64 and Ninja.

Known-good local build directory:

    ~/putty/build-win64

Known-good rebuild command:

    cd ~/putty
    cmake --build build-win64 --target putty

Output binary:

    ~/putty/build-win64/putty.exe

Original CMake configuration used:

    CMAKE_BUILD_TYPE=Release
    CMAKE_GENERATOR=Ninja
    CMAKE_TOOLCHAIN_FILE=/home/harri/putty/toolchain-mingw64.cmake

To copy from Windows PowerShell:

    scp goblin@explosion:~/putty/build-win64/putty.exe "$env:USERPROFILE\Desktop\putty-ignorehighfkeys.exe"
