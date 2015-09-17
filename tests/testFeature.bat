@echo off
IF [%DMD%] == [] set DMD=dmd
rdmd --compiler=%DMD% -debug -g -I%~dp0../src/ -of%~dp0testFeature %~dp0testFeature.d %*
