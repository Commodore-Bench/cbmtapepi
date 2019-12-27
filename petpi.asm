
; 2017.09.13
;
; marcel timm, rhinodevel

; cbm pet

; configured for basic 2.0 / rom v3.
; can be reconfigured for basic 1.0 / rom v2 by
; replacing values with following values in comments
; (if there are no commented-out values following,
; these addresses are equal).

*=32384
;*=634 ; tape buf. #1 & #2 used (192+192=384 bytes), load via basic loader prg.

; -------------------
; system sub routines
; -------------------

crlf     = $c9e2;$c9d2 <- basic 1.0 / rom v2 value.
wrt      = $ffd2

; ---------------
; system pointers
; ---------------

varstptr = 42;124 ; pointer to start of basic variables.

; -----------
; "constants"
; -----------

chr_0    = $30
chr_a    = $41
chr_spc  = $20

tapbufin = $bb;$271 ; tape buf. #1 & #2 indices to next char (2 bytes).
adptr    = 15;6 ; term. width & lim. for scanning src. columns (2 unused bytes).

; using tape #1 port for transfer:

cas_sense = $e810 ; bit 4.
;
; pia 1, port a (59408, tested => correct, 5v/1 when no key pressed or
;                unconnected, "0v"/0 when key pressed).

cas_read = $e811 ; bit 7 is high-to-low flag. pia 1, control register a (59409)

cas_write = $e840 ; bit 3
;
; via, port b (59456, tested => correct, 5v for 1, 0v output for 0).

defbasic = $401 ; default start addr. of basic prg.

out_req  = cas_write
in_ready = cas_read
in_data  = cas_sense
datamask = $10 ; bit 4.

; ---------
; functions
; ---------

; ************
; *** main ***
; ************

         ;cld

; expected values at this point:
;
; cas_write/out_req = output.
; cas_read/in_ready = input, don't care about level, just care about HIGH -> LOW
;                     change.
; cas_sense/in_data = input.

         lda out_req
         lsr a
         lsr a
         lsr a
         and #1
         sta tapbufin

         jsr readbyte  ; read start address.
         sta adptr     ; store for transfer.
         sta loadadr   ; store for later autostart.
         jsr readbyte
         sta adptr+1
         sta loadadr+1

         ;lda adptr+1  ; print start address.
         jsr printby
         lda adptr
         jsr printby

         lda #chr_spc
         jsr wrt

         jsr readbyte  ; read payload byte count.
         sta le
         jsr readbyte
         sta le+1

         ;lda le+1     ; print payload byte count.
         jsr printby
         lda le
         jsr printby

nextpl   jsr readbyte  ; read byte.

         ldy #0        ; store byte
         sta (adptr),y ; at current address.

         inc adptr
         bne decle
         inc adptr+1

decle    lda le
         cmp #1
         bne dodecle
         lda le+1      ;low byte is 1
         beq readdone  ;read done,if high byte is 0
dodecle  dec le        ;read is not done
         lda le
         cmp #$ff
         bne nextpl
         dec le+1      ;decrement high byte,too
         jmp nextpl

readdone lda adptr+1    ; set basic variables start pointer to behind loaded
         sta varstptr+1 ; prg. maybe not correct for (all) machine code prg's.
         lda adptr      ;
         sta varstptr   ;

         jsr crlf
         rts

; ****************************************
; *** "toggle" write based on tapbufin ***
; ****************************************
; *** modifies register a.             ***
; ****************************************

togout   lda tapbufin ; "toggle" depending on tapbufin.
         beq toghigh
         dec tapbufin ; toggle output to low.
         lda out_req
         and #247
         jmp togdo
toghigh  inc tapbufin ; toggle out_req output to high.
         lda out_req
         ora #8
togdo    sta out_req ; [does not work in vice (v3.1)]
         rts

; **************************************
; *** read a byte into register a    ***
; **************************************
; *** modifies registers a, x and y. ***
; **************************************

readbyte sei

         ldy #0         ; byte buffer during read.
         ldx #0         ; (read bit) counter.

readloop jsr togout     ; request next data bit.

readwait bit in_ready   ; wait for data-ready toggling (writes bit 7 to n flag).
         bpl readwait   ; branch, if n is 0 ("positive").

         bit in_ready-1 ; resets "toggle" bit by read operation (see pia doc.).

         lda in_data    ; load actual data (bit 4) into c flag.
         clc            ;
         and #datamask  ; sets z flag to 1, if bit 4 is 0.
         beq readadd    ; bit read is zero.
         sec            ;

readadd  tya            ; put read bit from c flag into byte buffer.
         ror            ;
         tay            ;

         inx
         cpx #8         ; last bit read?
         bne readloop

         tya            ; get byte read into accumulator.

         cli
         rts

; *********************************************************
; *** print "hexadigit" (hex.0-f) stored in accumulator ***
; *********************************************************

printhd  and #$0f      ;ignore left 4 bits
         cmp #$0a
         bcc printd
         clc           ;more or equal $0a - a to f
         adc #chr_a-$0a
         bcc print
printd   ;clc           ;less than $0a - 0 to 9
         adc #chr_0
print    jsr wrt
         rts

; ******************************************************
; *** print byte in accumulator as hexadecimal value ***
; ******************************************************

printby  pha
prbloop  lsr a
         lsr a
         lsr a
         lsr a
         jsr printhd
         pla
         jsr printhd
         rts

; ---------
; variables
; ---------

le       byte 0, 0 ; count of payload bytes.
loadadr  byte 0, 0 ; hold start address of loaded prg.
