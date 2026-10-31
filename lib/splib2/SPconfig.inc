;
; Sprite Pack V2.2 Configuration File
; Alvin Albrecht 07.2003
;
; Customize the following options prior to compiling the library.
;
;
; * DISPLAY RESOLUTION
;
;   Define exactly one of these as true:
;
	DISP_SPECTRUM = 1
;     for a 256x192 pixel, 32x24 colour Spectrum display
;
	DISP_HICOLOUR = 0
;     for a 256x192 pixel, 32x192 colour hi-colour display (Timex only)
;
	DISP_HIRES = 0
;     for a 512x192 pixel monochrome hi-res display (Timex only)
;
	DISP_TMXDUAL = 0
;     for spectrum display using double buffering (Timex dual screen mode).
;     also set DISP_SPECTRUM to 1 and NOFLICKER to 0
;
;
; * DISPLAY SIZE
;
;   Specify what rows of the display Sprite Pack will manage:
;
	SP_ROWSTART = 0; inclusive
	SP_ROWEND = 24; non-inclusive
;
;
; * SPECIFY SCREEN DRAW METHODS & VARIABLES
;
	NOFLICKER = 1
;     for no-flicker mode where a character is completely drawn
;     in a buffer before being copied to the screen
;
	SCROLLER = 0
;     to activate scroller mode where the first sprite in each
;     character is drawn as load-type regardless of its actual type
;
	COMPRESS = 0
;     to compress sprite graphics so that xor, or and load sprites
;     do not need an (unused) mask byte in their definitions; this means
;     that xor, or and load sprites can share graphic definitions but mask
;     sprite graphics (which require the mask byte) must have an
;     independent definition with the mask byte present.  BUGGED!
;
	SProtatetbl = 0xf000
;     the base address of the horizontal rotate table must be a
;     multiple of $1000; actual memory occupied is SProtatetbl+$200
;     to SProtatetbl+$fff
;
;
; * IM2 INTERRUPT VECTOR TABLE
;
	IM2TABLE = 0xf000; LSB = $00
;     the base address of the im 2 interrupt vector table;
;     occupies 257 bytes if EVENVECTORS is false, 256 otherwise
;
	EVENVECTORS = 0
;     if devices will only place even vectors on the data bus,
;     define this variable as true
;
;
; * DYNAMIC BLOCK MEMORY ALLOCATOR
;
	NUMQUEUES = 5
;     the number of memory queues managed by the dynamic block
;     memory allocator
;
;
; * AY-3-89xx SOUND CHIP PORT ASSIGNMENTS
;
	AYREG_2068 = 0xf5
	AYDAT_2068 = 0xf6
	AYREG_128 = 0xfffd
	AYDAT_128 = 0xbffd
	AYREG_FULLER = 0x3f
	AYDAT_FULLER = 0x5f
;
	AYREG_DEFAULT = AYREG_128
	AYDAT_DEFAULT = AYDAT_128
;
;

; Extra stuff
; use attr bit 7 for fg cells (sprites not drawn on them)
	FLASHASFG = 1
