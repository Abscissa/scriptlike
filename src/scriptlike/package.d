/++
Scriptlike: Utility to aid in script-like programs.

Written in the D programming language.
Tested with DMD 2.066.0 through 2.067.0
Licensed under The zlib/libpng License

Homepage:
$(LINK https://github.com/abscissa/scriptlike)

This API Reference:
$(LINK http://semitwist.com/scriptlike)

Authors: Nick Sabalausky, Jesse Phillips

Import all:
------------
import scriptlike;
------------

Modules:
$(LINK2 std.html,scriptlike.std)$(BR)
$(LINK2 path.html,scriptlike.path)$(BR)
$(LINK2 fail.html,scriptlike.fail)$(BR)
$(LINK2 interact.html,scriptlike.interact)$(BR)
+/

module scriptlike;

public import scriptlike.std;
public import scriptlike.fail;
public import scriptlike.path;
public import scriptlike.interact;
