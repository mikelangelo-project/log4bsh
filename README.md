log4bsh
=======
A simple to use logging library for your bash scripts, written in bash.
This project is part of the EU funded project MIKELANGELO



Requirements
------------
At least bash version 4.0 is required, because of associative arrays being used.
Further, following commands need to be available:
 * `sed`
 * `ps`
 * `tail`
 * `mkdir`



Getting Started
---------------
To have the logging functions available in your bash-scripts, you need to
source file `log4bsh.sh` at the begin of your scripts e.g.

```bash
#!/bin/bash
source log4bsh/src/log4bash.sh;
#..your code..
logInfoMsg "Hello World!";
#..more of your code..
exit 0;
```



Log Levels
----------
There are 5 different log levels, each one serving a specific purpose.

| Log Level      | Purpose        |
| :---              | :---          |
| TRACE | Most detailed log output, use it to print all details relevant, i.e. ssh verbose output. `TRACE` needs to be enabled. |
| DEBUG | More detailed output, use i.e. to indicate current step of processing. `DEBUG` needs to be enabled. |
| INFO | Info messages, the default message level. Always printed to log. |
| WARN | Warning messages, use it to indicate something is not as expected. Always printed to log.|
| ERROR | Error Message, use it in case you cannot continue with the execution. Always printed to log.|



Configuration Options
---------------------
There are several options available to control the behavior of the logging
functionality. You either can set environment variables providing these settings
or a configuration file.

| Config Parameter      | Description        | Default Value |
| :---              | :---          |:---          |
| `LOG4BSH_CONFIG_FILE`	| Optional configuration file, overrides all others. | `undefined` |
| `LOG_FILE`     | Log file for messages. | `~/.log4bsh.log` |
| `LOG_LEVEL`	| Defines current level for log msgs, allows also to log specific scripts at a certain level | `undefined` (== `ALL:INFO`) |
| `LOG_ROTATE` | Flag indicating to use log rotate. | `TRUE` |
| `MAX_LOG_SIZE` | Maximum size for log files in bytes. | `5242880` (= 5MB) |
| `ABORT_ON_ERROR ` | Flag indicating the default behaviour for error messages |  `TRUE ` |
| `PRINT_TO_STDOUT` | Flag indicating to print messages to log and `STDOUT` | `FALSE` |
| `DATE_FORMAT` | Date format for log messages. | `+%Y-%m-%dT%H:%M:%S` |
| `USE_COLORS` | Use colors for log messages | `TRUE` |
| `COLORS`	| Allows to override default colors for log levels. Associative array, with keys: TRACE,DEBUG,INFO,WARN,ERROR | `TRACE->lblue`, `DEBUG->blue`, `INFO->green`, `WARN->orange`, `ERROR->red` |
| `DEBUG` | Indicates to print msg at level 'DEBUG'. Ignored if LOG_LEVEL is set. | `FALSE` |
| `TRACE` | Indicates to print msg at level 'TRACE'. Ignored if LOG_LEVEL is set. | `FALSE` |



Using a Configuration File
--------------------------
If there is no configuration file, the default values listed in the table above
will be applied. However, if you want to change a certain option or all of them,
you can provide a configuration file the following ways:

For a system wide configuration, use file
* `/etc/log4bash.conf`
* If not found in `/etc`, it is searched for in `log4bsh.sh` installation dir.

For an user specific configuration, that overrides a system wide configuration,
use file
* `$HOME/log4bash.conf`
* If not found, it is search for file `$HOME/.log4bash.conf`

You may consider already set environment variables, and apply them only in
in case they are not set. For example:
```
#!/bin/bash
if [ -z ${USE_COLORS-} ]; then
  # not set
  USE_COLORS=true;
fi
```



Using Environment Variables for Configuration
---------------------------------------------
All configuration options can be applied via the environment, too.
This allows you, for example, to enable `DEBUG` or `TRACE` for certain code
section and disable it afterwards again. Or to log the output of specific
sub-scripts into their own log file by providing a dedicated LOG_FILE
setting for each one.

```bash
#!/bin/bash
#
# this file is called by another script that has linked the log4bsh.sh file.
# To write to a separate log file, define it separately in this script
# some options different from the parent script's configuration.
LOG_FILE="/tmp/myScript_XYZ.log";

# ..some code..

# now increase the log level to TRACE
TRACE=true;

# ..some more code where you want to print trace messages..

# now disable trace output again
TRACE=false;

# ..more code..

exit 0;
```

However there is no need to touch your scripts. If you want to modify the log
level for a specific script, you can do so from the outside.  
Example:
```bash
#!/bin/bash

# set overall logging level to WARN, but for myScript.sh set it to TRACE
export  LOG_LEVEL="ALL:WARN,myScript.sh:TRACE";
./myScriptThatUsesLog4bsh.sh
```


Logging Functions
-----------------
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



Function Hooks
--------------
There are function hooks provided, too. These functions are dummy functions
without any logic so far. They are intended to be overridden if needed.

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
                   dependent on the actual script's name.
  *  Parameter:
    * `$1`: Name of a script or process.
  *  Returns: Nothing per default, however the log file name is
              printed via echo to `STDOUT`.

* **`log4bsh_exitHook`**
  *  Description:  Allows you to execute some custom logic in case of an error
                    message before `exit` is called.
  *  Parameter:  none
  *  Returns:  Nothing per default.



Acknowledgement
---------------
This Horizon2020 EU project has been conducted within the RIA
 [MIKELANGELO project](https://www.mikelangelo-project.eu/) (no. 645402).
Started in January 2015, and co-funded by the European Commission under
> H2020-ICT- 07-2014: Advanced Cloud Infrastructures and Services program.

There is more of MIKELANGELO, checkout [Github](https://github.com/mikelangelo-project)
