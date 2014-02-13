// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

module scriptlike.fail;

import std.file;
import std.path;
import std.traits;

/// This is the exception thrown by fail(). There's no need to create or throw
/// this directly, but it's public in case you have reason to catch it.
class Fail : Exception
{
	private this()
	{
		super(null);
	}

	private static Fail opCall(string msg, string file=__FILE__, int line=__LINE__)
	{
		auto f = cast(Fail) cast(void*) Fail.classinfo.init;
		
		f.msg  = msg;
		f.file = file;
		f.line = line;
		
		throw f;
	}
	
	// Throwable.toString(sink) isn't an override on DMD 2.064.2, and druntime
	// won't even call this on DMD 2.064.2 anyway, so don't even bother
	// including this function if Throwable doesn't have toString(sink).
	static if( MemberFunctionsTuple!(Throwable, "toString").length > 1 )
	{
		override void toString(scope void delegate(in char[]) sink) const
		{
			auto appName = thisExePath().baseName();

			version(Windows)
				appName = appName.stripExtension();

			sink(appName~": ERROR: "~msg);
		}
	}
}

/++
Call this to end your program with an error message for the user, and no
ugly stack trace. The error message is sent to stderr and the errorlevel is
set to non-zero.

This is exception-safe, all cleanup code gets run.

Your program's name is automatically detected from std.file.thisExePath.

Example:
----------------
fail("You forgot to provide a destination!");

// Output on DMD 2.065 and up:
// yourProgramName: ERROR: You forgot to provide a destination!

// Output on DMD 2.064.2:
// scriptlike.fail.Fail@yourFilename.d(71): You forgot to provide a destination!
----------------
+/
void fail(string msg, string file=__FILE__, int line=__LINE__)
{
	throw Fail(msg, file, line);
}
