To run this example:

First, ensure you have DMD and DUB installed:
- DMD: http://dlang.org/download.html#dmd
- DUB: http://code.dlang.org/download

Then, make sure Scriptlike is installed through DUB:
dub fetch scriptlike --version=0.9.3

And then...

On Windows:
-----------
$ myscript
or
$ myscript Frank

On Linux/OSX:
-------------
Open "myscript.d", and on the first line change "/PATH/TO/rdmd" to the path
to your copy of rdmd. You can find the path by running "which rdmd".

Then:
$ ./myscript.d
or
$ ./myscript.d Frank
