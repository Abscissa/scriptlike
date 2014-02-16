// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

module scriptlike.path;

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

//TODO: Support optional OutputRange sink as an alternative to stdout
/// If true, all commands will be echoed to stdout
bool scriptlikeTraceCommands = false;

/// Indicates a command returned a non-zero errorlevel.
class ErrorLevelException : Exception
{
	int errorLevel;
	string command;
	
	this(int errorLevel, string command, string file=__FILE__, size_t line=__LINE__)
	{
		this.errorLevel = errorLevel;
		this.command = command;
		auto msg = text("Command exited with error level ", errorLevel, ": ", command);
		super(msg, file, line);
	}
}

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
		return filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(ExtT!C other) const
	{
		return filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(string other) const
	{
		return filenameCmp(this.str, other);
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
	immutable(C)[] toRawString()
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
		newPath.str = this.str.setExtension(rhs.str);
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
		str = str.setExtension(rhs.str);
		return this;
	}
	
	/// Compare using OS-specific case-sensitivity rules. If you want to force
	/// case-sensitive or case-insensistive, then call filenameCmp instead.
	int opCmp(ref const PathT!C other) const
	{
		return filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(PathT!C other) const
	{
		return filenameCmp(this.str, other.str);
	}

	///ditto
	int opCmp(string other) const
	{
		return filenameCmp(this.str, other);
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

/// Checks if the path exists as a directory.
///
/// This is like std.file.isDir, but returns false instead of throwing if the
/// path doesn't exist.
bool existsAsDir()(in char[] path) @trusted
{
	return exists(path) && isDir(path);
}
///ditto
bool existsAsDir(C)(in PathT!C path) @trusted if(isSomeChar!C)
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
bool existsAsFile(C)(in PathT!C path) @trusted if(isSomeChar!C)
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
bool existsAsSymlink(C)(in PathT!C path) @trusted if(isSomeChar!C)
{
	return existsAsSymlink(path.str.to!string());
}

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
	
	auto result = buildNormalizedPath(paths);
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

private void echoCommand(lazy string command)
{
	if(scriptlikeTraceCommands)
		writeln(command);
}

/++
Runs a command, through the system's command shell interpreter,
in typical shell-script style: Synchronously, with the command's
stdout/in/err automatically forwarded through your
program's stdout/in/err.

Optionally takes a working directory to run the command from.

The command is echoed if scriptlikeTraceCommands is true.

ErrorLevelException is thrown if the process returns a non-zero error level.
If you want to handle the error level yourself, use tryRun instead of run.

Example:
---------------------
Args cmd;
cmd ~= path("some tool");
cmd ~= "-o";
cmd ~= path(`dir/out file.txt`);
cmd ~= ["--abc", "--def", "-g"];
path("some working dir").run(cmd.data);
---------------------
+/
void run()(string command)
{
	auto errorLevel = tryRun(command);
	if(errorLevel != 0)
		throw new ErrorLevelException(errorLevel, command);
}

///ditto
void run(C)(PathT!C workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	run(command);
}

/++
Runs a command, through the system's command shell interpreter,
in typical shell-script style: Synchronously, with the command's
stdout/in/err automatically forwarded through your
program's stdout/in/err.

Optionally takes a working directory to run the command from.

The command is echoed if scriptlikeTraceCommands is true.

Returns: The error level the process exited with.

Example:
---------------------
Args cmd;
cmd ~= path("some tool");
cmd ~= "-o";
cmd ~= path(`dir/out file.txt`);
cmd ~= ["--abc", "--def", "-g"];
auto errLevel = path("some working dir").run(cmd.data);
---------------------
+/
int tryRun()(string command)
{
	echoCommand(command);
	return system(command);
}

///ditto
int tryRun(C)(PathT!C workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	return run(command);
}

/// Backwards-compatibility alias. runShell may become depricated in the
/// future, so you should use tryRun or run insetad.
alias runShell = tryRun;

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
PathT!C baseName(C)(PathT!C path)
	@trusted pure
{
	return PathT!C( path.str.baseName() );
}

///ditto
PathT!C baseName(CaseSensitive cs = CaseSensitive.osDefault, C, C1)
	(PathT!C path, in C1[] suffix)
	@safe pure
	if(isSomeChar!C1)
{
	return PathT!C( path.str.baseName!cs(suffix) );
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
PathT!C dirName(C)(PathT!C path) if(isSomeChar!C)
{
	return PathT!C( path.str.dirName() );
}

/// Part of workaround for DMD Issue #12111
C[] dirName(C)(C[] path)
	if (isSomeChar!C)
{
	return std.path.dirName(path);
}

/// Just like std.path.rootName, but operates on Path.
PathT!C rootName(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( path.str.rootName() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] rootName(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.rootName(path);
}

/// Just like std.path.driveName, but operates on Path.
PathT!C driveName(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( path.str.driveName() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] driveName(C)(inout(C)[] path)  @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.driveName(path);
}

/// Just like std.path.stripDrive, but operates on Path.
PathT!C stripDrive(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( path.str.stripDrive() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] stripDrive(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.stripDrive(path);
}

/// Just like std.path.extension, but takes a Path and returns an Ext.
ExtT!C extension(C)(in PathT!C path) @safe pure nothrow
{
	return ExtT!C( path.str.extension() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] extension(C)(inout(C)[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.extension(path);
}

/// Just like std.path.stripExtension, but operates on Path.
PathT!C stripExtension(C)(PathT!C path) @safe pure nothrow
{
	return PathT!C( path.str.stripExtension() );
}

/// Part of workaround for DMD Issue #12111
inout(C)[] stripExtension(C)(inout(C)[] path)  @safe pure nothrow
	if (isSomeChar!C)
{
	return std.path.stripExtension(path);
}

/// Just like std.path.setExtension, but operates on Path.
PathT!C setExtension(C, C2)(PathT!C path, const(C2)[] ext)
	@trusted pure nothrow
	if(is(C == Unqual!C2))
{
	return PathT!C( path.str.setExtension(ext) );
}

///ditto
PathT!C setExtension(C)(PathT!C path, ExtT!C ext)
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
PathT!C defaultExtension(C, C2)(PathT!C path, in C2[] ext)
	@trusted pure
	if(is(C == Unqual!C2))
{
	return PathT!C( path.str.defaultExtension(ext) );
}

///ditto
PathT!C defaultExtension(C)(PathT!C path, ExtT!C ext)
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
auto pathSplitter(C)(PathT!C path) @safe pure nothrow
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
bool isRooted(C)(in PathT!C path) @safe pure nothrow
{
	return path.str.isRooted();
}

/// Part of workaround for DMD Issue #12111
bool isRooted(C)(in C[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isRooted(path);
}

/// Just like std.path.isAbsolute, but operates on Path.
bool isAbsolute(C)(in PathT!C path) @safe pure nothrow
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
PathT!C absolutePath(C)(PathT!C path, lazy string base = getcwd())
	@safe pure
{
	return PathT!C( path.str.absolutePath(base) );
}

///ditto
PathT!C absolutePath(C)(PathT!C path, PathT!C base)
	@safe pure
{
	return PathT!C( path.str.absolutePath(base.str.to!string()) );
}

/// Part of workaround for DMD Issue #12111
string absolutePath(string path, lazy string base = getcwd())
	@safe pure
{
	return std.path.absolutePath(path, base);
}

/// Just like std.path.relativePath, but operates on Path.
PathT!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(PathT!C path, lazy string base = getcwd())
{
	return PathT!C( path.str.relativePath!cs(base) );
}

///ditto
PathT!C relativePath(CaseSensitive cs = CaseSensitive.osDefault, C)
	(PathT!C path, PathT!C base)
{
	return PathT!C( path.str.relativePath!cs(base.str.to!string()) );
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
	(PathT!C path, PathT!C2 filename2)
	@safe pure
{
	return path.str.filenameCmp(filename2.str);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(PathT!C path, const(C2)[] filename2)
	@safe pure
	if(isSomeChar!C2)
{
	return path.str.filenameCmp(filename2);
}

///ditto
int filenameCmp(CaseSensitive cs = CaseSensitive.osDefault, C, C2)
	(const(C)[] path, PathT!C2[] filename2)
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
	(PathT!C path, const(C)[] pattern)
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
bool isValidFilename(C)(in PathT!C path) @safe pure nothrow
{
	return path.str.isValidFilename();
}

/// Part of workaround for DMD Issue #12111
bool isValidFilename(C)(in C[] filename)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isValidFilename(filename);
}

/// Just like std.path.isValidPath, but operates on Path.
bool isValidPath(C)(in PathT!C path) @safe pure nothrow
{
	return path.str.isValidPath();
}

/// Part of workaround for DMD Issue #12111
bool isValidPath(C)(in C[] path)  @safe pure nothrow  if (isSomeChar!C)
{
	return std.path.isValidPath(path);
}

/// Just like std.path.expandTilde, but operates on Path.
PathT!C expandTilde(C)(PathT!C path)
{
	static if( is(C == char) )
		return PathT!C( path.str.expandTilde() );
	else
		return PathT!C( path.to!string().expandTilde().to!(C[])() );
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
void[] read(C)(in PathT!C name, size_t upTo = size_t.max) if(isSomeChar!C)
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
	S readText(C)(in PathT!C name) if(isSomeChar!C)
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
void write(C)(in PathT!C name, const void[] buffer) if(isSomeChar!C)
{
	write(name.str.to!string(), buffer);
}

/// Part of workaround for DMD Issue #12111
void write(in char[] name, const void[] buffer)
{
	std.file.write(name, buffer);
}

/// Just like std.file.append, but takes a Path.
void append(C)(in PathT!C name, in void[] buffer) if(isSomeChar!C)
{
	append(name.str.to!string(), buffer);
}

/// Part of workaround for DMD Issue #12111
void append(in char[] name, in void[] buffer)
{
	std.file.append(name, buffer);
}

/// Just like std.file.rename, but takes Path, and echoes if scriptlikeTraceCommands is true.
void rename(C)(in PathT!C from, in PathT!C to) if(isSomeChar!C)
{
	rename(from.str.to!string(), to.str.to!string());
}

///ditto
void rename(C)(in char[] from, in PathT!C to) if(isSomeChar!C)
{
	rename(from, to.str.to!string());
}

///ditto
void rename(C)(in PathT!C from, in char[] to) if(isSomeChar!C)
{
	rename(from.str.to!string(), to);
}

/// Just like std.file.rename, but echoes if scriptlikeTraceCommands is true.
void rename(in char[] from, in char[] to)
{
	echoCommand("rename: "~from.escapeShellArg()~" -> "~to.escapeShellArg());
	std.file.rename(from, to);
}

/// If 'from' exists, then rename. Otherwise do nothing.
/// Returns: Success?
bool tryRename(T1, T2)(T1 from, T2 to)
{
	if(from.exists())
	{
		rename(from, to);
		return true;
	}

	return false;
}

/// Just like std.file.remove, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void remove(C)(in PathT!C name) if(isSomeChar!C)
{
	remove(name.str.to!string());
}

/// Just like std.file.remove, but echoes if scriptlikeTraceCommands is true.
void remove(in char[] name)
{
	echoCommand("remove: "~name.escapeShellArg());
	std.file.remove(name);
}

/// If 'name' exists, then remove. Otherwise do nothing.
/// Returns: Success?
bool tryRemove(T)(T name)
{
	if(name.exists())
	{
		remove(name);
		return true;
	}
	
	return false;
}

/// Just like std.file.getSize, but takes a Path.
ulong getSize(C)(in PathT!C name) if(isSomeChar!C)
{
	return getSize(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
ulong getSize(in char[] name)
{
	return std.file.getSize(name);
}

/// Just like std.file.getTimes, but takes a Path.
void getTimes(C)(in PathT!C name,
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
version(Windows) void getTimesWin(C)(in PathT!C name,
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
void setTimes(C)(in PathT!C name,
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
SysTime timeLastModified(C)(in PathT!C name) if(isSomeChar!C)
{
	return timeLastModified(name.str.to!string());
}

/// Just like std.file.timeLastModified, but takes a Path.
SysTime timeLastModified(C)(in PathT!C name, SysTime returnIfMissing) if(isSomeChar!C)
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
bool exists(C)(in PathT!C name) @trusted if(isSomeChar!C)
{
	return exists(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
bool exists(in char[] name) @trusted
{
	return std.file.exists(name);
}

/// Just like std.file.getAttributes, but takes a Path.
uint getAttributes(C)(in PathT!C name) if(isSomeChar!C)
{
	return getAttributes(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
uint getAttributes(in char[] name)
{
	return std.file.getAttributes(name);
}

/// Just like std.file.getLinkAttributes, but takes a Path.
uint getLinkAttributes(C)(in PathT!C name) if(isSomeChar!C)
{
	return getLinkAttributes(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
uint getLinkAttributes(in char[] name)
{
	return std.file.getLinkAttributes(name);
}

/// Just like std.file.isDir, but takes a Path.
@property bool isDir(C)(in PathT!C name) if(isSomeChar!C)
{
	return isDir(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isDir(in char[] name)
{
	return std.file.isDir(name);
}

/// Just like std.file.isFile, but takes a Path.
@property bool isFile(C)(in PathT!C name) if(isSomeChar!C)
{
	return isFile(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isFile(in char[] name)
{
	return std.file.isFile(name);
}

/// Just like std.file.isSymlink, but takes a Path.
@property bool isSymlink(C)(PathT!C name) if(isSomeChar!C)
{
	return isSymlink(name.str.to!string());
}

/// Part of workaround for DMD Issue #12111
@property bool isSymlink(C)(const(C)[] name)
{
	return std.file.isSymlink(name);
}

/// Just like std.file.chdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void chdir(C)(in PathT!C pathname) if(isSomeChar!C)
{
	chdir(pathname.str.to!string());
}

/// Just like std.file.chdir, but echoes if scriptlikeTraceCommands is true.
void chdir(in char[] pathname)
{
	echoCommand("chdir: "~pathname.escapeShellArg());
	std.file.chdir(pathname);
}

/// Just like std.file.mkdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void mkdir(C)(in PathT!C pathname) if(isSomeChar!C)
{
	mkdir(pathname.str.to!string());
}

/// Just like std.file.mkdir, but echoes if scriptlikeTraceCommands is true.
void mkdir(in char[] pathname)
{
	echoCommand("mkdir: "~pathname.escapeShellArg());
	std.file.mkdir(pathname);
}

/// If 'name' doesn't already exist, then mkdir. Otherwise do nothing.
/// Returns: Success?
bool tryMkdir(T)(T name)
{
	if(!name.exists())
	{
		mkdir(name);
		return true;
	}
	
	return false;
}

/// Just like std.file.mkdirRecurse, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void mkdirRecurse(C)(in PathT!C pathname) if(isSomeChar!C)
{
	mkdirRecurse(pathname.str.to!string());
}

/// Just like std.file.mkdirRecurse, but echoes if scriptlikeTraceCommands is true.
void mkdirRecurse(in char[] pathname)
{
	echoCommand("mkdirRecurse: "~pathname.escapeShellArg());
	std.file.mkdirRecurse(pathname);
}

/// If 'name' doesn't already exist, then mkdirRecurse. Otherwise do nothing.
/// Returns: Success?
bool tryMkdirRecurse(T)(T name)
{
	if(!name.exists())
	{
		mkdirRecurse(name);
		return true;
	}
	
	return false;
}

/// Just like std.file.rmdir, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void rmdir(C)(in PathT!C pathname) if(isSomeChar!C)
{
	rmdir(pathname.str.to!string());
}

/// Just like std.file.rmdir, but echoes if scriptlikeTraceCommands is true.
void rmdir(in char[] pathname)
{
	echoCommand("rmdir: "~pathname.escapeShellArg());
	std.file.rmdir(pathname);
}

/// If 'name' exists, then rmdir. Otherwise do nothing.
/// Returns: Success?
bool tryRmdir(T)(T name)
{
	if(name.exists())
	{
		rmdir(name);
		return true;
	}
	
	return false;
}

/// Posix-only. Just like std.file.symlink, but takes Path, and echoes if scriptlikeTraceCommands is true.
version(Posix) void symlink(C1, C2)(PathT!C1 original, PathT!C2 link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original.str.to!string(), link.str.to!string());
}

///ditto
version(Posix) void symlink(C1, C2)(const(C1)[] original, PathT!C2 link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original, link.str.to!string());
}

///ditto
version(Posix) void symlink(C1, C2)(PathT!C1 original, const(C2)[] link) if(isSomeChar!C1 && isSomeChar!C2)
{
	symlink(original.str.to!string(), link);
}

/// Just like std.file.symlink, but echoes if scriptlikeTraceCommands is true.
version(Posix) void symlink(C1, C2)(const(C1)[] original, const(C2)[] link)
{
	echoCommand("symlink: [original] "~original.escapeShellArg()~" : [symlink] "~link.escapeShellArg());
	std.file.symlink(original, link);
}

/// If 'original' exists, then symlink. Otherwise do nothing.
/// Returns: Success?
version(Posix) bool trySymlink(T1, T2)(T1 original, T2 link)
{
	if(original.exists())
	{
		symlink(original, link);
		return true;
	}
	
	return false;
}

/// Posix-only. Just like std.file.readLink, but operates on Path.
version(Posix) PathT!C readLink(C)(PathT!C link) if(isSomeChar!C)
{
	return PathT!C( readLink(link.str.to!string()) );
}

/// Part of workaround for DMD Issue #12111
version(Posix) string readLink(C)(const(C)[] link)
{
	return std.file.readLink(link);
}

/// Just like std.file.copy, but takes Path, and echoes if scriptlikeTraceCommands is true.
void copy(C)(in PathT!C from, in PathT!C to) if(isSomeChar!C)
{
	copy(from.str.to!string(), to.str.to!string());
}

///ditto
void copy(C)(in char[] from, in PathT!C to) if(isSomeChar!C)
{
	copy(from, to.str.to!string());
}

///ditto
void copy(C)(in PathT!C from, in char[] to) if(isSomeChar!C)
{
	copy(from.str.to!string(), to);
}

/// Just like std.file.copy, but echoes if scriptlikeTraceCommands is true.
void copy(in char[] from, in char[] to)
{
	echoCommand("copy: "~from.escapeShellArg()~" -> "~to.escapeShellArg());
	std.file.copy(from, to);
}

/// If 'from' exists, then copy. Otherwise do nothing.
/// Returns: Success?
bool tryCopy(T1, T2)(T1 from, T2 to)
{
	if(from.exists())
	{
		copy(from, to);
		return true;
	}
	
	return false;
}

/// Just like std.file.rmdirRecurse, but takes a Path, and echoes if scriptlikeTraceCommands is true.
void rmdirRecurse(C)(in PathT!C pathname) if(isSomeChar!C)
{
	rmdirRecurse(pathname.str.to!string());
}

/// Just like std.file.rmdirRecurse, but echoes if scriptlikeTraceCommands is true.
void rmdirRecurse(in char[] pathname)
{
	echoCommand("rmdirRecurse: "~pathname.escapeShellArg());
	std.file.rmdirRecurse(pathname);
}

/// If 'name' exists, then rmdirRecurse. Otherwise do nothing.
/// Returns: Success?
bool tryRmdirRecurse(T)(T name)
{
	if(name.exists())
	{
		rmdirRecurse(name);
		return true;
	}
	
	return false;
}

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(C)(PathT!C path, SpanMode mode, bool followSymlink = true) if(isSomeChar!C)
{
	return dirEntries(path.str.to!string(), mode, followSymlink);
}

/// Just like std.file.dirEntries, but takes a Path.
auto dirEntries(C)(PathT!C path, string pattern, SpanMode mode,
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
	auto slurp(C)(PathT!C filename, in char[] format) if(isSomeChar!C)
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

/++
Much like std.array.Appender!string, but specifically geared towards
building a command string out of arguments. String and Path can both
be appended. All elements added will automatically be escaped,
and separated by spaces, as necessary.

Example:
-------------------
Args args;
args ~= path(`some/big path/here/foobar`);
args ~= "-A";
args ~= "--bcd";
args ~= "Hello World";
args ~= path("file.ext");

// On windows:
assert(args.data == `"some\big path\here\foobar" -A --bcd "Hello World" file.ext`);
// On linux:
assert(args.data == `'some/big path/here/foobar' -A --bcd 'Hello World' file.ext`);
-------------------

wchar and dchar versions not yet supported, blocked by DMD issue #12112
+/
struct ArgsT(C = char) if( is(C==char) /+|| is(C==wchar) || is(C==dchar)+/ )
{
	// Internal note: For every element the user adds to ArgsT,
	// *two* elements will be added to this internal buf: first a spacer
	// (normally a space, or an empty string in the case of the very first
	// element the user adds) and then the actual element the user added.
	private Appender!(immutable(C)[]) buf;
	private size_t _length = 0;
	
    void reserve(size_t newCapacity) @safe pure nothrow
	{
		// "*2" to account for the spacers
		buf.reserve(newCapacity * 2);
	}


    @property size_t capacity() const @safe pure nothrow
	{
		// "/2" to account for the spacers
		return buf.capacity / 2;
	}

	@property immutable(C)[] data() inout @trusted pure nothrow
	{
		return buf.data;
	}
	
	@property size_t length()
	{
		return _length;
	}
	
	private void putSpacer()
	{
		buf.put(_length==0? "" : " ");
	}
	
	void put(immutable(C)[] item)
	{
		putSpacer();
		buf.put(escapeShellArg(item));
		_length += 2;
	}

	void put(PathT!C item)
	{
		put(item.toRawString());
	}

	void put(Range)(Range items)
		if(
			isInputRange!Range &&
			(is(ElementType!Range == string) || is(ElementType!Range == PathT!C))
		)
	{
		for(; !items.empty; items.popFront())
			put(items.front);
	}

	void opOpAssign(string op)(immutable(C)[] item) if(op == "~")
	{
		put(item);
	}

	void opOpAssign(string op)(PathT!C item) if(op == "~")
	{
		put(item);
	}

	void opOpAssign(string op, Range)(Range items)
		if(
			op == "~" &&
			isInputRange!Range &&
			(is(ElementType!Range == string) || is(ElementType!Range == PathT!C))
		)
	{
		put(items);
	}
}
alias Args = ArgsT!char; ///ditto

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
	auto tempPath  = Path(tempname);
	auto tempPath2 = Path(tempname2);
	auto tempPath3 = Path(tempname3);
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
				
		tempPath3.up.run(`echo MoreTestStuff > `~tempPath3.baseName().to!string());
		assert(tempPath3.exists());
		assert(tempPath3.isFile());
		assert((cast(string)tempPath3.read()).strip() == "MoreTestStuff");
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

version(unittest_scriptlike_d)
unittest
{
	import std.stdio : writeln;
	writeln("Running 'scriptlike.d' unittests: ArgsT");

	Args args;
	args ~= Path(`some/big path/here/foobar`);
	args ~= "-A";
	args ~= "--bcd";
	args ~= "Hello World";
	args ~= Path("file.ext");

	version(Windows)
		assert(args.data == `"some\big path\here\foobar" -A --bcd "Hello World" file.ext`);
	else version(Posix)
		assert(args.data == `'some/big path/here/foobar' -A --bcd 'Hello World' file.ext`);
}
