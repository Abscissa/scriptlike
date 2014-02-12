@echo off
rdmd -Isrc --build-only -c -Dddocs src\scriptlike\package.d
dmd -c -o- -Dddocs src\scriptlike\index.d
del src\scriptlike\package.exe
