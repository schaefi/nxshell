/**************
FILE          : xtest.c
***************
PROJECT       : SaX ( SuSE advanced X configuration )
              :
BELONGS TO    : Configuration tool X11 version 4.x
              : YaST2 inst-sys tools
              :  
DESCRIPTION   : Checks if the X server is ok and sets the root
              : window's color. Forks a child that creates an
              : invisible X client. The child exits when the 
              : X server exits. 
              :
              : Exit code: 0: X server ok, 1: no X server.
              : 
STATUS        : Status: Up-to-date
**************/
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xmu/CurUtil.h>
#include <sys/types.h>
#include <sys/wait.h>

//======================================
// Defines
//--------------------------------------
#define TWM       "/usr/X11R6/bin/twm"
#define MWM       "/usr/X11R6/bin/mwm"
#define FVWM      "/usr/X11R6/bin/fvwm2"
#define MIN_X     800
#define MIN_Y     600
#define MIN_DEPTH 15

#define FVWMRC    "/usr/X11R6/share/fvwm/fvwmrc.yast2"

//======================================
// Globals
//--------------------------------------
char *fore_color = NULL;
char *back_color = NULL;
int screen;

//======================================
// Functions
//--------------------------------------
int validColorDepth (Display* dpy);
int validResolution (Display* dpy);
Cursor CreateCursorFromName (Display* dpy,char *name);
XColor NameToXColor (Display* dpy,char *name, unsigned long pixel);
int RunWindowManager (void);

int main (int argc, char **argv) {
	Cursor cursor;
	Display *display;
	Window root;
	unsigned long pixel;
	char *cname;
	XColor color;
	Atom prop;
	Pixmap save_pixmap = (Pixmap)None;

	//============================================
	// open display and check if we got a display
	//--------------------------------------------
	display = XOpenDisplay(NULL);
	if (!display) {
		exit (1);
	}
	if ((argc == 2) && (strcmp (argv[1],"--fast") == 0)) {
		XCloseDisplay(display);
		exit (0);
	}
	//============================================
	// check the resolution
	//--------------------------------------------
	if (!validResolution(display)) {
		fprintf (stderr,
			"testX: invalid dimensions, must be >= %dx%d Pixels\n", MIN_X,MIN_Y
		);
		exit (2);
	}
	//============================================
	// install color map for background pixels
	//--------------------------------------------
	cname = argc == 2 ? argv[1] : "black";
	screen = DefaultScreen(display);
	root = RootWindow(display, screen);
	pixel = BlackPixel(display, screen);

	if(XParseColor(display, DefaultColormap(display, screen), cname, &color)) {
	if(XAllocColor(display, DefaultColormap(display, screen), &color)) {
		pixel = color.pixel;
	}
	}
	XSetWindowBackground(display, root, pixel);
	XClearWindow (display, root);

	//============================================
	// set watch cursor
	//--------------------------------------------
	cursor = CreateCursorFromName(display,"watch");
	if (cursor) {
		XDefineCursor (display, root, cursor);
		XFreeCursor (display, cursor);
	}
	
	//============================================
	// run the windowmanager (FVWM)
	//--------------------------------------------
	RunWindowManager();

	//============================================
	// save background as pixmap
	//--------------------------------------------
	save_pixmap = XCreatePixmap (
		display, root, 1, 1, 1
	);
	prop = XInternAtom (display, "_XSETROOT_ID", False);
	XChangeProperty (
		display, root, prop, XA_PIXMAP, 32, 
		PropModeReplace, (unsigned char *) &save_pixmap, 1
	);
	XSetCloseDownMode (
		display, RetainPermanent
	);

	//============================================
	// close display and exit
	//--------------------------------------------
	XCloseDisplay(display);
	exit (0);
}

//=========================================
// CreateCursorFromName
//-----------------------------------------
Cursor CreateCursorFromName (Display* dpy,char *name) {
	XColor fg, bg;
	int     i;
	Font    fid;

	fg = NameToXColor (dpy,fore_color, BlackPixel(dpy, screen));
	bg = NameToXColor (dpy,back_color, WhitePixel(dpy, screen));
	#if 0
	if (reverse) {
		temp = fg; fg = bg; bg = temp;
	}
	#endif
	i = XmuCursorNameToIndex (name);
	if (i == -1)
	return (Cursor) 0;
	fid = XLoadFont (dpy, "cursor");
	if (!fid)
	return (Cursor) 0;
	return XCreateGlyphCursor (
		dpy, fid, fid, i, i+1, &fg, &bg
	);
}

//=========================================
// NameToXColor
//-----------------------------------------
XColor NameToXColor (Display* dpy,char *name, unsigned long pixel) {
	XColor c;

	if (!name || !*name) {
	c.pixel = pixel;
	XQueryColor(dpy, DefaultColormap(dpy, screen), &c);
	} else if (!XParseColor(dpy, DefaultColormap(dpy, screen), name, &c)) {
	fprintf (stderr, 
		"testX: unknown color or bad color format: %s\n",name
	);
	exit(1);
	}
	return(c);
}

//=========================================
// RunWindowManager
//-----------------------------------------
int RunWindowManager (void) {
	int wmpid = fork();
	switch(wmpid) {
	case -1:
		return (0);
	break;
	case 0:
		execl(FVWM,"fvwm2","-f",FVWMRC,NULL);
		execl(MWM,"mwm",NULL);
		execl(TWM,"twm",NULL);
		fprintf (stderr,
			"testX: could not run any windowmanager"
		);
		return (0);
	break;
	default:
	waitpid (
		wmpid, NULL, WNOHANG | WUNTRACED
	);
	}
	return (1);
}

//=========================================
// validColorDepth ( >= 8 Bit )
//-----------------------------------------
int validColorDepth (Display* dpy) {
	int planes = DisplayPlanes (dpy, DefaultScreen(dpy));
	if (planes >= MIN_DEPTH) {
		return 1;
	}
	return 0;
}

//=========================================
// validResolution ( >= 800x600 )
//-----------------------------------------
int validResolution (Display* dpy) {
	int x = DisplayWidth  (dpy, DefaultScreen(dpy));
	int y = DisplayHeight (dpy, DefaultScreen(dpy));
	if ((x >= MIN_X) && (y >= MIN_Y)) {
		return 1;
	}
	return 0;
}
