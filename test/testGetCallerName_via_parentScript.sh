#!/bin/bash
#
# Test: getCallerName, script called by one parent
#

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";

# script to execute
scriptToExec="$ABSOLUTE_PATH/testGetCallerName.sh";

# get caller name via SSH
callerName="$($scriptToExec false)";

# check result ?
if [ $# -eq 0 ] || $1; then
  if [ "$callerName" != "$(basename $scriptToExec)" ]; then
    echo "Test '$0' failed!";
    echo "expected: '$(basename $scriptToExec)', returned: '$callerName'";
    exit 1;
  else
    echo "Test '$0' passed.";
  fi
else
  echo $callerName;
fi
exit 0;
