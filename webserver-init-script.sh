#!/bin/bash
### BEGIN INIT INFO
# Provides:	  nginx
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the codesearch web server
# Description:       starts codesearch using start-stop-daemon
### END INIT INFO

set -e # Errors are fatal
set -o pipefail # Check all commands in a pipeline

NAME=codesearch

ROOT=/home/codesearch
REPO=${ROOT}/am
INDEX=${ROOT}/index
DOCROOT=${ROOT}/docroot
PIDFILE=/var/run/cs-webserver.pid

USER=codesearch
GROUP=codesearch

DAEMON=${REPO}/run-webserver.sh
DAEMON_ARGS="${REPO} ${INDEX} ${DOCROOT}"

. /lib/init/vars.sh
. /lib/lsb/init-functions

start_webserver() {
	start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON \
		--test > /dev/null || return 1
	start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON \
		-m -b --chuid $USER:$GROUP -- $DAEMON_ARGS 2>/dev/null \
		|| return 2
}

stop_webserver() {
	if [ ! -f "$PIDFILE" ]; then
		return 0
	fi
	PID=$(<"$PIDFILE")
	PGID=$(ps -o pgid= $PID | grep -o '[0-9]*')
	kill -9 -$PGID
	rm $PIDFILE
	return 0
}

case "$1" in
	start)
		log_daemon_msg "Starting codesearch webserver"
		start_webserver
		case "$?" in
			0|1) log_end_msg 0 ;;
			2) log_end_msg 1 ;;
		esac
		;;	
	stop)
		log_daemon_msg "Stopping codesearch webserver"
		stop_webserver
		case "$?" in
			0|1) log_end_msg 0 ;;
			2)   log_end_msg 1 ;;
		esac
		;;
	*)
		echo "Usage: $NAME {start|stop}" >&2
		exit 3
		;;
esac
