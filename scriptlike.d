// Utility to aid in script-like programs.
//
// This is deliberately created as one file for easier usage
// in script-like programs.
//
// Written in the D programming language.
// Tested with DMD 2.064.2

module scriptlike;

// Import privately because this module wraps all the members.
import std.file;
import std.path;

// Automatically pull in anything likely to be useful for scripts.
// curl is deliberately left out here because it involves an extra
// link dependency.
public import std.algorithm;
public import std.array;
public import std.bigint;
public import std.conv;
public import std.datetime;
public import std.exception;
public import std.getopt;
public import std.math;
public import std.process;
public import std.random;
public import std.range;
public import std.regex;
public import std.stdio;
public import std.string;
public import std.system;
public import std.traits;
public import std.typecons;
public import std.typetuple;
public import std.uni;
public import std.variant;

/++
In your main(), catch this Fail exception, then output Fail.msg and
return an error code.

Example:

int main()
{
	try
	{
		// Your code here
	}
	catch(Fail e)
	{
		writeln("mytool: ERROR: ", e.msg);
		return 1;
	}
	
	return 0;
}
+/
class Fail : Exception
{
	this(string msg, string file=__FILE__, int line=__LINE__)
	{
		super(msg, file, line);
	}
}

/// If you've set up your main() to handle the Fail exception (as shown in
/// Fail's documentation, then call this to end your program with an error
/// message in an exception-safe way.
void fail(string msg, string file=__FILE__, int line=__LINE__)
{
	throw new Fail(msg, file, line);
}

//TODO: Support optional OutputRange sink as an alternative to stdout
/// If true, all commands will be echoed to stdout
bool scriptlikeTraceCommands = false;

string escapeShellPath(T)(T str) if(isSomeString!T)
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

/// Helper for creating an Ext.
///
/// Returns either Ext!char, Ext!wchar or Ext!dchar depending on the
/// type of string given.
auto ext(T)(T str) if(isSomeString!T)
{
	return Ext!( Unqual!(ElementEncodingType!T) )(str);
}

/// Represents a file extension.
struct Ext(C = char) if( is(C==char) || is(C==wchar) || is(C==dchar) )
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
	
	//TODO: Implement comparisons, concat, and any other applicable parts of std.path
}

/// Helper for creating a Path.
///
/// Returns either Path!char, Path!wchar or Path!dchar depending on the
/// type of string given.
auto path(T)(T str = ".") if(isSomeString!T)
{
	return Path!( Unqual!(ElementEncodingType!T) )(str);
}

/// Represents a filesystem path.
/// wchar and dchar versions not yet supported, blocked by DMD issue #12112
struct Path(C = char) if( is(C==char) /+|| is(C==wchar) || is(C==dchar)+/ )
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
		auto pathWStr = Path!wchar(pathStr);
		auto pathDStr = Path!dchar(pathStr);
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
		return escapeShellPath(str);
	}
	
	/// Convert to string, wstring or dstring, depending on the type of Path.
	/// Does NOT do any escaping, even if path contains spaces.
	immutable(C)[] toRawString()
	{
		return str;
	}

	/// Concatenates two paths, with a directory separator in between.
	Path!C opBinary(string op)(Path!C rhs) if(op=="~")
	{
		Path!C newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs.str);
		return newPath;
	}
	
	///ditto
	Path!C opBinary(string op)(const(C)[] rhs) if(op=="~")
	{
		Path!C newPath;
		newPath.str = buildNormalizedPathFixed(this.str, rhs);
		return newPath;
	}
	
	///ditto
	Path!C opBinaryRight(string op)(const(C)[] lhs) if(op=="~")
	{
		Path!C newPath;
		newPath.str = buildNormalizedPathFixed(lhs, this.str);
		return newPath;
	}
	
	/// Appends an extension to a path. Naturally, a directory separator
	/// is NOT inserted in between.
	Path!C opBinary(string op)(Ext!C rhs) if(op=="~")
	{
		Path!C newPath;
		newPath.str = this.str.setExtension(rhs.str);
		return newPath;
	}
	
	/// Appends a path to this one, with a directory separator in between.
	Path!C opOpAssign(string op)(Path!C rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs.str);
		return this;
	}
	
	///ditto
	Path!C opOpAssign(string op)(const(C)[] rhs) if(op=="~")
	{
		str = buildNormalizedPathFixed(str, rhs);
		return this;
	}
	
	/// Appends an extension to this path. Naturally, a directory separator
	/// is NOT inserted in between.
	Path!C opOpAssign(string op)(Ext!C rhs) if(op=="~")
	{
		str = str.setExtension(rhs.str);
		return this;
	}
	
	//TODO: Comparisons

	/// Returns the parent path, according to std.path.dirName.
	@property Path!C up()
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

/// Checks if the path exists as a directory.
///
/// This is like std.file.isDir, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsDir()(in char[] path) @trusted
{
	return exists(path) && isDir(path);
}
///ditto
bool existsAsDir(C)(in Path!C path) @trusted if(isSomeChar!C)
{
	return existsAsDir(path.str.to!string());
}

/// Checks if the path exists as a file.
///
/// This is like std.file.isFile, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsFile()(in char[] path) @trusted
{
	return exists(path) && isFile(path);
}
///ditto
bool existsAsFile(C)(in Path!C path) @trusted if(isSomeChar!C)
{
	return existsAsFile(path.str.to!string());
}

/// Checks if the path exists as a symlink.
///
/// This is like std.file.isSymlink, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsSymlink()(in char[] path) @trusted
{
	return exists(path) && isSymlink(path);
}
///ditto
bool existsAsSymlink(C)(in Path!C path) @trusted if(isSomeChar!C)
{
	return existsAsSymlink(path.str.to!string());
}

/// Like buildNormalizedPath, but if the result is the current directory,
/// this returns "." instead of "". However, if all the inputs are "", or there
/// are no inputs, this still returns "" just like buildNormalizedPath.
immutable(C)[] buildNormalizedPathFixed(C)(const(C[])[] paths...)
	@trusted pure nothrow
	if (isSomeChar!C)
{
	if(all!`a==""`(paths))
		return "";
	
	auto result = buildNormalizedPath(paths);
	return result==""? "." : result;
}

private void echoCommand(lazy string command)
{
	if(scriptlikeTraceCommands)
		writeln(command);
}

/// Runs a command, through the system's command shell interpreter,
/// in typical shell-script style: Synchronously, with the command's
/// stdout/in/err automatically forwarded through your
/// program's stdout/in/err.
///
/// Optionally takes a working directory to run the command from.
///
/// The command is echoed if scriptlikeTraceCommands is true.
int runShell()(string command)
{
	echoCommand(command);
	return system(command);
}

///ditto
int runShell(C)(Path!C workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	return runShell(command);
}

// -- Wrappers for std.path --------------------

/// Part of workaround for DMD Issue #12111
alias dirSeparator   = std.path.dirSeparator;
alias pathSeparator  = std.path.pathSeparator; ///ditto
alias isDirSeparator = std.path.isDirSeparator; ///ditto
alias CaseSensitive  = std.path.CaseSensitive; ///ditto
alias osDefaultCaseSensitivity = std.path.osDefaultCaseSensitivity; ///ditto
alias buildPath                = std.path.buildPath; ///ditto
alias buildNormalizedPath      = std.path.buildNormalizedPath; ///ditto

/// Just like std.path.baseName, but operates on Path.
Path!C baseName(C)(Path!C path)
	@trusted pure
{
	return Path!C( path.str.baseName() );
}

///ditto
Path!C baseName(CaseSensitive cs = CaseSensitive.osDefault, C, C1)
	(Path!C path, in C1[] suffix)
	@safe pure
	if(isSomeChar!C1)
{
	return Path!C( path.str.baseName!cs(suffix) );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] baseName(C)(inout(C)[] path)
	@trusted pure
	if (isSomeChar!C)
{
	return std.path.baseName(path);
}

///ditto
inout(C)[] baseName(CaseSensitive cs = CaseSensitive.osDefault, C, C1)
	(inout(C)[] path, in C1[] suffix)
	@safe pure
	if (isSomeChar!C && isSomeChar!C1)
{
	return std.path.baseName(path, suffix);
}

/// Just like std.path.dirName, but operates on Path.
Path!C dirName(C)(Path!C path) if(isSomeChar!C)
{
	return Path!C( path.str.dirName() );
}

/// Part of workaround for DMD Issue #12111
C[] dirName(C)(C[] path)
	if (isSomeChar!C)
{
	return std.path.dirName(path);
}

/// Just like std.path.rootName, but operates on Path.
Path!C rootName(C)(Path!C path) @safe pure nothrow
{
	return Path!C( path.str.rootName() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] rootName(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.rootName(path);
}

/// Just like std.path.driveName, but operates on Path.
Path!C driveName(C)(Path!C path) @safe pure nothrow
{
	return Path!C( path.str.driveName() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] driveName(C)(inout(C)[] path)  @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.driveName(path);
}

/// Just like std.path.stripDrive, but operates on Path.
Path!C stripDrive(C)(Path!C path) @safe pure nothrow
{
	return Path!C( path.str.stripDrive() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] stripDrive(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.stripDrive(path);
}

/// Just like std.path.extension, but takes a Path and returns an Ext.
Ext!C extension(C)(in Path!C path) @safe pure nothrow
{
	return Ext!C( path.str.extension() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] extension(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.extension(path);
}

/// Just like std.path.stripExtension, but operates on Path.
Path!C stripExtension(C)(Path!C path) @safe pure nothrow
{
	return Path!C( path.str.stripExtension() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] stripExtension(C)(inout(C)[] path)  @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.stripExtension(path);
}

/// Just like std.path.setExtension, but operates on Path.
Path!C setExtension(C, C2)(Path!C path, const(C2)[] ext)
	@trusted pure nothrow
	if(is(C == Unqual!C2))
{
	return Path!C( path.str.setExtension(ext) );
}

///ditto
Path!C setExtension(C)(Path!C path, Ext!C ext)
	@trusted pure nothrow
{
	return path.setExtension(ext.toString());
}

/// Part of workaround for DMD Issue #12111
immutable(Unqual!C1)[] setExtension(C1, C2)(in C1[] path, in C2[] ext)
	@trusted pure nothrow
	if (isSomeChar!C1 && !is(C1 == immutable) && is(Unqual!C1 == Unqual!C2))
{
	return std.path.setExtension(path, ext);
}

/// Part of workaround for DMD Issue #12111
immutable(C1)[] setExtension(C1, C2)(immutable(C1)[] path, const(C2)[] ext)
	@trusted pure nothrow
	if (isSomeChar!C1 && is(Unqual!C1 == Unqual!C2))
{
	return std.path.setExtension(path, ext);
}

/// Just like std.path.defaultExtension, but operates on Path and optionally Ext.
Path!C defaultExtension(C, C2)(Path!C path, in C2[] ext)
	@trusted pure
	if(is(C == Unqual!C2))
{
	return Path!C( path.str.defaultExtension(ext) );
}

///ditto
Path!C defaultExtension(C)(Path!C path, Ext!C ext)
	@trusted pure
{
	return path.defaultExtension(ext.toString());
}

/// Part of workaround for DMD Issue #12111
immutable(Unqual!C1)[] defaultExtension(C1, C2)(in C1[] path, in C2[] ext)
	@trusted pure
	if (isSomeChar!C1 && is(Unqual!C1 == Unqual!C2))
{
	return std.path.defaultExtension(path, ext);
}

/// Just like std.path.pathSplitter. Note this returns a range of strings,
/// not a range of Path.
auto pathSplitter(C)(Path!C path) @safe pure nothrow
{
	return pathSplitter(path.str);
}

/// Part of workaround for DMD Issue #12111
ReturnType!(std.path.pathSplitter!C) pathSplitter(C)(const(C)[] path) @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.pathSplitter(path);
}

/// Just like std.path.isRooted, but operates on Path.
bool isRooted(C)(in Path!C path) @safe pure nothrow
{
	return path.str.isRooted();
}

/// Part of workaround for DMD Issue #12111
bool isRooted(C)(in C[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isRooted(path);
}

/// Just like std.path.isAbsolute, but operates on Path.
bool isAbsolute(C)(in Path!C path) @safe pure nothrow
{
	return path.str.isAbsolute();
}

/// Part of workaround for DMD Issue #12111
bool isAbsolute(C)(in C[] path)  @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.isAbsolute(path);
}

/// Just like std.path.absolutePath, but operates on Path.
Path!C absolutePath(C)(Path!C path, lazy string base = getcwd())
	@safe pure
{
	return Path!C( path.str.absolutePath(base) );
}

///ditto
Path!C absolutePath(C)(Path!C path, Path!C base)
	@safe pure
{
	return Path!C( path.str.absolutePath(base.str.to!string()) );
}

/// Part of workaround for DMD Issue #12111
string absolutePath(string path, lazy string base = getcwd())
	@safe pure
{
	return std.path.absolutePath(path, base);
}

/// Just like std.path.relativePath, but operates on Path.
Path!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(Path!C path, lazy string base = getcwd())
{
	return Path!C( path.str.relativePath!cs(base) );
}

///ditto
Path!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(Path!C path, Path!C base)
{
	return Path!C( path.str.relativePath!cs(base.str.to!string()) );
}

/// Part of workaround for DMD Issue #12111
string relativePath(CaseSensitive cs = CaseSensitive.osDefault)
	(string path, lazy string base = getcwd())
{
	return std.path.relativePath(path, base);
}

/// Part of workaround for DMD Issue #12111
int filenameCharCmp(CaseSensitive cs = CaseSensitive.osDefault)(dchar a, dchar b)
	@safe pure nothrow
{
	return std.path.filenameCharCmp(a, b);
}

/// Just like std.path.filenameCmp, but operates on Path.
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(Path!C path, Path!C2 filename2)
	@safe pure
{
	return path.str.filenameCmp(filename2.str);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(Path!C path, const(C2)[] filename2)
	@safe pure
	if(isSomeChar!C2)
{
	return path.str.filenameCmp(filename2);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(const(C)[] path, Path!C2[] filename2)
	@safe pure
	if(isSomeChar!C)
{
	return path.filenameCmp(filename2.str);
}

/// Part of workaround for DMD Issue #12111
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C1, C2)
	(const(C1)[] filename1, const(C2)[] filename2)
	@safe pure
	if (isSomeChar!C1 && isSomeChar!C2)
{
	return std.path.filenameCmp(filename1, filename2);
}

/// Just like std.path.globMatch, but operates on Path.
bool globMatch(CaseSensitive cs = CaseSensitive.osDefault, C)
	(Path!C path, const(C)[] pattern)
	@safe pure nothrow
{
	return path.str.globMatch!cs(pattern);
}

/// Part of workaround for DMD Issue #12111
bool globMatch(CaseSensitive cs = CaseSensitive.osDefault, C)
	(const(C)[] path, const(C)[] pattern)
	@safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.globMatch(path, pattern);
}

/// Just like std.path.isValidFilename, but operates on Path.
bool isValidFilename(C)(in Path!C path) @safe pure nothrow
{
	return path.str.isValidFilename();
}

/// Part of workaround for DMD Issue #12111
bool isValidFilename(C)(in C[] filename)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isValidFilename(filename);
}

/// Just like std.path.isValidPath, but operates on Path.
bool isValidPath(C)(in Path!C path) @safe pure nothrow
{
	return path.str.isValidPath();
}

/// Part of workaround for DMD Issue #12111
bool isValidPath(C)(in C[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isValidPath(path);
}

/// Just like std.path.expandTilde, but operates on Path.
Path!C expandTilde(C)(Path!C path)
{
	static if( is(C == char) )
		return Path!C( path.str.expandTilde() );
	else
		return Path!C( path.to!string().expandTilde().to!(C[])() );
}

/// Part of workaround for DMD Issue #12111
string expandTilde(string inputPath)
{
	return std.path.expandTilde(inputPath);
}

// -- Wrappers for std.file --------------------

/// Part of workaround for DMD Issue #12111
alias FileException = std.file.FileException;
alias SpanMode      = std.file.SpanMode;
alias attrIsDir     = std.file.attrIsDir;
alias attrIsFile    = std.file.attrIsFile;
alias attrIsSymlink = std.file.attrIsSymlink;
alias getcwd        = std.file.getcwd;
alias thisExePath   = std.file.thisExePath;
alias tempDir       = std.file.tempDir;

/// Just like std.file.read, but takes a Path.
void[] read(C)(in Path!C name, size_t upTo = size_t.max) if(isSomeChar!C)
{
	return read(name.str.to!string(), upTo);
}

/// Part of workaround for DMD Issue #12111
void[] read(in char[] name, size_t upTo = size_t.max)
{
	return std.file.read(name, upTo);
}

/// Just like std.file.readText, but takes a Path.
template readText(S = string)
{
	S readText(C)(in Path!C name) if(isSomeChar!C)
	{
		return std.file.readText(name.str.to!string());
	}
}

/// Part of workaround for DMD Issue #12111
S readText(S = string)(in char[] name)
{
	return std.file.readText(name);
}

/// Just like std.file.write, but takes a Path.
void write(C)(in Path!C name, const void[] buffer) if(isSomeChar!C)
{
	write(name.str.to!string(), buffer);
}

/// Part of workaround for DMD Issue #12111
void write(in char[] name, const void[] buffer)
{
	std.file.write(name, buffer);
}

/// Just like std.file.append, but takes a Path.
void append(C)(in Path!C name, in void[] buffer) if(isSomeChar!C)
{
	append(name.str.to!string(), buffer);
}

/// Part of workaround for DMD Issue #12111
void append(in char[] name, in void[] buffer)
{
	std.file.append(name, buffer);
}

/// Just like std.file.rename, but takes Path, and echoes if scriptlikeTraceCommands is true.
void rename(C)(in Path!C from, in Path!C to) if(isSomeChar!C)
{
	rename(from.str.to!string(), to.str.to!string());
}

///ditto
void rename(C)(in char[] from, in Path!C to) if(isSomeChar!C)
{
	rename(from, to.str.to!string());
}

///ditto
void rename(C)(in Path!C from, in char[] to) if(isSomeChar!C)
{
	rename(from.str.to!string(), to);
}

/// Just like std.file.rename, but echoes if scriptlikeTraceCommands is true.
void rename(in char[] from, in char[] to)
{
	echoCommand("rename: "~from.escapeShellPath()~" -> "~to.escapeShellPath());
	std.file.rename(from, to);
}

/// Just like std.file.remove, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void remove(C)(in Path!C name) if(isSomeChar!C)
{
	remove(name.str.to!string());
}

/// Just like std.file.remove, but echoes if scriptlikeTraceCommands is true.
void remove(in char[] name)
{
	echoCommand("remove: "~name.escapeShellPath());
	std.file.remove(name);
}

/// Just like std.file.getSize, but takes a Path.
ulong getSize(C)(in Path!C name) if(isSomeChar!C)
{
	return getSize(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
ulong getSize(in char[] name)
{
	return std.file.getSize(name);
}

/// Just like std.file.getTimes, but takes a Path.
void getTimes(C)(in Path!C name,
	out SysTime accessTime,
	out SysTime modificationTime) if(isSomeChar!C)
{
	getTimes(name.str.to!string(), accessTime, modificationTime);
}

/// Part of workaround for DMD Issue #12111
void getTimes(in char[] name,
	out SysTime accessTime,
	out SysTime modificationTime)
{
	std.file.getTimes(name, accessTime, modificationTime);
}

/// Windows-only. Just like std.file.getTimesWin, but takes a Path.
version(Windows) void getTimesWin(C)(in Path!C name,
	out SysTime fileCreationTime,
	out SysTime fileAccessTime,
	out SysTime fileModificationTime) if(isSomeChar!C)
{
	getTimesWin(name.str.to!string(), fileCreationTime, fileAccessTime, fileModificationTime);
}

/// Part of workaround for DMD Issue #12111
version(Windows) void getTimesWin(in char[] name,
	out SysTime fileCreationTime,
	out SysTime fileAccessTime,
	out SysTime fileModificationTime)
{
	std.file.getTimesWin(name, fileCreationTime, fileAccessTime, fileModificationTime);
}

/// Just like std.file.setTimes, but takes a Path.
void setTimes(C)(in Path!C name,
	SysTime accessTime,
	SysTime modificationTime) if(isSomeChar!C)
{
	setTimes(name.str.to!string(), accessTime, modificationTime);
}

/// Part of workaround for DMD Issue #12111
void setTimes(in char[] name,
	SysTime accessTime,
	SysTime modificationTime)
{
	return std.file.setTimes(name, accessTime, modificationTime);
}

/// Just like std.file.timeLastModified, but takes a Path.
SysTime timeLastModified(C)(in Path!C name) if(isSomeChar!C)
{
	return timeLastModified(name.str.to!string());
}

/// Just like std.file.timeLastModified, but takes a Path.
SysTime timeLastModified(C)(in Path!C name, SysTime returnIfMissing) if(isSomeChar!C)
{
	return timeLastModified(name.str.to!string(), returnIfMissing);
}

/// Part of workaround for DMD Issue #12111
SysTime timeLastModified(in char[] name)
{
	return std.file.timeLastModified(name);
}

///ditto
SysTime timeLastModified(in char[] name, SysTime returnIfMissing)
{
	return std.file.timeLastModified(name, returnIfMissing);
}

/// Just like std.file.exists, but takes a Path.
bool exists(C)(in Path!C name) @trusted if(isSomeChar!C)
{
	return exists(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
bool exists(in char[] name) @trusted
{
	return std.file.exists(name);
}

/// Just like std.file.getAttributes, but takes a Path.
uint getAttributes(C)(in Path!C name) if(isSomeChar!C)
{
	return getAttributes(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
uint getAttributes(in char[] name)
{
	return std.file.getAttributes(name);
}

/// Just like std.file.getLinkAttributes, but takes a Path.
uint getLinkAttributes(C)(in Path!C name) if(isSomeChar!C)
{
	return getLinkAttributes(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
uint getLinkAttributes(in char[] name)
{
	return std.file.getLinkAttributes(name);
}

/// Just like std.file.isDir, but takes a Path.
@property bool isDir(C)(in Path!C name) if(isSomeChar!C)
{
	return isDir(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isDir(in char[] name)
{
	return std.file.isDir(name);
}

/// Just like std.file.isFile, but takes a Path.
@property bool isFile(C)(in Path!C name) if(isSomeChar!C)
{
	return isFile(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isFile(in char[] name)
{
	return std.file.isFile(name);
}

/// Just like std.file.isSymlink, but takes a Path.
@property bool isSymlink(C)(Path!C name) if(isSomeChar!C)
{
	return isSymlink(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isSymlink(C)(const(C)[] name)
{
	return std.file.isSymlink(name);
}

/// Just like std.file.chdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void chdir(C)(in Path!C pathname) if(isSomeChar!C)
{
	chdir(pathname.str.to!string());
}

/// Just like std.file.chdir, but echoes if scriptlikeTraceCommands is true.
void chdir(in char[] pathname)
{
	echoCommand("chdir: "~pathname.escapeShellPath());
	std.file.chdir(pathname);
}

/// Just like std.file.mkdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void mkdir(C)(in Path!C pathname) if(isSomeChar!C)
{
	mkdir(pathname.str.to!string());
}

/// Just like std.file.mkdir, but echoes if scriptlikeTraceCommands is true.
void mkdir(in char[] pathname)
{
	echoCommand("mkdir: "~pathname.escapeShellPath());
	std.file.mkdir(pathname);
}

/// Just like std.file.mkdirRecurse, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void mkdirRecurse(C)(in Path!C pathname) if(isSomeChar!C)
{
	mkdirRecurse(pathname.str.to!string());
}

/// Just like std.file.mkdirRecurse, but echoes if scriptlikeTraceCommands is true.
void mkdirRecurse(in char[] pathname)
{
	echoCommand("mkdirRecurse: "~pathname.escapeShellPath());
	std.file.mkdirRecurse(pathname);
}

/// Just like std.file.rmdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void rmdir(C)(in Path!C pathname) if(isSomeChar!C)
{
	rmdir(pathname.str.to!string());
}

/// Just like std.file.rmdir, but echoes if scriptlikeTraceCommands is true.
void rmdir(in char[] pathname)
{
	echoCommand("rmdir: "~pathname.escapeShellPath());
	std.file.rmdir(pathname);
}

/// Posix-only. Just like std.file.symlink, but takes Path, and echoes if scriptlikeTraceCommands is true.
version(Posix) void symlink(C1, C2)(Path!C1 original, Path!C2 link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original.str.to!string(), link.str.to!string());
}

///ditto
version(Posix) void symlink(C1, C2)(const(C1)[] original, Path!C2 link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original, link.str.to!string());
}

///ditto
version(Posix) void symlink(C1, C2)(Path!C1 original, const(C2)[] link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original.str.to!string(), link);
}

/// Just like std.file.symlink, but echoes if scriptlikeTraceCommands is true.
version(Posix) void symlink(C1, C2)(const(C1)[] original, const(C2)[] link)
{
	echoCommand("symlink: [original] "~original.escapeShellPath()~" : [symlink] "~link.escapeShellPath());
	std.file.symlink(original, link);
}

/// Posix-only. Just like std.file.readLink, but operates on Path.
version(Posix) Path!C readLink(C)(Path!C link) if(isSomeChar!C)
{
	return Path!C( readLink(link.str.to!string()) );
}

/// Part of workaround for DMD Issue #12111
version(Posix) string readLink(C)(const(C)[] link)
{
	return std.file.readLink(link);
}

/// Just like std.file.copy, but takes Path, and echoes if scriptlikeTraceCommands is true.
void copy(C)(in Path!C from, in Path!C to) if(isSomeChar!C)
{
	copy(from.str.to!string(), to.str.to!string());
}

///ditto
void copy(C)(in char[] from, in Path!C to) if(isSomeChar!C)
{
	copy(from, to.str.to!string());
}

///ditto
void copy(C)(in Path!C from, in char[] to) if(isSomeChar!C)
{
	copy(from.str.to!string(), to);
}

/// Just like std.file.copy, but echoes if scriptlikeTraceCommands is true.
void copy(in char[] from, in char[] to)
{
	echoCommand("copy: "~from.escapeShellPath()~" -> "~to.escapeShellPath());
	std.file.copy(from, to);
}

/// Just like std.file.rmdirRecurse, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void rmdirRecurse(C)(in Path!C pathname) if(isSomeChar!C)
{
	rmdirRecurse(pathname.str.to!string());
}

/// Just like std.file.rmdirRecurse, but echoes if scriptlikeTraceCommands is true.
void rmdirRecurse(in char[] pathname)
{
	echoCommand("rmdirRecurse: "~pathname.escapeShellPath());
	std.file.rmdirRecurse(pathname);
}

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(C)(Path!C path, SpanMode mode, bool followSymlink = true) if(isSomeChar!C)
{
	return dirEntries(path.str.to!string(), mode, followSymlink);
}

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(C)(Path!C path, string pattern, SpanMode mode,
	bool followSymlink = true) if(isSomeChar!C)
{
	return dirEntries(path.str.to!string(), pattern, mode, followSymlink);
}

/// Part of workaround for DMD Issue #12111
auto dirEntries(string path, SpanMode mode, bool followSymlink = true)
{
	return std.file.dirEntries(path, mode, followSymlink);
}

///ditto
auto dirEntries(string path, string pattern, SpanMode mode,
	bool followSymlink = true)
{
	return std.file.dirEntries(path, pattern, mode, followSymlink);
}

/// Just like std.file.slurp, but takes a Path.
template slurp(Types...)
{
	auto slurp(C)(Path!C filename, in char[] format) if(isSomeChar!C)
	{
		return std.file.slurp!Types(filename.str.to!string(), format);
	}
}

/// Part of workaround for DMD Issue #12111
Select!(Types.length == 1, Types[0][], Tuple!(Types)[])
slurp(Types...)(string filename, in char[] format)
{
	return std.file.slurp(filename, format);
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
	writeln("Running 'scriptlike.d' unittests: std.path wrappers");
	
	alias dirSep = dirSeparator;

	foreach(C; TypeTuple!(char/+, wchar, dchar+/))
	{
		//pragma(msg, "==="~C.stringof);
		auto p = Path!C();
		assert(p.str == ".");
		assert(!p.empty);
		
		assert(Path!C("").empty);
		assert(path(cast(immutable(C)[])"").empty);
		
		p = path(cast(immutable(C)[])".");
		assert(!p.empty);
		
		version(Windows)
			auto testStrings = [cast(immutable(C)[])"/foo/bar", "/foo/bar/", `\foo\bar`, `\foo\bar\`];
		else version(Posix)
			auto testStrings = [cast(immutable(C)[])"/foo/bar", "/foo/bar/"];
		else
			static assert(0, "This platform not supported.");
		
		foreach(str; testStrings)
		{
			writeln("  testing str: ", str);
			
			p = Path!C(str);
			assert(!p.empty);
			assert(p.str == dirSep~"foo"~dirSep~"bar");
			
			p = path(str);
			assert(p.str == dirSep~"foo"~dirSep~"bar");
			assert(p.toRawString() == p.str);
			assert(p.toString()    == p.str.to!string());
			
			assert(p.up.toString() == dirSep~"foo");
			assert(p.up.up.toString() == dirSep);

			assert((p~"sub").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub");
			assert((p~"sub"~"2").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub"~dirSep~"2");
			assert((p~path("sub")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"sub");
			
			version(Windows)
				assert((p~"sub dir").toString() == `"`~dirSep~"foo"~dirSep~"bar"~dirSep~"sub dir"~`"`);
			else version(Posix)
				assert((p~"sub dir").toString() == `'`~dirSep~"foo"~dirSep~"bar"~dirSep~`sub dir'`);
			else
				static assert(0, "This platform not supported.");

			assert(("dir"~p).toString() == dirSep~"foo"~dirSep~"bar");
			assert(("dir"~path(str[1..$])).toString() == "dir"~dirSep~"foo"~dirSep~"bar");
			
			p ~= "blah";
			assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah");
			
			p ~= path("more");
			assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah"~dirSep~"more");
			
			p ~= "..";
			assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"blah");
			
			p ~= path("..");
			assert(p.toString() == dirSep~"foo"~dirSep~"bar");
			
			p ~= "sub dir";
			p ~= "..";
			assert(p.toString() == dirSep~"foo"~dirSep~"bar");
			
			p ~= "filename";
			assert((p~Ext!C(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert((p~Ext!C("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert((p~Ext!C("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

			p ~= ext(".ext");
			assert(p.toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			assert(p.baseName().toString() == "filename.ext");
			assert(p.dirName().toString() == dirSep~"foo"~dirSep~"bar");
			assert(p.rootName().toString() == dirSep);
			assert(p.driveName().toString() == "");
			assert(p.stripDrive().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			version(Windows)
			{
				assert(( path("C:"~p.toRawString()) ).toString() == "C:"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
				assert(( path("C:"~p.toRawString()) ).stripDrive().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
			}
			assert(p.extension().toString() == ".ext");
			assert(p.stripExtension().toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");
			assert(p.setExtension(".txt").toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension("txt").toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension("").toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");
			assert(p.setExtension(Ext!C(".txt")).toString() == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension(Ext!C("txt")).toString()  == dirSep~"foo"~dirSep~"bar"~dirSep~"filename.txt");
			assert(p.setExtension(Ext!C("")).toString()     == dirSep~"foo"~dirSep~"bar"~dirSep~"filename");

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

			assert(!( path("dir"~p.toRawString()) ).isRooted());
			assert(!( path("dir"~p.toRawString()) ).isAbsolute());
			
			version(Windows)
			{
				assert(( path("dir"~p.toRawString()) ).absolutePath("C:/main").toString() == "C:"~dirSep~"main"~dirSep~"dir"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
				assert(( path("C:"~p.toRawString()) ).relativePath("C:/foo").toString() == "bar"~dirSep~"filename.ext");
				assert(( path("C:"~p.toRawString()) ).relativePath("C:/foo/bar").toString() == "filename.ext");
			}
			else version(Posix)
			{
				assert(( path("dir"~p.toRawString()) ).absolutePath("/main").toString() == dirSep~"main"~dirSep~"dir"~dirSep~"foo"~dirSep~"bar"~dirSep~"filename.ext");
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
		}
	}
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
	import core.thread;

	writeln("Running 'scriptlike.d' unittests: std.file wrappers");
	
	immutable tempname  = buildPath(tempDir(), "deleteme.script like.unit test.pid"  ~ to!string(thisProcessID));
	immutable tempname2 = buildPath(tempDir(), "deleteme.script like.unit test2.pid" ~ to!string(thisProcessID));
	immutable tempname3 = buildPath(tempDir(), "deleteme.script like.unit test3.pid" ~ to!string(thisProcessID), "somefile");
	auto tempPath  = path(tempname);
	auto tempPath2 = path(tempname2);
	auto tempPath3 = path(tempname3);
	assert(!tempname.exists());
	assert(!tempname2.exists());
	assert(!tempname3.dirName().exists());
	assert(!tempname3.exists());
	
	{
		scope(exit)
		{
			if(exists(tempname)) remove(tempname);
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
			if(exists(tempname))  remove(tempname);
			if(exists(tempname2)) remove(tempname2);
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
			if(exists(tempname))  rmdir(tempname);
			if(exists(tempname3)) rmdir(tempname3);
			if(exists(tempname3.dirName())) rmdir(tempname3.dirName());
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
		
		auto saveDirName = getcwd();
		auto saveDir = path(saveDirName);
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
				if(exists(tempname2)) remove(tempname2);
				if(exists(tempname))  remove(tempname);
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
			if(exists(tempname)) remove(tempname);
		}
		
		runShell(`echo TestScriptStuff > `~tempPath.to!string());
		assert(tempPath.exists());
		assert(tempPath.isFile());
		assert((cast(string)tempPath.read()).strip() == "TestScriptStuff");
	}
	
	{
		assert(!tempPath3.exists());
		assert(!tempPath3.up.exists());

		scope(exit)
		{
			if(exists(tempname3)) remove(tempname3);
			if(exists(tempname3.dirName())) rmdir(tempname3.dirName());
		}
		
		tempPath3.up.mkdir();
		assert(tempPath3.up.exists());
		assert(tempPath3.up.isDir());
				
		tempPath3.up.runShell(`echo MoreTestStuff > `~tempPath3.baseName().to!string());
		assert(tempPath3.exists());
		assert(tempPath3.isFile());
		assert((cast(string)tempPath3.read()).strip() == "MoreTestStuff");
	}
}
