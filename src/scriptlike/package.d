/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))
Utility to aid in script-like programs.

Written in the $(LINK2 http://dlang.org, D programming language) and licensed
under The $(LINK2 https://github.com/Abscissa/scriptlike/blob/master/LICENSE.txt, zlib/libpng) License.

The latest version of this API reference is always available at:$(BR)
$(LINK http://semitwist.com/scriptlike/ )

For the list of officially supported compiler versions, see the
$(LINK2 https://github.com/Abscissa/scriptlike/blob/master/.travis.yml, .travis.yml)
file included with your version of Scriptlike.

Import all (including anything from Phobos likely to be useful for scripts):
------------
import scriptlike;
------------

Import all of Scriptlike only, but no Phobos:
------------
import scriptlike.only;
------------

Homepage:
$(LINK https://github.com/abscissa/scriptlike)

Copyright:
Copyright (C) 2014-2015 Nick Sabalausky.
Portions Copyright (C) 2010 Jesse Phillips.

License: $(LINK2 https://github.com/Abscissa/scriptlike/blob/master/LICENSE.txt, zlib/libpng)
Authors: Nick Sabalausky, Jesse Phillips
+/

module scriptlike;

public import scriptlike.only;
public import scriptlike.std;

version(D_Ddoc) import changelog;
version(unittest_scriptlike_d) void main() {}

// Run tests for sample programs in 'examples'
version(unittest_scriptlike_d)
unittest
{
	version(Windows)
		// This Posix artifact gets in the way of calling .myscript.exe
		// Only an issue when Win/Posix machines are operating from the same directory.
		tryRemove("tests/.testFeature");

	writeln("Testing sample programs in 'examples':");
	run(text( Path("tests/testFeature"), " All" ));
}
