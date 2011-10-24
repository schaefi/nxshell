#!/bin/sh
#================
# FILE          : nxshell-proxy.sh
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
VERSION=1.4

#=====================================
# PROXY code: Functions
#-------------------------------------
. /usr/share/nxshell/functions.sh

#=====================================
# Functions
#-------------------------------------
function log {
	hostname=`hostname`
	time=`date +%H:%M:%S`
	echo "$time $hostname nxshell-proxy: $1"
}
function createSessionKey {
	local sessionDir=$1
	local remoteHost=$2
	local remoteUser=$3
	if [ -f $sessionDir/session.key ];then
		rm -f $sessionDir/session.key
	fi
	ssh-keygen -q -t dsa -f $sessionDir/session.key -N ""
	if [ ! $? = 0 ];then
		log "Failed to create ssh session key... abort"
		exit 1
	fi
	ssh-copy-id -i $sessionDir/session.key.pub \
		$remoteUser@$remoteHost &>/dev/null
	if [ ! $? = 0 ];then
		log "Failed to install ssh session key... abort"
		exit 1
	fi
}
function cleanupSessionKey {
	local sessionDir=$1
	local remoteHost=$2
	local remoteUser=$3
	local k=`cat $sessionDir/session.key.pub`
	eval ssh -i $sessionDir/session.key \
		$remoteUser@$remoteHost $sessionDir/nxshell/cleankey.sh $k
}
function usage {
	echo "Linux nxshell (proxy) Version $VERSION (2004-12-08)"
	echo "(C) Copyright 2004 - SuSE GmbH <Marcus Schaefer ms@suse.de>"
	echo 
	echo "usage: nxshell-proxy [ options ]"
	echo "options:"
	echo "[ -c | --compression <level> ]"
	echo "   set compression level. Available levels are:"
	echo "   LAN, WAN, DSL, ISDN and MODEM. Default is DSL"
	echo
	echo "[ -r | --command <\"'command'\"> ]"
	echo "   set command line to run on NX display"
	echo
	echo "[ -l | --location <user@host> ]"
	echo "   set remote location using -l user@host"
	echo
	echo "[ -h | --help ]"
	echo "   display this help message"
	echo
	echo "[ -v | --version ]"
	echo "   get version information"
	echo
	echo "[ -L | --layout <layout> ]"
	echo "   set keyboard layout to use, default is: us"
	echo "   the layout given here must be a valid console"
	echo "   keyboard name. use -k to get a list of supported"
	echo "   keyboard maps"
	echo
	echo "[ -k | --keyboards ]"
	echo "   print supported keyboard mappings"
	echo 
	echo "[ -i | --ignore ]"
	echo "   ignore ICMP connection check"
	echo
	echo "[ -p | --port ]"
	echo "   set ssh port to connect to remote ssh daemon"
	echo
	echo "[ -f | --file <logfile> ]"
	echo "   set a log file name to store the information"
	echo
	echo "[ -d | --debug <level> ]"
	echo "   set SSH debug level, supported levels are"
	echo "   none (default), v , vv and vvv"
	echo
	echo "Examples:"
	echo "nxshell -l foo@bar --command xterm"
	echo "nxshell -l foo@bar --command \"'xterm -bg green'\" --layout de"
	echo "--"
	exit $1
}
function printKeymaps {
	kbd=/usr/share/nxshell/Keyboard.map
	xkb=/usr/share/nxshell/xkbctrl
	for i in `cat $kbd | grep -v ^\# | cut -f1 -d:`;do
		apply=`$xkb $i | grep Apply | cut -f2 -d: | tr -d \"`
		echo "$i : $apply"
	done | column -t -s:
}

#=====================================
# create log dir...
#-------------------------------------
if [ ! -d $HOME/.nxshell ];then
	mkdir $HOME/.nxshell
fi

#=====================================
# Initial parameters
#-------------------------------------
layout=us
compressionLevel=adsl
comeFrom=`hostname -f`
sshport=22
debug=

#=====================================
# Get options
#-------------------------------------
TEMP=`getopt -o "g:r:c:vhl:id:L:kp:f:" \
	-l "command:,compression:,version,help,location:,ignore,layout:,keyboards,debug:,port:,file:" \
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
		# -r run given command
		#-------------------------------------
		-r|--command)
			command="$2"
			shift 2
		;;
		#=====================================
		# -k print keymap list
		#-------------------------------------
		-k|--keyboards)
			printKeymaps
			exit 0
		;;
		#=====================================
		# -d ssh debug level
		#-------------------------------------
		-d|--debug)
			debug="-$2"
			shift 2
		;;
		#=====================================
		# -d ssh debug level
		#-------------------------------------
		-p|--port)
			sshport="$2"
			shift 2
		;;
		#=====================================
		# -f log file name
		#-------------------------------------
		-f|--file)
			exec >& $2
			shift 2
		;;
		#=====================================
		# -l set user and remote host
		#-------------------------------------
		-l|--location)
			remote="$2"
			shift 2
		;;
		#=====================================
		# -L set keyboard layout
		#-------------------------------------
		-L|--layout)
			layout="$2"
			shift 2
		;;
		#=====================================
		# -v got version information
		#-------------------------------------
		-v|--version)
			log "nxshell $VERSION"
			exit 0
		;;
		#=====================================
		# -i ignore ICMP connection check
		#-------------------------------------
		-i|--ignore)
			ignore=1
			shift 1
		;;
		#=====================================
		# -h got help
		#-------------------------------------
		-h|--help)
			usage 0
		;;
		--) shift; break ;;
		*) log "Internal parse error."; exit 1 ;;
	esac
done

#=====================================
# checking command
#-------------------------------------
if [ -z "$command" ];then
	command=xterm
fi

#=====================================
# checking connectivity
#-------------------------------------
thisUser=`echo $remote | cut -f1 -d@`
remoteHost=`echo $remote | cut -f2 -d@`
thisHost=`host $comeFrom | head -n 1 | cut -f4 -d" "`
echo $remoteHost | grep -qE "^([0-9]{1,3}\.){3}[0-9]{1,3}$"
if [ ! $? = 0 ];then
	remoteHost=`host $remoteHost 2>/dev/null | head -n 1 | cut -f4 -d" "`
fi
if [ -z $remoteHost ];then
	usage 1
fi
if [ ! "$ignore" = 1 ];then
	ping -c 1 $remoteHost >/dev/null 2>&1
	if [ ! $? = 0 ];then
		log "couldn't resolve remote host... abort"
		exit 1
	fi
fi
if [ $thisHost = $remoteHost ];then
	log "source and destination machine are the same... abort"
	exit 1
fi

#=====================================
# check local X11 connection...
#-------------------------------------
checkDisplay

#=====================================
# Add local xauth cookie...
#-------------------------------------
initConnection

#=====================================
# Init netcat and SSH ports
#-------------------------------------
if [ -z "$tunnelPort" ];then
	tunnelPort=`expr 4000 + $display`
fi
if [ -z "$netcatPort" ];then
	netcatPort=`expr $tunnelPort + 1`
fi

#=====================================
# Install session key
#-------------------------------------
cdir=/var/tmp/.session-$thisUser
mkdir -p $cdir && createSessionKey $cdir $remoteHost $thisUser

#=====================================
# Check NX versions local/remote
#-------------------------------------
rpmQC="rpm -q NX --qf %{VERSION}"
locNX=$($rpmQC)
remNX=$(ssh -x -i $cdir/session.key $debug -p $sshport $remote $rpmQC)
if [ ! "$locNX" = "$remNX" ];then
	log "NX versions differ: local: $locNX remote: $remNX... abort"
	exit 1
fi

#=====================================
# Transfer remote code
#-------------------------------------
log "Transfering remote code..."
code=/usr/share/nxshell/remote.tgz
arch=$cdir/remote.tgz
cat $code | ssh -x -i $cdir/session.key $debug -p $sshport $remote \
	"mkdir -p $cdir && cat >$arch && tar -xzf $arch -C $cdir"

#=====================================
# transfer cookie...
#-------------------------------------
log "waiting for agent [ sync: $netcatPort ]..."
nc="netcat -w 30 -l -p $netcatPort"
ssh -f -x -i $cdir/session.key $debug -p $sshport \
	$remote "echo "$COOKIE" | $nc"

#=====================================
# run nxagent, wait for cookie
#-------------------------------------
log "open ssh connection to $remote [ port: $tunnelPort ]"
{
ssh -f -x -i $cdir/session.key $debug -p $sshport \
	$remote $cdir/nxshell/nxshell-agent.sh --compression $compressionLevel \
	--command $command --nxdisplay $display --syncport $netcatPort \
	--layout $layout
}&

#=====================================
# wait for agent to settle
#-------------------------------------
log "waiting for agent to settle..."
ssh -x -i $cdir/session.key $debug -p $sshport \
	$remote "echo 'waiting for agent to settle' | $nc"

#=====================================
# forward remote agent port via ssh
#-------------------------------------
log "forwarding agent port $tunnelPort:$remoteHost:$tunnelPort..."
ssh -f -x -i $cdir/session.key $debug -p $sshport \
	-L $tunnelPort:$remoteHost:$tunnelPort $remote -N

#=====================================
# run the proxy.
#-------------------------------------
log "starting nxproxy..."
nxproxy -S "localhost:$display"

#=====================================
# cleanup session key
#-------------------------------------
cleanupSessionKey \
	$cdir $remoteHost $thisUser
