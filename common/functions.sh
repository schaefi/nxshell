#!/bin/sh
#================
# FILE          : functions.sh
#----------------
# PROJECT       : NX ( X11 Proxy To Proxy communication )
# COPYRIGHT     : (c) 2004 SuSE Linux AG, Germany. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : NX Tools
#               :
# DESCRIPTION   : Open a nx connection to run single applications
#               : using the NX protocol. Connect using ssh to HOST as LOGIN.
#               : Tunnel an X connection using NX compression via the
#               : encrypted link and run COMMAND
#               :
# STATUS        : BETA
#----------------
#=====================================
# cleanup...
#-------------------------------------
function cleanup {
	xauth remove "$HOSTNAME/unix:$display" >/dev/null 2>&1
	xauth remove "$HOSTNAME:$display" >/dev/null 2>&1
}
#=====================================
# cleanupAndExit...
#-------------------------------------
function cleanupAndExit {
	cleanup ; exit 0
}
#=====================================
# checkDisplay...
#-------------------------------------
function checkDisplay {
	if [ -z "$DISPLAY" ];then
		echo "Display not set"
		exit 1
	fi
	export DISPLAY=$DISPLAY
	/usr/X11R6/bin/testX --fast 2>/dev/null
	if [ $? = 1 ];then
		log "Unable to open display: $DISPLAY"
		exit 1
	fi
}
#=====================================
# getCookie...
#-------------------------------------
function getCookie {
	AUTH=`xauth list "${DISPLAY#localhost}"`
	if test -z "$AUTH"; then
		log "Unable to determine the X authorization token to use."
		log "DISPLAY environment variable may be set incorrectly."
		exit 1
	fi
	if test `echo "$AUTH" | wc -l` -gt 1; then
		log "WARNING: Multiple X authorization tokens found"
		log "Using the first, I hope this is right."
		AUTH=`echo "$AUTH" | head -n1`
	fi
	COOKIE=`
		echo "$AUTH" \
		| sed "s/\([[:blank:]]*[^[:blank:]]*\)\{2\}[[:blank:]]*//"
	`
}
#=====================================
# addCookie...
#-------------------------------------
function addCookie {
	xauth -q <<- EOF
		add $HOSTNAME/unix:$display MIT-MAGIC-COOKIE-1 $COOKIE
	EOF
	xauth -q <<- EOF
		add $HOSTNAME:$display MIT-MAGIC-COOKIE-1 $COOKIE
	EOF
}
#=====================================
# newDisplay...
#-------------------------------------
function newDisplay {
	display=`expr $RANDOM % 20 + 15`
	incs=(2 3 5 7 11 13)
	inc=${incs[$(expr $RANDOM % ${#incs[@]} || true)]}
	while netcat -z localhost $(expr 6000 + $display) >/dev/null 2>&1 \
		|| nc -z localhost $(expr 4000 + $display) >/dev/null 2>&1
	do
		let display+=$inc
	done
}
#=====================================
# initConnection...
#-------------------------------------
function initConnection {
	newDisplay
	getCookie
}
