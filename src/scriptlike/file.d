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

/// Output a (lazy) string through scriptlike's echo logger.
/// Does nothing if scriptlikeEcho and scriptlikeDryRun are both false.
void echoCommand(lazy string msg)
{
	import std.stdio;
	
	if(scriptlikeEcho || scriptlikeDryRun)
	{
		if(scriptlikeCustomEcho)
			scriptlikeCustomEcho(msg);
		else
			writeln(msg);
	}
}

/// Checks if the path exists as a directory.
///
/// This is like std.file.isDir, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsDir(in string path) @trusted
{
	return std.file.exists(path) && std.file.isDir(path);
}
///ditto
bool existsAsDir(in Path path) @trusted
{
	return existsAsDir(path.toRawString().to!string());
}

/// Checks if the path exists as a file.
///
/// This is like std.file.isFile, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsFile(in string path) @trusted
{
	return std.file.exists(path) && std.file.isFile(path);
}
///ditto
bool existsAsFile(in Path path) @trusted
{
	return existsAsFile(path.toRawString().to!string());
}

/// Checks if the path exists as a symlink.
///
/// This is like std.file.isSymlink, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsSymlink()(in string path) @trusted
{
	return std.file.exists(path) && std.file.isSymlink(path);
}
///ditto
bool existsAsSymlink(in Path path) @trusted
{
	return existsAsSymlink(path.toRawString().to!string());
}

// -- std.path wrappers to support Path type, scriptlikeEcho and scriptlikeDryRun --

/// Just like std.file.read, but takes a Path.
void[] read(in Path name, size_t upTo = size_t.max)
{
	return std.file.read(name.toRawString().to!string(), upTo);
}

/// Just like std.file.readText, but takes a Path.
S readText(S = string)(in Path name)
{
	return std.file.readText(name.toRawString().to!string());
}

/// Just like std.file.write, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void write(in Path name, const void[] buffer)
{
	write(name.toRawString().to!string(), buffer);
}

///ditto
void write(in string name, const void[] buffer)
{
	echoCommand(text("Write ", name));
	
	if(!scriptlikeDryRun)
		std.file.write(name, buffer);
}

/// Just like std.file.append, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void append(in Path name, in void[] buffer)
{
	append(name.toRawString().to!string(), buffer);
}

///ditto
void append(in string name, in void[] buffer)
{
	echoCommand(text("Append ", name));

	if(!scriptlikeDryRun)
		std.file.append(name, buffer);
}

/// Just like std.file.rename, but optionally takes Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void rename(in Path from, in Path to)
{
	rename(from.toRawString().to!string(), to.toRawString().to!string());
}

///ditto
void rename(in string from, in Path to)
{
	rename(from, to.toRawString().to!string());
}

///ditto
void rename(in Path from, in string to)
{
	rename(from.toRawString().to!string(), to);
}

///ditto
void rename(in string from, in string to)
{
	echoCommand("rename: "~from.escapeShellArg()~" -> "~to.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rename(from, to);
}

/// If 'from' exists, then rename. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.remove, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void remove(in Path name)
{
	remove(name.toRawString().to!string());
}

///ditto
void remove(in string name)
{
	echoCommand("remove: "~name.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.remove(name);
}

/// If 'name' exists, then remove. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.getSize, but takes a Path.
ulong getSize(in Path name)
{
	return std.file.getSize(name.toRawString().to!string());
}

/// Just like std.file.getTimes, but takes a Path.
void getTimes(in Path name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	std.file.getTimes(name.toRawString().to!string(), accessTime, modificationTime);
}

version(ddoc_scriptlike_d)
{
	/// Windows-only. Just like std.file.getTimesWin, but takes a Path.
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
	std.file.getTimesWin(name.toRawString().to!string(), fileCreationTime, fileAccessTime, fileModificationTime);
}

/// Just like std.file.setTimes, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void setTimes(in Path name,
	SysTime accessTime,
	SysTime modificationTime)
{
	setTimes(name.toRawString().to!string(), accessTime, modificationTime);
}

///ditto
void setTimes(in string name,
	SysTime accessTime,
	SysTime modificationTime)
{
	echoCommand(text(
		"setTimes: ", name.escapeShellArg(),
		" Accessed ", accessTime, "; Modified ", modificationTime
	));

	if(!scriptlikeDryRun)
		std.file.setTimes(name, accessTime, modificationTime);
}

/// Just like std.file.timeLastModified, but takes a Path.
SysTime timeLastModified(in Path name)
{
	return std.file.timeLastModified(name.toRawString().to!string());
}

/// Just like std.file.timeLastModified, but takes a Path.
SysTime timeLastModified(in Path name, SysTime returnIfMissing)
{
	return std.file.timeLastModified(name.toRawString().to!string(), returnIfMissing);
}

/// Just like std.file.exists, but takes a Path.
bool exists(in Path name) @trusted
{
	return std.file.exists(name.toRawString().to!string());
}

/// Just like std.file.getAttributes, but takes a Path.
uint getAttributes(in Path name)
{
	return std.file.getAttributes(name.toRawString().to!string());
}

/// Just like std.file.getLinkAttributes, but takes a Path.
uint getLinkAttributes(in Path name)
{
	return std.file.getLinkAttributes(name.toRawString().to!string());
}

/// Just like std.file.isDir, but takes a Path.
@property bool isDir(in Path name)
{
	return std.file.isDir(name.toRawString().to!string());
}

/// Just like std.file.isFile, but takes a Path.
@property bool isFile(in Path name)
{
	return std.file.isFile(name.toRawString().to!string());
}

/// Just like std.file.isSymlink, but takes a Path.
@property bool isSymlink(Path name)
{
	return std.file.isSymlink(name.toRawString().to!string());
}

/// Just like std.file.getcwd, but returns a Path.
Path getcwd()
{
	return Path( std.file.getcwd() );
}

/// Just like std.file.chdir, but takes a Path, and echoes if scriptlikeEcho is true.
void chdir(in Path pathname)
{
	chdir(pathname.toRawString().to!string());
}

/// Just like std.file.chdir, but echoes if scriptlikeEcho is true.
void chdir(in string pathname)
{
	echoCommand("chdir: "~pathname.escapeShellArg());
	std.file.chdir(pathname);
}

/// Just like std.file.mkdir, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void mkdir(in Path pathname)
{
	mkdir(pathname.toRawString().to!string());
}

///ditto
void mkdir(in string pathname)
{
	echoCommand("mkdir: "~pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.mkdir(pathname);
}

/// If 'name' doesn't already exist, then mkdir. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.mkdirRecurse, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void mkdirRecurse(in Path pathname)
{
	mkdirRecurse(pathname.toRawString().to!string());
}

///ditto
void mkdirRecurse(in string pathname)
{
	echoCommand("mkdirRecurse: "~pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.mkdirRecurse(pathname);
}

/// If 'name' doesn't already exist, then mkdirRecurse. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.rmdir, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void rmdir(in Path pathname)
{
	rmdir(pathname.toRawString().to!string());
}

///ditto
void rmdir(in string pathname)
{
	echoCommand("rmdir: "~pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rmdir(pathname);
}

/// If 'name' exists, then rmdir. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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
	/// Posix-only. Just like std.file.symlink, but optionally takes Path,
	/// and obeys scriptlikeEcho and scriptlikeDryRun.
	void symlink(Path original, Path link);

	///ditto
	void symlink(string original, Path link);

	///ditto
	void symlink(Path original, string link);

	///ditto
	void symlink(string original, string link);

	/// Posix-only. If 'original' exists, then symlink. Otherwise do nothing.
	/// Obeys scriptlikeEcho and scriptlikeDryRun.
	/// Returns: Success?
	bool trySymlink(T1, T2)(T1 original, T2 link)
		if(
			(is(T1==string) || is(T1==Path)) &&
			(is(T2==string) || is(T2==Path))
		);

	/// Posix-only. Just like std.file.readLink, but operates on Path.
	Path readLink(Path link);
}
else version(Posix)
{
	void symlink(Path original, Path link)
	{
		symlink(original.toRawString().to!string(), link.toRawString().to!string());
	}

	void symlink(string original, Path link)
	{
		symlink(original, link.toRawString().to!string());
	}

	void symlink(Path original, string link)
	{
		symlink(original.toRawString().to!string(), link);
	}

	void symlink(string original, string link)
	{
		echoCommand("symlink: [original] "~original.escapeShellArg()~" : [symlink] "~link.escapeShellArg());

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
		return Path( std.file.readLink(link.toRawString().to!string()) );
	}
}

/// Just like std.file.copy, but optionally takes Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void copy(in Path from, in Path to)
{
	copy(from.toRawString().to!string(), to.toRawString().to!string());
}

///ditto
void copy(in string from, in Path to)
{
	copy(from, to.toRawString().to!string());
}

///ditto
void copy(in Path from, in string to)
{
	copy(from.toRawString().to!string(), to);
}

///ditto
void copy(in string from, in string to)
{
	echoCommand("copy: "~from.escapeShellArg()~" -> "~to.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.copy(from, to);
}

/// If 'from' exists, then copy. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.rmdirRecurse, but optionally takes a Path,
/// and obeys scriptlikeEcho and scriptlikeDryRun.
void rmdirRecurse(in Path pathname)
{
	rmdirRecurse(pathname.toRawString().to!string());
}

///ditto
void rmdirRecurse(in string pathname)
{
	echoCommand("rmdirRecurse: "~pathname.escapeShellArg());

	if(!scriptlikeDryRun)
		std.file.rmdirRecurse(pathname);
}

/// If 'name' exists, then rmdirRecurse. Otherwise do nothing.
/// Obeys scriptlikeEcho and scriptlikeDryRun.
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

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(Path path, SpanMode mode, bool followSymlink = true)
{
	return std.file.dirEntries(path.toRawString().to!string(), mode, followSymlink);
}

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(Path path, string pattern, SpanMode mode,
	bool followSymlink = true)
{
	return std.file.dirEntries(path.toRawString().to!string(), pattern, mode, followSymlink);
}

/// Just like std.file.slurp, but takes a Path.
template slurp(Types...)
{
	auto slurp(Path filename, in string format)
	{
		return std.file.slurp!Types(filename.toRawString().to!string(), format);
	}
}

/// Just like std.file.thisExePath, but returns a Path.
@trusted Path thisExePath()
{
	return Path( std.file.thisExePath() );
}

/// Just like std.file.tempDir, but returns a Path.
@trusted Path tempDir()
{
	return Path( std.file.tempDir() );
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
