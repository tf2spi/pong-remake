.INCLUDE "vcs.inc"

.BANK 0 SLOT 2
.ORGA $F000
Entry:
CLD
LDA #$0
STA VBLANK

LDA #2
STA VSYNC

STA WSYNC
STA WSYNC
STA WSYNC

LDA #0
STA VSYNC

LDA #37
JSR HBlankWait

LDX #0
LDA #192
_RenderLoop:
INX
STX COLUBK
STA WSYNC
SEC
SBC #1
BNE _RenderLoop

LDA #$42
STA VSYNC

LDA #30
JSR HBlankWait
JMP Entry

HBlankWait:
SEC
_HBlankWaitLoop:
STA WSYNC
SBC #1
BNE _HBlankWaitLoop
RTS

.ORGA $FFFA
.DW Entry
.DW Entry
.DW Entry
