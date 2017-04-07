#!/bin/bash
#
# Copyright 2016 HLRS, University of Stuttgart
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#=============================================================================
#
#         FILE: log4bsh.sh
#
#        USAGE: source log4bsh.sh
#
#  DESCRIPTION: Easy to use logging library for bash.
#               It allows to either go straight on and use the configuration
#               defaults or override some options as required.
#               Log msg format:
#                [host|date|processName|logLevel] logMsg
#
#  ENV VARIABLES:
#
#               LOG4BSH_CONFIG_FILE
#                Optional configuration file, overrides all other configs.
#                Default: empty
#
#               LOG_FILE
#                Standard log file to be used, if there is no dedicated one
#                for a specific script.
#                Default: ~/log4bsh.log
#
#               LOG_LEVEL
#                Defines current level for log msgs, allows to log also
#                specific scripts at a certain level.
#                dedicated level can be set.
#                Default: empty (== ALL at level 'INFO')
#
#               LOG_ROTATE
#                Whether to use log rotation to keep log size limimted.
#                Default: true
#
#               MAX_LOG_SIZE
#                Maximum log file size in KB. Ignored if LOG_ROTATE is 'false'.
#                Default: 5242880 (== 5MB)
#
#               PRINT_TO_STDOUT
#                Indicates whether to print to STDOUT in addition.
#                Default: false
#
#               ABORT_ON_ERROR
#                Indicates whether to exit in case of an error msg.
#                Default: false
#
#               DATE_FORMAT
#                Dateformat for logging msgs.
#                Default: "+%Y-%m-%dT%H:%M:%S"
#
#               USE_COLORS
#                Indicates to use colors for msgs.
#                Default: true
#
#               COLORS
#                Allows to override default colors for log levels.
#                Associative array, with keys: TRACE,DEBUG,INFO,WARN,ERROR
#                Defaults: TRACE->lblue, DEBUG->blue, INFO->green, WARN->orange, ERROR->red
#
#               DEBUG
#                Indicates to print msg at debug level.
#                Ignored if LOG_LEVEL is set.
#                Default: false
#
#               TRACE
#                Indicates to print msg at trace level
#                Ignored if LOG_LEVEL is set.
#                Default: false
#
#
#
# REQUIREMENTS: bash version 4.0 or later (associative arrays are used)
#
#         BUGS: ---
#
#        NOTES: 1) Messages logged at level 'INFO','WARN','ERROR' will always
#                  be printed, except 'LOG_LEVEL' is set.
#               2) When a configuration file is found, it may override
#                  environment variables that have been set by a file loaded
#                  previously. It actually depends on the configuration
#                  file's logic, i.e. it can skip options if already set.
#               3) If bash option 'x' is present, e.g. by calling 'set -x',
#                  the flag will be removed during the logging and restored
#                  after. Otherwise the debugging output would be largely
#                  expanded by log4bsh's internal calls.
#
#       AUTHOR: Nico Struckmann, struckmann@hlrs.de
#      COMPANY: HLRS, University of Stuttgart
#      VERSION: 0.2
#      CREATED: Sept 30th, 2016
#     REVISION: ...
#
#    CHANGELOG
#     2017-02-22  v0.2  N.Struckmann    some bug fixes, config enhanced
#
#=============================================================================

# determine our base directory
LOG4BSH_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";


#----------------------------------------------------------------------------#
#                                                                            #
#                              LOAD CONFIG FILE                              #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Check if there are any configuration files.
#
# Files found are loaded one by one to enable a global base configuration for
# all users on a system.
# The system-wide config can be overridden and customized by users.
#
# Order of configuration files being loaded and overriding the previous one's
# settings:
#
#  1) Read from log4bsh's dir, config file 'log4bsh.conf'.
#  2) Read file '/etc/log4bsh.conf'.
#  3) Read from users $HOME, file 'log4bash.conf',
#      if not found try hidden file '.log4bash.conf'.
#  4) As last check the environment variable 'LOG4BSH_CONFIG_FILE',
#      and load it if it points to a file.
#


#
#  1) Read from log4bsh's dir, config file 'log4bsh.conf'.
#
if [ -f "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf" ]; then
  source "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf";
fi

#
#  2) Read file '/etc/log4bsh.conf'.
#
if [ -f "/etc/log4bash.conf" ]; then
  source "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf";
fi

#
#  3) Read from users $HOME, file 'log4bash.conf',
#      if not found try hidden file '.log4bash.conf'.
#
if [ -f ~/log4bash.conf ]; then
  source ~/log4bash.conf;
elif [ -f ~/.log4bash.conf ]; then
  source ~/.log4bash.conf;
fi

#
#  4) As last check the environment variable 'LOG4BSH_CONFIG_FILE',
#      and load it if it points to a file.
#
if [ -n "${LOG4BSH_CONFIG_FILE-}" ] \
    && [ -f "$LOG4BSH_CONFIG_FILE" ]; then
  source "$LOG4BSH_CONFIG_FILE";
fi


#----------------------------------------------------------------------------#
#                                                                            #
#                               CONSTANTS                                    #
#                      (do not touch or override!)                           #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Constant for local host's name.
#
LOCALHOST="$(hostname -s)";

#
# Colors used for log messages.
#
LOG4BSH_RED='\033[0;31m';
LOG4BSH_ORANGE='\033[0;33m';
LOG4BSH_GREEN='\033[0;32m';
LOG4BSH_BLUE='\033[0;34m';
LOG4BSH_LBLUE='\033[1;34m';
LOG4BSH_NC='\033[0m'; # No Color


#----------------------------------------------------------------------------#
#                                                                            #
#                               DEFAULTS                                     #
#                                                                            #
#        (following values are applied, if there is no setting defined)      #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Log file defined ?
# Default location is user's home.
#
if [ -z ${LOG_FILE-} ]; then
  # no, set default
  LOG_FILE="~/.log4bsh.log";
fi

#
# Log rotate defined ?
# Default is 'true'.
#
if [ -z ${LOG_ROTATE-} ]; then
  # no, set default
  LOG_ROTATE=true;
fi

#
# Max log file size defined ?
# Default is 5MB.
#
if [ -z ${MAX_LOG_SIZE-} ]; then
  # no, set default
  MAX_LOG_SIZE=5242880; #5MB
fi

#
# Flag indicating whether to print to STDOUT in case it is not
# defined by the caller (argument missing)
#
if [ -z ${PRINT_TO_STDOUT-} ]; then
  # no, set default
  PRINT_TO_STDOUT=false;
fi

#
# Flag indicating the default behaviour for error messages.
#
if [ -z ${ABORT_ON_ERROR-} ]; then
  # no, set default
  ABORT_ON_ERROR=true;
fi

#
# Date format for log messages.
#
if [ -z ${DATE_FORMAT-} ]; then
  DATE_FORMAT="+%Y-%m-%dT%H:%M:%S";
fi

#
# Use colors for log messages ?
#
if [ -z ${USE_COLORS-} ]; then
  # no, set default
  USE_COLORS=true;
fi

#
# Flag indicating to print debug messages.
#
if [ -z ${DEBUG-} ]; then
  # no, set default
  DEBUG=false;
fi

#
# Flag indicating to print trace messages.
#
if [ -z ${TRACE-} ]; then
  # no, set default
  TRACE=false;
elif $TRACE; then
# if trace is enabled, DEBUG (= lower level) ensure DEBUG is, too
  DEBUG=true;
fi

#
# Mapping of log levels to colors.
#
if [ -z "${LOG4BSH_COLORS-}" ]; then
  declare -A LOG4BSH_COLORS;
fi
if [ -z "${LOG4BSH_COLORS['TRACE']-}" ]; then
  LOG4BSH_COLORS["TRACE"]=$LOG4BSH_LBLUE;
fi
if [ -z "${LOG4BSH_COLORS['DEBUG']-}" ]; then
  LOG4BSH_COLORS["DEBUG"]=$LOG4BSH_BLUE;
fi
if [ -z "${LOG4BSH_COLORS['INFO']-}" ]; then
  LOG4BSH_COLORS["INFO"]=$LOG4BSH_GREEN;
fi
if [ -z "${LOG4BSH_COLORS['WARN']-}" ]; then
  LOG4BSH_COLORS["WARN"]=$LOG4BSH_ORANGE;
fi
if [ -z "${LOG4BSH_COLORS['ERROR']-}" ]; then
  LOG4BSH_COLORS["ERROR"]=$LOG4BSH_RED;
fi


#----------------------------------------------------------------------------#
#                                                                            #
#                            INTERNAL VARIABLES                              #
#                        (do not touch or override!)                         #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Flag to indicate whether the redirection has been enabled. Used to keep the
# file free of duplicate messages.
#
REDIRECTION_ENABLED=false;


#----------------------------------------------------------------------------#
#                                                                            #
#                            INTERNAL FUNCTIONS                              #
#                         (do not use, may change)                           #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# Central internal logging function.
#
# Parameter
#  $1: message's log level, one of
#       'DEBUG','TRACE','INFO','WARN','ERROR'
#  $2: message to log
#  $3: optional, print to stdout,
#       if false, msg appears in log, only
#       if not set 'PRINT_TO_STDOUT' will be used instead
#
# Returns
#  nothing
#
_log() {

  # check amount of params
  if [ $# -lt 2 ]; then
    logErrorMsg "Function '_log' called with '$#' arguments, '2-3' are expected.\
\nProvided params are: '$@'" 2;
  fi

  local logLevel=$1;
  local logMsg=$2;
  local printToSTDOUT;

  # optional argument provided ?
  local printToSTDout;
  if [ $# -gt 2 ]; then
    printToSTDOUT=$3;
  else
    printToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # get caller's name (script file name or parent process if remote)
  local processName="$(getCallerName)";

  #
  # determine if msg should be logged at current level
  #
  local logTheMsg=false;
  if [ -z "${LOG_LEVEL-}" ]; then
    # no filter defined check TRACE/DEBUG
    if $TRACE \
        || ($DEBUG && [ "$logLevel" != "TRACE" ]) \
        || [[ "$logLevel" =~ ^(INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    fi
  elif [[ "$LOG_LEVEL" =~ $processName:?.*,? ]]; then
    # check if log level is below threshold
    if [[ "$LOG_LEVEL" =~ "$processName:NONE" ]]; then
      logTheMsg=false;
    elif [[ "$LOG_LEVEL" =~ "$processName:$logLevel" ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ "$processName:TRACE" ]] \
        && [[ $logLevel =~ ^(TRACE|DEBUG|INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ "$processName:DEBUG" ]] \
        && [[ $logLevel =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ "$processName:INFO" ]] \
        && [[ $logLevel =~ ^(INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ "$processName:WARN" ]] \
        && [[ $logLevel =~ ^(WARN|ERROR)$ ]]; then
      logTheMsg=true;
    fi
  elif [[ "$LOG_LEVEL" =~ (ALL:)ALL,?.*$ ]] \
      || [[ "$LOG_LEVEL" =~ (ALL:)?$logLevel ]]; then
    logTheMsg=true;
  elif [[ "$LOG_LEVEL" =~ ALL:NONE,?.*$ ]]; then
    logTheMsg=false;
  else
     # no direct match of log level, check if log level is below threshold
    if [[ "$LOG_LEVEL" =~ (ALL:)?TRACE ]] \
        && [[ $logLevel =~ ^(TRACE|DEBUG|INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ (ALL:)?:DEBUG ]] \
        && [[ $logLevel =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ (ALL:)?:INFO ]] \
        && [[ $logLevel =~ ^(INFO|WARN|ERROR)$ ]]; then
      logTheMsg=true;
    elif [[ "$LOG_LEVEL" =~ (ALL:)?:WARN ]] \
        && [[ $logLevel =~ ^(WARN|ERROR)$ ]]; then
      logTheMsg=true;
    fi
  fi

  # abort here ?
  $logTheMsg \
    || return 0;

  # for shorter log level names, prepend the log message with a space to
  # have all messages starting at the same point, more convenient to read
  # if there is anything set to debug or trace (skip if "level INFO, only")
  if [[ $logLevel =~ ^(WARN|INFO)$ ]] \
       && ([[ "${LOG_LEVEL-}" =~ (TRACE|DEBUG) ]] \
        || ([ -z ${LOG_LEVEL-} ] \
             && $DEBUG)); then
    logMsg=" $logMsg";
  fi

  # construct log message
  local printMsg;
  if $USE_COLORS; then
    printMsg="${LOG4BSH_COLORS[$logLevel]}[$LOCALHOST|$(date $DATE_FORMAT)|$processName|$logLevel]$LOG4BSH_NC $logMsg";
  else
    printMsg="[$LOCALHOST|$(date $DATE_FORMAT)|$processName|$logLevel] $logMsg";
  fi

  #
  # get log file name
  #
  local logFile="$(log4bsh_getLogFileName $processName)";

  #
  # log rotate, if enabled
  #
  if $LOG_ROTATE \
        && [ -e "$logFile" ]; then
    # ensure log is not bigger than MAX_LOG_SIZE
    file_size=$(du -b "$logFile" | tr -s '\t' ' ' | cut -d' ' -f1);
    if [ $file_size -ge $MAX_LOG_SIZE ]; then
      mv "$logFile" "$logFile.$(date +%Y-%m-%dT%H-%M-%S)";
      touch "$logFile";
    fi
  fi

  #
  # print the log msg
  #

  # ensure log file dir exists
  if [ ! -f "$logFile" ] \
        && ([ ! -d $(dirname "$logFile") ] \
            && [ ! $(mkdir -p $(dirname "$logFile")) ] \
        || ! $(touch "$logFile")); then
    echo "ERROR: Cannot write log to '$logFile' !";
    # print to STDOUT at least if not disabled
    if $printToSTDOUT; then
        echo -e "$printMsg";
    fi
  elif $REDIRECTION_ENABLED; then
    # when redirection is enabled, print to STDOUT only (otherwise msg appears twice in the log)
    echo -e "$printMsg";
  elif $printToSTDOUT; then
    # print log msg on screen and in file (only if redirection is not enabled
    echo -e "$printMsg" |& tee -a "$logFile";
  else
    # print into log file, only
    echo -e "$printMsg" &>> "$logFile";
  fi
}


#---------------------------------------------------------
#
# Helper function that disable's 'x' in order to not too spam the logs too much
#
# Parameter
#  none
#
# Returns
#  nothing
#
_unsetXFlag() {
  # is '-x' set ? if yes disable it
  [[ "$1" =~ x ]] && set +x;
}


#---------------------------------------------------------
#
# Helper function that re-enable's 'x' if it was active before
#
# Parameter
#  none
#
# Returns
#  nothing
#
_setXFlag() {
  # was '-x' set ? if yes disable it
  [[ "$1" =~ x ]] && set -x;
}


#----------------------------------------------------------------------------#
#                                                                            #
#                         OPTIONAL FUNCTION HOOKS                            #
#                   (override in cutom config on demand)                     #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# Override to map of file names to custom entity names,
# to remove file suffixes or use short names instead, and
# similar tasks.
#
# Parameter
#  $1: Script or process name that called one of the logging functions
#
# Returns
#  nothing, but echos (mapped) script name to STDOUT
#
log4bsh_mapName() {
  echo $1;
}


#---------------------------------------------------------
#
# Override to have multiple logfiles, dependent on the
# actual script's or process' name.
#
# Parameter
#  $1: Script or process name that called one of the logging functions
#
# Returns
#  nothing, but echos (mapped) script name to STDOUT
#
log4bsh_getLogFileName() {
  echo $LOG_FILE;
}


#---------------------------------------------------------
#
# Override to run custom logic in case of exit, caused by
# calling function 'logErrorMsg'.
#
# Parameter
#  none
#
# Returns
#  nothing
#
log4bsh_exitHook(){
  echo "";
}


#----------------------------------------------------------------------------#
#                                                                            #
#                              API FUNCTIONS                                 #
#                                                                            #
#----------------------------------------------------------------------------#

#---------------------------------------------------------
#
# Enables capturing of STDOUT and STDERR streams, if
# 'DEBUG' or 'TRACE' is set to 'true'.
# I.e. useful for 'set -x' output in scripts running in the
# background.
#
# Parameter
#  $1: Optional, flag to indicate to force the redirection, even if DEBUG is
#      set to false.
#
# Returns
#  0: in case redirection is enabled
#  1: if not enabled, e.g. DEBUG not active
#
captureOutputStreams() {

  if $REDIRECTION_ENABLED; then
    return 0;
  fi

  # get log file name
  local logFile="$(log4bsh_getLogFileName)";

  # filedescriptors for STDOUT and STDERR both exist ?
  if [ ! -e /proc/$$/fd/1 ] \
      || [ ! -e /proc/$$/fd/2 ]; then #no
    local msg="Cannot capture outputstreams, no filedescriptors '1' and '2' available for process '$$'.";
    # write to log file if possible
    if [ -f "$logFile" ] \
        || $(touch "$logFile"); then
      echo "$msg" >> "$logFile";
    else # write to syslog instead
      logger "$msg";
      return 1;
    fi
  fi

  if $DEBUG \
      || ([ $# -gt 0 ] && $1); then
    # store pipes, std in 3 and err in 4
    exec 3>&1 4>&2;
    # write to log-file and stderr/stdout
    exec 2>> >(tee -a "$logFile");
    exec 1>> >(tee -a "$logFile");
    # remember it
    REDIRECTION_ENABLED=true;
    # indicate success
    return 0;
  fi

  # indicate failure
  return 1;
}


#---------------------------------------------------------
#
# Stops the redirection of STDOUT and STDERR streams.
#
# Parameter
#  none
#
# Returns
#  0: in case of success
#  1: if redirection was not active
#
stopOutputCapturing() {
  if $REDIRECTION_ENABLED; then
    # restore pipes
    exec 1>&3 2>&4;
    REDIRECTION_ENABLED=false;
    return 0;
  fi
  return 1;
}


#---------------------------------------------------------
#
# Internal function to get the name of script/parent
# process that called a script.
#
# Parameter
#  none
#
# Returns
#  nothing, but echo the caller's name to STDOUT
#
getCallerName() {

  # running via SSH ?
  local process="$(ps --no-headers -o command $PPID | tr -s ' ' | cut -d' ' -f1 | sed 's,:,,g')";
  local viaSSH=false;

  # running via SSH ?
  if [[ "$process" =~ sshd$ ]]; then
    viaSSH=true;
  fi

  # try resolval via PID
  process="$(ps --no-headers -o command $$ | tr -s ' ' | cut -d' ' -f2 | sed 's,:,,g')";
  if [ ! -n "$process" ]; then
    # try via parent PID
    process="$(ps --no-headers -o command $PPID | tr -s ' ' | cut -d' ' -f1 | sed 's,:,,g')";
  fi

  # remove leading '-' if exists
  if [[ "$process" =~ ^-.+ ]]; then
    process="${process:1}";
  fi

  if [[ "$process" =~ (sshd|bash|notty)$ ]]; then
    # via parent PID
    process="$(ps --no-headers -o command $PPID | tr -s ' ' | cut -d' ' -f2)";
    # try via own PID
    if [[ "$process" =~ bash$ ]]; then
      process="$(ps --no-headers -o command $$ | tr -s ' ' | cut -d' ' -f1)";
      if [[ "$process" =~ bash$ ]]; then
        process="$(ps --no-headers -o command $$ | tr -s ' ' | cut -d' ' -f2)";
      fi
    elif [[ "$process" =~ notty$ ]]; then
        process="$(ps --no-headers -o command $$ | tr -s ' ' | cut -d' ' -f2)";
    elif [[ "$process" =~ @(pts|tty) ]]; then
      # running in shell, not inside a script
      process="bash";
    fi
  fi

  # check if process is not empty before issuing calls on it
  if [ -n "$process" ]; then
    process="$(basename $process)";
    process="$(log4bsh_mapName $process)";
  fi

  if $viaSSH; then
   process="sshd:$process";
  fi
  echo $process;
}


#---------------------------------------------------------
#
# Prints the name of the parent process that calls a
# script.
#
# Parameter
#  $1: optional, string log level; default is DEBUG
#  $2: optional, boolean indicating to print to STDOUT
#
# Returns
#  nothing
#
logCaller() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional loglevel argument provided ?
  local logLevel;
  if [ $# -eq 1 ]; then
    logLevel=$1;
  else
    logLevel="DEBUG";
  fi

  # optional argument provided ?
  local logToSTDOUT;
  if [ $# -eq 2 ]; then
    logToSTDOUT=$1;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # write log message
  _log $logLevel "Called by: '$(ps --no-headers -o command $$ | tr -s ' ' | cut -d' ' -f1)'" $logToSTDOUT;

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs parent script's cmd line, including arguments.
#
# Parameter
#  $1: optional, string log level; default is DEBUG
#  $2: optional, boolean indicating to print to STDOUT
#
# Returns
#  nothing
#
logCmdLine() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  local logLevel;
  if [ $# -gt 0 ]; then
    logLevel=$1;
  else
    logLevel="DEBUG";
  fi

  # optional argument provided ?
  local logToSTDOUT;
  if [ $# -gt 1 ]; then
    logToSTDOUT=$2;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # fetch parent's full cmd line
  cmdLine="$(ps --no-headers -o command $$)";
  _log $logLevel "Cmd line: '$cmdLine'" $logToSTDOUT;

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs a trace message.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logTraceMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # log msg
  _log "TRACE" "${1-}" ${2-};

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs a debug message.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logDebugMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # log msg
  _log "DEBUG" "${1-}" ${2-};

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs an info message.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logInfoMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # print log msg
  _log "INFO" "${1-}" ${2-};

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs a warn message.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logWarnMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # print log message
  _log "WARN" "${1-}" ${2-};

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs an error message and exits, expect ABORT_ON_ERROR
# is set to false and provided error code arg is not '0'.
#
# Parameter
#  $1: The message to log.
#  $2: Optional error code, 0 means do not exit regardless of `ABORT_ON_ERROR`
#  $3: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logErrorMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  local exitCode;
  if [ $# -gt 1 ]; then
    exitCode=$2;
  else
    exitCode=1;
  fi

  # optional argument provided ?
  local printToSTDOUT;
  if [ $# -gt 2 ]; then
    printToSTDOUT=$3;
  else
    printToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print log msg
  _log "ERROR" "${1-}" $printToSTDOUT;

  if $ABORT_ON_ERROR \
      || [ $exitCode -ne 0 ]; then

    # call the pre-exit hook
    log4bsh_exitHook;

    #
    # call exit hook and
    # abort with exit code
    #
    exit $exitCode;
  fi
}

#---------------------------------------------------------
#
# Logs a trace message.
#
# Parameter
#  $1: Log level, one of: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR'
#  $2: The message to log.
#  $3: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logMsg() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # log msg at log level provided
  _log "${1-}" "${2-}" ${3-};

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Prints simple runtime statistics for a script by the
# help of cmd 'times', as debug msg per default.
#
# Parameter
#  $1: log level, causes to print stats regardless of 'DEBUG'
#
# Returns
#  nothing
#
runTimeStats() {

  # in case '-x' is set, unset it and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # log level given ?
  local level;
  local ignoreDebugFlag;
  if [ $# -gt 0 ] \
      && [[ $1 =~ ^(TRACE|DEBUG|INFO|WARN|ERROR)$ ]]; then
    level=$1;
    ignoreDebugFlag=true;
  else
    level="DEBUG";
    ignoreDebugFlag=false;
  fi

  # print log msg
  logMsg $level "Runtime statistic for '$0':\n---------------------\n\
   shell (user | system)\nchildren (user | system)\n----------------";

  # get log file name
  local logFile="$(log4bsh_getLogFileName)";

  # print runtime stats ?
  if $ignoreDebugFlag \
      || $DEBUG; then

    # print to stdout ?
    if $PRINT_TO_STDOUT \
         && [ -e /proc/$$/fd/1 ] \
         && [ -e /proc/$$/fd/2 ]; then
       # yes
       times |& tee -a "$LOG_FILE";
       echo "" |& tee -a "$LOG_FILE";
     elif [ -f "$LOG_FILE" ]; then
       # no, print to file, only
       times &>> "$LOG_FILE";
       # add a line break
       echo "" >> "$LOG_FILE";
     fi
  fi

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Opens the log-file by the help of tail -f and keeps it
# open. This method will block execution until 'tail -f' is canceled/killed.
# Log file content will be printed to screen, starting by
# the latest line. Log will be kept open and all new log lines continue to
# appear on screen.
# In case the file doesn't exist, yet, or its parent directory does not exist,
# it will be created beforehand.
#
# Useful i.e. in case where a script spawns to remote nodes and log is written
# to a commonly shared file.
#
# NOTE:
# This method blocks until 'Ctrl+c' is pressed or 'tail -f' is killed.
#
# Parameter
#  $1: boolean indicating to print the hint for 'Ctrl+c'
#
# Returns
#  nothing
#
showLog(){
  # ensure log file's dir exits
  [ ! -f $LOG_FILE ] \
      && [ ! -d $(dirname "$LOG_FILE") ] \
      && mkdir -p $(dirname "$LOG_FILE") ];
  # ensure log file exists
  [ ! -f "$LOG_FILE" ] \
    && touch "$LOG_FILE";
  # print hint ?
  local printHint=true;
  if [ $# -gt 0 ]; then
    printHint=$1;
  fi
  # show log on screen
  if $printHint; then
    echo "Opening logfile '$LOG_FILE'.\nPress 'Ctrl+c' to abort.";
  fi
  tail -n1 -f $LOG_FILE;
}
