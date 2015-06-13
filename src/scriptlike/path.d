// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

/// Copyright: Copyright (C) 2014-2015 Nick Sabalausky
/// License:   zlib/libpng
/// Authors:   Nick Sabalausky

module scriptlike.path;

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.process;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

static import std.path;
public import std.path : dirSeparator, pathSeparator, isDirSeparator,
	CaseSensitive, osDefaultCaseSensitivity, buildPath, buildNormalizedPath;

/// Represents a file extension.
struct Ext
{
	private string str;
	
	/// Main constructor.
	this(string extension = null) pure @safe nothrow
	{
		this.str = extension;
	}
	
	/// Convert to string.
	string toString() pure @safe nothrow
	{
		return str;
	}
	
	/// No longer needed. Use Ext.toString() instead.
	string toRawString()
	{
		return str;
	}
	
	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opCmp(ref const Ext other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(Ext other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(string other) const
	{
		return std.path.filenameCmp(this.str, other);
	}

	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opEquals(ref const Ext other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(Ext other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(string other) const
	{
		return opCmp(other) == 0;
	}

	/// Convert to bool
	T opCast(T)() if(is(T==bool))
	{
		return !!str;
	}
}

/// Represents a filesystem path. The path is always kept normalized
/// automatically (as performed by buildNormalizedPathFixed).
struct Path
{
	private string str = ".";
	
	/// Main constructor.
	this(string path = ".") @safe pure nothrow
	{
		this.str = buildNormalizedPathFixed(path);
	}
	
	@trusted pure nothrow invariant()
	{
		assert(str == buildNormalizedPathFixed(str));
	}
	
	/// Convert to string, quoting or escaping spaces if necessary.
	string toString()
	{
		return escapeShellArg(str);
	}
	
	/// Returns the underlying string. Does NOT do any escaping, even if path contains spaces.
	string toRawString() const
	{
		return str;
	}

	/// Concatenates two paths, with a directory separator in between.
	Path opBinary(string op)(Path rhs) if(op=="~")
	{
		Path newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs.str);
		return newPath;
	}
	
	///ditto
	Path opBinary(string op)(string rhs) if(op=="~")
	{
		Path newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs);
		return newPath;
	}
	
	///ditto
	Path opBinaryRight(string op)(string lhs) if(op=="~")
	{
		Path newPath;
		newPath.str = buildNormalizedPathFixed(lhs, this.str);
		return newPath;
	}
	
	/// Appends an extension to a path. Naturally, a directory separator
	/// is NOT inserted in between.
	Path opBinary(string op)(Ext rhs) if(op=="~")
	{
		Path newPath;
		newPath.str = std.path.setExtension(this.str, rhs.str);
		return newPath;
	}
	
	/// Appends a path to this one, with a directory separator in between.
	Path opOpAssign(string op)(Path rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs.str);
		return this;
	}
	
	///ditto
	Path opOpAssign(string op)(string rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs);
		return this;
	}
	
	/// Appends an extension to this path. Naturally, a directory separator
	/// is NOT inserted in between.
	Path opOpAssign(string op)(Ext rhs) if(op=="~")
	{
		str = std.path.setExtension(str, rhs.str);
		return this;
	}
	
	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opCmp(ref const Path other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(Path other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(string other) const
	{
		return std.path.filenameCmp(this.str, other);
	}

	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opEquals(ref const Path other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(Path other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(string other) const
	{
		return opCmp(other) == 0;
	}
	
	/// Convert to bool
	T opCast(T)() if(is(T==bool))
	{
		return !!str;
	}
	
	/// Returns the parent path, according to std.path.dirName.
	@property Path up()
	{
		return this.dirName();
	}
	
	/// Is this path equal to empty string?
	@property bool empty()
	{
		return str == "";
	}
}

/// Convenience aliases
alias extOf      = extension;
alias stripExt   = stripExtension;   ///ditto
alias setExt     = setExtension;     ///ditto
alias defaultExt = defaultExtension; ///ditto

/// Like buildNormalizedPath, but if the result is the current directory,
/// this returns "." instead of "". However, if all the inputs are "", or there
/// are no inputs, this still returns "" just like buildNormalizedPath.
string buildNormalizedPathFixed(string[] paths...)
	@trusted pure nothrow
{
	if(all!`a is null`(paths))
		return null;
	
	if(all!`a==""`(paths))
		return "";
	
	auto result = std.path.buildNormalizedPath(paths);
	return result==""? "." : result;
}

/// Properly escape arguments containing spaces for the command shell, if necessary.
string escapeShellArg(string str)
{
	if(str.canFind(' '))
	{
		version(Windows)
			return escapeWindowsArgument(str);
		else version(Posix)
			return escapeShellFileName(str);
		else
			static assert(0, "This platform not supported.");
	}
	else
		return str;
}

// -- std.path wrappers to support Path type --------------------

/// Just like std.path.baseName, but operates on Path.
Path baseName(Path path)
	@trusted pure
{
	return Path( std.path.baseName(path.str) );
}

///ditto
Path baseName(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, in string suffix)
	@safe pure
{
	return Path( std.path.baseName!cs(path.str, suffix) );
}
/// Just like std.path.dirName, but operates on Path.
Path dirName(Path path)
{
	return Path( std.path.dirName(path.str) );
}

/// Just like std.path.rootName, but operates on Path.
Path rootName(Path path) @safe pure nothrow
{
	return Path( std.path.rootName(path.str) );
}

/// Just like std.path.driveName, but operates on Path.
Path driveName(Path path) @safe pure nothrow
{
	return Path( std.path.driveName(path.str) );
}

/// Just like std.path.stripDrive, but operates on Path.
Path stripDrive(Path path) @safe pure nothrow
{
	return Path( std.path.stripDrive(path.str) );
}

/// Just like std.path.extension, but takes a Path and returns an Ext.
Ext extension(in Path path) @safe pure nothrow
{
	return Ext( std.path.extension(path.str) );
}

/// Just like std.path.stripExtension, but operates on Path.
Path stripExtension(Path path) @safe pure nothrow
{
	return Path( std.path.stripExtension(path.str) );
}

/// Just like std.path.setExtension, but operates on Path.
Path setExtension(Path path, string ext)
	@trusted pure nothrow
{
	return Path( std.path.setExtension(path.str, ext) );
}

///ditto
Path setExtension(Path path, Ext ext)
	@trusted pure nothrow
{
	return path.setExtension(ext.toString());
}

/// Just like std.path.defaultExtension, but operates on Path and optionally Ext.
Path defaultExtension(Path path, in string ext)
	@trusted pure
{
	return Path( std.path.defaultExtension(path.str, ext) );
}

///ditto
Path defaultExtension(Path path, Ext ext)
	@trusted pure
{
	return path.defaultExtension(ext.toString());
}

/// Just like std.path.pathSplitter. Note this returns a range of strings,
/// not a range of Path.
auto pathSplitter(Path path) @safe pure nothrow
{
	return std.path.pathSplitter(path.str);
}

/// Just like std.path.isRooted, but operates on Path.
bool isRooted(in Path path) @safe pure nothrow
{
	return std.path.isRooted(path.str);
}

/// Just like std.path.isAbsolute, but operates on Path.
bool isAbsolute(in Path path) @safe pure nothrow
{
	return std.path.isAbsolute(path.str);
}

/// Just like std.path.absolutePath, but operates on Path.
Path absolutePath(Path path, lazy string base = getcwd())
	@safe pure
{
	return Path( std.path.absolutePath(path.str, base) );
}

///ditto
Path absolutePath(Path path, Path base)
	@safe pure
{
	return Path( std.path.absolutePath(path.str, base.str.to!string()) );
}

/// Just like std.path.relativePath, but operates on Path.
Path relativePath(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, lazy string base = getcwd())
{
	return Path( std.path.relativePath!cs(path.str, base) );
}

///ditto
Path relativePath(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, Path base)
{
	return Path( std.path.relativePath!cs(path.str, base.str.to!string()) );
}

/// Just like std.path.filenameCmp, but operates on Path.
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, Path filename2)
	@safe pure
{
	return std.path.filenameCmp(path.str, filename2.str);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, string filename2)
	@safe pure
{
	return std.path.filenameCmp(path.str, filename2);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault)
	(string path, Path filename2)
	@safe pure
{
	return std.path.filenameCmp(path, filename2.str);
}

/// Just like std.path.globMatch, but operates on Path.
bool globMatch(CaseSensitive cs = CaseSensitive.osDefault)
	(Path path, string pattern)
	@safe pure nothrow
{
	return std.path.globMatch!cs(path.str, pattern);
}

/// Just like std.path.isValidFilename, but operates on Path.
bool isValidFilename(in Path path) @safe pure nothrow
{
	return std.path.isValidFilename(path.str);
}

/// Just like std.path.isValidPath, but operates on Path.
bool isValidPath(in Path path) @safe pure nothrow
{
	return std.path.isValidPath(path.str);
}

/// Just like std.path.expandTilde, but operates on Path.
Path expandTilde(Path path)
{
	return Path( std.path.expandTilde(path.str) );
}

// The unittests in this module mainly check that all the templates compile
// correctly and that the appropriate Phobos functions are correctly called.
//
// A completely thorough testing of the behavior of such functions is
// occasionally left to Phobos itself as it is outside the scope of these tests.

version(unittest_scriptlike_d)
unittest
{
	import std.stdio : writeln;
	writeln("Running Scriptlike unittests: std.path wrappers");
	
	alias dirSep = dirSeparator;

	{
		auto e = Ext(".txt");
		assert(e != Ext(".dat"));
		assert(e == Ext(".txt"));
		version(Windows)
			assert(e == Ext(".TXT"));
		else version(OSX)
			assert(e == Ext(".TXT"));
		else version(Posix)
			assert(e != Ext(".TXT"));
		else
			static assert(0, "This platform not supported.");
		
		// Test the other comparison overloads
		assert(e != Ext(".dat"));
		assert(e == Ext(".txt"));
		assert(Ext(".dat") != e);
		assert(Ext(".txt") == e);
		assert(".dat" != e);
		assert(".txt" == e);

		assert(Ext("foo"));
		assert(Ext(""));
		assert(Ext(null).str is null);
		assert(!Ext(null));
	}

	auto p = Path();
	assert(p.str == ".");
	assert(!p.empty);
	
	assert(Path("").empty);
	
	assert(Path("foo"));
	assert(Path(""));
	assert(Path(null).str is null);
	assert(!Path(null));
	
	version(Windows)
		auto testStrings = ["/foo/bar", "/foo/bar/", `\foo\bar`, `\foo\bar\`];
	else version(Posix)
		auto testStrings = ["/foo/bar", "/foo/bar/"];
	else
		static assert(0, "This platform not supported.");
	
	foreach(str; testStrings)
	{
		writeln("  testing str: ", str);
		
		p = Path(str);
		assert(!p.empty);
		assert(p.str == dirSep~"foo"~dirSep~"bar");
		
		p = Path(str);
		assert(p.str == dirSep~"foo"~dirSep~"bar");
		assert(p.toRawString() == p.str);
		assert(p.toString()    == p.str.to!string());
		
		assert(p.up.toString() == dirSep~"foo");
		assert(p.up.up.toString() == dirSep);

		assert((p~"sub").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub");
		assert((p~"sub"~"2").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub"~dirSep~"2");
		assert((p~Path("sub")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub");
		
		version(Windows)
			assert((p~"sub dir").toString() == `"`~dirSep~"foo"~dirSep~"bar"~dirSep~"sub dir"~`"`);
		else version(Posix)
			assert((p~"sub dir").toString() == `'`~dirSep~"foo"~dirSep~"bar"~dirSep~`sub dir'`);
		else
			static assert(0, "This platform not supported.");

		assert(("dir"~p).toString() == dirSep~"foo"~dirSep~"bar");
		assert(("dir"~Path(str[1..$])).toString() == "dir"~dirSep~"foo"~dirSep~"bar");
		
		p ~= "blah";
		assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah");
		
		p ~= Path("more");
		assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah"~dirSep~"more");
		
		p ~= "..";
		assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah");
		
		p ~= Path("..");
		assert(p.toString() == dirSep~"foo"~dirSep~"bar");
		
		p ~= "sub dir";
		p ~= "..";
		assert(p.toString() == dirSep~"foo"~dirSep~"bar");
		
		p ~= "filename";
		assert((p~Ext(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert((p~Ext("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert((p~Ext("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

		p ~= Ext(".ext");
		assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
		assert(p.baseName().toString() == "filename.ext");
		assert(p.dirName().toString() == dirSep~"foo"~dirSep~"bar");
		assert(p.rootName().toString() == dirSep);
		assert(p.driveName().toString() == "");
		assert(p.stripDrive().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
		version(Windows)
		{
			assert(( Path("C:"~p.toRawString()) ).toString() == "C:"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			assert(( Path("C:"~p.toRawString()) ).stripDrive().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
		}
		assert(p.extension().toString() == ".ext");
		assert(p.stripExtension().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");
		assert(p.setExtension(".txt").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert(p.setExtension("txt").toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert(p.setExtension("").toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");
		assert(p.setExtension(Ext(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert(p.setExtension(Ext("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
		assert(p.setExtension(Ext("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

		assert(p.defaultExtension(".dat").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
		assert(p.stripExtension().defaultExtension(".dat").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.dat");

		assert(equal(p.pathSplitter(), [dirSep, "foo", "bar", "filename.ext"]));

		assert(p.isRooted());
		version(Windows)
			assert(!p.isAbsolute());
		else version(Posix)
			assert(p.isAbsolute());
		else
			static assert(0, "This platform not supported.");

		assert(!( Path("dir"~p.toRawString()) ).isRooted());
		assert(!( Path("dir"~p.toRawString()) ).isAbsolute());
		
		version(Windows)
		{
			assert(( Path("dir"~p.toRawString()) ).absolutePath("C:/main").toString() == "C:"~dirSep~"main"~dirSep~"dir"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			assert(( Path("C:"~p.toRawString()) ).relativePath("C:/foo").toString() == "bar"~dirSep~"filename.ext");
			assert(( Path("C:"~p.toRawString()) ).relativePath("C:/foo/bar").toString() == "filename.ext");
		}
		else version(Posix)
		{
			assert(( Path("dir"~p.toRawString()) ).absolutePath("/main").toString() == dirSep~"main"~dirSep~"dir"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			assert(p.relativePath("/foo").toString() == "bar"~dirSep~"filename.ext");
			assert(p.relativePath("/foo/bar").toString() == "filename.ext");
		}
		else
			static assert(0, "This platform not supported.");

		assert(p.filenameCmp(dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext") == 0);
		assert(p.filenameCmp(dirSep~"faa"~dirSep~"bat"~dirSep~"filename.ext") != 0);
		assert(p.globMatch("*foo*name.ext"));
		assert(!p.globMatch("*foo*Bname.ext"));

		assert(!p.isValidFilename());
		assert(p.baseName().isValidFilename());
		assert(p.isValidPath());
		
		assert(p.expandTilde().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
		
		assert(p != Path("/dir/subdir/filename.ext"));
		assert(p == Path("/foo/bar/filename.ext"));
		version(Windows)
			assert(p == Path("/FOO/BAR/FILENAME.EXT"));
		else version(OSX)
			assert(p == Path("/FOO/BAR/FILENAME.EXT"));
		else version(Posix)
			assert(p != Path("/FOO/BAR/FILENAME.EXT"));
		else
			static assert(0, "This platform not supported.");
		
		// Test the other comparison overloads
		assert(p != Path("/dir/subdir/filename.ext"));
		assert(p == Path("/foo/bar/filename.ext"));
		assert(Path("/dir/subdir/filename.ext") != p);
		assert(Path("/foo/bar/filename.ext")    == p);
		assert("/dir/subdir/filename.ext" != p);
		assert("/foo/bar/filename.ext"    == p);
	}
}
