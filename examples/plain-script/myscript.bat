@echo off
rdmd -I%APPDATA%/dub/packages/scriptlike-0.9.5/scriptlike/src/ -of%~dp0.myscript %~dp0myscript.d %*
