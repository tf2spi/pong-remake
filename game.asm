.INCLUDE "vcs.inc"

.BANK 0 SLOT 2
.ORGA $F000

; Data section
.ENUM $80
bscroll DB
escroll DB
.ENDE

_DataStart:
.DB 0 ; Bscroll
.DB 7 ; Escroll
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
LDX #0
STX COLUBK

; Enable reflection of playfield
LDX #1
STX CTRLPF

; Playfield to Grey-Gold, Grey
LDX #$0F
STX COLUPF

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

; Position Missle (HBLANK -> 1)
STA WSYNC
LDY #9
_PositionLoop:
DEY
BNE _PositionLoop
STA RESM0

; HBlank wait remaning lines (HBLANK -> 22)
LDY #21
JSR HBlankWait

; Do the cool rendering thing
LDY #230
LDX #$02
_RenderLoop:
STA WSYNC
TYA
AND #7
BNE _SkipENAM0Change
TXA
EOR #$02
TAX
STA ENAM0
_SkipENAM0Change:
DEY
BNE _RenderLoop

LDA #$42
STA VSYNC

LDY #30
JSR HBlankWait
JMP _GameLoop

HBlankWait:
_HBlankWaitLoop:
STA WSYNC
DEY
BNE _HBlankWaitLoop
RTS

.ORGA $FFFA
.DW Entry
.DW Entry
.DW Entry
