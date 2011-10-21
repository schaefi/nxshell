buildroot = /
bindir    = ${buildroot}/usr/bin
sharedir  = ${buildroot}/usr/share/nxshell

all:
	${MAKE} -C ./xtest all
	./.remote

install:
	install -d -m 755 ${bindir}
	install -d -m 755 ${sharedir}
	install -m 755 ./nxshell-agent.sh ${bindir}
	install -m 755 ./nxshell-proxy.sh ${bindir}
	install -m 644 ./common/functions.sh ${sharedir}
	install -m 755 ./xtest/testX ${sharedir}
	install -m 755 ./xctrl/xkbctrl.pl ${sharedir}/xkbctrl
	install -m 644 ./xctrl/Keyboard.map ${sharedir}
	install -m 644 ./remote.tgz ${sharedir}
	ln -sf /usr/bin/nxshell-proxy.sh ${bindir}/nxshell

clean:
	${MAKE} -C ./xtest clean

build:
	./.doit -p --local
