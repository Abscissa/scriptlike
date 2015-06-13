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
struct ExtT(C = char) if( is(C==char) || is(C==wchar) || is(C==dchar) )
{
	private immutable(C)[] str;
	
	/// Main constructor.
	this(immutable(C)[] extension = null)
	{
		this.str = extension;
	}
	
	/// Convert to string.
	string toString()
	{
		return str.to!string();
	}
	
	/// Convert to string, wstring or dstring, depending on the type of Ext.
	immutable(C)[] toRawString()
	{
		return str;
	}
	
	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opCmp(ref const ExtT!C other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(ExtT!C other) const
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
	int opEquals(ref const ExtT!C other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(ExtT!C other) const
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
alias Ext  = ExtT!char;  ///ditto
alias WExt = ExtT!wchar; ///ditto
alias DExt = ExtT!dchar; ///ditto

/// Represents a filesystem path. The path is always kept normalized
/// automatically (as performed by buildNormalizedPathFixed).
///
/// wchar and dchar versions not yet supported, blocked by DMD issue #12112
struct PathT(C = char) if( is(C==char) /+|| is(C==wchar) || is(C==dchar)+/ )
{
	private immutable(C)[] str = ".";
	
	/// Main constructor.
	this()(const(C)[] path = ".") @safe pure nothrow
	{
		this.str = buildNormalizedPathFixed(path);
	}
	
	/++
	Convert from one type of Path to another.
	Example:
		auto pathStr  = Path("foo");
		auto pathWStr = PathT!wchar(pathStr);
		auto pathDStr = PathT!dchar(pathStr);
		pathStr = Path(pathWStr);
		pathStr = Path(pathDStr);
	+/
	this(T)(T[] path = ".") if(isSomeChar!T)
	{
		this.str = to!(immutable(C)[])( buildNormalizedPathFixed(path.to!string()) );
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
	
	/// Convert to string, wstring or dstring, depending on the type of Path.
	/// Does NOT do any escaping, even if path contains spaces.
	immutable(C)[] toRawString() const
	{
		return str;
	}

	/// Concatenates two paths, with a directory separator in between.
	PathT!C opBinary(string op)(PathT!C rhs) if(op=="~")
	{
		PathT!C newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs.str);
		return newPath;
	}
	
	///ditto
	PathT!C opBinary(string op)(const(C)[] rhs) if(op=="~")
	{
		PathT!C newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs);
		return newPath;
	}
	
	///ditto
	PathT!C opBinaryRight(string op)(const(C)[] lhs) if(op=="~")
	{
		PathT!C newPath;
		newPath.str = buildNormalizedPathFixed(lhs, this.str);
		return newPath;
	}
	
	/// Appends an extension to a path. Naturally, a directory separator
	/// is NOT inserted in between.
	PathT!C opBinary(string op)(ExtT!C rhs) if(op=="~")
	{
		PathT!C newPath;
		newPath.str = std.path.setExtension(this.str, rhs.str);
		return newPath;
	}
	
	/// Appends a path to this one, with a directory separator in between.
	PathT!C opOpAssign(string op)(PathT!C rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs.str);
		return this;
	}
	
	///ditto
	PathT!C opOpAssign(string op)(const(C)[] rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs);
		return this;
	}
	
	/// Appends an extension to this path. Naturally, a directory separator
	/// is NOT inserted in between.
	PathT!C opOpAssign(string op)(ExtT!C rhs) if(op=="~")
	{
		str = std.path.setExtension(str, rhs.str);
		return this;
	}
	
	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opCmp(ref const PathT!C other) const
	{
		return std.path.filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(PathT!C other) const
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
	int opEquals(ref const PathT!C other) const
	{
		return opCmp(other) == 0;
	}

	///ditto
	int opEquals(PathT!C other) const
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
	@property PathT!C up()
	{
		return this.dirName();
	}
	
	/// Is this path equal to empty string?
	@property bool empty()
	{
		return str == "";
	}
}
alias Path  = PathT!char; ///ditto
//alias WPath = PathT!wchar; ///ditto
//alias DPath = PathT!dchar; ///ditto

/// Convenience aliases
alias extOf      = extension;
alias stripExt   = stripExtension;   ///ditto
alias setExt     = setExtension;     ///ditto
alias defaultExt = defaultExtension; ///ditto


/// Like buildNormalizedPath, but if the result is the current directory,
/// this returns "." instead of "". However, if all the inputs are "", or there
/// are no inputs, this still returns "" just like buildNormalizedPath.
immutable(C)[] buildNormalizedPathFixed(C)(const(C[])[] paths...)
	@trusted pure nothrow
	if(isSomeChar!C)
{
	if(all!`a is null`(paths))
		return null;
	
	if(all!`a==""`(paths))
		return "";
	
	auto result = std.path.buildNormalizedPath(paths);
	return result==""? "." : result;
}

/// Properly escape arguments containing spaces for the command shell, if necessary.
string escapeShellArg(T)(T str) if(isSomeString!T)
{
	string s = str.to!string();

	if(str.canFind(' '))
	{
		version(Windows)
			return escapeWindowsArgument(s);
		else version(Posix)
			return escapeShellFileName(s);
		else
			static assert(0, "This platform not supported.");
	}
	else
		return s;
}

// -- std.path wrappers to support Path type --------------------

/// Just like std.path.baseName, but operates on Path.
PathT!C baseName(C)(PathT!C path)
	@trusted pure
{
	return PathT!C( std.path.baseName(path.str) );
}

///ditto
PathT!C baseName(CaseSensitive cs = CaseSensitive.osDefault, C, C1)
	(PathT!C path, in C1[] suffix)
	@safe pure
	if(isSomeChar!C1)
{
	return PathT!C( std.path.baseName!cs(path.str, suffix) );
}
/// Just like std.path.dirName, but operates on Path.
PathT!C dirName(C)(PathT!C path) if(isSomeChar!C)
{
	return PathT!C( std.path.dirName(path.str) );
}

/// Just like std.path.rootName, but operates on Path.
PathT!C rootName(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( std.path.rootName(path.str) );
}

/// Just like std.path.driveName, but operates on Path.
PathT!C driveName(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( std.path.driveName(path.str) );
}

/// Just like std.path.stripDrive, but operates on Path.
PathT!C stripDrive(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( std.path.stripDrive(path.str) );
}

/// Just like std.path.extension, but takes a Path and returns an Ext.
ExtT!C extension(C)(in PathT!C path) @safe pure nothrow
{
	return ExtT!C( std.path.extension(path.str) );
}

/// Just like std.path.stripExtension, but operates on Path.
PathT!C stripExtension(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( std.path.stripExtension(path.str) );
}

/// Just like std.path.setExtension, but operates on Path.
PathT!C setExtension(C, C2)(PathT!C path, const(C2)[] ext)
	@trusted pure nothrow
	if(is(C == Unqual!C2))
{
	return PathT!C( std.path.setExtension(path.str, ext) );
}

///ditto
PathT!C setExtension(C)(PathT!C path, ExtT!C ext)
	@trusted pure nothrow
{
	return path.setExtension(ext.toString());
}

/// Just like std.path.defaultExtension, but operates on Path and optionally Ext.
PathT!C defaultExtension(C, C2)(PathT!C path, in C2[] ext)
	@trusted pure
	if(is(C == Unqual!C2))
{
	return PathT!C( std.path.defaultExtension(path.str, ext) );
}

///ditto
PathT!C defaultExtension(C)(PathT!C path, ExtT!C ext)
	@trusted pure
{
	return path.defaultExtension(ext.toString());
}

/// Just like std.path.pathSplitter. Note this returns a range of strings,
/// not a range of Path.
auto pathSplitter(C)(PathT!C path) @safe pure nothrow
{
	return std.path.pathSplitter(path.str);
}

/// Just like std.path.isRooted, but operates on Path.
bool isRooted(C)(in PathT!C path) @safe pure nothrow
{
	return std.path.isRooted(path.str);
}

/// Just like std.path.isAbsolute, but operates on Path.
bool isAbsolute(C)(in PathT!C path) @safe pure nothrow
{
	return std.path.isAbsolute(path.str);
}

/// Just like std.path.absolutePath, but operates on Path.
PathT!C absolutePath(C)(PathT!C path, lazy string base = getcwd())
	@safe pure
{
	return PathT!C( std.path.absolutePath(path.str, base) );
}

///ditto
PathT!C absolutePath(C)(PathT!C path, PathT!C base)
	@safe pure
{
	return PathT!C( std.path.absolutePath(path.str, base.str.to!string()) );
}

/// Just like std.path.relativePath, but operates on Path.
PathT!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(PathT!C path, lazy string base = getcwd())
{
	return PathT!C( std.path.relativePath!cs(path.str, base) );
}

///ditto
PathT!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(PathT!C path, PathT!C base)
{
	return PathT!C( std.path.relativePath!cs(path.str, base.str.to!string()) );
}

/// Just like std.path.filenameCmp, but operates on Path.
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(PathT!C path, PathT!C2 filename2)
	@safe pure
{
	return std.path.filenameCmp(path.str, filename2.str);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(PathT!C path, const(C2)[] filename2)
	@safe pure
	if(isSomeChar!C2)
{
	return std.path.filenameCmp(path.str, filename2);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(const(C)[] path, PathT!C2[] filename2)
	@safe pure
	if(isSomeChar!C)
{
	return std.path.filenameCmp(path, filename2.str);
}

/// Just like std.path.globMatch, but operates on Path.
bool globMatch(CaseSensitive cs = CaseSensitive.osDefault, C)
	(PathT!C path, const(C)[] pattern)
	@safe pure nothrow
{
	return std.path.globMatch!cs(path.str, pattern);
}

/// Just like std.path.isValidFilename, but operates on Path.
bool isValidFilename(C)(in PathT!C path) @safe pure nothrow
{
	return std.path.isValidFilename(path.str);
}

/// Just like std.path.isValidPath, but operates on Path.
bool isValidPath(C)(in PathT!C path) @safe pure nothrow
{
	return std.path.isValidPath(path.str);
}

/// Just like std.path.expandTilde, but operates on Path.
PathT!C expandTilde(C)(PathT!C path)
{
	static if( is(C == char) )
		return PathT!C( std.path.expandTilde(path.str) );
	else
		return PathT!C( std.path.expandTilde( path.to!string() ).to!(C[])() );
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

	foreach(C; TypeTuple!(char/+, wchar, dchar+/))
	{
		//pragma(msg, "==="~C.stringof);

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
			assert(e != ExtT!C(".dat"));
			assert(e == ExtT!C(".txt"));
			assert(ExtT!C(".dat") != e);
			assert(ExtT!C(".txt") == e);
			assert(".dat" != e);
			assert(".txt" == e);

			assert(Ext("foo"));
			assert(Ext(""));
			assert(Ext(null).str is null);
			assert(!Ext(null));
		}

		auto p = PathT!C();
		assert(p.str == ".");
		assert(!p.empty);
		
		assert(PathT!C("").empty);
		assert(Path(cast(immutable(C)[])"").empty);
		
		p = Path(cast(immutable(C)[])".");
		assert(!p.empty);
		
		assert(Path("foo"));
		assert(Path(""));
		assert(Path(null).str is null);
		assert(!Path(null));
		
		version(Windows)
			auto testStrings = [cast(immutable(C)[])"/foo/bar", "/foo/bar/", `\foo\bar`, `\foo\bar\`];
		else version(Posix)
			auto testStrings = [cast(immutable(C)[])"/foo/bar", "/foo/bar/"];
		else
			static assert(0, "This platform not supported.");
		
		foreach(str; testStrings)
		{
			writeln("  testing str: ", str);
			
			p = PathT!C(str);
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
			assert((p~ExtT!C(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert((p~ExtT!C("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert((p~ExtT!C("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

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
			assert(p.setExtension(ExtT!C(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension(ExtT!C("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension(ExtT!C("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

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
			assert(p != PathT!C("/dir/subdir/filename.ext"));
			assert(p == PathT!C("/foo/bar/filename.ext"));
			assert(PathT!C("/dir/subdir/filename.ext") != p);
			assert(PathT!C("/foo/bar/filename.ext")    == p);
			assert("/dir/subdir/filename.ext" != p);
			assert("/foo/bar/filename.ext"    == p);
		}
	}
}
