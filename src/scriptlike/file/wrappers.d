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

import scriptlike.core;
import scriptlike.path.extras;

/// Alias of same-named function from $(MODULE_STD_FILE)
alias read       = std.file.read;
alias readText() = std.file.readText; ///ditto
//alias write      = std.file.write;    ///ditto
//alias append     = std.file.append;   ///ditto
//alias rename     = std.file.rename;   ///ditto
//alias remove     = std.file.remove;   ///ditto
//alias getSize    = std.file.getSize;  ///ditto
//alias getTimes   = std.file.getTimes; ///ditto

//version(ddoc_scriptlike_d) alias getTimesWin = std.file.getTimesWin; ///ditto
//else version(Windows)      alias getTimesWin = std.file.getTimesWin; ///ditto

//alias setTimes          = std.file.setTimes;          ///ditto
//alias timeLastModified  = std.file.timeLastModified;  ///ditto
//alias exists            = std.file.exists;            ///ditto
//alias getAttributes     = std.file.getAttributes;     ///ditto
//alias getLinkAttributes = std.file.getLinkAttributes; ///ditto
//alias isDir             = std.file.isDir;             ///ditto
//alias isFile            = std.file.isFile;            ///ditto
//alias isSymlink()       = std.file.isSymlink;         ///ditto
alias chdir             = std.file.chdir;             ///ditto
alias mkdir             = std.file.mkdir;             ///ditto
alias mkdirRecurse      = std.file.mkdirRecurse;      ///ditto
alias rmdir             = std.file.rmdir;             ///ditto

version(ddoc_scriptlike_d) alias symlink() = std.file.symlink; ///ditto
else version(Posix)        alias symlink() = std.file.symlink; ///ditto

version(ddoc_scriptlike_d) alias readLink() = std.file.readLink; ///ditto
else version(Posix)        alias readLink() = std.file.readLink; ///ditto

alias copy         = std.file.copy;         ///ditto
alias rmdirRecurse = std.file.rmdirRecurse; ///ditto
alias dirEntries   = std.file.dirEntries;   ///ditto
alias slurp        = std.file.slurp;        ///ditto

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

version(unittest_scriptlike_d)
unittest
{
	string file;
	void checkPre()
	{
		assert(!std.file.exists(file));
	}

	void checkPost()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));
		assert(cast(string) std.file.read(file) == "abc123");
	}

	// Create
	testFileOperation!("write", "Create: string")(() {
		mixin(useTmpName!"file");

		checkPre();
		write(file, "abc123");
		mixin(checkResult);
	});

	testFileOperation!("write", "Create: Path")(() {
		mixin(useTmpName!"file");

		checkPre();
		write(Path(file), "abc123");
		mixin(checkResult);
	});

	// Overwrite
	testFileOperation!("write", "Overwrite: string")(() {
		mixin(useTmpName!"file");

		checkPre();
		write(file, "hello");
		write(file, "abc123");
		mixin(checkResult);
	});

	testFileOperation!("write", "Overwrite: Path")(() {
		mixin(useTmpName!"file");

		checkPre();
		write(Path(file), "hello");
		write(Path(file), "abc123");
		mixin(checkResult);
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file;
	void checkPre()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));
		assert(cast(string) std.file.read(file) == "abc123");
	}

	void checkPost()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));
		assert(cast(string) std.file.read(file) == "abc123hello");
	}

	testFileOperation!("append", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		checkPre();
		append(file, "hello");
		mixin(checkResult);
	});

	testFileOperation!("append", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		checkPre();
		append(Path(file), "hello");
		mixin(checkResult);
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file1;
	string file2;
	void checkPre()
	{
		assert(!std.file.exists(file2));
		assert(std.file.exists(file1));
		assert(std.file.isFile(file1));
		assert(cast(string) std.file.read(file1) == "abc");
	}

	void checkPost()
	{
		assert(!std.file.exists(file1));
		assert(std.file.exists(file2));
		assert(std.file.isFile(file2));
		assert(cast(string) std.file.read(file2) == "abc");
	}

	testFileOperation!("rename", "string,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		std.file.write(file1, "abc");

		checkPre();
		rename(file1, file2);
		mixin(checkResult);
	});

	testFileOperation!("rename", "string,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		std.file.write(file1, "abc");

		checkPre();
		rename(file1, Path(file2));
		mixin(checkResult);
	});

	testFileOperation!("rename", "Path,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		std.file.write(file1, "abc");

		checkPre();
		rename(Path(file1), file2);
		mixin(checkResult);
	});

	testFileOperation!("rename", "Path,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		std.file.write(file1, "abc");

		checkPre();
		rename(Path(file1), Path(file2));
		mixin(checkResult);
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file;
	void checkPre()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));
		assert(cast(string) std.file.read(file) == "abc");
	}

	void checkPost()
	{
		assert(!std.file.exists(file));
	}

	testFileOperation!("remove", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc");

		checkPre();
		remove(file);
		mixin(checkResult);
	});

	testFileOperation!("remove", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc");

		checkPre();
		remove(Path(file));
		mixin(checkResult);
	});
}

/// Like $(FULL_STD_FILE getSize), but supports Path and command echoing.
ulong getSize(in Path name)
{
	return getSize(name.toRawString());
}

///ditto
ulong getSize(in string name)
{
	yapFunc(name);
	return std.file.getSize(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("getSize", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");
		
		assert(getSize(file) == 6);
	});

	testFileOperation!("getSize", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		assert(getSize(Path(file)) == 6);
	});
}

/// Like $(FULL_STD_FILE getTimes), but supports Path and command echoing.
void getTimes(in Path name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	getTimes(name.toRawString(), accessTime, modificationTime);
}

///ditto
void getTimes(in string name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	yapFunc(name);
	std.file.getTimes(name, accessTime, modificationTime);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("getTimes", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		SysTime a, b;
		getTimes(file, a, b);
	});

	testFileOperation!("getTimes", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		SysTime a, b;
		getTimes(Path(file), a, b);
	});
}

version(ddoc_scriptlike_d)
{
	/// Windows-only. Like $(FULL_STD_FILE getTimesWin), but supports Path and command echoing.
	void getTimesWin(in Path name,
		out SysTime fileCreationTime,
		out SysTime fileAccessTime,
		out SysTime fileModificationTime);

	///ditto
	void getTimesWin(in string name,
		out SysTime fileCreationTime,
		out SysTime fileAccessTime,
		out SysTime fileModificationTime);
}
else version(Windows)
{
	void getTimesWin(in Path name,
		out SysTime fileCreationTime,
		out SysTime fileAccessTime,
		out SysTime fileModificationTime)
	{
		getTimesWin(name.toRawString(), fileCreationTime, fileAccessTime, fileModificationTime);
	}

	void getTimesWin(in string name,
		out SysTime fileCreationTime,
		out SysTime fileAccessTime,
		out SysTime fileModificationTime)
	{
		yapFunc(name);
		std.file.getTimesWin(name, fileCreationTime, fileAccessTime, fileModificationTime);
	}

	version(unittest_scriptlike_d)
	unittest
	{
		string file;

		testFileOperation!("getTimesWin", "string")(() {
			mixin(useTmpName!"file");
			std.file.write(file, "abc123");

			SysTime a, b, c;
			getTimesWin(file, a, b, c);
		});

		testFileOperation!("getTimesWin", "Path")(() {
			mixin(useTmpName!"file");
			std.file.write(file, "abc123");

			SysTime a, b;
			getTimesWin(Path(file), a, b, c);
		});
	}
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

version(unittest_scriptlike_d)
unittest
{
	string file;
	SysTime actualAccessTime, actualModTime;
	SysTime expectedAccessTime = SysTime(234567890);
	SysTime expectedModTime    = SysTime(123456789);
	
	void checkPre()
	{
		std.file.getTimes(file, actualAccessTime, actualModTime);
		assert(actualAccessTime != expectedAccessTime);
		assert(actualModTime != expectedModTime);
	}

	void checkPost()
	{
		std.file.getTimes(file, actualAccessTime, actualModTime);
		assert(actualAccessTime == expectedAccessTime);
		assert(actualModTime == expectedModTime);
	}

	/+
	testFileOperation!("setTimes", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc");

		checkPre();
		setTimes(file, expectedAccessTime, expectedModTime);
		mixin(checkResult);
	});

	testFileOperation!("setTimes", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc");

		checkPre();
		setTimes(Path(file), expectedAccessTime, expectedModTime);
		mixin(checkResult);
	});
	+/
}

/// Like $(FULL_STD_FILE timeLastModified), but supports Path and command echoing.
SysTime timeLastModified(in Path name)
{
	return timeLastModified(name.toRawString());
}

///ditto
SysTime timeLastModified(in string name)
{
	yapFunc(name);
	return std.file.timeLastModified(name);
}

///ditto
SysTime timeLastModified(in Path name, SysTime returnIfMissing)
{
	return timeLastModified(name.toRawString(), returnIfMissing);
}

///ditto
SysTime timeLastModified(in string name, SysTime returnIfMissing)
{
	yapFunc(name);
	return std.file.timeLastModified(name, returnIfMissing);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("timeLastModified", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		timeLastModified(file);
	});

	testFileOperation!("timeLastModified", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		timeLastModified(Path(file));
	});

	testFileOperation!("timeLastModified", "string,SysTime - exists")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		auto ifMissing = SysTime(123);
		timeLastModified(file, ifMissing);
	});

	testFileOperation!("timeLastModified", "Path,SysTime - exists")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		auto ifMissing = SysTime(123);
		timeLastModified(Path(file), ifMissing);
	});

	testFileOperation!("timeLastModified", "string,SysTime - missing")(() {
		mixin(useTmpName!"file");

		auto ifMissing = SysTime(123);
		assert(timeLastModified(file, ifMissing) == SysTime(123));
	});

	testFileOperation!("timeLastModified", "Path,SysTime - missing")(() {
		mixin(useTmpName!"file");

		auto ifMissing = SysTime(123);
		assert(timeLastModified(Path(file), ifMissing) == SysTime(123));
	});
}

/// Like $(FULL_STD_FILE exists), but supports Path and command echoing.
bool exists(in Path name) @trusted
{
	return exists(name.toRawString());
}

///ditto
bool exists(in string name) @trusted
{
	yapFunc(name);
	return std.file.exists(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("exists", "string")(() {
		mixin(useTmpName!"file");

		assert(!exists(file));
		std.file.write(file, "abc");
		assert(exists(file));
	});

	testFileOperation!("exists", "Path")(() {
		mixin(useTmpName!"file");

		assert(!exists(Path(file)));
		std.file.write(file, "abc");
		assert(exists(Path(file)));
	});
}

/// Like $(FULL_STD_FILE getAttributes), but supports Path and command echoing.
uint getAttributes(in Path name)
{
	return getAttributes(name.toRawString());
}

///ditto
uint getAttributes(in string name)
{
	yapFunc(name);
	return std.file.getAttributes(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("getAttributes", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		getAttributes(file);
	});

	testFileOperation!("getAttributes", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		getAttributes(Path(file));
	});
}

/// Like $(FULL_STD_FILE getLinkAttributes), but supports Path and command echoing.
uint getLinkAttributes(in Path name)
{
	return getLinkAttributes(name.toRawString());
}

///ditto
uint getLinkAttributes(in string name)
{
	yapFunc(name);
	return std.file.getLinkAttributes(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file;

	testFileOperation!("getLinkAttributes", "string")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		getLinkAttributes(file);
	});

	testFileOperation!("getLinkAttributes", "Path")(() {
		mixin(useTmpName!"file");
		std.file.write(file, "abc123");

		getLinkAttributes(Path(file));
	});
}

/// Like $(FULL_STD_FILE isDir), but supports Path and command echoing.
@property bool isDir(in Path name)
{
	return isDir(name.toRawString());
}

///ditto
@property bool isDir(in string name)
{
	yapFunc(name);
	return std.file.isDir(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file, dir;

	testFileOperation!("isDir", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( !isDir(file) );
		assert( isDir(dir) );
	});

	testFileOperation!("isDir", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( !isDir(Path(file)) );
		assert( isDir(Path(dir)) );
	});
}

/// Like $(FULL_STD_FILE isFile), but supports Path and command echoing.
@property bool isFile(in Path name)
{
	return isFile(name.toRawString());
}

///ditto
@property bool isFile(in string name)
{
	yapFunc(name);
	return std.file.isFile(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file, dir;

	testFileOperation!("isFile", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( isFile(file) );
		assert( !isFile(dir) );
	});

	testFileOperation!("isFile", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( isFile(Path(file)) );
		assert( !isFile(Path(dir)) );
	});
}

/// Like $(FULL_STD_FILE isSymlink), but supports Path and command echoing.
@property bool isSymlink(in Path name)
{
	return isSymlink(name.toRawString());
}

///ditto
@property bool isSymlink(in string name)
{
	yapFunc(name);
	return std.file.isSymlink(name);
}

version(unittest_scriptlike_d)
unittest
{
	string file, dir, fileLink, dirLink;

	testFileOperation!("isSymlink", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"fileLink");
		mixin(useTmpName!"dirLink");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);
		version(Posix)
		{
			std.file.symlink(file, fileLink);
			std.file.symlink(dir, dirLink);
		}

		assert( !isSymlink(file) );
		assert( !isSymlink(dir) );
		version(Posix)
		{
			assert( isSymlink(fileLink) );
			assert( isSymlink(dirLink) );
		}
	});

	testFileOperation!("isSymlink", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"fileLink");
		mixin(useTmpName!"dirLink");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);
		version(Posix)
		{
			std.file.symlink(file, fileLink);
			std.file.symlink(dir, dirLink);
		}

		assert( !isSymlink(Path(file)) );
		assert( !isSymlink(Path(dir)) );
		version(Posix)
		{
			assert( isSymlink(Path(fileLink)) );
			assert( isSymlink(Path(dirLink)) );
		}
	});
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

version(unittest_scriptlike_d)
unittest
{
	string dir;

	testFileOperation!("chdir", "string")(() {
		mixin(useTmpName!"dir");
		std.file.mkdir(dir);

		chdir(dir);
		assert(std.file.getcwd() == dir);
	});

	testFileOperation!("chdir", "Path")(() {
		mixin(useTmpName!"dir");
		std.file.mkdir(dir);

		chdir(Path(dir));
		assert(std.file.getcwd() == dir);
	});
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

version(unittest_scriptlike_d)
{
	immutable checkResult = q{
		if(scriptlikeDryRun)
			checkPre();
		else
			checkPost();
	};

	// Runs the provided test in both normal and dryrun modes.
	// The provided test can read scriptlikeDryRun and assert appropriately.
	//
	// Automatically ensures the test echoes in the echo and dryrun modes,
	// and doesn't echo otherwise.
	void testFileOperation(string funcName, string msg = null, string module_ = __MODULE__)
		(void delegate() test)
	{
		static import std.stdio;
		import std.stdio : writeln, stdout;
		
		string capturedEcho;
		void captureEcho(string str)
		{
			capturedEcho ~= str;
			capturedEcho ~= '\n';
		}
		
		auto originalCurrentDir = std.file.getcwd();
		
		// Test normally
		{
			std.stdio.write("Testing ", module_, ".", funcName, (msg? ": " : ""), msg, "\t[normal]");
			stdout.flush();
			scriptlikeEcho = false;
			scriptlikeDryRun = false;
			capturedEcho = null;
			scriptlikeCustomEcho = &captureEcho;

			scope(failure) writeln();
			scope(exit) std.file.chdir(originalCurrentDir);
			test();
			assert(
				capturedEcho == "",
				"Expected the test not to echo, but it echoed this:\n------------\n"~capturedEcho~"------------"
			);
		}
		
		// Test in echo mode
		{
			std.stdio.write(" [echo]");
			stdout.flush();
			scriptlikeEcho = true;
			scriptlikeDryRun = false;
			capturedEcho = null;
			scriptlikeCustomEcho = &captureEcho;

			scope(failure) writeln();
			scope(exit) std.file.chdir(originalCurrentDir);
			test();
			assert(capturedEcho != "", "Expected the test to echo, but it didn't.");
			assert(
				capturedEcho.canFind(funcName~": "),
				"Couldn't find '"~funcName~": ' in test's echo output:\n------------\n"~capturedEcho~"------------"
			);
		}
		
		// Test in dry run mode
		{
			std.stdio.write(" [dryrun]");
			stdout.flush();
			scriptlikeEcho = false;
			scriptlikeDryRun = true;
			capturedEcho = null;
			scriptlikeCustomEcho = &captureEcho;

			scope(failure) writeln();
			scope(exit) std.file.chdir(originalCurrentDir);
			test();
			assert(capturedEcho != "", "Expected the test to echo, but it didn't.");
			assert(
				capturedEcho.canFind(funcName~": "),
				"Couldn't find '"~funcName~": ' in the test's echo output:\n------------"~capturedEcho~"------------"
			);
		}

		writeln();
	}

	unittest
	{
		mixin(initTest!"testFileOperation");
		
		testFileOperation!("testFileOperation", "Echo works 1")(() {
			void testFileOperation()
			{
				yapFunc();
			}
			testFileOperation();
		});
		
		testFileOperation!("testFileOperation", "Echo works 2")(() {
			if(scriptlikeEcho)        scriptlikeCustomEcho("testFileOperation: ");
			else if(scriptlikeDryRun) scriptlikeCustomEcho("testFileOperation: ");
			else                      {}
		});
		
		{
			auto countNormal = 0;
			auto countEcho   = 0;
			auto countDryRun = 0;
			testFileOperation!("testFileOperation", "Gets run in each mode")(() {
				if(scriptlikeEcho)
				{
					countEcho++;
					scriptlikeCustomEcho("testFileOperation: ");
				}
				else if(scriptlikeDryRun)
				{
					countDryRun++;
					scriptlikeCustomEcho("testFileOperation: ");
				}
				else
					countNormal++; 
			});
			assert(countNormal == 1);
			assert(countEcho   == 1);
			assert(countDryRun == 1);
		}
		
		assertThrown!AssertError(
			testFileOperation!("testFileOperation", "Echoing even with both echo and dryrun disabled")(() {
				scriptlikeCustomEcho("testFileOperation: ");
			})
		);
		
		assertThrown!AssertError(
			testFileOperation!("testFileOperation", "No echo in echo mode")(() {
				if(scriptlikeEcho)        {}
				else if(scriptlikeDryRun) scriptlikeCustomEcho("testFileOperation: ");
				else                      {}
				})
		);
		
		assertThrown!AssertError(
			testFileOperation!("testFileOperation", "No echo in dryrun mode")(() {
				if(scriptlikeEcho)        scriptlikeCustomEcho("testFileOperation: ");
				else if(scriptlikeDryRun) {}
				else                      {}
				})
		);
	}
}
