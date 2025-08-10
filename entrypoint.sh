#!/bin/sh

_term() {
	echo "Gracefully terminate mldonkey process..."
	kill $child
}

trap _term INT TERM

if [ ! -f /var/lib/mldonkey/downloads.ini ]; then
    mlnet &
    child=$!
    echo "Waiting for mldonkey to start..."
    sleep 5
    /usr/lib/mldonkey/mldonkey_command "set allowed_ips 0.0.0.0/0"
    /usr/lib/mldonkey/mldonkey_command "save"
    export MLDONKEY_ADMIN_PASSWORD
    if [ ! -z "$MLDONKEY_ADMIN_PASSWORD" ]; then
        /usr/lib/mldonkey/mldonkey_command "useradd admin $MLDONKEY_ADMIN_PASSWORD"
    fi
else
    mlnet &
    child=$!
fi

wait $child
sleep 5
echo "mldonkey process closed"
