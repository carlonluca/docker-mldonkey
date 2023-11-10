#!/bin/sh

if [ ! -f /root/initialized ]; then
	if [ ! -z "$MLDONKEY_UID" ]; then
    		echo "Resetting mldonkey uid to $MLDONKEY_UID"
    		usermod -u $MLDONKEY_UID mldonkey
	fi

	if [ ! -z "$MLDONKEY_GID" ]; then
    		echo "Resetting mldonkey gid to $MLDONKEY_GID"
    		groupmod -g $MLDONKEY_GID mldonkey
	fi

	touch /root/initialized
fi

if [ ! -f /var/lib/mldonkey/downloads.ini ]; then
    chown mldonkey:mldonkey /var/lib/mldonkey
fi
