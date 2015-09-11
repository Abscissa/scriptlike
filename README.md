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

* [Filepaths](#filepaths)
* [User Input Prompts](#user-input-prompts)
* [Command Echoing](#command-echoing)
* [Automatic Phobos Import](#automatic-phobos-import)
* [Try/As Filesystem Operations](#tryas-filesystem-operations)
* [Script-style Shell Commands](#script-style-shell-commands)
* [Fail](#fail)
* [String Interpolation](#string-interpolation)

### Filepaths

Simple, reliable, cross-platform. No more worrying about slashes, paths-with-spaces, [buildPath](http://dlang.org/phobos/std_path.html#buildPath), [normalizing](http://dlang.org/phobos/std_path.html#buildNormalizedPath), or getting paths mixed up with ordinary strings:

```d
// This is AUTOMATICALLY kept normalized (via std.path.buildNormalizedPath)
auto dir = Path("foo/bar");
dir ~= "subdir"; // Append a subdirectory
//dir ~= "subdir/"; // IDENTICAL to previous line, no worries!

// No worries about forword/backslashes!
assert(dir == Path("foo/bar/subdir"));
assert(dir == Path("foo\\bar\\subdir"));

// No worries about spaces!
auto file = dir.up ~ "different subdir\\Filename with spaces.txt";
assert(dir == Path("foo/bar/different subdir/Filename with spaces.txt"));
writeln(dir.toString()); // Always properly escaped for current platform!
writeln(dir.toRawString()); // Don't escape!

// Even file extentions are type-safe!
Ext ext = file.extension;
auto anotherFile = Path("/path/to/file") ~ ext;
assert(anotherFile.baseName == Path("file.txt"));

// std.path and std.file are wrapped to offer Path/Ext support
assert(dirName(anotherFile) == Path("/path/to"));
copy(anotherFile, Path("target/path/new file.txt"));
```

See: [```Path```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html), [```Path.toString```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.toString.html), [```Path.toRawString```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.toRawString.html), [```Path.up```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.up.html), [```Ext```](http://semitwist.com/scriptlike/scriptlike/path/extras/Ext.html), [```dirName```](http://semitwist.com/scriptlike/scriptlike/path/wrappers/dirName.html), [```copy```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/copy.html), [```buildNormalizedPath```](http://dlang.org/phobos/std_path.html#buildNormalizedPath)

### User Input Prompts

Easy prompting for and verifying command-line user input with the [```interact```](http://semitwist.com/scriptlike/scriptlike/interact.html) module:

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
pause("Hit Enter again, dood!!");
```

See: [```userInput```](http://semitwist.com/scriptlike/scriptlike/interact/userInput.html), [```pathLocation```](http://semitwist.com/scriptlike/scriptlike/interact/pathLocation.html), [```menu```](http://semitwist.com/scriptlike/scriptlike/interact/menu.html), [```require```](http://semitwist.com/scriptlike/scriptlike/interact/require.html), [```pause```](http://semitwist.com/scriptlike/scriptlike/interact/pause.html)

### Command Echoing

Optionally enable automatic command echoing (including shell commands, changing/creating directories and deleting/copying/moving/linking/renaming both directories and files) by setting one simple flag: [```bool scriptlikeEcho```](http://semitwist.com/scriptlike/scriptlike/core/scriptlikeEcho.html)

```d
/++
Output:
--------
tryRun: echo Hello > file.txt
mkdirRecurse: 'some/new/dir'
copy: 'file.txt' -> 'some/new/dir/target name.txt'
Gonna run foo() now...
foo: i = 42
--------
+/

scriptlikeEcho = true; // Enable automatic echoing

run("echo Hello > file.txt");

auto newDir = Path("some/new/dir");
mkdirRecurse(newDir.toRawString()); // Even works with non-Path overloads
copy("file.txt", newDir ~ "target name.txt");

void foo(int i = 42) {
	yapFunc("i = ", i); // Evaluated lazily
}

// yap and yapFunc ONLY output when echoing is enabled
yap("Gonna run foo() now...");
foo();
```

See: [```scriptlikeEcho```](http://semitwist.com/scriptlike/scriptlike/core/scriptlikeEcho.html), [```yap```](http://semitwist.com/scriptlike/scriptlike/core/yap.html), [```yapFunc```](http://semitwist.com/scriptlike/scriptlike/core/yapFunc.html), [```run```](http://semitwist.com/scriptlike/scriptlike/process/run.html), [```Path```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html), [```Path.toRawString```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.toRawString.html), [```mkdirRecurse```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/mkdirRecurse.html), [```copy```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/copy.html)

### Automatic Phobos Import

For most typical Phobos modules. Unless you [don't want to](http://semitwist.com/scriptlike/scriptlike/only.html). Who needs rows and rows of standard lib imports for a mere script?

```d
import scriptlike;
//import scriptlike.only; // In case you don't want Phobos auto-imported
void main() {
	writeln("Works!");
}
```

See: Module [```scriptlike```](https://github.com/Abscissa/scriptlike/blob/examples/src/scriptlike/package.d), Module [```scriptlike.only```](https://github.com/Abscissa/scriptlike/blob/examples/src/scriptlike/only.d), Module [```scriptlike.std```](https://github.com/Abscissa/scriptlike/blob/examples/src/scriptlike/std.d)

### Try/As Filesystem Operations

Less pedantic, when you don't care if there's nothing to do:

```d
// Just MAKE SURE this exists! If it's already there, then GREAT!
tryMkdir("somedir");
//mkdir("somedir"); // Exception: Already exists!
tryMkdir("somedir"); // No error, works fine!

// Just MAKE SURE this is gone! If it's already gone, then GREAT!
tryRmdir("somedir");
//rmdir("somedir"); // Exception: Already gone!
tryRmdir("somedir"); // No error, works fine!

// Just MAKE SURE it doesn't exist. Don't bother me if it doesn't!
tryRemove("file");

// Copy if it exists, otherwise don't worry about it.
tryCopy("file", "file-copy");

// Is this a directory? If it doesn't even
// exist, then obviously it's NOT a directory.
if(existsAsDir("foo/bar"))
	{/+ ...do stuff... +/}
```

See: [```tryMkdir```](http://semitwist.com/scriptlike/scriptlike/file/extras/tryMkdir.html), [```mkdir```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/mkdir.html), [```tryRmdir```](http://semitwist.com/scriptlike/scriptlike/file/extras/tryRmdir.html), [```rmdir```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/rmdir.html), [```tryRemove```](http://semitwist.com/scriptlike/scriptlike/file/extras/tryRemove.html), [```tryCopy```](http://semitwist.com/scriptlike/scriptlike/file/extras/tryCopy.html), [```existsAsDir```](http://semitwist.com/scriptlike/scriptlike/file/extras/existsAsDir.html), and [more...](http://semitwist.com/scriptlike/scriptlike/file/extras.html)

### Script-style Shell Commands

Invoke a command synchronously with forwarded stdout/in/err from any working directory, or capture the output instead. Automatically throw on non-zero status code if you want:

One simple call, [```run```](http://semitwist.com/scriptlike/scriptlike/process/run.html), to run a shell command script-style (ie, synchronously with forwarded stdout/in/err) from any working directory, and automatically throw if it fails. Or [```runCollect```](http://semitwist.com/scriptlike/scriptlike/process/runCollect.html) to capture the output instead of displaying it. Or [```tryRun```](http://semitwist.com/scriptlike/scriptlike/process/tryRun.html)/[```tryRunCollect```](http://semitwist.com/scriptlike/scriptlike/process/tryRunCollect.html) if you want to receive the status code instead of automatically throwing on non-zero.

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
string dmdHelp = runCollect("dmd --help");
auto isDMD_2_068_1 = dmdHelp.canFind("D Compiler v2.068.1");

// Don't bail on error
auto result = tryRunCollect("dmd --help");
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

See: [```run```](http://semitwist.com/scriptlike/scriptlike/process/run.html), [```tryRun```](http://semitwist.com/scriptlike/scriptlike/process/tryRun.html), [```runCollect```](http://semitwist.com/scriptlike/scriptlike/process/runCollect.html), [```tryRunCollect```](http://semitwist.com/scriptlike/scriptlike/process/tryRunCollect.html), [```pause```](http://semitwist.com/scriptlike/scriptlike/interact/pause.html), [```Path```](http://semitwist.com/scriptlike/scriptlike/path/extras/Path.html), [```getcwd```](http://semitwist.com/scriptlike/scriptlike/file/wrappers/getcwd.html), [```canFind```](http://dlang.org/phobos/std_algorithm_searching.html#.canFind), [```text```](http://dlang.org/phobos/std_conv.html#text)

### Fail

Single function to bail out with an error message, exception-safe.

<!-- test comment -->
```d
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

See: [```fail```](http://semitwist.com/scriptlike/scriptlike/fail/fail.html), [```failEnforce```](http://semitwist.com/scriptlike/scriptlike/fail/failEnforce.html), [```Fail```](http://semitwist.com/scriptlike/scriptlike/fail/Fail.html)

### String Interpolation

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

See: [```interp```](http://semitwist.com/scriptlike\/scriptlike/core/interp.html)
 