Scriptlike [![Build Status](https://travis-ci.org/Abscissa/scriptlike.svg)](https://travis-ci.org/Abscissa/scriptlike)
==========

Utility to aid in writing script-like programs in the [D Programming Language](http://dlang.org).

This library has no external dependencies.

Officially supported compiler versions are shown in [.travis.yml](https://github.com/Abscissa/scriptlike/blob/master/.travis.yml).

* [API Reference](http://semitwist.com/scriptlike)
* [Changelog](http://semitwist.com/scriptlike/changelog.html)
* [DUB](http://code.dlang.org/about) [Package](http://code.dlang.org/packages/scriptlike)
* [Small article explaining the original motivations behind scriptlike](http://semitwist.com/articles/article/view/scriptlike-shell-scripting-in-d-annoyances-and-a-library-solution)

Importing
---------
```import scriptlike;```

That imports all of Scriptlike, plus automatically includes anything from Phobos likely to be useful for scripts.

Or, if you don't want any of Phobos imported automatically, you can import only Scriptlike:

```import scriptlike.only;```

Features
--------

* [Filepaths](#Filepaths)
* [User input prompts](#User-input-prompts)
* [Command echoing](#Command-echoing)
* [Automatic Phobos import](#Automatic-Phobos-import)
* [Try/As filesystem operations](#Try-As-filesystem-operations)
* [Script-style shell commands](#Script-style-shell-commands)
* [Fail](#Fail)
* [String interpolation](#String-interpolation)

### Filepaths

Simple, reliable, cross-platform. No more worrying about slashes, paths-with-spaces, [buildPath](http://dlang.org/phobos/std_path.html#buildPath), [normalizing](http://dlang.org/phobos/std_path.html#buildNormalizedPath), or getting paths mixed up with ordinary strings:

```d
// This is AUTOMATICALLY kept [normalized](http://dlang.org/phobos/std_path.html#buildNormalizedPath)
auto dir = [Path](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html)("foo/bar");
dir ~= "subdir"; // Append a subdirectory
//dir ~= "subdir/"; // IDENTICAL to previous line, no worries!

// No worries about forword/backslashes!
assert(dir == Path("foo/bar/subdir"));
assert(dir == Path("foo\\bar\\subdir"));

// No worries about spaces!
auto file = dir.up ~ "different subdir\\Filename with spaces.txt";
assert(dir == Path("foo/bar/different subdir/Filename with spaces.txt"));
writeln(dir.[toString](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.toString.html)()); // Always properly escaped for current platform
writeln(dir.[toRawString](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.toRawString.html)()); // Don't escape!

// Even file extentions are type-safe!
[Ext](http://semitwist.com/scriptlike/scriptlike/path/extras/Ext.html) ext = file.extension;
auto anotherFile = Path("/path/to/file") ~ ext;
assert(anotherFile.baseName == Path("file.txt"));

// [std.path](http://dlang.org/phobos/std_path.html) and [std.file](http://dlang.org/phobos/std_file.html) are wrapped to offer [Path](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html)/[Ext](http://semitwist.com/scriptlike/scriptlike/path/extras/Ext.html) support
assert([dirName](http://semitwist.com/scriptlike/scriptlike/path/wrappers/dirName.html)(anotherFile) == Path("/path/to"));
copy(anotherFile, Path("target/path/new file.txt"));
```

### User input prompts

With the [interact](http://semitwist.com/scriptlike/scriptlike/interact.html) module:

```d
auto name = userInput!string("Please enter your name");
auto age = userInput!int("And your age");

if(userInput!bool("Do you want to continue?"))
{
	auto outputFolder = pathLocation("Where you do want to place the output?");
	auto color = menu!string("What color would you like to use?", ["Blue", "Green"]);
}

auto num = require!(int, "a > 0 && a <= 10")("Enter a number from 1 to 10");

pause(); // Prompt "Press Enter to continue...";
pause("Heya, plz hit Enter again, dood...");
```

### Command echoing

Optionally enable automatic command echoing (including shell commands, changing/creating directories and deleting/copying/moving/linking/renaming both directories and files) by setting one simple flag: [bool scriptlikeEcho](http://semitwist.com/scriptlike/scriptlike/core/scriptlikeEcho.html)

```d
scriptlikeEcho = true; // Enable automatic echoing

run("echo Hello > file.txt");

auto newDir = Path("some/new/dir");
mkdirRecurse(newDir.toRawString()); // Even works with non-[Path](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html) overloads
copy("file.txt", newDir ~ "target name.txt");

void foo(int i = 42) {
	yapFunc("i = ", i); // Evaluated lazily
}

// yap and yapFunc ONLY output when echoing is enabled
yap("Gonna run foo() now...");
foo();

/++
Output:

tryRun: echo Hello > file.txt
mkdirRecurse: 'some/new/dir'
copy: 'file.txt' -> 'some/new/dir/target name.txt'
Gonna run foo() now...
foo: i = 42
+/
```

### Automatic Phobos import

For most typical Phobos modules. Unless you [don't want to](http://semitwist.com/scriptlike/scriptlike/only.html). Who needs rows and rows of standard lib imports for a mere script?

```d
import scriptlike;
//import [scriptlike.only](http://semitwist.com/scriptlike/scriptlike/only.html); // In case you don't want Phobos automatically
void main() {
	writeln("Works!");
}
```

### Try/As filesystem operations

Less pedantic, when you don't care if there's nothing to do:

```d
// Just MAKE SURFailE this exists! If it's already there, then GREAT!
[tryMkdir](http://semitwist.com/scriptlike/scriptlike/file/extras/tryMkdir.html)("somedir");
//[mkdir](http://semitwist.com/scriptlike/scriptlike/file/wrappers/mkdir.html)("somedir"); // Exception: Already exists!
[tryMkdir](http://semitwist.com/scriptlike/scriptlike/file/extras/tryMkdir.html)("somedir"); // No error, works fine!

// Just MAKE SURE this is gone! If it's already gone, then GREAT!
[tryRmdir](http://semitwist.com/scriptlike/scriptlike/file/extras/tryRmdir.html)("somedir");
//[mkdir](http://semitwist.com/scriptlike/scriptlike/file/wrappers/mkdir.html)("somedir"); // Exception: Already gone!
[tryRmdir](http://semitwist.com/scriptlike/scriptlike/file/extras/tryRmdir.html)("somedir"); // No error, works fine!

// Just MAKE SURE it doesn't exist. Don't bother me if it doesn't!
[tryRemove](http://semitwist.com/scriptlike/scriptlike/file/extras/tryRemove.html)("file");

// Copy if it exists, otherwise don't worry about it.
[tryCopy](http://semitwist.com/scriptlike/scriptlike/file/extras/tryCopy.html)("file", "file-copy");

// Is this a directory? If it doesn't even
// exist, then obviously it's NOT a directory.
if([existsAsDir](http://semitwist.com/scriptlike/scriptlike/file/extras/existsAsDir.html)("foo/bar"))
	{/+ ...do stuff... +/}
```

### Script-style shell commands

Invoke a command synchronously with forwarded stdout/in/err from any working directory, or capture the output instead. Automatically throw on non-zero status code if you want:

One simple call, [run](http://semitwist.com/scriptlike/scriptlike/process/run.html), to run a shell command script-style (ie, synchronously with forwarded stdout/in/err) from any working directory. Or [runCollect](http://semitwist.com/scriptlike/scriptlike/process/runCollect.html) to capture the output instead of displaying it.

```d
run("dmd --help"); // Display DMD help screen
pause(); // Wait for user to hit Enter

// Automatically throws ErrorLevelException(1, "dmd --bad-flag")
//run("dmd --bad-flag");

// Automatically throws ErrorLevelException(-1, "this-cmd-does-not-exist")
//run("this-cmd-does-not-exist");

// Don't bail on error
int statusCode = tryRun("dmd --bad-flag");

// Collect output instead of showing it
string dmdHelp = [runCollect](http://semitwist.com/scriptlike/scriptlike/process/runCollect.html)("dmd --help");
auto isDMD_2_068_1 = dmdHelp.canFind("D Compiler v2.068.1");

// Don't bail on error
auto result = [tryRunCollect](http://semitwist.com/scriptlike/scriptlike/process/tryRunCollect.html)("dmd --help");
if(result.status == 0 && result.output.canFind("D Compiler v2.068.1"))
	writeln("Found DMD v2.068.1!");

// Use any working directory:
auto myProjectDir = Path("my/proj/dir");
auto mainFile = Path("src/main.d");
myProjectDir.run(text("dmd ", mainFile, " -O")); // mainFile is properly escaped!

// Verify it actually IS running from a different working directory:
version(Posix)        enum pwd = "pwd";
else version(Windows) enum pwd = "cd";
else static assert(0);
auto expectedDir = getcwd() ~ myProjectDir;
assert( Path(myProjectDir.runCollect(pwd)) == expectedDir);
```
* One simple function, [fail(...)](http://semitwist.com/scriptlike/scriptlike/fail/fail.html), to help you exit with an error message in an exception-safe way. Doesn't require *any* boilerplate in your main()!. Or use it std.exception.enforce-style with [failEnforce(cond, ...)](http://semitwist.com/scriptlike/scriptlike/fail/failEnforce.html).

### Fail

Single function to bail out with an error message, exception-safe.

```d
<!-- test comment -->
import scriptlike;

// Throws a Fail exception on bad args:
void helper(string[] args) {
	// Like std.exception.enforce, but bails with no ugly stack trace,
	// and if uncaught, outputs the program name and "ERROR: "
	failEnforce(args.length == 3, "Need two args, not ", args.length-1, "!");

	if(args[1] != "foobar")
		fail("First arg must be 'foobar', not '", args[1], "'!");
}

void main(string[] args) {
	helper(args);
}

/++
Example:
$ rdmd test.d
test: ERROR: Need two args, not 0!
$ rdmd test.d abc 123
test: ERROR: First arg must be 'foobar', not 'abc'!
+/
```

### String interpolation

Variable expansion inside strings:

```d
// Output: The number 21 doubled is 42!
int num = 21;
writeln( mixin(interp!"The number ${num} doubled is ${num * 2}!") );

// Output: Empty braces output nothing.
writeln( mixin(interp!"Empty ${}braces ${}output nothing.") );

// Output: Multiple params: John Doe.
auto first = "John", last = "Doe";
writeln( mixin(interp!`Multiple params: ${first, " ", last}.`) );
```
