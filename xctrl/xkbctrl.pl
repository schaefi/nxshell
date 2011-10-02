#!/usr/bin/perl
# Copyright (c) 2002 SuSE GmbH Nuernberg, Germany.  All rights reserved.
#
# Author: Marcus Schaefer <sax@suse.de>, 2002
# SaX2 script: get console -> x11 xkb mapping information
# --
# CVS ID:
# --------
# Status: Up-to-date
#
use strict;

#=================================
# Globals...
#---------------------------------
my $user = qx (whoami) ; chomp ($user);
my $CFGMap = "/usr/share/nxshell/Keyboard.map";
if (! -f $CFGMap) {
	$CFGMap = "/var/tmp/.session-$user/nxshell/Keyboard.map";
}

#=================================
# The magic main :-)
#---------------------------------
sub main {
#------------------------------------------------
# check for all the keyboard information needed	
# to setup X11 XKB keyboard:
# --
	my $XkbVariant;
	my $XkbLayout;
	my $XkbModel;
	my $Protocol;
	my $XkbRules;
	my $XkbOptions;
	my $MapName;
	my $XkbKeyCodes;
	my $LeftAlt;
	my $RightAlt;
	my $ScrollLock;
	my $RightCtl;
	my $Apply;

	my %map;
	my %opt;
	
	if (! defined $ARGV[0]) {
		die "xkbctrl: no console name given";
	}
	if ($ARGV[0] =~ /(.*)\.map\.gz.*/) {
		$ARGV[0] = $1;
	}
	%map = ReadDataConfigMap ($CFGMap);
	foreach (keys %map) {
	if ($_ eq $ARGV[0]) {
		my @list = split (/:/,$map{$_});
		$XkbModel    = Tr (shift(@list));
		$XkbLayout   = Tr (shift(@list));
		$XkbVariant  = Tr (shift(@list));
		$XkbKeyCodes = Tr (shift(@list));
		$LeftAlt     = Tr (shift(@list));
		$RightAlt    = Tr (shift(@list));
		$ScrollLock  = Tr (shift(@list));
		$RightCtl    = Tr (shift(@list));
		$XkbOptions  = Tr (join(":",@list));
	}
	}
	$opt{-model}   = $XkbModel;
	$opt{-layout}  = $XkbLayout;
	$opt{-option}  = $XkbOptions;
	$opt{-variant} = $XkbVariant;
	foreach (keys %opt) {
	if (($opt{$_} ne "x") && ($opt{$_} ne "")) {
		$Apply = "$Apply $_ $opt{$_}";
	}
	}
	$Apply =~ s/^ +//;

	print "\$[\n";
	if ($XkbVariant ne "x") {
	print "   \"XkbVariant\"   : \"$XkbVariant\",\n";
	}
	print "   \"XkbLayout\"    : \"$XkbLayout\",\n";
	print "   \"XkbModel\"     : \"$XkbModel\",\n";
	if ($XkbOptions ne "x") {
	print "   \"XkbOptions\"   : \"$XkbOptions\",\n";
	}
	if ($XkbKeyCodes !~ /xfree86/) {
	print "   \"XkbKeyCodes\"  : \"$XkbKeyCodes\",\n";
	}
	if ($LeftAlt ne "x") {
	print "   \"LeftAlt\"      : \"$LeftAlt\",\n";
	}
	if ($RightAlt ne "x") {
	print "   \"RightAlt\"     : \"$RightAlt\",\n";
	}
	if ($ScrollLock ne "x") {
	print "   \"ScrollLock\"   : \"$ScrollLock\",\n";
	}
	if ($RightCtl ne "x") {
	print "   \"RightCtl\"     : \"$RightCtl\",\n";
	}
	print "   \"Apply\"        : \"$Apply\"\n";
	print "]\n"
}

#----[ ReadDataConfigMap ]----------#
sub ReadDataConfigMap {
#--------------------------------------------
# read Keyboard.map information file...
# return a hash
#
	my $filename = $_[0];

	my $consoleName;
	my $stuff;
	my %result;

	if (! open (DATA,$filename)) {
		die "could not open file: $filename";
	}
	while (my $line=<DATA>) {
		chomp ($line);
		my @list = split (/:/,$line);
		$consoleName = shift (@list);
		$consoleName =~ s/ +//g;
		$consoleName =~ s/\t+//g;
		$stuff = join(":",@list);
		$result{$consoleName} = $stuff;
	}
	return (%result);
}

#---[ tr ]----#
sub Tr {
#----------------------------------------------
# translate item into a non whitespace format
# 
	my $item = $_[0];
	$item =~ s/^\t+//g; $item =~ s/\t+$//g;
	$item =~ s/^ +//g; $item =~ s/ +$//g;
	return ($item);
}

main();
