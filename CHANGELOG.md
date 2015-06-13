Scriptlike - Changelog
======================

(Dates below are YYYY/MM/DD)

v0.8.0 - TBD
-------------------
- **Change:** Minimum officially supported DMD increased from v2.064.2 to v2.066.0. Versions below v2.066.0 may still work, but there will now be certain problems when dealing with paths that contain spaces, particularly on Windows.
- **Change:** Removed unnecessary non-[```Path```](http://semitwist.com/scriptlike/path.html#Path) wrappers around std.file/std.path. Things not wrapped (like dirSeparator and SpanMode) are now selective public imports instead of aliases. These changes should reduce issues with symbol conflicts.
- **Change:** [API reference](http://semitwist.com/scriptlike/) now built using [ddox](https://github.com/rejectedsoftware/ddox) and uses much improved styling (actually uses a stylesheet now).
- **Change:** Eliminate remnants of the "planned but never enabled" wstring/dstring versions of Path/Ext/Args. There turned out not to be much need for them, and even std.file doesn't support wstring/dstring either.
- **Enhancement:** Add module scriptlike.only to import all of scriptlike, but omit the helper Phobos imports in scriptlike.std.
- **Enhancement:** [```fail```](http://semitwist.com/scriptlike/fail.html#fail) now accepts an arbitrary list of args or any type, just like writeln,
- **Enhancement:** Added [```failEnforce```](http://semitwist.com/scriptlike/fail.html#failEnforce), like std.exception.enforce, but for ```fail()```.
- **Enhancement:** Added [```runCollect```](http://semitwist.com/scriptlike/process.html#runCollect) and [```tryRunCollect```](http://semitwist.com/scriptlike/process.html#tryRunCollect), to capture a command's output instead of displaying it.
- **Enhancement:** Added [```pause```](http://semitwist.com/scriptlike/interact.html#pause) to pause and prompt the user to press Enter.
- **Enhancement:** [```echoCommand```](http://semitwist.com/scriptlike/file.html#echoCommand) is no longer private.
- Added Path-based wrappers for std.file's getcwd, thisExePath and tempDir.
- **Fixed:** No longer uses the deprecated std.process.system().

v0.7.0 - 2015/04/02
-------------------
- **Enhancement:** [#14](https://github.com/Abscissa/scriptlike/issues/14): Added ```[interact](http://semitwist.com/scriptlike/interact.html)``` module for easy user-input prompts. (Thanks to [Jesse Phillips](https://github.com/JesseKPhillips))
- **Fixed:** Unittest compile failure on DMD v2.067.0.

v0.6.0 - 2014/02/16
-------------------
- **Change:** [```Path```](http://semitwist.com/scriptlike/path.html#Path) and [```Ext```](http://semitwist.com/scriptlike/path.html#Ext) are now aliases for the UTF-8 instantiations, and the template structs are now named ```PathT``` and ```ExtT```.
- **Change:** Removed ```path()``` and ```ext()``` helper functions to free up useful names from the namespace, since they are no longer needed. Use ```Path()``` and ```Ext()``` instead.
- **Change:** Internally split into separate modules, but uses package.d to preserve ```import scriptlike;```.
- **Change**: Rename ```escapeShellPath``` -> [```escapeShellArg```](http://semitwist.com/scriptlike/path.html#escapeShellArg).
- **Change**: Rename ```runShell``` -> [```tryRun```](http://semitwist.com/scriptlike/process.html#tryRun). Temporarily keep ```runShell``` as an alias.
- **Change**: Rename ```scriptlikeTraceCommands``` -> [```scriptlikeEcho```](http://semitwist.com/scriptlike/file.html#scriptlikeEcho). Temporarily keep ```scriptlikeTraceCommands``` as an alias.
- **Enhancement:** Added scripts to run unittests and build API docs.
- **Enhancement:** Added [```opCast!bool```](http://semitwist.com/scriptlike/path.html#Path.opCast) for Path and Ext.
- **Enhancement:** [```fail()```](http://semitwist.com/scriptlike/fail.html) no longer requires any boilerplate in main(). [NG link](http://forum.dlang.org/thread/ldc6qt$22tv$1@digitalmars.com)
- **Enhancement:** Added [```run```](http://semitwist.com/scriptlike/process.html#run) to run a shell command like [```tryRun```](http://semitwist.com/scriptlike/process.html#tryRun), but automatically throw if the process returns a non-zero error level.
- **Enhancement:** [#2](https://github.com/Abscissa/scriptlike/issues/2): Optional callback sink for command echoing: [```scriptlikeCustomEcho```](http://semitwist.com/scriptlike/file.html#scriptlikeCustomEcho).
- **Enhancement:** [#8](https://github.com/Abscissa/scriptlike/issues/8): Dry run support via bool [```scriptlikeDryRun```](http://semitwist.com/scriptlike/file.html#scriptlikeDryRun).
- **Enhancement:** [#13](https://github.com/Abscissa/scriptlike/issues/13): Added [```ArgsT```](http://semitwist.com/scriptlike/process.html#Args) (and ```Args``` helper alias) to safely build command strings from parts.
- **Enhancement:** Added this changelog.
- **Fixed:** Path(null) and Ext(null) were automatically changed to empty string.
- **Fixed:** [#10](https://github.com/Abscissa/scriptlike/issues/10): Docs should include all OS-specific functions.

v0.5.0 - 2014/02/11
-------------------
- Initial release
