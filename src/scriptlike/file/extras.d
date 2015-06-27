/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))

Extra Scriptlike-only functionality to complement $(MODULE_STD_FILE).

Copyright: Copyright (C) 2014-2015 Nick Sabalausky
License:   zlib/libpng
Authors:   Nick Sabalausky
+/
module scriptlike.file.extras;

import std.algorithm;
import std.conv;
import std.datetime;
import std.string;
import std.traits;
import std.typecons;

static import std.file;
static import std.path;

import scriptlike.path;
import scriptlike.file.wrappers;

/// If true, all commands will be echoed. By default, they will be
/// echoed to stdout, but you can override this with scriptlikeCustomEcho.
bool scriptlikeEcho = false;

/// Alias for backwards-compatibility. This will be deprecated in the future.
/// You should use scriptlikeEcho insetad.
alias scriptlikeTraceCommands = scriptlikeEcho;

/++
If true, then run, tryRun, file write, file append, and all the echoable
commands that modify the filesystem will be echoed to stdout (regardless
of scriptlikeEcho) and NOT actually executed.

Warning! This is NOT a "set it and forget it" switch. You must still take
care to write your script in a way that's dryrun-safe. Two things to remember:

1. ONLY Scriptlike's functions will obey this setting. Calling Phobos
functions directly will BYPASS this setting.

2. If part of your script relies on a command having ACTUALLY been run, then
that command will fail. You must avoid that situation or work around it.
For example:

---------------------
run(`date > tempfile`);

// The following will FAIL or behave INCORRECTLY in dryrun mode:
auto data = cast(string)read("tempfile");
run("echo "~data);
---------------------

That may be an unrealistic example, but it demonstrates the problem: Normally,
the code above should run fine (at least on posix). But in dryrun mode,
"date" will not actually be run. Therefore, tempfile will neither be created
nor overwritten. Result: Either an exception reading a non-existent file,
or outdated information will be displayed.

Scriptlike cannot anticipate or handle such situations. So it's up to you to
make sure your script is dryrun-safe.
+/
bool scriptlikeDryRun = false;

/++
By default, scriptlikeEcho and scriptlikeDryRun echo to stdout.
You can override this behavior by setting scriptlikeCustomEcho to your own
sink delegate. Set this to null to go back to Scriptlike's default
of "echo to stdout" again.

Note, setting this does not automatically enable echoing. You still need to
set either scriptlikeEcho or scriptlikeDryRun to true.
+/
void delegate(string) scriptlikeCustomEcho;

/++
Output text lazily through scriptlike's echo logger.
Does nothing if scriptlikeEcho and scriptlikeDryRun are both false.

The yapFunc version automatically prepends the output with the
name of the calling function. Ex:

----------------
void foo(int i = 42) {
	// Outputs:
	// foo: i = 42
	yapFunc("i = ", i);
}
----------------
+/
void yap(T...)(lazy T args)
{
	import std.stdio;
	
	if(scriptlikeEcho || scriptlikeDryRun)
	{
		if(scriptlikeCustomEcho)
			scriptlikeCustomEcho(text(args));
		else
			writeln(args);
	}
}

///ditto
void yapFunc(string funcName=__FUNCTION__, T...)(lazy T args)
{
	static assert(funcName != "");
	
	auto funcNameSimple = funcName.split(".")[$-1];
	yap(funcNameSimple, ": ", args);
}

/// Maintained for backwards-compatibility. Will be deprecated.
/// Use 'yap' instead.
void echoCommand(lazy string msg)
{
	yap(msg);
}

/// Checks if the path exists as a directory.
///
/// This is like $(FULL_STD_FILE isDir), but returns false instead of
/// throwing if the path doesn't exist.
bool existsAsDir(in string path) @trusted
{
	yapFunc(path.escapeShellArg());
	return std.file.exists(path) && std.file.isDir(path);
}
///ditto
bool existsAsDir(in Path path) @trusted
{
	return existsAsDir(path.toRawString());
}

/// Checks if the path exists as a file.
///
/// This is like $(FULL_STD_FILE isFile), but returns false instead of
/// throwing if the path doesn't exist.
bool existsAsFile(in string path) @trusted
{
	yapFunc(path.escapeShellArg());
	return std.file.exists(path) && std.file.isFile(path);
}
///ditto
bool existsAsFile(in Path path) @trusted
{
	return existsAsFile(path.toRawString());
}

/// Checks if the path exists as a symlink.
///
/// This is like $(FULL_STD_FILE isSymlink), but returns false instead of
/// throwing if the path doesn't exist.
bool existsAsSymlink()(in string path) @trusted
{
	yapFunc(path.escapeShellArg());
	return std.file.exists(path) && std.file.isSymlink(path);
}
///ditto
bool existsAsSymlink(in Path path) @trusted
{
	return existsAsSymlink(path.toRawString());
}

/// If 'from' exists, then rename. Otherwise do nothing.
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryRename(T1, T2)(T1 from, T2 to)
	if(
		(is(T1==string) || is(T1==Path)) &&
		(is(T2==string) || is(T2==Path))
	)
{
	if(from.exists())
	{
		rename(from, to);
		return true;
	}

	return false;
}

/// If 'name' exists, then remove. Otherwise do nothing.
/// Supports Path, command echoing and dryrun.
///
/// Returns: Success?
bool tryRemove(T)(T name) if(is(T==string) || is(T==Path))
{
	if(name.exists())
	{
		remove(name);
		return true;
	}
	
	return false;
}

/// If 'name' doesn't already exist, then mkdir. Otherwise do nothing.
/// Supports Path and command echoing.
/// Returns: Success?
bool tryMkdir(T)(T name) if(is(T==string) || is(T==Path))
{
	if(!name.exists())
	{
		mkdir(name);
		return true;
	}
	
	return false;
}

/// If 'name' doesn't already exist, then mkdirRecurse. Otherwise do nothing.
/// Supports Path and command echoing.
/// Returns: Success?
bool tryMkdirRecurse(T)(T name) if(is(T==string) || is(T==Path))
{
	if(!name.exists())
	{
		mkdirRecurse(name);
		return true;
	}
	
	return false;
}

/// If 'name' exists, then rmdir. Otherwise do nothing.
/// Supports Path and command echoing.
/// Returns: Success?
bool tryRmdir(T)(T name) if(is(T==string) || is(T==Path))
{
	if(name.exists())
	{
		rmdir(name);
		return true;
	}
	
	return false;
}

version(ddoc_scriptlike_d)
{
	/// Posix-only. If 'original' exists, then symlink. Otherwise do nothing.
	/// Supports Path and command echoing.
	/// Returns: Success?
	bool trySymlink(T1, T2)(T1 original, T2 link)
		if(
			(is(T1==string) || is(T1==Path)) &&
			(is(T2==string) || is(T2==Path))
		);
}
else version(Posix)
{
	bool trySymlink(T1, T2)(T1 original, T2 link)
		if(
			(is(T1==string) || is(T1==Path)) &&
			(is(T2==string) || is(T2==Path))
		)
	{
		if(original.exists())
		{
			symlink(original, link);
			return true;
		}
		
		return false;
	}
}

/// If 'from' exists, then copy. Otherwise do nothing.
/// Supports Path and command echoing.
/// Returns: Success?
bool tryCopy(T1, T2)(T1 from, T2 to)
	if(
		(is(T1==string) || is(T1==Path)) &&
		(is(T2==string) || is(T2==Path))
	)
{
	if(from.exists())
	{
		copy(from, to);
		return true;
	}
	
	return false;
}

/// If 'name' exists, then rmdirRecurse. Otherwise do nothing.
/// Supports Path and command echoing.
/// Returns: Success?
bool tryRmdirRecurse(T)(T name) if(is(T==string) || is(T==Path))
{
	if(name.exists())
	{
		rmdirRecurse(name);
		return true;
	}
	
	return false;
}
