# MC Decompiler

## Requirements

### Software

* Linux (Tested with Debian)
* Bash
* Jq
* Wget
* Curl
* Java (tested with OpenJDK 11)
* Git

### Hardware

* At least 2 GB of free ram, i guess. if you have less, you might have to change the `xargs` command. The `-P` sets the amount of threads.
* recommended: 4 core.
* 12 gb of free disk space, at the time of writing(2022-05-07). Each version requires about 80-90 mb. Modifying the program to add the versions to after decompiling would lower the disk requirements to about 500 mb.

### Time

* On my server it took about 2-3 hours. Be prepared to have it run for a long time in the background.

## How to run

run `./downloadAll.sh`

### Recommendations

You can stop/re-launch the program at any time, except the git phase. If you stop it at that step, please remove the `git` folder before re-starting.
