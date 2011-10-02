all: testX

testX: xtest.o
	gcc -Wall -o testX xtest.o -L/usr/X11R6/lib -L/usr/X11R6/lib64 -lX11 -lXmu

xtest.o: xtest.c
	gcc -Wall -c xtest.c

clean:
	rm -f testX
	rm -f *.o
