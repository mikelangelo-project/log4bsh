#!/bin/bash
#
# Test: getCallerName
#

# log logging functions as last - must not override the values above
source "$(realpath -s $(dirname $0))/../src/log4bsh.sh";

# call function to test
callerName=$(getCallerName);

# check result ?
if [ $# -eq 0 ] || $1; then
  if [ "$callerName" != "$(basename $0)" ]; then
    echo "Test '$0' failed!";
    echo "expected: '$(basename $0)', returned: '$callerName'";
    exit 1;
  else
    echo "Test '$0' passed.";
  fi
else
  # called by other test scripts
  echo $callerName;
fi

exit 0;
