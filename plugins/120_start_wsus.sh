#!/bin/bash
# Copyright (c) Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.

MINION=$1

#Stop update service
salt "$MINION" cmd.run "sc config wuauserv start= disabled"
salt "$MINION" cmd.run "net stop wuauserv"

UPDATES=$( oss_api_text.sh GET softwares/devicesByName/${CLIENT}/updates )
if [ "${UPDATES:0:7}" = '{"code"' ]; then
                exit
fi
if [ "${UPDATES}" = "true" ]; then
	salt --async "$MINION" "oss_update.do"
fi

