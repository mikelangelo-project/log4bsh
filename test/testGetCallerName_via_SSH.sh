#!/bin/bash
#
# Test: getCallerName via SSH on localhost
#

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";

# script to execute
scriptToExec="$ABSOLUTE_PATH/testGetCallerName.sh";

# get caller name via SSH
callerName=$(ssh localhost "$scriptToExec false" 2>/dev/null);

# check result
if [ "$callerName" != "sshd:$(basename $scriptToExec)" ]; then
  echo "Test '$0' failed!";
  echo "expected: 'sshd:$(basename $scriptToExec)', returned: '$callerName'";
  exit 1;
else
  echo "Test '$0' passed.";
fi

exit 0;