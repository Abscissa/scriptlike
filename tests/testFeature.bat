@echo off
IF [%DMD%] == [] set DMD=dmd
rdmd --compiler=%DMD% --force -debug -g -I%~dp0../src/ -of%~dp0.testFeature %~dp0testFeature.d %*
