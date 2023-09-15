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
    su mldonkey -c 'mldonkey' &
    echo "Waiting for mldonkey to start..."
    sleep 5
    su mldonkey -c '/usr/lib/mldonkey/mldonkey_command "set allowed_ips 0.0.0.0/0"'
    su mldonkey -c '/usr/lib/mldonkey/mldonkey_command "save"'
    export MLDONKEY_ADMIN_PASSWORD
    if [ ! -z "$MLDONKEY_ADMIN_PASSWORD" ]; then
        su mldonkey -c '/usr/lib/mldonkey/mldonkey_command "useradd admin $MLDONKEY_ADMIN_PASSWORD"'
    fi
else
    su mldonkey -c 'mldonkey'
fi
