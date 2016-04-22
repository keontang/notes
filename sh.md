##### unusual notes  
- Magic **#!** line, the bare option **-** says that there are no more shell options; this is a security feature to prevent certain kinds of spoofing attacks.  
```sh
#! /bin/sh -  
```

- two dashes **--**  should be used to signify the end of options.  

- To force POSIX behavior, invoke bash with the **--posix** option or run **set -o posix** in the shell.  

－ A **here string** can be considered as a stripped-down form of a here document.  
It consists of nothing more than **COMMAND <<< ["]$WORD["]**,
where **$WORD** is expanded and fed to the **stdin of COMMAND**.

- The **trap** command allows you to execute a command when a signal is received by your script. It works like this:  
**trap "commands" signals**  

- `set`: Set or unset values of shell options and positional parameters. Change the value of shell attributes and positional parameters, or display the names and values of shell variables.  
set --: If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters are set to the arguments, even if some of them begin with a ‘-’.  

##### ShellProgramming  
[ShellProgramming](./ShellProgramming.HTM)  



