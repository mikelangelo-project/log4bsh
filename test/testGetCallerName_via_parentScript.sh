#!/bin/bash
#
# Test: getCallerName, script called by one parent
#

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";

# get caller name via SSH
callerName="$($ABSOLUTE_PATH/testGetCallerName.sh false)";

# check result ?
if [ $# -eq 0 ] || $1; then
  if [ "$callerName" != "$(basename $0)" ]; then
      echo "Test '$0' failed!";
      echo "Caller: $callerName";
  else
      echo "Test '$0' passed.";
  fi
else
    echo $callerName;
fi
exit 0;
