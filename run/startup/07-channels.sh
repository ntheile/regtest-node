#!/bin/sh
## Startup script for opening and funding channels.

set -E

###############################################################################
# Environment
###############################################################################



###############################################################################
# Methods
###############################################################################



###############################################################################
# Script
###############################################################################

peers=`lightning-cli listpeers | jgrep id`
channels=`lightning-cli listpeers | grep CHANNELD_NORMAL`

if [ -z "$channels" ]; then
  for peer in $peers; do
    lightning-cli fundchannel $peer 100000
  done;
fi