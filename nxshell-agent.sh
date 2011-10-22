#!/bin/bash -login
#================
# FILE          : nxshell-agent.sh
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
VERSION=1.2

#=====================================
# Signal trap
#-------------------------------------
trap "cleanupAndExit" EXIT HUP INT ABRT QUIT STOP TERM

thisUser=`whoami`
cdir=/var/tmp/.session-$thisUser
#=====================================
# AGENT code: Functions
#-------------------------------------
. $cdir/nxshell/functions.sh

#=====================================
# Functions
#-------------------------------------
function log { 
	hostname=`hostname`
	time=`date +%H:%M:%S`
	echo "$time $hostname nxshell-agent: $1"
}
function usage {
	echo "Linux nxshell (agent) Version $VERSION (2004-12-08)"
	echo "(C) Copyright 2004 - SuSE GmbH <Marcus Schaefer ms@suse.de>"
	echo 
	echo "usage: nxshell-agent [ options ]"
	echo "options:"
	echo "[ -c | --compression <level> ]"
	echo "   set compression level"
	echo
	echo "[ -x | --nxdisplay <display-ID> ]"
	echo "   set NX display used with nxagent"
	echo
	echo "[ -s | --syncport <port> ]"
	echo "   set netcat sync port"
	echo
	echo "[ -l | --layout <layout> ]"
	echo "   set keyboard layout to use"
	echo
	echo "[ -r | --command <command> ]"
	echo "   set command line to run on NX display"
	exit $1
}

#=====================================
# create log dir...
#-------------------------------------
if [ ! -d $HOME/.nxshell ];then
	mkdir $HOME/.nxshell
fi

#=====================================
# Get options
#-------------------------------------
TEMP=`getopt -o "c:x:g:s:r:l:" \
	-l "syncport:,nxdisplay:,command:,compression:,layout:" \
	-n 'nxshell' -- "$@"`
if [ $? != 0 ];then
	usage 1;
fi
eval set -- "$TEMP"
while true; do
	case "$1" in
		#=====================================
		# -c compression level
		#-------------------------------------
		-c|--compression)
			compressionLevel=$2
			shift 2
		;;
		#=====================================
		# -s netcat port for cookie transfer
		#-------------------------------------
		-s|--syncport)
			netcatPort="$2"
			shift 2
		;;
		#=====================================
		# -l set keyboard layout
		#-------------------------------------
		-l|--layout)
			layout="$2"
			shift 2
		;;
		#=====================================
		# -x diaplay to use with NX
		#-------------------------------------
		-x|--nxdisplay)
			display="$2"
			shift 2
		;;
		#=====================================
		# -r run given command
		#-------------------------------------
		-r|--command)
			command="$2"
			shift 2
		;;
		--) shift; break ;;
		*) log "Internal parse error."; exit 1 ;;
	esac
done

#=====================================
# parameters refering compression
#-------------------------------------
# NX protocol and image compression...
case "$compressionLevel" in
	LAN)   link=lan   ; pack=no-pack ;;
	WAN)   link=wan   ; pack=no-pack ;;
	DSL)   link=adsl  ; pack=no-pack ;;
	ISDN)  link=isdn  ; pack=64k-png ;;
	MODEM) link=modem ; pack=4k-png  ;;
	*) 
		link=adsl ; pack=no-pack
	;;
esac

#=====================================
# prepare agent parameters
#-------------------------------------
NX_HOST_PORT_PARAMS="nx/nx,link=$link,pack=$pack"
NX_HOST_PORT_PARAMS="$NX_HOST_PORT_PARAMS,nodelay=1,limit=0"
NX_HOST_PORT_PARAMS="$NX_HOST_PORT_PARAMS"
NX_HOST_PORT_PARAMS="$NX_HOST_PORT_PARAMS,root=$HOME/.nxshell"

#=====================================
# add cookie
#-------------------------------------
count=0
while true;do
	COOKIE=$(netcat localhost $netcatPort)
	if [ ! -z "$COOKIE" ];then
		log "Adding cookie: $COOKIE"
		addCookie
		break
	fi
	count=$((count + 1))
	if [ $count -eq 5 ];then
		log "couldn't get a COOKIE... abort"
		exit 1
	fi
	sleep 1
done

#=====================================
# start the agent
#-------------------------------------
log "starting nxagent: init display [$display]"
nxagent \
	-once -persistent -display $NX_HOST_PORT_PARAMS:$display \
	-class TrueColor -noreset -geometry 800x600 -R \
	-auth $HOME/.Xauthority -name "NX-Tunnel - $HOSTNAME" :$display \
&
AGENT=$!
while true;do
	sleep 5
	if ! kill -0 $AGENT &>/dev/null;then
		log "couldn't start nxagent... abort"
		exit 1
	fi
	if [ -S /tmp/.X11-unix/X$display ];then
		log "starting nxagent: ready to accept connections"
		break
	fi
done

#=====================================
# test connection...
#-------------------------------------
export DISPLAY=:$display
while true;do
	$cdir/nxshell/testX --fast 2>/dev/null
	if [ $? = 0 ];then
		echo -en "\r"
		log "starting nxagent: connection established"
		break
	fi
done

#=====================================
# run the application
#-------------------------------------
log "calling command: $command"
eval $command
exitcode=$?

#=====================================
# clean sweep
#-------------------------------------
log "stopping service nxagent [PID: $AGENT]"
cleanup
sleep 2
kill $AGENT >/dev/null 2>&1
wait $AGENT >/dev/null 2>&1
exit $exitcode
