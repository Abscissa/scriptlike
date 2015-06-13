/++
Scriptlike: Utility to aid in script-like programs.

Written in the D programming language.

Import this "scriptlike.only" module instead of "scriptlike" if you want to
import all of Scriptlike, but NOT automatically import any of Phobos.

Copyright: Copyright (C) 2014-2015 Nick Sabalausky
License:   zlib/libpng
Authors:   Nick Sabalausky
+/


module scriptlike.only;

public import scriptlike.interact;
public import scriptlike.fail;
public import scriptlike.file;
public import scriptlike.path;
public import scriptlike.process;
