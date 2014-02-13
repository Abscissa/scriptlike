Scriptlike - Changelog
======================

v0.6.0 - TBD
------------
- *Change:* ```Path``` and ```Ext``` are now aliases for the UTF-8 instantiations, and the template structs are now named ```PathT``` and ```ExtT```.
- *Change:* Internally split into separate modules, but uses package.d to preserve ```import scriptlike;```.
- *Enhancement:* Added scripts to run unittests and build API docs.
- *Enhancement:* Added opCast!bool for Path and Ext.
- *Enhancement:* fail() no longer requires any boilerplate in main(). [NG link](http://forum.dlang.org/thread/ldc6qt$22tv$1@digitalmars.com)
- *Enhancement:* Added this changelog.
- *Fixed:* Path(null) and Ext(null) were automatically changed to empty string.

v0.5.0 - 2014/2/11
------------------
- Initial release
