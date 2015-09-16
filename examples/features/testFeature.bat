@echo off
rdmd -debug -g -I%~dp0../../src/ -of%~dp0testFeature %~dp0testFeature.d %*
