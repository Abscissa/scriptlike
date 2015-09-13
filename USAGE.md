How to Use Scriptlike in Scripts
================================

These examples can be found in the "[examples](https://github.com/Abscissa/scriptlike/blob/master/examples)" directory.

* [In a DUB-based project](#in-a-dub-based-project)
* [In a standalone script](#in-a-standalone-script)

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

In a standalone script
----------------------

Assuming you have [DMD](http://dlang.org/download.html#dmd) and [DUB](http://code.dlang.org/download) installed:

myscript.d:
```d
#!/PATH/TO/rdmd --shebang -I~/.dub/packages/scriptlike-0.9.3/src/
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

myscript.bat:
```batch
@echo off
rdmd -I%APPDATA%/dub/packages/scriptlike-0.9.3/src/ myscript.d %*
```

On Linux/OSX:
```bash
$ chmod +x myscript.d
$ dub fetch scriptlike --version=0.9.3
$ ./myscript.d Frank
Hello, Frank!
```

On Windows:
```batch
> dub fetch scriptlike --version=0.9.3
> myscript Frank
Hello, Frank!
```
