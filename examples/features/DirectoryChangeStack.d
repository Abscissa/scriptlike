import scriptlike;

void main()
{
	// Setup and cleanup
	chdir(thisExePath.dirName);
	scope(exit)
	{
		scriptlikeEcho = false;
		tryRmdirRecurse("dir1");
	}
    tryMkdirRecurse("dir1/dir2");

    // Move into a subdirectory and do some work, 
    // then easily move back into the old directory!
    tryPushDir("dir1");
    /* tryRun... tryCopy.. etc.*/
    tryPopDir();

    // Since it's stack based, you can push and pop freely.
    tryPushDir("dir1"); // ./dir1
    tryPushDir("dir2"); // ./dir1/dir2
    popDirRecurse();    // ./
}
