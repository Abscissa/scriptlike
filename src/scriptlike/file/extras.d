/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))

Extra Scriptlike-only functionality to complement $(MODULE_STD_FILE).

Copyright: Copyright (C) 2014-2017 Nick Sabalausky
License:   zlib/libpng
Authors:   Nick Sabalausky
+/
module scriptlike.file.extras;

import std.algorithm;
import std.datetime;
import std.exception : enforce;
import std.traits;
import std.typecons;

static import std.file;
static import std.path;

import scriptlike.core;
import scriptlike.path;
import scriptlike.file.wrappers;

private string[] g_dirPathStack;

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
	return existsAsDir(path.raw);
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
	return existsAsFile(path.raw);
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
	return existsAsSymlink(path.raw);
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

/// If 'from' exists, then rename. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryRename(T1, T2)(T1 from, T2 to)
	if(
		(is(T1==string) || is(T1==Path)) &&
		(is(T2==string) || is(T2==Path))
	)
{
	yapFunc(from.escapeShellArg(), " -> ", to.escapeShellArg());
	mixin(gagEcho);

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
		assert( tryRename(file1, file2) );
		assert( !tryRename(notExist1, notExist2) );
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "string,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryRename(file1, Path(file2)) );
		assert( !tryRename(notExist1, Path(notExist2)) );
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "Path,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryRename(Path(file1), file2) );
		assert( !tryRename(Path(notExist1), notExist2) );
		mixin(checkResult);
	});

	testFileOperation!("tryRename", "Path,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryRename(Path(file1), Path(file2)) );
		assert( !tryRename(Path(notExist1), Path(notExist2)) );
		mixin(checkResult);
	});
}

/// If 'name' exists, then remove. Otherwise, do nothing and return false.
///
/// Supports Path, command echoing and dryrun.
///
/// Returns: Success?
bool tryRemove(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(name.exists())
	{
		remove(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string file, notExist;
	void checkPre()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));
		assert(cast(string) std.file.read(file) == "abc");

		assert(!std.file.exists(notExist));
	}

	void checkPost()
	{
		assert(!std.file.exists(file));
		assert(!std.file.exists(notExist));
	}

	testFileOperation!("tryRemove", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");

		checkPre();
		assert( tryRemove(file) );
		assert( !tryRemove(notExist) );
		mixin(checkResult);
	});

	testFileOperation!("tryRemove", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");

		checkPre();
		assert( tryRemove(Path(file)) );
		assert( !tryRemove(Path(notExist)) );
		mixin(checkResult);
	});
}

/// If 'name' doesn't already exist, then mkdir. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryMkdir(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(!name.exists())
	{
		mkdir(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string dir, alreadyExist;
	void checkPre()
	{
		assert(!std.file.exists(dir));
		assert(std.file.exists(alreadyExist));
	}

	void checkPost()
	{
		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));
		assert(std.file.exists(alreadyExist));
	}

	testFileOperation!("tryMkdir", "string")(() {
		mixin(useTmpName!"dir");
		mixin(useTmpName!"alreadyExist");
		std.file.mkdir(alreadyExist);

		checkPre();
		assert( tryMkdir(dir) );
		assert( !tryMkdir(alreadyExist) );
		mixin(checkResult);
	});

	testFileOperation!("tryMkdir", "Path")(() {
		mixin(useTmpName!"dir");
		mixin(useTmpName!"alreadyExist");
		std.file.mkdir(alreadyExist);

		checkPre();
		assert( tryMkdir(Path(dir)) );
		assert( !tryMkdir(Path(alreadyExist)) );
		mixin(checkResult);
	});
}

/// If 'name' doesn't already exist, then mkdirRecurse. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryMkdirRecurse(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(!name.exists())
	{
		mkdirRecurse(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string dir, alreadyExist;
	void checkPre()
	{
		assert(!std.file.exists(dir));
		assert(std.file.exists(alreadyExist));
	}

	void checkPost()
	{
		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));
		assert(std.file.exists(alreadyExist));
	}

	testFileOperation!("tryMkdirRecurse", "string")(() {
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"alreadyExist");
		std.file.mkdir(alreadyExist);

		checkPre();
		assert( tryMkdirRecurse(dir) );
		assert( !tryMkdirRecurse(alreadyExist) );
		mixin(checkResult);
	});

	testFileOperation!("tryMkdirRecurse", "Path")(() {
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"alreadyExist");
		std.file.mkdir(alreadyExist);

		checkPre();
		assert( tryMkdirRecurse(Path(dir)) );
		assert( !tryMkdirRecurse(Path(alreadyExist)) );
		mixin(checkResult);
	});
}

/// If 'name' exists, then rmdir. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryRmdir(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(name.exists())
	{
		rmdir(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string dir, notExist;
	void checkPre()
	{
		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));
	}

	void checkPost()
	{
		assert(!std.file.exists(dir));
	}

	testFileOperation!("tryRmdir", "string")(() {
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.mkdir(dir);

		checkPre();
		assert( tryRmdir(dir) );
		assert( !tryRmdir(notExist) );
		mixin(checkResult);
	});

	testFileOperation!("tryRmdir", "Path")(() {
		mixin(useTmpName!"dir");
		mixin(useTmpName!"notExist");
		std.file.mkdir(dir);

		checkPre();
		assert( tryRmdir(Path(dir)) );
		assert( !tryRmdir(Path(notExist)) );
		mixin(checkResult);
	});
}

version(docs_scriptlike_d)
{
	/// Posix-only. If 'original' exists, then symlink. Otherwise, do nothing and return false.
	///
	/// Supports Path and command echoing.
	///
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
		yapFunc("[original] ", original.escapeShellArg(), " : [symlink] ", link.escapeShellArg());
		mixin(gagEcho);

		if(original.exists())
		{
			symlink(original, link);
			return true;
		}
		
		return false;
	}

	version(unittest_scriptlike_d)
	unittest
	{
		string file, link, notExistFile, notExistLink;
		void checkPre()
		{
			assert(std.file.exists(file));
			assert(std.file.isFile(file));
			assert(cast(string) std.file.read(file) == "abc123");
			
			assert(!std.file.exists(link));

			assert(!std.file.exists(notExistFile));
			assert(!std.file.exists(notExistLink));
		}

		void checkPost()
		{
			assert(std.file.exists(file));
			assert(std.file.isFile(file));
			assert(cast(string) std.file.read(file) == "abc123");
			
			assert(std.file.exists(link));
			assert(std.file.isSymlink(link));
			assert(std.file.readLink(link) == file);
			assert(cast(string) std.file.read(link) == "abc123");

			assert(!std.file.exists(notExistFile));
			assert(!std.file.exists(notExistLink));
		}

		testFileOperation!("trySymlink", "string,string")(() {
			mixin(useTmpName!"file");
			mixin(useTmpName!"link");
			mixin(useTmpName!"notExistFile");
			mixin(useTmpName!"notExistLink");
			std.file.write(file, "abc123");

			checkPre();
			assert( trySymlink(file, link) );
			assert( !trySymlink(notExistFile, notExistLink) );
			mixin(checkResult);
		});

		testFileOperation!("trySymlink", "string,Path")(() {
			mixin(useTmpName!"file");
			mixin(useTmpName!"link");
			mixin(useTmpName!"notExistFile");
			mixin(useTmpName!"notExistLink");
			std.file.write(file, "abc123");

			checkPre();
			assert( trySymlink(file, Path(link)) );
			assert( !trySymlink(notExistFile, Path(notExistLink)) );
			mixin(checkResult);
		});

		testFileOperation!("trySymlink", "Path,string")(() {
			mixin(useTmpName!"file");
			mixin(useTmpName!"link");
			mixin(useTmpName!"notExistFile");
			mixin(useTmpName!"notExistLink");
			std.file.write(file, "abc123");

			checkPre();
			assert( trySymlink(Path(file), link) );
			assert( !trySymlink(Path(notExistFile), notExistLink) );
			mixin(checkResult);
		});

		testFileOperation!("trySymlink", "Path,Path")(() {
			mixin(useTmpName!"file");
			mixin(useTmpName!"link");
			mixin(useTmpName!"notExistFile");
			mixin(useTmpName!"notExistLink");
			std.file.write(file, "abc123");

			checkPre();
			assert( trySymlink(Path(file), Path(link)) );
			assert( !trySymlink(Path(notExistFile), Path(notExistLink)) );
			mixin(checkResult);
		});
	}
}

/// If 'from' exists, then copy. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryCopy(T1, T2)(T1 from, T2 to)
	if(
		(is(T1==string) || is(T1==Path)) &&
		(is(T2==string) || is(T2==Path))
	)
{
	yapFunc(from.escapeShellArg(), " -> ", to.escapeShellArg());
	mixin(gagEcho);

	if(from.exists())
	{
		copy(from, to);
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

		assert(std.file.exists(file1));
		assert(std.file.isFile(file1));
		assert(cast(string) std.file.read(file1) == "abc");

		assert(!std.file.exists(file2));
	}

	void checkPost()
	{
		assert(!std.file.exists(notExist1));
		assert(!std.file.exists(notExist2));

		assert(std.file.exists(file1));
		assert(std.file.isFile(file1));
		assert(cast(string) std.file.read(file1) == "abc");

		assert(std.file.exists(file2));
		assert(std.file.isFile(file2));
		assert(cast(string) std.file.read(file2) == "abc");
	}

	testFileOperation!("tryCopy", "string,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryCopy(file1, file2) );
		assert( !tryCopy(notExist1, notExist2) );
		mixin(checkResult);
	});

	testFileOperation!("tryCopy", "string,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryCopy(file1, Path(file2)) );
		assert( !tryCopy(notExist1, Path(notExist2)) );
		mixin(checkResult);
	});

	testFileOperation!("tryCopy", "Path,string")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryCopy(Path(file1), file2) );
		assert( !tryCopy(Path(notExist1), notExist2) );
		mixin(checkResult);
	});

	testFileOperation!("tryCopy", "Path,Path")(() {
		mixin(useTmpName!"file1");
		mixin(useTmpName!"file2");
		mixin(useTmpName!"notExist1");
		mixin(useTmpName!"notExist2");
		std.file.write(file1, "abc");

		checkPre();
		assert( tryCopy(Path(file1), Path(file2)) );
		assert( !tryCopy(Path(notExist1), Path(notExist2)) );
		mixin(checkResult);
	});
}

/// If 'name' exists, then rmdirRecurse. Otherwise, do nothing and return false.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryRmdirRecurse(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(name.exists())
	{
		rmdirRecurse(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string dir, notExist;
	void checkPre()
	{
		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));

		assert(!std.file.exists( notExist ));
	}

	void checkPost()
	{
		assert(!std.file.exists( std.path.dirName(dir) ));

		assert(!std.file.exists( notExist ));
	}

	testFileOperation!("tryRmdirRecurse", "string")(() {
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.mkdirRecurse(dir);

		checkPre();
		assert(tryRmdirRecurse( std.path.dirName(dir) ));
		assert(!tryRmdirRecurse( notExist ));
		mixin(checkResult);
	});

	testFileOperation!("tryRmdirRecurse", "Path")(() {
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.mkdirRecurse(dir);

		checkPre();
		assert(tryRmdirRecurse(Path( std.path.dirName(dir) )));
		assert(!tryRmdirRecurse(Path( notExist ) ));
		mixin(checkResult);
	});
}

/// Delete `name` regardless of whether it's a file or directory.
/// If it's a directory, it's deleted recursively, via
/// $(API_FILE_WRAP rmdirRecurse). Throws if the file/directory doesn't exist.
///
/// If you just want to make sure a file/dir is gone, and don't care whether
/// it already exists or not, consider using `tryRemovePath` instead.
///
/// Supports Path and command echoing.
void removePath(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());

	if(name.exists() && name.isDir())
		rmdirRecurse(name);
	else
		remove(name);
}

version(unittest_scriptlike_d)
unittest
{
	import std.exception;
	string file, dir, notExist;

	void checkPre()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));

		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));

		assert(!std.file.exists( notExist ));
	}

	void checkPost()
	{
		assert(!std.file.exists( file ));
		assert(!std.file.exists( std.path.dirName(dir) ));
		assert(!std.file.exists( notExist ));
	}

	testFileOperation!("removePath", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");
		std.file.mkdirRecurse(dir);

		checkPre();
		removePath( file );
		removePath( std.path.dirName(dir) );
		if(scriptlikeDryRun)
			removePath( notExist );
		else
			assertThrown(removePath( notExist ));
		mixin(checkResult);
	});

	testFileOperation!("removePath", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");
		std.file.mkdirRecurse(dir);

		checkPre();
		removePath(Path( file ));
		removePath(Path( std.path.dirName(dir) ));
		if(scriptlikeDryRun)
			removePath(Path( notExist ));
		else
			assertThrown(removePath(Path( notExist ) ));
		mixin(checkResult);
	});
}

/// If `name` exists, then delete it regardless of whether it's a file or
/// directory. If it doesn't already exist, do nothing and return false.
///
/// If you want an exception to be thrown if `name` doesn't already exist,
/// use `removePath` instead.
///
/// Supports Path and command echoing.
///
/// Returns: Success?
bool tryRemovePath(T)(T name) if(is(T==string) || is(T==Path))
{
	yapFunc(name.escapeShellArg());
	mixin(gagEcho);

	if(name.exists())
	{
		removePath(name);
		return true;
	}
	
	return false;
}

version(unittest_scriptlike_d)
unittest
{
	string file, dir, notExist;

	void checkPre()
	{
		assert(std.file.exists(file));
		assert(std.file.isFile(file));

		assert(std.file.exists(dir));
		assert(std.file.isDir(dir));

		assert(!std.file.exists( notExist ));
	}

	void checkPost()
	{
		assert(!std.file.exists( file ));
		assert(!std.file.exists( std.path.dirName(dir) ));
		assert(!std.file.exists( notExist ));
	}

	testFileOperation!("tryRemovePath", "string")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");
		std.file.mkdirRecurse(dir);

		checkPre();
		assert(tryRemovePath( file ));
		assert(tryRemovePath( std.path.dirName(dir) ));
		assert(!tryRemovePath( notExist ));
		mixin(checkResult);
	});

	testFileOperation!("tryRemovePath", "Path")(() {
		mixin(useTmpName!"file");
		mixin(useTmpName!("dir", "subdir"));
		mixin(useTmpName!"notExist");
		std.file.write(file, "abc");
		std.file.mkdirRecurse(dir);

		checkPre();
		assert(tryRemovePath(Path( file )));
		assert(tryRemovePath(Path( std.path.dirName(dir) )));
		assert(!tryRemovePath(Path( notExist ) ));
		mixin(checkResult);
	});
}

version(docs_scriptlike_d)
{
	/// Posix-only. Check the user (ie "owner") executable bit of a file. File must exist.
	bool isUserExec(Path path);
	///ditto
	bool isUserExec(string path);

	/// Posix-only. Check the group executable bit of a file. File must exist.
	bool isGroupExec(Path path);
	///ditto
	bool isGroupExec(string path);

	/// Posix-only. Check the world (ie "other") executable bit of a file. File must exist.
	bool isWorldExec(Path path);
	///ditto
	bool isWorldExec(string path);
}
else version(Posix)
{
	bool isUserExec(Path path)
	{
		return isUserExec(path.raw);
	}

	bool isUserExec(string path)
	{
		import core.sys.posix.sys.stat;
		return !!(getAttributes(path) & S_IXUSR);
	}

	bool isGroupExec(Path path)
	{
		return isGroupExec(path.raw);
	}

	bool isGroupExec(string path)
	{
		import core.sys.posix.sys.stat;
		return !!(getAttributes(path) & S_IXGRP);
	}

	bool isWorldExec(Path path)
	{
		return isUserExec(path.raw);
	}

	bool isWorldExec(string path)
	{
		import core.sys.posix.sys.stat;
		return !!(getAttributes(path) & S_IXOTH);
	}
}

version(Posix)
version(unittest_scriptlike_d)
unittest
{
	import std.stdio;
	writeln("Running Scriptlike unittests: isUserExec / isGroupExec / isWorldExec"); stdout.flush();

	mixin(useSandbox);

	import scriptlike.process : run;
	
	writeFile("noX.txt", "Hi");
	writeFile("userX.txt", "Hi");
	writeFile("groupX.txt", "Hi");
	writeFile("otherX.txt", "Hi");
	writeFile("allX.txt", "Hi");
	run("chmod -x noX.txt");
	run("chmod u+x,go-x userX.txt");
	run("chmod g+x,uo-x groupX.txt");
	run("chmod o+x,ug-x otherX.txt");
	run("chmod +x allX.txt");

	assert(!isUserExec("noX.txt"));
	assert(isUserExec("userX.txt"));
	assert(!isUserExec("groupX.txt"));
	assert(!isUserExec("otherX.txt"));
	assert(isUserExec("allX.txt"));

	assert(!isGroupExec("noX.txt"));
	assert(!isGroupExec("userX.txt"));
	assert(isGroupExec("groupX.txt"));
	assert(!isGroupExec("otherX.txt"));
	assert(isGroupExec("allX.txt"));

	assert(!isWorldExec("noX.txt"));
	assert(!isWorldExec("userX.txt"));
	assert(!isWorldExec("groupX.txt"));
	assert(isWorldExec("otherX.txt"));
	assert(isWorldExec("allX.txt"));
}

/// Tries to change directory into the given path, and if it succeeds then
/// the current (pre-change) directory is pushed onto the directory stack.
///
/// Returns: Success?
bool tryPushDir(in Path path) @trusted
{
    return tryPushDir(path.raw);
}

/// ditto
bool tryPushDir(in string path) @trusted
{
    yapFunc(path.escapeShellArg());

    if(!path.existsAsDir)
        return false;

    g_dirPathStack ~= std.file.getcwd();
    std.file.chdir(path);
    return true;
}

/// This is like `scriptlike.file.extras.tryPushDir` except that it throws on failure
/// instead of returning a success flag.
void pushDir(in Path path) @trusted
{
    pushDir(path.raw);
}

/// ditto
void pushDir(in string path) @trusted
{
    yapFunc(path.escapeShellArg());
    mixin(gagEcho);
    enforce(tryPushDir(path), "Path does not exist: "~path);
}

private bool tryPopDirImpl(in string yapName) @trusted
{
    if(g_dirPathStack.length == 0)
    {
        yap(yapName, ": ", "<Empty Stack>");
        return false;
    }

    const path = g_dirPathStack[$-1];
    g_dirPathStack.length--;

    yap(yapName, ": ", path.escapeShellArg());
    std.file.chdir(path);

    return true;
}

/// If the directory stack is not empty, then the current directory
/// is changed to the directory that is on top of the stack. The stack is then popped.
///
/// Returns: Success?
bool tryPopDir() @trusted
{
    return tryPopDirImpl("tryPopDir");
}

/// This is like `scriptlike.file.extras.tryPopDir` except that is throws on failure
/// instead of returning a success flag.
void popDir() @trusted
{
    enforce(tryPopDirImpl("popDir"), "Cannot pop directory path as stack is empty.");
}

/// Completely pops the directory stack, returning the current directory to its
/// original location. An empty directory stack results in no directory change.
void popDirRecurse() @trusted
{
    // idk whether the verbose output like this is useful or not.
    while(tryPopDirImpl("popDirRecurse")){}
}

version(unittest_scriptlike_d)
unittest
{
    import std.path      : buildPath;
    import std.exception : assertThrown, assertNotThrown;

    mixin(useSandbox);
    const originalDir = std.file.getcwd();

    foreach(path; ["a", "b", "a/b/"])
        std.file.mkdir(path);

    void assertInOriginalDir()
    {
        const cwd = std.file.getcwd();
        assert(cwd == originalDir, 
            "Expected to be in dir:\n\t"~originalDir~"\nBut we're in:\n\t"~cwd
        );
        assert(g_dirPathStack.length == 0, "The path stack isn't empty.");
    }

    testFileOperation!("pushDir", "basic usage")(() {
        assertInOriginalDir();

        pushDir("a");
        assert(g_dirPathStack.length == 1);
        assert(g_dirPathStack[0] == originalDir);

        pushDir("b");
        assert(std.file.getcwd() == originalDir.buildPath("a", "b"));

        // Kind of have to test both here at the same time.
        assert(tryPopDir());
        assert(g_dirPathStack.length == 1);
        assert(tryPopDir());
        assert(!tryPopDir());
        assertInOriginalDir();
    });

    testFileOperation!("popDir", "empty stack")(() {
        assertInOriginalDir();
        pushDir("b");
        assertNotThrown(popDir());
        assertThrown(popDir());
        assertInOriginalDir();
    });

    testFileOperation!("tryPushDir", "basic usage")(() {
        assertInOriginalDir();
        assert(tryPushDir("a"));
        assert(tryPushDir("b"));
        assert(!tryPushDir("c"));
        assert(tryPopDir());
        assert(tryPopDir());
        assert(!tryPopDir());
        assertInOriginalDir();
    });

    testFileOperation!("popDirRecurse", "basic usage")(() {
        assertInOriginalDir();
        pushDir("a");
        pushDir("b");
        popDirRecurse();
        assertInOriginalDir();
    });

    testFileOperation!("popDirRecurse", "empty stack")(() {
        popDirRecurse();
        assertInOriginalDir();
    });
}
