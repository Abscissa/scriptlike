@echo off

echo Note, generating Scriptlike's docs requires ddox available on the PATH.
echo If you get errors, double-check you have ddox installed:
echo ^<https://github.com/rejectedsoftware/ddox^>
echo.

rdmd -Isrc -Iddoc --build-only --force -c -Dddocs_tmp -X -Xfdocs\docs.json src\scriptlike\package.d
rmdir /S /Q docs_tmp > NUL 2> NUL
del src\scriptlike\package.exe
ddox filter docs\docs.json --min-protection=Protected
ddox generate-html docs\docs.json docs\public --navigation-type=ModuleTree --std-macros=ddoc\macros.ddoc
