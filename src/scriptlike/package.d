/++
Scriptlike: Utility to aid in script-like programs.

Written in the D programming language.
Tested with DMD 2.066.0 through 2.067.0.
Licensed under The zlib/libpng License.

Import all:
------------
import scriptlike;
------------

Homepage:
$(LINK https://github.com/abscissa/scriptlike)

This API Reference:
$(LINK http://semitwist.com/scriptlike)

Modules:
$(LINK2 std.html,scriptlike.std)$(BR)
$(LINK2 path.html,scriptlike.path)$(BR)
$(LINK2 fail.html,scriptlike.fail)$(BR)
$(LINK2 interact.html,scriptlike.interact)$(BR)

Copyright:
Copyright (C) 2014-2015 Nick Sabalausky.
Portions Copyright (C) 2010 Jesse Phillips.

License: zlib/libpng
Authors: Nick Sabalausky, Jesse Phillips
+/

module scriptlike;

public import scriptlike.only;
public import scriptlike.std;
