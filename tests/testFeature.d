/// This program runs and tests one or all of the "features" examples
/// in this directory.

import scriptlike;

void function()[string] lookupTest; // Lookup test by name
string testName; // Name of test being run

void main(string[] args)
{
	// Init test lookup
	lookupTest = [
		"All":                       &testAll,
		"AutomaticPhobosImport":     &testAutomaticPhobosImport,
		"CommandEchoing":            &testCommandEchoing,
		"DisambiguatingWrite":       &testDisambiguatingWrite,
		"DryRunAssistance":          &testDryRunAssistance,
		"Fail":                      &testFail,
		"Filepaths":                 &testFilepaths,
		"ScriptStyleShellCommands":  &testScriptStyleShellCommands,
		"StringInterpolation":       &testStringInterpolation,
		"TryAsFilesystemOperations": &testTryAsFilesystemOperations,
		"UserInputPrompts":          &testUserInputPrompts,
	];

	// Check args
	getopt(args, "v", &scriptlikeEcho);

	failEnforce(
		args.length == 2,
		"Invalid args.\n",
		"\n",
		"Usage: testFeature [-v] NAME\n",
		"\n",
		"Options:\n",
		"-v  Verbose\n",
		"\n",
		"Examples:\n",
		"    testFeature All\n",
		"    testFeature UserInputPrompts\n",
		"\n",
		"Available Test Names:\n",
		"    ", lookupTest.keys.sort,
	);

	testName = args[1];
	failEnforce(
		(testName in lookupTest) != null,
		"No such test '", testName, "'.\n",
		"Available Test Names:\n",
		"    ", lookupTest.keys.sort,
	);

	// Run test
	chdir(thisExePath.dirName);
	tryMkdir("bin"); // gdmd doesn't automatically create the output directory.
	lookupTest[testName]();
}

void showTestName()
{
	writeln("Testing ", testName, ".d");
}

string rdmdCommand(string testName)
{
	version(Windows)
		return "rdmd --compiler="~environment["DMD"]~" --force -debug -g -I../src ../examples/features/"~testName~".d";
	else version(Posix)
		return environment["DMD"]~" -debug -g -I../src ../src/**/*.d ../src/scriptlike/**/*.d -ofbin/"~testName~" ../examples/features/"~testName~".d && bin/"~testName;
	else
		static assert(0);
}

string normalizeNewlines(string str)
{
	version(Windows)
		return str.replace("\r\n", "\n");
	else
		return str;
}

string fixSlashes(string path)
{
	version(Windows)
		return path.replace(`/`, `\`);
	else version(Posix)
		return path.replace(`\`, `/`);
	else
		static assert(0);
}

string quote(string str)
{
	version(Windows)
		return `"` ~ str ~ `"`;
	else version(Posix)
		return `'` ~ str ~ `'`;
	else
		static assert(0);
}

void testAll()
{
	bool failed = false; // Have any tests failed?
	
	foreach(name; lookupTest.keys.sort)
	if(lookupTest[name] != &testAll)
	{
		// Instead of running the test function directly, run it as a separate
		// process. This way, we can safely continue running all the tests
		// even if one throws an AssertError or other Error.
		auto verbose = scriptlikeEcho? "-v " : "";
		auto status = tryRun("." ~ dirSeparator ~ "testFeature " ~ verbose ~ name);
		if(status != 0)
			failed = true;
	}

	failEnforce(!failed, "Not all tests succeeded.");
}

void testAutomaticPhobosImport()
{
	showTestName();
	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == "Works!\n");
}

void testCommandEchoing()
{
	showTestName();

	immutable expected = 
"run: echo Hello > file.txt
mkdirRecurse: "~("some/new/dir".fixSlashes)~"
copy: file.txt -> "~("some/new/dir/target name.txt".fixSlashes.quote)~"
Gonna run foo() now...
foo: i = 42
";
	
	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == expected);
}

void testDisambiguatingWrite()
{
	showTestName();

	immutable expected =  "Hello worldHello world";

	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == expected);
}

void testDryRunAssistance()
{
	showTestName();

	immutable expected = 
"copy: original.d -> app.d
run: dmd app.d -ofbin/app
exists: another-file
";

	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == expected);
}

void testFail()
{
	showTestName();
	
	auto result = tryRunCollect( rdmdCommand(testName) );
	assert(result.status > 0);
	assert(result.output.normalizeNewlines == "Fail: ERROR: Need two args, not 0!\n");

	result = tryRunCollect( rdmdCommand(testName) ~ " abc 123" );
	assert(result.status > 0);
	assert(result.output.normalizeNewlines == "Fail: ERROR: First arg must be 'foobar', not 'abc'!\n");

	auto output = runCollect( rdmdCommand(testName) ~ " foobar 123" );
	assert(output == "");
}

void testFilepaths()
{
	showTestName();

	immutable expected = 
		("foo/bar/different subdir/Filename with spaces.txt".fixSlashes.quote) ~ "\n" ~
		("foo/bar/different subdir/Filename with spaces.txt".fixSlashes) ~ "\n";

	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == expected);
}

void testScriptStyleShellCommands()
{
	// This test relies on "dmd" being available on the PATH
	auto dmdResult = tryRunCollect("dmd --help");
	if(dmdResult.status != 0)
	{
		writeln(`Skipping `, testName, `.d: Couldn't find 'dmd' on the PATH.`);
		return;
	}

	showTestName();
	
	immutable inFile = "testinput.txt";
	scope(exit)
		tryRemove(inFile);

	import scriptlike.file.wrappers : write;
	write(inFile, "\n");

	version(OSX) enum key = "Return";
	else         enum key = "Enter";

	immutable expectedExcerpt =
		"Press "~key~" to continue...Error: unrecognized switch '--bad-flag'\n";

	auto output = runCollect( rdmdCommand(testName) ~ " < " ~ inFile ).normalizeNewlines;
	assert(output.canFind(expectedExcerpt));
}

void testStringInterpolation()
{
	showTestName();
	
	immutable expected = 
"The number 21 doubled is 42!
Empty braces output nothing.
Multiple params: John Doe.
";

	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == expected);
}

void testTryAsFilesystemOperations()
{
	showTestName();
	auto output = runCollect( rdmdCommand(testName) ).normalizeNewlines;
	assert(output == "");
}

void testUserInputPrompts()
{
	showTestName();
	
	immutable inFile = "testinput.txt";
	scope(exit)
		tryRemove(inFile);

	import scriptlike.file.wrappers : write;
	write(inFile,
"Nana
20
y
testFeature.d
2
7
\n\n"
	);

	version(OSX) enum key = "Return";
	else         enum key = "Enter";

	immutable expectedExcerpt =
"Please enter your name
> And your age
> Do you want to continue?
> Where you do want to place the output?
> What color would you like to use?
       1. Blue
       2. Green
No Input. Quit

> Enter a number from 1 to 10
> Press "~key~" to continue...Hit Enter again, dood!!";

	auto output = runCollect( rdmdCommand(testName) ~ " < " ~ inFile ).normalizeNewlines;
	assert(output.canFind(expectedExcerpt));
}
