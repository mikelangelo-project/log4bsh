#!/bin/bash
#
# Test: getCallerName via SSH on localhost
#

ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";

# get caller name via SSH
callerName=$(ssh localhost "$ABSOLUTE_PATH/testGetCallerName.sh false");

# check result
if [ "$callerName" != "sshd:testGetCallerName.sh" ]; then
    echo "Test '$0' failed!";
    echo "Caller: $callerName";
else
    echo "Test '$0' passed.";
fi

exit 0;