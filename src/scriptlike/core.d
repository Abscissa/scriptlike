// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

/// Copyright: Copyright (C) 2014-2015 Nick Sabalausky
/// License:   zlib/libpng
/// Authors:   Nick Sabalausky

module scriptlike.core;

import std.conv;
import std.string;

/// If true, all commands will be echoed. By default, they will be
/// echoed to stdout, but you can override this with scriptlikeCustomEcho.
bool scriptlikeEcho = false;

/// Alias for backwards-compatibility. This will be deprecated in the future.
/// You should use scriptlikeEcho insetad.
alias scriptlikeTraceCommands = scriptlikeEcho;

/++
If true, then run, tryRun, file write, file append, and all the echoable
commands that modify the filesystem will be echoed to stdout (regardless
of scriptlikeEcho) and NOT actually executed.

Warning! This is NOT a "set it and forget it" switch. You must still take
care to write your script in a way that's dryrun-safe. Two things to remember:

1. ONLY Scriptlike's functions will obey this setting. Calling Phobos
functions directly will BYPASS this setting.

2. If part of your script relies on a command having ACTUALLY been run, then
that command will fail. You must avoid that situation or work around it.
For example:

---------------------
run(`date > tempfile`);

// The following will FAIL or behave INCORRECTLY in dryrun mode:
auto data = cast(string)read("tempfile");
run("echo "~data);
---------------------

That may be an unrealistic example, but it demonstrates the problem: Normally,
the code above should run fine (at least on posix). But in dryrun mode,
"date" will not actually be run. Therefore, tempfile will neither be created
nor overwritten. Result: Either an exception reading a non-existent file,
or outdated information will be displayed.

Scriptlike cannot anticipate or handle such situations. So it's up to you to
make sure your script is dryrun-safe.
+/
bool scriptlikeDryRun = false;

/++
By default, scriptlikeEcho and scriptlikeDryRun echo to stdout.
You can override this behavior by setting scriptlikeCustomEcho to your own
sink delegate. Set this to null to go back to Scriptlike's default
of "echo to stdout" again.

Note, setting this does not automatically enable echoing. You still need to
set either scriptlikeEcho or scriptlikeDryRun to true.
+/
void delegate(string) scriptlikeCustomEcho;

/++
Output text lazily through scriptlike's echo logger.
Does nothing if scriptlikeEcho and scriptlikeDryRun are both false.

The yapFunc version automatically prepends the output with the
name of the calling function. Ex:

----------------
void foo(int i = 42) {
	// Outputs:
	// foo: i = 42
	yapFunc("i = ", i);
}
----------------
+/
void yap(T...)(lazy T args)
{
	import std.stdio;
	
	if(scriptlikeEcho || scriptlikeDryRun)
	{
		if(scriptlikeCustomEcho)
			scriptlikeCustomEcho(text(args));
		else
			writeln(args);
	}
}

///ditto
void yapFunc(string funcName=__FUNCTION__, T...)(lazy T args)
{
	static assert(funcName != "");
	
	auto funcNameSimple = funcName.split(".")[$-1];
	yap(funcNameSimple, ": ", args);
}

/// Maintained for backwards-compatibility. Will be deprecated.
/// Use 'yap' instead.
void echoCommand(lazy string msg)
{
	yap(msg);
}
