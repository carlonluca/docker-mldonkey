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
    su -s /bin/bash -c 'mldonkey' - mldonkey &
    echo "Waiting for mldonkey to start..."
    sleep 5
    su -s /bin/bash -c '/usr/lib/mldonkey/mldonkey_command -p "" "set allowed_ips 0.0.0.0/0" "save"' mldonkey &
    if [ -z "$MLDONKEY_ADMIN_PASSWORD" ]; then
        su -s /bin/bash -c '/usr/lib/mldonkey/mldonkey_command -p "" "kill"' - mldonkey
    else
        su -s /bin/bash -c '/usr/lib/mldonkey/mldonkey_command -p "" "useradd admin $MLDONKEY_ADMIN_PASSWORD"' - mldonkey
        su -s /bin/bash -c '/usr/lib/mldonkey/mldonkey_command -u admin -p "$MLDONKEY_ADMIN_PASSWORD" "kill"' - mldonkey
    fi
fi

su -s /bin/bash -c 'mldonkey' - mldonkey
