Scriptlike
==========

Utility to aid in writing script-like programs in the [D Programming Language](http://dlang.org).

This library has no external dependencies.

Tested with DMD 2.066.0 through 2.067.1.

* [API Reference](http://semitwist.com/scriptlike)
* [Changelog](https://github.com/Abscissa/scriptlike/blob/master/CHANGELOG.md)
* [DUB](http://code.dlang.org/about) [Package](http://code.dlang.org/packages/scriptlike)
* [Small article explaining the motivations behind scriptlike](http://semitwist.com/articles/article/view/scriptlike-shell-scripting-in-d-annoyances-and-a-library-solution)

Importing
---------
```import scriptlike;```

That imports all of Scriptlike, plus automatically includes anything from Phobos likely to be useful for scripts.

Or, if you don't want any of Phobos imported automatically, you can import only Scriptlike:

```import scriptlike.only;```

Features
--------
* A thin wrapper over [std.path](http://dlang.org/phobos/std_path.html) and [std.file](http://dlang.org/phobos/std_file.html) that provides a dedicated Path type specifically designed for managing file paths in a simple, reliable, cross-platform way. No more dealing with slashes, paths-with-spaces, calling [buildPath](http://dlang.org/phobos/std_path.html#buildPath), [normalizing](http://dlang.org/phobos/std_path.html#buildNormalizedPath), or getting paths mixed up with ordinary strings.
* Easy user-input prompts with [interact](http://semitwist.com/scriptlike/interact.html) module.
* Optionally enable automatic command echoing (including shell commands, changing/creating directories and deleting/copying/moving/linking/renaming both directories and files) by setting one simple flag: [bool scriptlikeEcho](http://semitwist.com/scriptlike/file.html#scriptlikeEcho)
* Most typical Phobos modules automatically imported [unless you don't want to](http://semitwist.com/scriptlike/only.html). Who needs rows and rows of standard lib imports for a mere script?
* Less-pedantic filesystem operations for when you don't care whether it exists or not: [existsAsFile](http://semitwist.com/scriptlike/file.html#existsAsFile), [existsAsDir](http://semitwist.com/scriptlike/file.html#existsAsDir), [existsAsSymlink](http://semitwist.com/scriptlike/file.html#existsAsSymlink), [tryRename](http://semitwist.com/scriptlike/file.html#tryRename), [trySymlink](http://semitwist.com/scriptlike/file.html#trySymlink), [tryCopy](http://semitwist.com/scriptlike/file.html#tryCopy), [tryMkdir](http://semitwist.com/scriptlike/file.html#tryMkdir), [tryMkdirRecurse](http://semitwist.com/scriptlike/file.html#tryMkdirRecurse), [tryRmdir](http://semitwist.com/scriptlike/file.html#tryRmdir), [tryRmdirRecurse](http://semitwist.com/scriptlike/file.html#tryRmdirRecurse), [tryRemove](http://semitwist.com/scriptlike/file.html#tryRemove): All check whether the source path exists and return WITHOUT throwing if there's nothing to do.
* One simple call, [run](http://semitwist.com/scriptlike/process.html#run), to run a shell command script-style (ie, synchronously with forwarded stdout/in/err) from any working directory. Or [runCollect](http://semitwist.com/scriptlike/process.html#runCollect) to capture the output instead of displaying it.
* [run](http://semitwist.com/scriptlike/process.html#run) and [runCollect](http://semitwist.com/scriptlike/process.html#runCollect) automatically throw if a process exits with a non-zero exit code. Or use [tryRun](http://semitwist.com/scriptlike/path.html#tryRun) and [tryRunCollect](http://semitwist.com/scriptlike/process.html#tryRunCollect) to ignore or handle the error level yourself.
* One simple function, [fail(...)](http://semitwist.com/scriptlike/fail.html#fail), to help you exit with an error message in an exception-safe way. Doesn't require *any* boilerplate in your main()!. Or use it std.exception.enforce-style with [failEnforce(cond, ...)](http://semitwist.com/scriptlike/fail.html#failEnforce).
* [More to come!](https://github.com/Abscissa/scriptlike/issues)
