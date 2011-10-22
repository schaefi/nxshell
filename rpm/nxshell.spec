# /.../
# spec file for package nxshell (Version 1.4)
#
# Copyright (c) 2004 SUSE LINUX AG, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://www.suse.de/feedback/
#
Name:          nxshell
BuildRequires: xorg-x11-devel
Requires:      netcat NX bash perl
Summary:       NX Tool to start single application via NX protocol
Version:       1.4
Release:       2
Group:         System/X11/Utilities
License:       GPL
Source:        nxshell.tar.bz2
BuildRoot:     %{_tmppath}/%{name}-%{version}-build

%description
nxshell make use of the NX proxy system to run a remote
X11 application over a slow line like Modem ISDN or DSL
connections.

Authors:
--------
    Marcus Schäfer <ms@suse.de>

%prep
%setup -n nxshell

%build
make

%install
rm -rf $RPM_BUILD_ROOT
make buildroot=$RPM_BUILD_ROOT install

%files
%defattr(-,root,root)
%dir /usr/share/nxshell
/usr/bin/nxshell
/usr/bin/nxshell-agent.sh
/usr/bin/nxshell-proxy.sh
/usr/share/nxshell/functions.sh
/usr/share/nxshell/testX
/usr/share/nxshell/xkbctrl
/usr/share/nxshell/Keyboard.map
/usr/share/nxshell/remote.tgz
