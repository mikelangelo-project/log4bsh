#!/bin/bash
#
# Test: getCallerName, script called by one parent
#

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";

# script to execute
scriptToExec="$ABSOLUTE_PATH/testGetCallerName_via_parentScript.sh";

# get caller name via SSH
callerName="$(ssh localhost \"$scriptToExec false\" 2>/dev/null)";

# check result ?
if [ $# -eq 0 ] || $1; then
  if [ "$callerName" != "sshd:testGetCallerName.sh" ]; then
    echo "Test '$0' failed!";
    echo "expected: 'sshd:testGetCallerName.sh', returned: '$callerName'";
    exit 1;
  else
    echo "Test '$0' passed.";
  fi
else
  echo $callerName;
fi
exit 0;
