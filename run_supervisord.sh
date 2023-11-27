#!/bin/bash

_term() {
	echo "Gracefully terminate supervisord process..."
	kill $child
}

trap _term INT TERM

/init.sh
/usr/bin/supervisord &
child=$!
wait $child
sleep 5
echo "supervisord process closed"
