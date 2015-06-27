// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

/// Copyright: Copyright (C) 2014-2015 Nick Sabalausky
/// License:   zlib/libpng
/// Authors:   Nick Sabalausky

module scriptlike.process;

import std.array;
import std.conv;
import std.process;
import std.range;

import scriptlike.core;
import scriptlike.path;
import scriptlike.file;

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

/++
Runs a command, through the system's command shell interpreter,
in typical shell-script style: Synchronously, with the command's
stdout/in/err automatically forwarded through your
program's stdout/in/err.

Optionally takes a working directory to run the command from.

The command is echoed if scriptlikeEcho is true.

ErrorLevelException is thrown if the process returns a non-zero error level.
If you want to handle the error level yourself, use tryRun instead of run.

Example:
---------------------
Args cmd;
cmd ~= Path("some tool");
cmd ~= "-o";
cmd ~= Path(`dir/out file.txt`);
cmd ~= ["--abc", "--def", "-g"];
Path("some working dir").run(cmd.data);
---------------------
+/
void run(string command)
{
	auto errorLevel = tryRun(command);
	if(errorLevel != 0)
		throw new ErrorLevelException(errorLevel, command);
}

///ditto
void run(Path workingDirectory, string command)
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

The command is echoed if scriptlikeEcho is true.

Returns: The error level the process exited with. Or -1 upon failure to
start the process.

Example:
---------------------
Args cmd;
cmd ~= Path("some tool");
cmd ~= "-o";
cmd ~= Path(`dir/out file.txt`);
cmd ~= ["--abc", "--def", "-g"];
auto errLevel = Path("some working dir").run(cmd.data);
---------------------
+/
int tryRun(string command)
{
	yapFunc(command);

	if(scriptlikeDryRun)
		return 0;
	else
	{
		try
			return spawnShell(command).wait();
		catch(Exception e)
			return -1;
	}
}

///ditto
int tryRun(Path workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	return tryRun(command);
}

/// Backwards-compatibility alias. runShell may become deprecated in the
/// future, so you should use tryRun or run insetad.
alias runShell = tryRun;

/// Similar to run(), but (like std.process.executeShell) captures and returns
/// the output instead of displaying it.
string runCollect(string command)
{
	auto result = tryRunCollect(command);
	if(result.status != 0)
		throw new ErrorLevelException(result.status, command);

	return result.output;
}

///ditto
string runCollect(Path workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	return runCollect(command);
}

/// Similar to tryRun(), but (like std.process.executeShell) captures and returns the
/// output instead of displaying it.
/// 
/// Returns same tuple as std.process.executeShell:
/// std.typecons.Tuple!(int, "status", string, "output")
///
/// Returns: The "status" field will be -1 upon failure to
/// start the process.
auto tryRunCollect(string command)
{
	yapFunc(command);
	auto result = std.typecons.Tuple!(int, "status", string, "output")(0, null);

	if(scriptlikeDryRun)
		return result;
	else
	{
		try
			return executeShell(command);
		catch(Exception e)
		{
			result.status = -1;
			return result;
		}
	}
}

///ditto
auto tryRunCollect(Path workingDirectory, string command)
{
	auto saveDir = getcwd();
	workingDirectory.chdir();
	scope(exit) saveDir.chdir();
	
	return tryRunCollect(command);
}

/++
Much like std.array.Appender!string, but specifically geared towards
building a command string out of arguments. String and Path can both
be appended. All elements added will automatically be escaped,
and separated by spaces, as necessary.

Example:
-------------------
Args args;
args ~= Path(`some/big path/here/foobar`);
args ~= "-A";
args ~= "--bcd";
args ~= "Hello World";
args ~= Path("file.ext");

// On windows:
assert(args.data == `"some\big path\here\foobar" -A --bcd "Hello World" file.ext`);
// On linux:
assert(args.data == `'some/big path/here/foobar' -A --bcd 'Hello World' file.ext`);
-------------------
+/
struct Args
{
	// Internal note: For every element the user adds to ArgsT,
	// *two* elements will be added to this internal buf: first a spacer
	// (normally a space, or an empty string in the case of the very first
	// element the user adds) and then the actual element the user added.
	private Appender!(string) buf;
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

	@property string data() inout @trusted pure nothrow
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
	
	void put(string item)
	{
		putSpacer();
		buf.put(escapeShellArg(item));
		_length += 2;
	}

	void put(Path item)
	{
		put(item.toRawString());
	}

	void put(Range)(Range items)
		if(
			isInputRange!Range &&
			(is(ElementType!Range == string) || is(ElementType!Range == Path))
		)
	{
		for(; !items.empty; items.popFront())
			put(items.front);
	}

	void opOpAssign(string op)(string item) if(op == "~")
	{
		put(item);
	}

	void opOpAssign(string op)(Path item) if(op == "~")
	{
		put(item);
	}

	void opOpAssign(string op, Range)(Range items)
		if(
			op == "~" &&
			isInputRange!Range &&
			(is(ElementType!Range == string) || is(ElementType!Range == Path))
		)
	{
		put(items);
	}
}

version(unittest_scriptlike_d)
unittest
{
	import std.stdio : writeln;
	writeln("Running Scriptlike unittests: Args");

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
