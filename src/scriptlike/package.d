/++
$(H2 Scriptlike $(SCRIPTLIKE_VERSION))
Utility to aid in script-like programs.

Written in the $(LINK2 http://dlang.org, D programming language) and licensed
under The $(LINK2 https://github.com/Abscissa/scriptlike/blob/master/LICENSE.txt, zlib/libpng) License.

The latest version of this API reference is always available at:$(BR)
$(LINK http://semitwist.com/scriptlike/ )

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
