Scriptlike
==========

Utility to aid in writing script-like programs in the [D Programming Language](http://dlang.org).

This library has no external dependencies.

Since this is intended for script-like programs, the focus is on making such scripts easier and more convenient to write. Optimal performance is secondary to that goal (most scripts are more IO-bound or process-bound anyway), so when necessary this library may accept minor internal inefficiencies for the sake of the primary goal. That said, this IS the D Programming Language, so things aren't exactly likely to be slow overall anyway.

Tested with DMD 2.064.2 through 2.067.0.

* [API Reference](http://semitwist.com/scriptlike)
* [Changelog](https://github.com/Abscissa/scriptlike/blob/master/CHANGELOG.md)
* [DUB](http://code.dlang.org/about) [Package](http://code.dlang.org/packages/scriptlike)
* [Small article explaining the motivations behind scriptlike](http://semitwist.com/articles/article/view/scriptlike-shell-scripting-in-d-annoyances-and-a-library-solution)

Importing
---------
```import scriptlike;```

Features
--------
* A thin wrapper over [std.path](http://dlang.org/phobos/std_path.html) and [std.file](http://dlang.org/phobos/std_file.html) that provides a dedicated Path type specifically designed for managing file paths in a simple, reliable, cross-platform way. No more dealing with slashes, paths-with-spaces, calling [buildPath](http://dlang.org/phobos/std_path.html#buildPath), [normalizing](http://dlang.org/phobos/std_path.html#buildNormalizedPath), or getting paths mixed up with ordinary strings.
* Easy user-input prompts with [interact](http://semitwist.com/scriptlike/interact.html) module.
* Optionally enable automatic command echoing (including shell commands, changing/creating directories and deleting/copying/moving/linking/renaming both directories and files) by setting one simple flag: [bool scriptlikeEcho](http://semitwist.com/scriptlike/path.html#scriptlikeEcho)
* Most typical Phobos modules automatically imported. Who needs rows and rows of standard lib imports for a mere script?
* Less-pedantic filesystem operations for when you don't care whether it exists or not: [existsAsFile](http://semitwist.com/scriptlike/path.html#existsAsFile), [existsAsDir](http://semitwist.com/scriptlike/path.html#existsAsDir), [existsAsSymlink](http://semitwist.com/scriptlike/path.html#existsAsSymlink), [tryRename](http://semitwist.com/scriptlike/path.html#tryRename), [trySymlink](http://semitwist.com/scriptlike/path.html#trySymlink), [tryCopy](http://semitwist.com/scriptlike/path.html#tryCopy), [tryMkdir](http://semitwist.com/scriptlike/path.html#tryMkdir), [tryMkdirRecurse](http://semitwist.com/scriptlike/path.html#tryMkdirRecurse), [tryRmdir](http://semitwist.com/scriptlike/path.html#tryRmdir), [tryRmdirRecurse](http://semitwist.com/scriptlike/path.html#tryRmdirRecurse), [tryRemove](http://semitwist.com/scriptlike/path.html#tryRemove): All check whether the source path exists and return WITHOUT throwing if there's nothing to do.
* One simple call, [run](http://semitwist.com/scriptlike/path.html#run), to run a shell command script-style (ie, synchronously with forwarded stdout/in/err) from any working directory. (Also automatically works around DMD [#10863](https://d.puremagic.com/issues/show_bug.cgi?id=10863) without waiting for v2.066.)
* [run](http://semitwist.com/scriptlike/path.html#run) automatically throws if a process exits with a non-zero exit code. Or use [tryRun](http://semitwist.com/scriptlike/path.html#tryRun) to ignore or handle the error level yourself.
* One simple function, [fail(string msg)](http://semitwist.com/scriptlike/fail.html#fail), to help you exit with an error message in an exception-safe way. (No longer requires any boilerplate in your main()!)
* [More to come!](https://github.com/Abscissa/scriptlike/issues)
