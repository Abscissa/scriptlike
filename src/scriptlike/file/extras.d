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
