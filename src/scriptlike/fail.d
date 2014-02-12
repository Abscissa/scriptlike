// Scriptlike: Utility to aid in script-like programs.
// Written in the D programming language.

module scriptlike.fail;

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
