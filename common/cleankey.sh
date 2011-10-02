#!/bin/sh
#================
# FILE          : cleankey.sh
#----------------
# PROJECT       : NX ( X11 Proxy To Proxy communication )
# COPYRIGHT     : (c) 2004 SuSE Linux AG, Germany. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : NX Tools
#               :
# DESCRIPTION   : removes the session key from the
#               : authorized_keys file
#               :
# STATUS        : BETA
#----------------
pkey=$*
file="$HOME/.ssh/authorized_keys"

cat $file | grep -v "^$pkey$" > $file.new && mv $file.new $file
