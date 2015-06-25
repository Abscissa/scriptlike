// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

/// Copyright: Copyright (C) 2014-2015 Nick Sabalausky
/// License:   zlib/libpng
/// Authors:   Nick Sabalausky

module scriptlike.file;

import std.algorithm;
import std.conv;
import std.datetime;
import std.string;
import std.traits;
import std.typecons;

static import std.file;
public import std.file : FileException, SpanMode,
	attrIsDir, attrIsFile, attrIsSymlink;
static import std.path;

import scriptlike.path;

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
/// This is like std.file.isDir, but returns false instead of throwing if the
/// path doesn't exist.
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
/// This is like std.file.isFile, but returns false instead of throwing if the
/// path doesn't exist.
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
/// This is like std.file.isSymlink, but returns false instead of throwing if the
/// path doesn't exist.
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

// -- std.path wrappers to support Path, scriptlikeEcho and scriptlikeDryRun --

/// Like std.file.read, but supports Path and command echoing.
void[] read(in Path name, size_t upTo = size_t.max)
{
	yapFunc(name);
	return std.file.read(name.toRawString(), upTo);
}

/// Like std.file.readText, but supports Path and command echoing.
S readText(S = string)(in Path name)
{
	yapFunc(name);
	return std.file.readText(name.toRawString());
}

/// Like std.file.write, but supports Path, command echoing and dryrun.
void write(in Path name, const void[] buffer)
{
	write(name.toRawString(), buffer);
}

///ditto
void write(in string name, const void[] buffer)
{
	yapFunc(name.escapeShellArg());
	
	if(!scriptlikeDryRun)
		std.file.write(name, buffer);
}

/// Like std.file.append, but supports Path, command echoing and dryrun.
void append(in Path name, in void[] buffer)
{
	append(name.toRawString(), buffer);
}

///ditto
void append(in string name, in void[] buffer)
{
	yapFunc(name.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.append(name, buffer);
}

/// Like std.file.rename, but supports Path, command echoing and dryrun.
void rename(in Path from, in Path to)
{
	rename(from.toRawString(), to.toRawString());
}

///ditto
void rename(in string from, in Path to)
{
	rename(from, to.toRawString());
}

///ditto
void rename(in Path from, in string to)
{
	rename(from.toRawString(), to);
}

///ditto
void rename(in string from, in string to)
{
	yapFunc(from.escapeShellArg(), " -> ", to.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rename(from, to);
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

/// Like std.file.remove, but supports Path, command echoing and dryrun.
void remove(in Path name)
{
	remove(name.toRawString());
}

///ditto
void remove(in string name)
{
	yapFunc(name.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.remove(name);
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

/// Like std.file.getSize, but supports Path and command echoing.
ulong getSize(in Path name)
{
	yapFunc(name);
	return std.file.getSize(name.toRawString());
}

/// Like std.file.getTimes, but supports Path and command echoing.
void getTimes(in Path name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	yapFunc(name);
	std.file.getTimes(name.toRawString(), accessTime, modificationTime);
}

version(ddoc_scriptlike_d)
{
	/// Windows-only. Like std.file.getTimesWin, but supports Path and command echoing.
	void getTimesWin(in Path name,
		out SysTime fileCreationTime,
		out SysTime fileAccessTime,
		out SysTime fileModificationTime);
}
else version(Windows) void getTimesWin(in Path name,
	out SysTime fileCreationTime,
	out SysTime fileAccessTime,
	out SysTime fileModificationTime)
{
	yapFunc(name);
	std.file.getTimesWin(name.toRawString(), fileCreationTime, fileAccessTime, fileModificationTime);
}

/// Like std.file.setTimes, but supports Path, command echoing and dryrun.
void setTimes(in Path name,
	SysTime accessTime,
	SysTime modificationTime)
{
	setTimes(name.toRawString(), accessTime, modificationTime);
}

///ditto
void setTimes(in string name,
	SysTime accessTime,
	SysTime modificationTime)
{
	yapFunc(name.escapeShellArg(),
		"Accessed ", accessTime, "; Modified ", modificationTime);

	if(!scriptlikeDryRun)
		std.file.setTimes(name, accessTime, modificationTime);
}

/// Like std.file.timeLastModified, but supports Path and command echoing.
SysTime timeLastModified(in Path name)
{
	yapFunc(name);
	return std.file.timeLastModified(name.toRawString());
}

/// Like std.file.timeLastModified, but supports Path and command echoing.
SysTime timeLastModified(in Path name, SysTime returnIfMissing)
{
	yapFunc(name);
	return std.file.timeLastModified(name.toRawString(), returnIfMissing);
}

/// Like std.file.exists, but supports Path and command echoing.
bool exists(in Path name) @trusted
{
	yapFunc(name);
	return std.file.exists(name.toRawString());
}

/// Like std.file.getAttributes, but supports Path and command echoing.
uint getAttributes(in Path name)
{
	yapFunc(name);
	return std.file.getAttributes(name.toRawString());
}

/// Like std.file.getLinkAttributes, but supports Path and command echoing.
uint getLinkAttributes(in Path name)
{
	yapFunc(name);
	return std.file.getLinkAttributes(name.toRawString());
}

/// Like std.file.isDir, but supports Path and command echoing.
@property bool isDir(in Path name)
{
	yapFunc(name);
	return std.file.isDir(name.toRawString());
}

/// Like std.file.isFile, but supports Path and command echoing.
@property bool isFile(in Path name)
{
	yapFunc(name);
	return std.file.isFile(name.toRawString());
}

/// Like std.file.isSymlink, but supports Path and command echoing.
@property bool isSymlink(Path name)
{
	yapFunc(name);
	return std.file.isSymlink(name.toRawString());
}

/// Like std.file.getcwd, but returns a Path.
Path getcwd()
{
	return Path( std.file.getcwd() );
}

/// Like std.file.chdir, but supports Path and command echoing.
void chdir(in Path pathname)
{
	chdir(pathname.toRawString());
}

/// Like std.file.chdir, but supports Path and command echoing.
void chdir(in string pathname)
{
	yapFunc(pathname.escapeShellArg());
	std.file.chdir(pathname);
}

/// Like std.file.mkdir, but supports Path, command echoing and dryrun.
void mkdir(in Path pathname)
{
	mkdir(pathname.toRawString());
}

///ditto
void mkdir(in string pathname)
{
	yapFunc(pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.mkdir(pathname);
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

/// Like std.file.mkdirRecurse, but supports Path, command echoing and dryrun.
void mkdirRecurse(in Path pathname)
{
	mkdirRecurse(pathname.toRawString());
}

///ditto
void mkdirRecurse(in string pathname)
{
	yapFunc(pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.mkdirRecurse(pathname);
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

/// Like std.file.rmdir, but supports Path, command echoing and dryrun.
void rmdir(in Path pathname)
{
	rmdir(pathname.toRawString());
}

///ditto
void rmdir(in string pathname)
{
	yapFunc(pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rmdir(pathname);
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
	/// Posix-only. Like std.file.symlink, but supports Path and command echoing.
	void symlink(Path original, Path link);

	///ditto
	void symlink(string original, Path link);

	///ditto
	void symlink(Path original, string link);

	///ditto
	void symlink(string original, string link);

	/// Posix-only. If 'original' exists, then symlink. Otherwise do nothing.
	/// Supports Path and command echoing.
	/// Returns: Success?
	bool trySymlink(T1, T2)(T1 original, T2 link)
		if(
			(is(T1==string) || is(T1==Path)) &&
			(is(T2==string) || is(T2==Path))
		);

	/// Posix-only. Like std.file.readLink, but supports Path and command echoing.
	Path readLink(Path link);
}
else version(Posix)
{
	void symlink(Path original, Path link)
	{
		symlink(original.toRawString(), link.toRawString());
	}

	void symlink(string original, Path link)
	{
		symlink(original, link.toRawString());
	}

	void symlink(Path original, string link)
	{
		symlink(original.toRawString(), link);
	}

	void symlink(string original, string link)
	{
		yapFunc("[original] ", original.escapeShellArg(), " : [symlink] ", link.escapeShellArg());

		if(!scriptlikeDryRun)
			std.file.symlink(original, link);
	}

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

	Path readLink(Path link)
	{
		yapFunc(link);
		return Path( std.file.readLink(link.toRawString()) );
	}
}

/// Like std.file.copy, but supports Path, command echoing and dryrun.
void copy(in Path from, in Path to)
{
	copy(from.toRawString(), to.toRawString());
}

///ditto
void copy(in string from, in Path to)
{
	copy(from, to.toRawString());
}

///ditto
void copy(in Path from, in string to)
{
	copy(from.toRawString(), to);
}

///ditto
void copy(in string from, in string to)
{
	yapFunc(from.escapeShellArg(), " -> ", to.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.copy(from, to);
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

/// Like std.file.rmdirRecurse, but supports Path, command echoing and dryrun.
void rmdirRecurse(in Path pathname)
{
	rmdirRecurse(pathname.toRawString());
}

///ditto
void rmdirRecurse(in string pathname)
{
	yapFunc(pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rmdirRecurse(pathname);
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

/// Like std.file.dirEntries, but supports Path and command echoing.
auto dirEntries(Path path, SpanMode mode, bool followSymlink = true)
{
	yapFunc(path);
	return std.file.dirEntries(path.toRawString(), mode, followSymlink);
}

/// Like std.file.dirEntries, but supports Path and command echoing.
auto dirEntries(Path path, string pattern, SpanMode mode,
	bool followSymlink = true)
{
	yapFunc(path);
	return std.file.dirEntries(path.toRawString(), pattern, mode, followSymlink);
}

/// Like std.file.slurp, but supports Path and command echoing.
template slurp(Types...)
{
	auto slurp(Path filename, in string format)
	{
		yapFunc(filename);
		return std.file.slurp!Types(filename.toRawString(), format);
	}
}

/// Like std.file.thisExePath, but supports Path and command echoing.
@trusted Path thisExePath()
{
	auto path = Path( std.file.thisExePath() );
	yapFunc(path);
	return path;
}

/// Like std.file.tempDir, but supports Path and command echoing.
@trusted Path tempDir()
{
	auto path = Path( std.file.tempDir() );
	yapFunc(path);
	return path;
}

version(unittest_scriptlike_d)
unittest
{
	// std.file.slurp seems to randomly trigger an internal std.algorithm
	// assert failure on DMD 2.064.2, so don't test it there. Seems
	// to be fixed in DMD 2.065.
	static import std.compiler;
	static if(
		std.compiler.vendor == std.compiler.Vendor.digitalMars ||
		(std.compiler.version_major == 2 && std.compiler.version_minor == 64)
	)
		enum testSlurp = false;
	else
		enum testSlurp = true;

	import std.stdio : writeln;
	import std.process : thisProcessID;
	import core.thread;
	alias copy = scriptlike.path.copy;

	writeln("Running Scriptlike unittests: std.file wrappers");
	
	immutable tempname  = std.path.buildPath(std.file.tempDir(), "deleteme.script like.unit test.pid"  ~ to!string(thisProcessID));
	immutable tempname2 = std.path.buildPath(std.file.tempDir(), "deleteme.script like.unit test2.pid" ~ to!string(thisProcessID));
	immutable tempname3 = std.path.buildPath(std.file.tempDir(), "deleteme.script like.unit test3.pid" ~ to!string(thisProcessID), "somefile");
	auto tempPath  = Path(tempname);
	auto tempPath2 = Path(tempname2);
	auto tempPath3 = Path(tempname3);
	assert(!std.file.exists(tempname));
	assert(!std.file.exists(tempname2));
	assert(!std.file.exists( std.path.dirName(tempname3) ));
	assert(!std.file.exists(tempname3));
	
	{
		scope(exit)
		{
			if(std.file.exists(tempname)) std.file.remove(tempname);
		}

		tempPath.write("stuff");

		tempPath.append(" more");
		assert(tempPath.read(3) == "stu");
		assert(tempPath.read() == "stuff more");
		assert(tempPath.readText() == "stuff more");
		assert(tempPath.getSize() == 10);

		if(testSlurp)
		{
			auto parsed = tempPath.slurp!(string, string)("%s %s");
			assert(equal(parsed, [tuple("stuff", "more")]));
		}
		
		SysTime timeA, timeB, timeC;
		tempPath.getTimes(timeA, timeB);
		version(Windows)
			tempPath.getTimesWin(timeA, timeB, timeC);
		tempPath.setTimes(timeA, timeB);
		timeA = tempPath.timeLastModified();
		timeA = tempPath.timeLastModified(timeB);
		
		uint attr;
		attr = tempPath.getAttributes();
		attr = tempPath.getLinkAttributes();
		
		assert(tempPath.exists());
		assert(tempPath.isFile());
		assert(tempPath.existsAsFile());
		assert(!tempPath.isDir());
		assert(!tempPath.existsAsDir());
		assert(!tempPath.isSymlink());
		assert(!tempPath.existsAsSymlink());
		tempPath.remove();
		assert(!tempPath.exists());
		assert(!tempPath.existsAsFile());
		assert(!tempPath.existsAsDir());
		assert(!tempPath.existsAsSymlink());
	}
	
	{
		assert(!tempPath.exists());
		assert(!tempPath2.exists());

		scope(exit)
		{
			if(std.file.exists(tempname))  std.file.remove(tempname);
			if(std.file.exists(tempname2)) std.file.remove(tempname2);
		}
		tempPath.write("ABC");
		
		assert(tempPath.existsAsFile());
		assert(!tempPath2.exists());

		tempPath.rename(tempPath2);
		
		assert(!tempPath.exists());
		assert(tempPath2.existsAsFile());
		
		tempPath2.copy(tempPath);
		
		assert(tempPath.existsAsFile());
		assert(tempPath2.existsAsFile());
	}
	
	{
		scope(exit)
		{
			if(std.file.exists(tempname))  std.file.rmdir(tempname);
			if(std.file.exists(tempname3)) std.file.rmdir(tempname3);
			if(std.file.exists( std.path.dirName(tempname3) )) std.file.rmdir( std.path.dirName(tempname3) );
		}
		
		assert(!tempPath.exists());
		assert(!tempPath3.exists());
		
		tempPath.mkdir();
		assert(tempPath.exists());
		assert(!tempPath.isFile());
		assert(!tempPath.existsAsFile());
		assert(tempPath.isDir());
		assert(tempPath.existsAsDir());
		assert(!tempPath.isSymlink());
		assert(!tempPath.existsAsSymlink());

		tempPath3.mkdirRecurse();
		assert(tempPath3.exists());
		assert(!tempPath3.isFile());
		assert(!tempPath3.existsAsFile());
		assert(tempPath3.isDir());
		assert(tempPath3.existsAsDir());
		assert(!tempPath3.isSymlink());
		assert(!tempPath3.existsAsSymlink());
		
		auto saveDirName = std.file.getcwd();
		auto saveDir = Path(saveDirName);
		scope(exit) chdir(saveDirName);

		tempPath.chdir();
		assert(getcwd() == tempname);
		saveDir.chdir();
		assert(getcwd() == saveDirName);
		
		auto entries1 = (tempPath3~"..").dirEntries(SpanMode.shallow);
		assert(!entries1.empty);
		auto entries2 = (tempPath3~"..").dirEntries("*", SpanMode.shallow);
		assert(!entries2.empty);
		auto entries3 = (tempPath3~"..").dirEntries("TUNA TUNA THIS DOES NOT EXIST TUNA WHEE", SpanMode.shallow);
		assert(entries3.empty);
		
		tempPath.rmdir();
		assert(!tempPath.exists());
		assert(!tempPath.existsAsFile());
		assert(!tempPath.existsAsDir());
		assert(!tempPath.existsAsSymlink());

		tempPath3.rmdirRecurse();
		assert(!tempPath.exists());
		assert(!tempPath.existsAsFile());
		assert(!tempPath.existsAsDir());
		assert(!tempPath.existsAsSymlink());
	}
	
	{
		version(Posix)
		{
			assert(!tempPath.exists());
			assert(!tempPath2.exists());

			scope(exit)
			{
				if(std.file.exists(tempname2)) std.file.remove(tempname2);
				if(std.file.exists(tempname))  std.file.remove(tempname);
			}
			tempPath.write("DEF");
			
			tempPath.symlink(tempPath2);
			assert(tempPath2.exists());
			assert(tempPath2.isFile());
			assert(tempPath2.existsAsFile());
			assert(!tempPath2.isDir());
			assert(!tempPath2.existsAsDir());
			assert(tempPath2.isSymlink());
			assert(tempPath2.existsAsSymlink());
			
			auto linkTarget = tempPath2.readLink();
			assert(linkTarget.toRawString() == tempname);
		}
	}
	
	{
		assert(!tempPath.exists());

		scope(exit)
		{
			if(std.file.exists(tempname)) std.file.remove(tempname);
		}

		import scriptlike.process;
		run(`echo TestScriptStuff > `~tempPath.to!string());
		assert(tempPath.exists());
		assert(tempPath.isFile());
		assert((cast(string)tempPath.read()).strip() == "TestScriptStuff");
		tempPath.remove();
		assert(!tempPath.exists());

		auto errlevel = tryRun(`echo TestScriptStuff > `~tempPath.to!string());
		assert(tempPath.exists());
		assert(tempPath.isFile());
		assert((cast(string)tempPath.read()).strip() == "TestScriptStuff");
		assert(errlevel == 0);
		tempPath.remove();
		assert(!tempPath.exists());

		import scriptlike.process;
		getcwd().run(`echo TestScriptStuff > `~tempPath.to!string());
		getcwd().tryRun(`echo TestScriptStuff > `~tempPath.to!string());
	}
	
	{
		assert(!tempPath3.exists());
		assert(!tempPath3.up.exists());

		scope(exit)
		{
			if(std.file.exists(tempname3)) std.file.remove(tempname3);
			if(std.file.exists( std.path.dirName(tempname3) )) std.file.rmdir( std.path.dirName(tempname3) );
		}
		
		tempPath3.up.mkdir();
		assert(tempPath3.up.exists());
		assert(tempPath3.up.isDir());
				
		import scriptlike.process;
		tempPath3.up.run(`echo MoreTestStuff > `~tempPath3.baseName().to!string());
		assert(tempPath3.exists());
		assert(tempPath3.isFile());
		assert((cast(string)tempPath3.read()).strip() == "MoreTestStuff");
	}

	{
		scope(exit)
		{
			if(std.file.exists(tempname))  std.file.rmdir(tempname);
			if(std.file.exists(tempname3)) std.file.rmdir(tempname3);
			if(std.file.exists( std.path.dirName(tempname3) )) std.file.rmdir( std.path.dirName(tempname3) );
		}
		
		assert(!tempPath.exists());
		assert(!tempPath3.exists());
		
		assert(!tempPath.tryRmdir());
		assert(!tempPath.tryRmdirRecurse());
		assert(!tempPath.tryRemove());
		assert(!tempPath.tryRename(tempPath3));
		version(Posix) assert(!tempPath.trySymlink(tempPath3));
		assert(!tempPath.tryCopy(tempPath3));

		assert(tempPath.tryMkdir());
		assert(tempPath.exists());
		assert(!tempPath.tryMkdir());
		assert(!tempPath.tryMkdirRecurse());

		assert(tempPath.tryRmdir());
		assert(!tempPath.exists());

		assert(tempPath.tryMkdirRecurse());
		assert(tempPath.exists());
		assert(!tempPath.tryMkdirRecurse());
	}
}
