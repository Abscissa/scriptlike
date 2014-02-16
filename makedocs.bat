@echo off
rdmd -Isrc --build-only --force -c -Dddocs -version=ddoc_scriptlike_d src\scriptlike\package.d
del docs\index.html > NUL 2> NUL
rename docs\package.html index.html
del src\scriptlike\package.exe
