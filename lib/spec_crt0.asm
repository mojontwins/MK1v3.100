
        MODULE  zx82_crt0

        
;--------
; Include zcc_opt.def to find out some info
;--------
        INCLUDE "zcc_opt.def"

;--------
; Some scope definitions
;--------

        XREF    _main           ; main() is always external to crt0 code

        IF !STACKPTR
                DEFC    STACKPTR = $FFFF   ; below UDG, keep eye when using banks
        ENDIF
        
        
        IF      !myzorg
            IF (startup=2)                 ; ROM ?
                defc    myzorg  = 0
                defc    STACKPTR = 32767
            ELSE
                defc    myzorg  = 32768
            ENDIF
        ENDIF


        org     myzorg


start:

  IF      STACKPTR
    ld      sp,STACKPTR
  ENDIF
    jp    _main           ; Call user program
