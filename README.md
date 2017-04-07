# log4bsh
A simple to use logging library for your bash scripts, written in bash.



## Table of Contents
* [Getting Started](#getting-started)
* [Prerequisites](#prerequisites)
* [Installation and Removal](#installation-and-removal)
* [Using a Configuration File](#using-a-configuration-file)
* [Using Environment Variables for Configuration](#using-environment-variables-for-configuration)
* [Dedicated Log Files](#dedicated-log-files)
* [Log Levels](#log-levels)
* [Configuration Options](#configuration-options)
* [Logging Functions](#logging-functions)
* [Function Hooks](#function-hooks)
* [Acknowledgement](#acknowledgement)



## Getting Started
To have the logging functions available in your bash-scripts, you either need to run the
`setup.sh` or to source file `log4bsh.sh` at the begin of your scripts e.g.

```bash
 #!/bin/bash
 source log4bsh/src/log4bash.sh; #not needed if setup.sh was run
 #..your code..
 logInfoMsg "Hello World!";
 #..more of your code..
 exit 0;
```



## Prerequisites
At least bash version 4.0 is required, because of associative arrays being used.  
Further, following commands need to be available:
 * `mkdir` (package [coreutils](https://www.gnu.org/software/coreutils/coreutils.html))
 * `tail` (package [coreutils](https://www.gnu.org/software/coreutils/coreutils.html))
 * `tee` (package [coreutils](https://www.gnu.org/software/coreutils/coreutils.html))
 * `ps` (package [procps](http://procps.sourceforge.net/))
 * `sed` (package sed [procps](http://sed.sourceforge.net/))



## Installation and Removal
To install log4bsh, run command
```
./setup.sh [--prefix=<dir>] [--userspace]
```
If you do not provide a prefix log4bsh is installed to `/usr/share/log4bsh/`
or to `$HOME/lib/log4bsh/` in case of an userspace installation.
Make use of `--userspace` if you want to install it for your user, only.
A system wide installation requires root permissions.

To remove log4bsh, use
```
./setup.sh --uninstall [--prefix=<dir>] [--userspace]
```



## Using a Configuration File
If there is no configuration file, the default values will be applied,
see [Configuration Options](#configuration-options).  
However, if you want to change a certain option or all of them, you can
provide a configuration file in the following ways:

For a system wide configuration, use file
* `/etc/log4bash.conf`
* If not found in `/etc`, it is searched for in `log4bsh.sh` installation dir.

For an user specific configuration, that overrides a system wide configuration,
use file
* `$HOME/log4bash.conf`
* If not found, it is search for file `$HOME/.log4bash.conf`

Note: You may consider already set environment variables, and apply them only in
in case they are not set. For example:
```bash
 #!/bin/bash
 if [ -z ${USE_COLORS-} ]; then
   # not set
   USE_COLORS=true;
 fi
```


## Using Environment Variables for Configuration
All configuration options can also be set inside scripts. This allows you, for
example, to enable flag `DEBUG` or `TRACE` for a code section and disable it
afterwards again.

```bash
 #!/bin/bash

 # ..some code..

 # now increase the log level to TRACE
 TRACE=true;

 # ..some more code where you want to print trace messages..

 # now disable trace output again
 TRACE=false;

 # ..more code..
 
 exit 0;
```

However, there is no need to touch your scripts. If you want to modify the log
level for a specific script, you can do so before executing your script from the
outside by the help of environment variables .
```bash
 # set overall logging level to WARN, but for myScript.sh set it to TRACE
 export LOG_LEVEL="ALL:WARN,myScript.sh:TRACE";
 ./myScript.sh
```

## Dedicated Log Files
You have the opportunity to define by the help of hook function
`log4bsh_getLogFileName` dedicated log files, dependent on the script that
logs messages.

```bash
 # write 'myScript.sh' messages to a separate log file, but all others to the
 # default log file '$LOG_FILE'
 log4bsh_getLogFileName() {
   if [ "${1-}" == "myScript.sh" ]; then
     echo "/tmp/myScript.log";
   else
     echo "$LOG_FILE";
   fi
 }
```


## Log Levels
There are 5 different log levels, in addition to `NONE`, each one serving a specific purpose.
Lowest level is `ERROR`, default level is `INFO` and most verbose log level is `TRACE`.

| Log Level      | Purpose        |
| :---              | :---          |
| TRACE | Most detailed log output, use it to print all details relevant, e.g. content of generated files. |
| DEBUG | More detailed output, use e.g. to indicate current step of processing. |
| INFO | Info messages, the default log level. Always logged except log level `NONE` is set. |
| WARN | Warning messages, use it to indicate something is not as expected. Always logged, except log level `NONE` is set. |
| ERROR | Error messages, use it to indicate sth went wrong. Always logged, except log level `NONE` is set. |
| NONE | Do not log any messages. |



## Configuration Options
There are several options available to control the behavior of the logging
functionality.
You either can set environment variables providing these settings
or use a configuration file as described in sections
[Using Environment Variables for Configuration](#using-environment-variables-for-configuration)
and [Using a Configuration File](#using-a-configuration-file).

| Config Parameter      | Description        | Default Value |
| :---              | :---          |:---          |
| `LOG4BSH_CONFIG_FILE` | Optional configuration file, overrides all others. | `undefined` |
| `LOG_FILE` | Log file for messages. | `~/.log4bsh.log` |
| `LOG_LEVEL` | Defines current level for log msgs, allows also to log specific scripts at a certain level | `undefined` (== `ALL:INFO`) |
| `LOG_ROTATE` | Flag indicating to use log rotate. | `TRUE` |
| `MAX_LOG_SIZE` | Maximum size for log files in bytes. | `5242880` (= 5MB) |
| `ABORT_ON_ERROR` | Flag indicating the default behavior for error messages |  `TRUE ` |
| `PRINT_TO_STDOUT` | Flag indicating to print messages to log and `STDOUT` | `FALSE` |
| `DATE_FORMAT` | Date format for log messages. | `+%Y-%m-%dT%H:%M:%S` |
| `USE_COLORS` | Use colors for log messages | `TRUE` |
| `COLORS` | Allows to override default colors for log levels. Associative array, with keys: TRACE,DEBUG,INFO,WARN,ERROR | `TRACE->lblue`, `DEBUG->blue`, `INFO->green`, `WARN->orange`, `ERROR->red` |
| `DEBUG` | Indicates to print msg at level 'DEBUG' or below. Ignored if LOG_LEVEL is set. | `FALSE` |
| `TRACE` | Indicates to print msg at level 'TRACE' or below. Ignored if LOG_LEVEL is set. | `FALSE` |



## Logging Functions
List of functions provided to you by `log4bsh.sh`.

* **`captureOutputStreams`**
  *  Description:
       Copies the output of `STDOUT` and `STDERR` and writes it to the
       log file. Very useful for scheduled execution or other
       situations where you do not have the `STDOUT` available on your
       screen while the script runs.
  *  Parameter:
     * `$1`: Optional flag, force capturing that happens per default in case
          `DEBUG` or `TRACE` is enabled, only.
  *  Returns:
     * `0`: in case of success, redirection is enabled
     * `1`: if not enabled, e.g. DEBUG not active

* **`stopOutputCapturing`**
  *  Description:
       Stops the redirection of `STDOUT` and `STDERR` streams.
  *  Parameter:
       none
  *  Returns:
     * `0`: in case of success
     * `1`: if streams where not captured (nothing to do)

* **`getCallerName`**
  *  Description:
       Internal function to get the name of script/parent process that called
       your script.
  *  Parameter:
       none
  *  Returns:
       nothing, however it echos the caller's name to STDOUT

* **`logCaller`**
  *  Description:
       Logs the name of the parent process that calls your script.
  *  Parameter:
     * `$1`: Optional string log level; default is `DEBUG`.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logCmdline`**
  *  Description:
       Logs parent script's cmd line, including arguments.
  *  Parameter:
     * `$1`: Optional string log level; default is `DEBUG`.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logTraceMsg`**
  *  Description:
       Logs a trace message, if `TRACE` is `true`.
  *  Parameter:
     * `$1`: The message to log.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logDebugMsg`**
  *  Description:
       Logs a debug message, if `DEBUG` is `true`.
  *  Parameter:
     * `$1`: The message to log.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logInfoMsg`**
  *  Description:
       Logs an info message.
  *  Parameter:
     * `$1`: The message to log.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logWarnMsg`**
  *  Description:
       Logs a warn message.
  *  Parameter:
     * `$1`: The message to log.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`logErrorMsg`**
  *  Description:
       Logs an error message and exits.
  *  Parameter:
     * `$1`: The message to log.
     * `$2`: Optional boolean indicating to print to `STDOUT`.
  *  Returns:
       nothing

* **`runTimeStats`**
  *  Description:
       Prints runtime statistics for your script.
  *  Parameter:
       none
  *  Returns:
       nothing

* **`showLog`**
  *  Description:
       Opens the log-file by the help of tail -f and keeps it open.
       This method will block execution until 'tail -f' is canceled/killed.
       Log file content will be printed to screen, starting by the latest line.
       Log will be kept open and all new log lines continue to appear on
       screen.
       In case the file doesn't exist, yet, or its parent directory does not
       exist, it will be created beforehand.
  *  Note:
       This method blocks until 'Ctrl+C' is pressed or 'tail -f' is killed!
  *  Parameter:
       none
  *  Returns:
       nothing



## Function Hooks
There are several function hooks available implemented as dummy functions
without any logic. These are intended to be overridden as needed.

* **`log4bsh_mapName`**
  *  Description:  Allows you to map file names to certain entity names.
                   For example, if you want to hide file extensions in the
                   output, or use short names for specific process names or
                   your (sub-)scripts in the logging output.
  *  Parameter:
     * `$1`: Name of a script or process.
  *  Returns: Nothing per default, however the (mapped/non-mapped) name is
              printed via echo to `STDOUT`.

* **`log4bsh_getLogFileName`**
  *  Description:  Allows you have dedicated log files for your scripts,
                   dependent on the actual script's name that logs messages.
  *  Parameter:
     * `$1`: Name of a script or process.
  *  Returns: Nothing per default, however the log file name is
              printed via echo to `STDOUT`.

* **`log4bsh_exitHook`**
  *  Description:  Allows you to execute some custom logic in case of an error
                    message before `exit` is called.
  *  Parameter:  none
  *  Returns:  Nothing per default.



## Acknowledgement
This Horizon2020 EU project has been conducted within the RIA
 [MIKELANGELO project](https://www.mikelangelo-project.eu/) (no. 645402).
Started in January 2015, and co-funded by the European Commission under
> H2020-ICT- 07-2014: Advanced Cloud Infrastructures and Services program.

There is more of MIKELANGELO on [Github](https://github.com/mikelangelo-project)
