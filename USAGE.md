How to Use Scriptlike in Scripts
================================

These examples can be found in the "[examples](https://github.com/Abscissa/scriptlike/blob/master/examples)" directory.

* [In a DUB-based project](#in-a-dub-based-project)
* [In a standalone script](#in-a-standalone-script)
* [FAQ](#faq)

In a DUB-based project
----------------------
If your project uses [DUB](http://code.dlang.org/getting_started), just include the scriptlike as a dependency in your [dub.json](http://code.dlang.org/package-format?lang=json) or [dub.sdl](http://code.dlang.org/package-format?lang=sdl) file like this:

dub.json:
```json
"dependencies": {
	"scriptlike": "~>0.9.3"
}
```

dub.sdl:
```
dependency "scriptlike" version="~>0.9.3"
```

And then import with one of these:

```d
// Imports all of Scriptlike, plus anything from Phobos likely to
// be useful for scripts:
import scriptlike;

// Or import only Scriptlike and omit the automatic Phobos imports:
import scriptlike.only;
```

Run your project with dub like normal:

```bash
$ dub
```

In a standalone script
----------------------

Assuming you have [DMD](http://dlang.org/download.html#dmd) and [DUB](http://code.dlang.org/download) installed:

myscript.d:
```d
import scriptlike;

void main(string[] args) {
	string name;

	if(args.length > 1)
		name = args[1];
	else
		name = userInput!string("What's your name?");

	writeln("Hello, ", name, "!");
}
```

myscript:
```bash
#!/bin/sh
SCRIPT_DIR="$(dirname "$(readlink "$0")")"
rdmd -I~/.dub/packages/scriptlike-0.9.3/src/ -of$SCRIPT_DIR/.myscript $SCRIPT_DIR/myscript.d "$@"
```

myscript.bat:
```batch
@echo off
rdmd -I%APPDATA%/dub/packages/scriptlike-0.9.3/src/ -of%~dp0myscript.bin %~dp0myscript.d %*
```

On Linux/OSX:
```bash
$ chmod +x myscript
$ dub fetch scriptlike --version=0.9.3
$ ./myscript Frank
Hello, Frank!
```

On Windows:
```batch
> dub fetch scriptlike --version=0.9.3
> myscript Frank
Hello, Frank!
```

FAQ
---

### Why not just use a shebang line instead of the bash helper script?

**Short:** You can, but it won't work work on other people's machines.

**Long:** D does support Posix shebang lines, so you *could* omit the `myscript` file and add the following to the top of `myscript.d`:

```bash
#!/PATH/TO/rdmd --shebang -I~/.dub/packages/scriptlike-0.9.3/src/
```

Problem is, there's no way to make that portable across machines. The rdmd tool isn't always going to be in the same place for everyone. Some people may have it in `/bin`, some may have it in `/opt/dmd2/linux/bin64`, `/opt/dmd2/linux/bin32` or `/opt/dmd2/osx/bin`, some people install via [DVM](https://github.com/jacob-carlborg/dvm) (which I recommend) which puts it in `~/.dvm/compilers/dmd-VERSION/...`, and some people simply unzip the [DMD](http://dlang.org/download.html#dmd) archive and use it directly from there.

What about `/usr/bin/env`? Unfortunately, it can't be used here. It lacks an equivalent to RDMD's `--shebang` command, so it's impossible to use it in a shebang line and still pass the necessary args to RDMD.

Additionally, using the shebang method on Posix would mean that invoking the script would be different even more between Posix and Windows than simply slash-vs-backslash: `myscript.d` vs `myscript`.

### Why the -of?

**Short:** So rdmd doesn't break [```std.file.thisExePath```](http://dlang.org/phobos/std_file.html#thisExePath).

**Long:** Without ```-of```, rdmd will create the executable binary in a temporary directory. So if your program uses [```std.file.thisExePath```](http://dlang.org/phobos/std_file.html#thisExePath) to find the directory your program is in, it will only get the temporary directory, instead of the directory with your script.

Of course, if your program doesn't use [```std.file.thisExePath```](http://dlang.org/phobos/std_file.html#thisExePath), then it doesn't matter and you can omit the ```-of```.

Why even use [```std.file.thisExePath```](http://dlang.org/phobos/std_file.html#thisExePath) instead of ```args[0]```? Because ```args[0]``` is notoriously unreliable and for various reasons, will often not give you the *real* path to the *real* executable (this is true in any language, not just D).

### What's with the ```"$(dirname "$(readlink "$0")")"``` and ```%~dp0```?

**Short:** So you can run your script from any directory, not just its own.

**Long:** Those are the Posix/Windows shell methods to get the directory of the currently-running script. This way, if you run your script from a different working directory, rdmd will look for your D file is the correct place, rather than just assuming it's in whatever directory you happen to be in.
