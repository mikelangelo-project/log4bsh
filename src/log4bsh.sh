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
#               It allows you to either go straight on and use the
#               configuration defaults or override some options as required.
#               Log msg format:
#                [host|date|processName|logLevel] logMsg
#
#      OPTIONS:
#               LOG4BSH_CONFIG_FILE
#                Optional configuration file
#               PRINT_TO_STDOUT
#                Indicates whether to print to STDOUT
#               DATE_FORMAT
#                Default is "+%H:%M:%S"
#               USE_COLORS
#                Indicates to use colors for msgs, default is 'true'
#               DEBUG
#                Indicates to print msg at debug level
#               TRACE
#                Indicates to print msg at trace level
#
# REQUIREMENTS: bash version 4.0 or later
#
#         BUGS: ---
#
#        NOTES: 1) Messages logged at level 'INFO','WARN','ERROR' will always
#                  be printed.
#               2) When a configuration file is found, it may override
#                  environment variables you have set in addition. Depends on
#                  your configuration file's logic, i.e. you can control to
#                  skip the initialization if an (environment) variable exists.
#               3) If bash option x is present, e.g. by calling 'set -x', the
#                  flag will be removed during the logging and restored after.
#                  Otherwise your debugging output would be largely expanded
#                  by the logging's internal calls.
#
#       AUTHOR: Nico Struckmann, struckmann@hlrs.de
#      COMPANY: HLRS, University of Stuttgart
#      VERSION: 0.1
#      CREATED: Sept 30th, 2016
#     REVISION: ..
#
#    CHANGELOG
#
#=============================================================================
set -o nounset;

# determine our base directory
LOG4BSH_ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";


#----------------------------------------------------------------------------#
#                                                                            #
#                                CONFIG                                      #
#           (can be overriden via config file or environment vars)           #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Check if there are any configuration files.
# They are loaded one by one to enable you having a global base configuration
# that can be overridden by a user defined one in his home. And for development
# and debugging purposes you can define a temporary file via the environment.
#
# order of configuration files being loaded:
#  1) at first check in the logger lib's dir
#  2) check if there is one in home, named '.log4bash.conf'
#  3) at last check the environment variable 'LOG4BSH_CONFIG_FILE'
#
if [ -f "/etc/log4bash.conf" ]; then
  # yes, source it
  source "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf";
elif [ -f "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf" ]; then
  # yes, source it
  source "$LOG4BSH_ABSOLUTE_PATH/log4bash.conf";
fi

# config present in home (that will override the global one) ?
if [ -f ~/.log4bash.conf ]; then
  # yes, source it
  source ~/.log4bash.conf;
fi

# is there a config file defined in the environment (overrides previous ones) ?
if [ -n "${LOG4BSH_CONFIG_FILE-}" ] \
    && [ -f "$LOG4BSH_CONFIG_FILE" ]; then
  # yes, source it
  source "$LOG4BSH_CONFIG_FILE";
fi

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


#----------------------------------------------------------------------------#
#                                                                            #
#                               CONSTANTS                                    #
#   (do not touch or override, except you exactly know what you're doing!)   #
#                                                                            #
#----------------------------------------------------------------------------#

#
# Constant for local host's name.
#
LOCALHOST="$(hostname -s)";

#
# Colors used for log messages.
#
RED='\033[0;31m';
ORANGE='\033[0;33m';
GREEN='\033[0;32m';
BLUE='\033[0;34m';
LBLUE='\033[1;34m';
NC='\033[0m'; # No Color

#
# Mapping of log levels to colors.
#
declare -A COLORS;
COLORS["TRACE"]=$LBLUE;
COLORS["DEBUG"]=$BLUE;
COLORS["INFO"]=$GREEN;
COLORS["WARN"]=$ORANGE;
COLORS["ERROR"]=$RED;


#----------------------------------------------------------------------------#
#                                                                            #
#                            INTERNAL VARIABLES                              #
#                             (do not touch!)                                #
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
#                (not intended to be used outside this script)               #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# Central internal logging function.
#
# Parameter
#  $1: logMsgType - DEBUG, TRACE, INFO, WARN, ERROR
#  $2: the log message
#
# Returns
#  nothing
#
_log() {

  # check amount of params
  if [ $# -ne 3 ]; then
    logErrorMsg "Function '_log' called with '$#' arguments, '3' are expected.\
\nProvided params are: '$@'" 2;
  fi

  logLevel=$1;
  color=${COLORS[$logLevel]};
  logMsg=$2;
  printToSTDout=$3;

  # get caller's name (script file name or parent process if remote)
  processName="$(getCallerName)";

  # for shorter log level names, we prepend the log message with a space to
  # have all messages starting at the same point, more convenient to read
  if [[ $logLevel =~ ^(WARN|INFO)$ ]]; then
    logMsg=" $logMsg";
  fi

  # construct log message
  if $USE_COLORS; then
    printMsg="$color[$LOCALHOST|$(date $DATE_FORMAT)|$processName|$logLevel]$NC $logMsg";
  else
    printMsg="[$LOCALHOST|$(date $DATE_FORMAT)|$processName|$logLevel] $logMsg";
  fi

  # log rotate enabled
  if $LOG_ROTATE \
        && [ -e $LOG_FILE ]; then
    # ensure log is not bigger than MAX_LOG_SIZE
    file_size=$(du -b $LOG_FILE | tr -s '\t' ' ' | cut -d' ' -f1);
    if [ $file_size -ge $MAX_LOG_SIZE ]; then
      mv $LOG_FILE $LOG_FILE.$(date +%Y-%m-%dT%H-%M-%S);
      touch $LOG_FILE;
    fi
  fi

  #
  # print the log msg
  #

  # ensure log file dir exists
  if [ ! -f $LOG_FILE ] \
      && [ ! -d $(dirname $LOG_FILE) ] \
      &&  ! (mkdir -p $(dirname $LOG_FILE) \
        && touch $LOG_FILE); then
    echo "ERROR: Cannot write log to '$LOG_FILE' !";
    # print to STDOUT at least if not disabled
    if $printToSTDout; then
        echo -e "$printMsg";
    fi
  elif $REDIRECTION_ENABLED; then
    # when redirection is enabled, we print to STDOUT only (otherwise msg appears twice in the log)
    echo -e "$printMsg";
  elif $printToSTDout; then
    # print log msg on screen and in file (only if redirection is not enabled
    echo -e "$printMsg" |& tee -a $LOG_FILE;
  else
    # print into log file, only
    echo -e "$printMsg" &>> $LOG_FILE;
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
  #return 0;
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
  #return 0;
  # was '-x' set ? if yes disable it
  [[ "$1" =~ x ]] && set -x;
}



#----------------------------------------------------------------------------#
#                                                                            #
#                           FUNCTIONS TO OVERRIDE                            #
#                                (as needed)                                 #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# This function is intended to be overridden on demand.
# Allows you to map file names to certain entity names.
# For example, if you want to hide file extensions in the output, or use short
# names for your (sub-)scripts in the logging output.
#
# Parameter
#  $1: a script or process name
#
# Returns
#  nothing, but echo (mapped) script name to STDOUT
#
log4bsh_mapName() {
  echo $1;
}


#---------------------------------------------------------
#
# This function is intended to be overridden on demand.
#
# Parameter
#  $1: a script or process name
#
# Returns
#  nothing, but echo (mapped) script name to STDOUT
#
log4bsh_exitHook(){
  echo "";
}



#----------------------------------------------------------------------------#
#                                                                            #
#                          API / PUBLIC FUNCTIONS                            #
#                                                                            #
#----------------------------------------------------------------------------#


#---------------------------------------------------------
#
# Function to enable capturing of all output to STDOUT/ERR,
# if $DEBUG or $TRACE is 'true'.
#
# Ensures that output from 'set -x' for example is written to the log, too.
# While a job does not complete (getting re-queued for ex) we have no log
# and without this redirect our logfile would not contain it either
#
# quote:
# "Also, standard input for both scripts is connected to a system dependent file.
# Currently, for all systems this is /dev/null.
# Except for epilogue scripts of an interactive job, prologue.parallel,
# epilogue.precancel, and epilogue.parallel, the standard output and error are
# connected to output and error files associated with the job
# For prologue.parallel and epilogue.parallel, the user will need to redirect
# stdout and stderr manually."
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
  elif ([ $# -gt 0 ] && $1) || $DEBUG; then
    # store pipes, std in 3 and err in 4
    exec 3>&1 4>&2;
    # write to log-file and stderr/stdout
    exec 2>> >(tee -a $LOG_FILE);
    exec 1>> >(tee -a $LOG_FILE);
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
    exec >&3 2>&4;
    REDIRECTION_ENABLED=false;
    return 0;
  fi
  return 1;
}


#---------------------------------------------------------
#
# Internal function to get the name of script/parent process that called your
# script.
#
# Parameter
#  none
#
# Returns
#  nothing, but echo the caller's name to STDOUT
#
getCallerName() {

  # try via parent PID
  process="$(ps --no-headers -o command $PPID | tr -s ' ' | cut -d' ' -f1 | sed 's,:,,g')";
  if [[ "$process" =~ sshd$ ]]; then
    viaSSH=true;
  else
    viaSSH=false;
  fi

  if [[ "$process" =~ [sshd|bash|notty]$ ]]; then
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
    fi
  fi

  process="$(basename $process)";
  process="$(log4bsh_mapName $process)";

  if $viaSSH; then
   process="sshd:$process";
  fi
  echo $process;
}


#---------------------------------------------------------
#
# Prints the name of the parent process that calls your
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

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
   if [ $# -eq 1 ]; then
    logLevel=$1;
  else
    logLevel="DEBUG";
  fi

  # optional argument provided ?
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

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
   if [ $# -eq 1 ]; then
    logLevel=$1;
  else
    logLevel="DEBUG";
  fi

  # optional argument provided ?
   if [ $# -eq 2 ]; then
    logToSTDOUT=$1;
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
# Prints the message in case the environment variable
# TRACE is 'true', only.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logTraceMsg() {

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  if [ $# -eq 2 ]; then
    logToSTDOUT=$2;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print in case, only if TRACE is 'true'
  if $TRACE; then
    _log "TRACE" "$1" $logToSTDOUT;
  fi

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs a debug message, if 'DEBUG' is 'true'.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logDebugMsg() {

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  if [ $# -eq 2 ]; then
    logToSTDOUT=$2;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print in both cases, only: DEBUG and/or TRACE is 'true'
  if $DEBUG || $TRACE; then
    _log "DEBUG" "$1" $logToSTDOUT;
  fi

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs an info message, regardless of DEBUG flag.
#
# Parameter
#  $1: The message to log.
#  $2: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logInfoMsg() {

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  if [ $# -eq 2 ]; then
    logToSTDOUT=$2;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print log msg
  _log "INFO" "$1" $logToSTDOUT;

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

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  if [ $# -eq 2 ]; then
    logToSTDOUT=$2;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print log message
  _log "WARN" "$1" $logToSTDOUT;

  # renable if it was enabled before
  _setXFlag $cachedBashOpts;
}


#---------------------------------------------------------
#
# Logs an error message and exits.
#
# Parameter
#  $1: The message to log.
#  $2: Optional error code, 0 means do not exit
#  $3: Optional boolean indicating to print to `STDOUT`.
#
# Returns
#  nothing
#
logErrorMsg() {

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # optional argument provided ?
  if [ $# -gt 2 ]; then
    exitCode=$2;
  else
    exitCode=1;
  fi

  # optional argument provided ?
  if [ $# -eq 3 ]; then
    logToSTDOUT=$3;
  else
    logToSTDOUT=$PRINT_TO_STDOUT;
  fi

  # print log msg
  _log "ERROR" "$1" $logToSTDOUT;

  if $ABORT_ON_ERROR || [ $exitCode -ne 0 ]; then

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
# Prints runtime statistics for your script.
#
# Parameter
#  none
#
# Returns
#  nothing
#
runTimeStats() {

  # in case '-x' is set, we unset it, and remember
  local cachedBashOpts="$-";
  _unsetXFlag $cachedBashOpts;

  # print log msg
  logDebugMsg "Runtime statistic for '$0':\n---------------------\n\
   shell (user | system)\nchildren (user | system)\n----------------";

  # print to stdout ?
  if $PRINT_TO_STDOUT; then
     # yes
     $DEBUG && times |& tee -a $LOG_FILE;
     $DEBUG && echo "" |& tee -a $LOG_FILE;
   else
     # no, print to file, only
     times &>> $LOG_FILE;
     echo "" >> $LOG_FILE;
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
# NOTE:
# This method blocks until 'Ctrl+C' is pressed or 'tail -f' is killed!
#
# Parameter
#  none
#
# Returns
#  nothing
#
showLog(){
  [ ! -f $LOG_FILE ] \
      && [ ! -d $(dirname $LOG_FILE) ] \
      && mkdir -p $(dirname $LOG_FILE) ];
  [ ! -f $LOG_FILE ] && touch $LOG_FILE;
  tail -n1 -f $LOG_FILE;
}

