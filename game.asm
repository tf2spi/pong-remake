.INCLUDE "vcs.inc"

.BANK 0 SLOT 2
.ORGA $F000

; Data section
.ENUM $80
p0y DB
p1y DB
enam0flag DB
.ENDE

_DataStart:
.DB 55 ; p0y
.DB 55 ; p1y
.DB 0  ; enam0flag
_DataEnd:

Entry:
LDY #(_DataEnd - _DataStart - 1)
_RamSetData:
LDX.W _DataStart,Y
STX $80,Y
DEY
BPL _RamSetData

_HwRegInit:
; Background to black
; Set Port A to INPUT
LDX #0
STX COLUBK
STX SWACNT

; Enable reflection of playfield
LDX #1
STX CTRLPF

; Playfield to Grey-Gold, White
; Players to Grey-Gold, White
LDX #$0F
STX COLUPF
STX COLUP0
STX COLUP1

_GameLoop:
; Do VBLANKs and VSYNCs first
CLD
LDA #$0
STA VBLANK

LDA #2
STA VSYNC

LDY #3
JSR HBlankWait

LDA #0
STA VSYNC

; Setup playfield vars
LDX #0
STX PF0
STX PF1
STX PF2

; Enable missle 0 and set small size
LDX #$00
STX NUSIZ0
LDX #$02
STX ENAM0
LDX #$0F
STX COLUP0

; Position Missle 0 (HBLANK -> 1)
STA WSYNC
LDY #6
JSR BusyWait0
STA RESM0

; Position Player 0 (HBLANK -> 2)
STA WSYNC
LDY #1
JSR BusyWait0
STA RESP0

; Position Player 1 (HBLANK -> 3)
STA WSYNC
LDY #11
JSR BusyWait0
STA RESP1

; Render players in loop (HBLANK -> 4)
STA WSYNC 
LDX #$00
STX GRP0
STX GRP1

; Process P0,P1 input (HBLANK -> 6)
STA WSYNC
LDA SWCHA

ROL A
ROL A
ROL A
BCC _SkipMoveP0Down
INC p0y
_SkipMoveP0Down:
ROL A
BCC _SkipMoveP0Up
DEC p0y
_SkipMoveP0Up:

PHA
LDY p0y
JSR BoundBat
STA p0y
PLA
STA WSYNC
ROL A
ROL A
ROL A
BCC _SkipMoveP1Down
INC p1y
_SkipMoveP1Down:
ROL A
BCC _SkipMoveP1Up
DEC p1y
_SkipMoveP1Up:
LDY p1y
JSR BoundBat
STA p1y

; HBlank wait remaning lines (HBLANK -> 22)
LDY #16
JSR HBlankWait

; Render for 230 scanlines
; Update every 2 scanlines
LDY #115
LDX #$02
STX enam0flag
_RenderLoop:
TYA
CLC
SBC p0y
BNE _SkipP0Render
LDX #$0F
STX GRP0
_SkipP0Render:
CLC
ADC #24
BNE _SkipP0Unrender
LDX #$00
STX GRP0
_SkipP0Unrender:
TYA
CLC
SBC p1y
BNE _SkipP1Render
LDX #$F0
STX GRP1
_SkipP1Render:
CLC
ADC #24
BNE _SkipP1Unrender
LDX #$00
STX GRP1
_SkipP1Unrender:
_RenderM0:
TYA
AND #3
BNE _SkipENAM0Change
LDA enam0flag
EOR #$02
STA enam0flag
STA ENAM0
_SkipENAM0Change:
STA WSYNC
STA WSYNC
DEY
BNE _RenderLoop

LDA #$42
STA VSYNC

LDY #30
JSR HBlankWait
JMP _GameLoop

; Y = Number of loops to busy wait
.ORGA $FF00
BusyWait2:
NOP
BusyWait1:
NOP
BusyWait0:
_BusyWaitLoop:
DEY
BNE _BusyWaitLoop
RTS

; Y = # of HBLANKS
HBlankWait:
_HBlankWaitLoop:
STA WSYNC
DEY
BNE _HBlankWaitLoop
RTS

; Y = Bat position
; Return new bat position in A 
BoundBat:
CPY #23
BCS _SkipBatBoundLower
LDY #23
_SkipBatBoundLower:
CPY #114
BCC _SkipBatBoundHigher
LDY #114
_SkipBatBoundHigher:
TYA
RTS

.ORGA $FFFA
.DW Entry
.DW Entry
.DW Entry
