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
