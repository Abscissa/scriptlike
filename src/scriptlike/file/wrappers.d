/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))

Wrappers for $(MODULE_STD_FILE) that add support for Scriptlike's
$(API_PATH_EXTR Path), command echoing and dry-run features.

Copyright: Copyright (C) 2014-2015 Nick Sabalausky
License:   zlib/libpng
Authors:   Nick Sabalausky
+/
module scriptlike.file.wrappers;

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

import scriptlike.file.extras;
import scriptlike.path.extras;

/// Like $(FULL_STD_FILE read), but supports Path and command echoing.
void[] read(in Path name, size_t upTo = size_t.max)
{
	yapFunc(name);
	return std.file.read(name.toRawString(), upTo);
}

/// Like $(FULL_STD_FILE readText), but supports Path and command echoing.
S readText(S = string)(in Path name)
{
	yapFunc(name);
	return std.file.readText(name.toRawString());
}

/// Like $(FULL_STD_FILE write), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE append), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE rename), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE remove), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE getSize), but supports Path and command echoing.
ulong getSize(in Path name)
{
	yapFunc(name);
	return std.file.getSize(name.toRawString());
}

/// Like $(FULL_STD_FILE getTimes), but supports Path and command echoing.
void getTimes(in Path name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	yapFunc(name);
	std.file.getTimes(name.toRawString(), accessTime, modificationTime);
}

version(ddoc_scriptlike_d)
{
	/// Windows-only. Like $(FULL_STD_FILE getTimesWin), but supports Path and command echoing.
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

/// Like $(FULL_STD_FILE setTimes), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE timeLastModified), but supports Path and command echoing.
SysTime timeLastModified(in Path name)
{
	yapFunc(name);
	return std.file.timeLastModified(name.toRawString());
}

/// Like $(FULL_STD_FILE timeLastModified), but supports Path and command echoing.
SysTime timeLastModified(in Path name, SysTime returnIfMissing)
{
	yapFunc(name);
	return std.file.timeLastModified(name.toRawString(), returnIfMissing);
}

/// Like $(FULL_STD_FILE exists), but supports Path and command echoing.
bool exists(in Path name) @trusted
{
	yapFunc(name);
	return std.file.exists(name.toRawString());
}

/// Like $(FULL_STD_FILE getAttributes), but supports Path and command echoing.
uint getAttributes(in Path name)
{
	yapFunc(name);
	return std.file.getAttributes(name.toRawString());
}

/// Like $(FULL_STD_FILE getLinkAttributes), but supports Path and command echoing.
uint getLinkAttributes(in Path name)
{
	yapFunc(name);
	return std.file.getLinkAttributes(name.toRawString());
}

/// Like $(FULL_STD_FILE isDir), but supports Path and command echoing.
@property bool isDir(in Path name)
{
	yapFunc(name);
	return std.file.isDir(name.toRawString());
}

/// Like $(FULL_STD_FILE isFile), but supports Path and command echoing.
@property bool isFile(in Path name)
{
	yapFunc(name);
	return std.file.isFile(name.toRawString());
}

/// Like $(FULL_STD_FILE isSymlink), but supports Path and command echoing.
@property bool isSymlink(Path name)
{
	yapFunc(name);
	return std.file.isSymlink(name.toRawString());
}

/// Like $(FULL_STD_FILE getcwd), but returns a Path.
Path getcwd()
{
	return Path( std.file.getcwd() );
}

/// Like $(FULL_STD_FILE chdir), but supports Path and command echoing.
void chdir(in Path pathname)
{
	chdir(pathname.toRawString());
}

/// Like $(FULL_STD_FILE chdir), but supports Path and command echoing.
void chdir(in string pathname)
{
	yapFunc(pathname.escapeShellArg());
	std.file.chdir(pathname);
}

/// Like $(FULL_STD_FILE mkdir), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE mkdirRecurse), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE rmdir), but supports Path, command echoing and dryrun.
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

version(ddoc_scriptlike_d)
{
	/// Posix-only. Like $(FULL_STD_FILE symlink), but supports Path and command echoing.
	void symlink(Path original, Path link);

	///ditto
	void symlink(string original, Path link);

	///ditto
	void symlink(Path original, string link);

	///ditto
	void symlink(string original, string link);

	/// Posix-only. Like $(FULL_STD_FILE readLink), but supports Path and command echoing.
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

	Path readLink(Path link)
	{
		yapFunc(link);
		return Path( std.file.readLink(link.toRawString()) );
	}
}

/// Like $(FULL_STD_FILE copy), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE rmdirRecurse), but supports Path, command echoing and dryrun.
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

/// Like $(FULL_STD_FILE dirEntries), but supports Path and command echoing.
auto dirEntries(Path path, SpanMode mode, bool followSymlink = true)
{
	yapFunc(path);
	return std.file.dirEntries(path.toRawString(), mode, followSymlink);
}

/// Like $(FULL_STD_FILE dirEntries), but supports Path and command echoing.
auto dirEntries(Path path, string pattern, SpanMode mode,
	bool followSymlink = true)
{
	yapFunc(path);
	return std.file.dirEntries(path.toRawString(), pattern, mode, followSymlink);
}

/// Like $(FULL_STD_FILE slurp), but supports Path and command echoing.
template slurp(Types...)
{
	auto slurp(Path filename, in string format)
	{
		yapFunc(filename);
		return std.file.slurp!Types(filename.toRawString(), format);
	}
}

/// Like $(FULL_STD_FILE thisExePath), but supports Path and command echoing.
@trusted Path thisExePath()
{
	auto path = Path( std.file.thisExePath() );
	yapFunc(path);
	return path;
}

/// Like $(FULL_STD_FILE tempDir), but supports Path and command echoing.
@trusted Path tempDir()
{
	auto path = Path( std.file.tempDir() );
	yapFunc(path);
	return path;
}
