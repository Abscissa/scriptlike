@echo off
rdmd -unittest -gc -debug -ofscriptlike_unittest -version=unittest_scriptlike_d -main -Isrc src\scriptlike\package.d
