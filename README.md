Scriptlike
==========

Utility to aid in writing script-like programs in the [D Programming Language](http://dlang.org).

For easier usage in script-like programs, this is created as one source file with no dependencies.

Since this is intended for script-like programs, the focus is on making such scripts easier and more convenient to write. Optimal performance is secondary to that goal (most scripts are more IO-bound or process-bound anyway), so when necessary this library may accept minor internal inefficiencies for the sake of the primary goal. That said, this IS the D Programming Language, so things aren't exactly likely to be slow overall anyway.

Tested with DMD 2.064.2

* [API Reference](http://semitwist.com/scriptlike)
* [DUB](http://code.dlang.org/about) [Package](http://code.dlang.org/packages/scriptlike)
* [Small article explaining the motivations behind scriptlike](https://semitwist.com/articles/article/view/scriptlike-shell-scripting-in-d-annoyances-and-a-library-solution)

Features
--------
* A thin wrapper over [std.path](http://dlang.org/phobos/std_path.html) and [std.file](http://dlang.org/phobos/std_file.html) that provides a dedicated Path type specifically designed for managing file paths in a simple, reliable, cross-platform way. No more dealing with slashes, paths-with-spaces, calling buildPath, normalizing, or getting paths mixed up with ordinary strings.
* Optionally enable automatic command echoing (including shell commands, changing/creating directories and deleting/copying/moving/linking/renaming both directories and files) by setting one simple flag: [bool scriptlikeTraceCommands](http://semitwist.com/scriptlike/#scriptlikeTraceCommands)
* Most typical Phobos modules automatically imported. Who needs rows and rows of standard lib imports for a mere script?
* Less-pedantic filesystem operations for when you don't care whether it exists or not: [existsAsFile](http://semitwist.com/scriptlike/#existsAsFile), [existsAsDir](http://semitwist.com/scriptlike/#existsAsDir), [existsAsSymlink](http://semitwist.com/scriptlike/#existsAsSymlink), [tryRename](http://semitwist.com/scriptlike/#tryRename), [trySymlink](http://semitwist.com/scriptlike/#trySymlink), [tryCopy](http://semitwist.com/scriptlike/#tryCopy), [tryMkdir](http://semitwist.com/scriptlike/#tryMkdir), [tryMkdirRecurse](http://semitwist.com/scriptlike/#tryMkdirRecurse), [tryRmdir](http://semitwist.com/scriptlike/#tryRmdir), [tryRmdirRecurse](http://semitwist.com/scriptlike/#tryRmdirRecurse), [tryRemove](http://semitwist.com/scriptlike/#tryRemove): All check whether the source path exists and return WITHOUT throwing if there's nothing to do.
* One simple call, [runShell](http://semitwist.com/scriptlike/#runShell), to run a shell command script-style (ie, synchronously with forwarded stdout/in/err) from any working directory. (Also automatically works around DMD [#10863](https://d.puremagic.com/issues/show_bug.cgi?id=10863) without waiting for v2.066.)
* One simple function, [fail(string msg)](http://semitwist.com/scriptlike/#fail), to help you exit with an error message in an exception-safe way. (Does require some minor [boilerplate](http://semitwist.com/scriptlike/#Fail) added to your main().)
* [More to come!](https://github.com/Abscissa/scriptlike/issues)
