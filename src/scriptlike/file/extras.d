/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))

Extra Scriptlike-only functionality to complement $(MODULE_STD_FILE).

Copyright: Copyright (C) 2014-2015 Nick Sabalausky
License:   zlib/libpng
Authors:   Nick Sabalausky
+/
module scriptlike.file.extras;

import std.algorithm;
import std.datetime;
import std.traits;
import std.typecons;

static import std.file;
static import std.path;

import scriptlike.core;
import scriptlike.path;
import scriptlike.file.wrappers;

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

version(unittest_scriptlike_d)
unittest
{
	string file, dir, notExist;

	testFileOperation!("existsAsDir", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( !existsAsDir(file) );
		assert( existsAsDir(dir) );
		assert( !existsAsDir(notExist) );
	});

	testFileOperation!("existsAsDir", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( !existsAsDir(Path(file)) );
		assert( existsAsDir(Path(dir)) );
		assert( !existsAsDir(Path(notExist)) );
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file, dir, notExist;

	testFileOperation!("existsAsFile", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( existsAsFile(file) );
		assert( !existsAsFile(dir) );
		assert( !existsAsFile(notExist) );
	});

	testFileOperation!("existsAsFile", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);

		assert( existsAsFile(Path(file)) );
		assert( !existsAsFile(Path(dir)) );
		assert( !existsAsFile(Path(notExist)) );
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file, dir, fileLink, dirLink, notExist;

	testFileOperation!("existsAsSymlink", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"fileLink");
		mixin(useTmpName!"dirLink");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);
		version(Posix)
		{
			std.file.symlink(file, fileLink);
			std.file.symlink(dir, dirLink);
		}

		assert( !existsAsSymlink(file) );
		assert( !existsAsSymlink(dir) );
		assert( !existsAsSymlink(notExist) );
		version(Posix)
		{
			assert( existsAsSymlink(fileLink) );
			assert( existsAsSymlink(dirLink) );
		}
	});

	testFileOperation!("existsAsSymlink", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"dir");
		mixin(useTmpName!"fileLink");
		mixin(useTmpName!"dirLink");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc123");
		std.file.mkdir(dir);
		version(Posix)
		{
			std.file.symlink(file, fileLink);
			std.file.symlink(dir, dirLink);
		}

		assert( !existsAsSymlink(Path(file)) );
		assert( !existsAsSymlink(Path(dir)) );
		assert( !existsAsSymlink(Path(notExist)) );
		version(Posix)
		{
			assert( existsAsSymlink(Path(fileLink)) );
			assert( existsAsSymlink(Path(dirLink)) );
		}
	});
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

version(unittest_scriptlike_d)
unittest
{
	string file1, file2, notExist1, notExist2;
	void checkPre()
	{
		assert(!std.file.exists(notExist1));
		assert(!std.file.exists(notExist2));

		assert(!std.file.exists(file2));
		assert(std.file.exists(file1));
		assert(std.file.isFile(file1));
		assert(cast(string) std.file.read(file1) == "abc");
	}

	void checkPost()
	{
		assert(!std.file.exists(notExist1));
		assert(!std.file.exists(notExist2));

		assert(!std.file.exists(file1));
		assert(std.file.exists(file2));
		assert(std.file.isFile(file2));
		assert(cast(string) std.file.read(file2) == "abc");
	}

	testFileOperation!("tryRename", "string,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		tryRename(file1, file2);
		tryRename(notExist1, notExist2);
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "string,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		tryRename(file1, Path(file2));
		tryRename(notExist1, Path(notExist2));
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "Path,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		tryRename(Path(file1), file2);
		tryRename(Path(notExist1), notExist2);
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "Path,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		tryRename(Path(file1), Path(file2));
		tryRename(Path(notExist1), Path(notExist2));
		mixin(checkResult);
	});
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
