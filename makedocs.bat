@echo off

rem 'ddox' must be installed and on PATH:
rem https://github.com/rejectedsoftware/ddox

rdmd -Isrc --build-only --force -c -Dddocs_tmp -X -Xfdocs\docs.json src\scriptlike\package.d
rmdir /S /Q docs_tmp > NUL 2> NUL
del src\scriptlike\package.exe
ddox filter docs\docs.json --min-protection=Protected
ddox generate-html docs\docs.json docs\public --navigation-type=ModuleTree
