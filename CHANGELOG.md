Scriptlike - Changelog
======================

v0.6.0 - TBD
------------
- **Change:** [```Path```](http://semitwist.com/scriptlike/path.html#PathT) and [```Ext```](http://semitwist.com/scriptlike/path.html#ExtT) are now aliases for the UTF-8 instantiations, and the template structs are now named ```PathT``` and ```ExtT```.
- **Change:** Internally split into separate modules, but uses package.d to preserve ```import scriptlike;```.
- **Change**: Rename ```escapeShellPath``` -> [```escapeShellArg```](http://semitwist.com/scriptlike/path.html#escapeShellArg).
- **Change**: Rename ```runShell``` -> [```run```](http://semitwist.com/scriptlike/path.html#run). Temporarily keep ```runShell``` as an alias.
- **Enhancement:** Added scripts to run unittests and build API docs.
- **Enhancement:** Added [```opCast!bool```](http://semitwist.com/scriptlike/path.html#opCast) for Path and Ext.
- **Enhancement:** [```fail()```](http://semitwist.com/scriptlike/fail.html) no longer requires any boilerplate in main(). [NG link](http://forum.dlang.org/thread/ldc6qt$22tv$1@digitalmars.com)
- **Enhancement:** [#13](https://github.com/Abscissa/scriptlike/issues/13): Added [```ArgsT```](http://semitwist.com/scriptlike/path.html#ArgsT) (and ```Args``` helper alias) to safely build command strings from parts.
- **Enhancement:** Added this changelog.
- **Fixed:** Path(null) and Ext(null) were automatically changed to empty string.

v0.5.0 - 2014/2/11
------------------
- Initial release
