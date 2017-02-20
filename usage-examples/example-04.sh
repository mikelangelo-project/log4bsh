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

# override log file
LOG_FILE="/tmp/test-04.log";

# override date format
DATE_FORMAT="+%H:%M:%S";

# override print2stdout
PRINT_TO_STDOUT=true;

# enable debug messages
DEBUG=false;

# enable trace messages
TRACE=false;

# log logging functions as last - must not override the values above
source "$(realpath -s $(dirname $0))/../src/log4bsh.sh";

#
# prints the log file's content on screen
#
printLog() {
  echo "===========LogFile_Content============";
  cat $LOG_FILE;
  echo "======================================";
}

#
# When an error msg is printed, exit is called, but
# before this happens stop the redirection and print
# the log on screen.
#
log4bsh_exitHook() {
  stopOutputCapturing;
  printLog;
  rm -f $LOG_FILE;
}



#----------------------------------------------------------------------------#
#                                                                            #
#                                   MAIN                                     #
#                                                                            #
#----------------------------------------------------------------------------#

# clean log file
rm -f $LOG_FILE;

# copy cmd output
captureOutputStreams true;

# trigger some output to std out and std err
dir=/tmp/$(date +%s);
mkdir $dir; #create a tmp dir
mkdir $dir; # second call will cause an error, printed to STDERR
echo "test msg via std out";
echo "another test msg via std out" >&1;
echo "test msg via sdt err" >&2;
rmdir $dir; #remove tmp dir

# log the whole cmd line the example script has been called with
logCmdLine "INFO";

# log the calling process' name
logCaller "TRACE";

# log a trace msg (without TRACE flag set)
logTraceMsg "This is a trace message";

# log a debug msg (without DEBUG flag set)
logDebugMsg "This is a debug message";

# log an info msg
logInfoMsg "This is an info message";

# log a warn msg
logWarnMsg "This is an warn message";

# log an error msg (will stop execution)
logErrorMsg "This is an error message";

# not reached, since the error msg logging will exit before
exit 0;