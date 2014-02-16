Scriptlike - Changelog
======================

v0.6.0 - TBD
------------
- **Change:** [```Path```](http://semitwist.com/scriptlike/path.html#PathT) and [```Ext```](http://semitwist.com/scriptlike/path.html#ExtT) are now aliases for the UTF-8 instantiations, and the template structs are now named ```PathT``` and ```ExtT```.
- **Change:** Removed ```path()``` and ```ext()``` helper functions to free up useful names from the namespace, since they are no longer needed. Use ```Path()``` and ```Ext()``` instead.
- **Change:** Internally split into separate modules, but uses package.d to preserve ```import scriptlike;```.
- **Change**: Rename ```escapeShellPath``` -> [```escapeShellArg```](http://semitwist.com/scriptlike/path.html#escapeShellArg).
- **Change**: Rename ```runShell``` -> [```tryRun```](http://semitwist.com/scriptlike/path.html#tryRun). Temporarily keep ```runShell``` as an alias.
- **Enhancement:** Added scripts to run unittests and build API docs.
- **Enhancement:** Added [```opCast!bool```](http://semitwist.com/scriptlike/path.html#opCast) for Path and Ext.
- **Enhancement:** [```fail()```](http://semitwist.com/scriptlike/fail.html) no longer requires any boilerplate in main(). [NG link](http://forum.dlang.org/thread/ldc6qt$22tv$1@digitalmars.com)
- **Enhancement:** [#13](https://github.com/Abscissa/scriptlike/issues/13): Added [```ArgsT```](http://semitwist.com/scriptlike/path.html#ArgsT) (and ```Args``` helper alias) to safely build command strings from parts.
- **Enhancement:** Added [```run```](http://semitwist.com/scriptlike/path.html#run) to run a shell command like tryRun, but automatically throw if the process returns a non-zero error level.
- **Enhancement:** [#8](https://github.com/Abscissa/scriptlike/issues/): Dry run support via bool [```scriptlikeDryRun```](http://semitwist.com/scriptlike/path.html#scriptlikeDryRun).
- **Enhancement:** Added this changelog.
- **Fixed:** Path(null) and Ext(null) were automatically changed to empty string.
- **Fixed:** [#10](https://github.com/Abscissa/scriptlike/issues/10): Docs should include all OS-specific functions.

v0.5.0 - 2014/2/11
------------------
- Initial release
