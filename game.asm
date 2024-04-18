.INCLUDE "vcs.inc"

.BANK 0 SLOT 2
.ORGA $F000

; Data section
.ENUM $80
p0y DB
p1y DB
p0pixels DB
p1pixels DB
blflag DB
enam0flag DB
spawnball DB
blx DB
bly DB
scoretile DB
p0score DW
p1score DW
p0scorepf DB
p1scorepf DB
.ENDE

_DataStart:
.DB 27   ; p0y
.DB 27   ; p1y
.DB 0    ; p0pixels
.DB 0    ; p1pixels
.DB 0    ; blflag
.DB 0    ; enam0flag
.DB $80  ; spawnball
.DB 100  ; blx
.DB 27   ; bly
.DB 5    ; scoretile
.DW N0Tiles ; p0score
.DW N1Tiles ; p1score
.DB 0       ; p0scorepf
.DB 0       ; p1scorepf
_DataEnd:

Entry:
LDY #(_DataEnd - _DataStart - 1)
LDX #$FF
TXS
_RamSetData:
LDX.W _DataStart,Y
STX $80,Y
DEY
BPL _RamSetData

_HwRegInit:
; Background to black
; Set Port A to INPUT
; Set PF0 and PF2 to unused
LDX #0
STX COLUBK
STX SWACNT
STX PF0
STX PF2

; Enable reflection of playfield
; Set ball size to 4 color cycles
LDX #$20
STX CTRLPF

; Playfield to Grey-Gold, White
; Players to Grey-Gold, White
LDX #$0F
STX COLUPF
STX COLUP0
STX COLUP1

; Set missle 0 to have small size
LDX #$00
STX NUSIZ0

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

; Position Ball (HBLANK -> 4)
STA WSYNC
BIT spawnball
BPL _SkipSpawnBl
LDY #5
JSR BusyWait0
STA RESBL
_SkipSpawnBl:
LDX #0
STX ENABL
INC bly
LDY bly
_BoundBlDown:
CPY #57
BNE _SkipWrapBl
LDY #2
_SkipWrapBl:
STY bly

; Render players in loop (HBLANK -> 5)
STA WSYNC 
LDX #$00

; Process P0,P1 input (HBLANK -> 7)
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

; HBlank wait remaning lines (HBLANK -> 21)
LDY #14
JSR HBlankWait

; Set initial state of missle and 
LDX #$02
STX enam0flag
STX ENAM0
LDX #$00
STX p0scorepf
STX p1scorepf
STX p0pixels
STX p1pixels
STX GRP0
STX GRP1
STX PF1
LDX #$01
STX blflag
STX ENABL
LDX #$05
STX scoretile

; Render for 230 scanlines
; Update every 4 scanlines
; Enter render loop on new scanline (HBLANK -> 22)
LDX #57
STA WSYNC
JMP _RenderLoop

.ORGA $F1E0
_SkipPFDelay:
LDY #1
BNE _SkipPFChange

_SkipBGDelay:
NOP
NOP
LDY #1
BNE _SkipBGChange

.ORGA $F200
_RenderLoop:
_UpdateBG:
LDY p0scorepf
STY PF1
TXA
AND #1
BNE _SkipBGDelay
LDY scoretile
BEQ _SkipPFDelay
DEY
STY scoretile
LDA (p0score),Y
STA p0scorepf
LDA (p1score),Y
STA p1scorepf
STA PF1
_SkipPFChange:
LDA enam0flag
EOR #$02
STA enam0flag
_SkipBGChange:
LDY p1scorepf
STY PF1
STA WSYNC
_ChangeP0:
LDY p0scorepf
STY PF1
TXA
CLC
SBC p0y
BEQ _P0Change
CMP #-12
BNE _SkipP0Change
_P0Change:
LDA p0pixels
EOR #$0F
STA p0pixels
_SkipP0Change:
_ChangeP1:
TXA
CLC
SBC p1y
BEQ _P1Change
CMP #-12
BNE _SkipP1Change
_P1Change:
LDA p1pixels
EOR #$0F
STA p1pixels
_SkipP1Change:
LDY p1scorepf
STY PF1
STA WSYNC

_RenderSync:
LDY blflag
STY ENABL
LDY p0pixels
STY GRP0
LDY p0scorepf
STY PF1
LDY enam0flag
STY ENAM0
LDY p1pixels
STY GRP1
LDY #1
JSR BusyWait0
LDY p1scorepf
STY PF1
STA WSYNC
_ChangeBl:
LDY p0scorepf
STY PF1
TXA
CLC
SBC bly
BEQ _BlChange
CMP #-2
BNE _SkipBlChange
_BlChange:
LDA blflag
EOR #$02
STA blflag
_SkipBlChange:
LDY #1
JSR BusyWait0
LDY p1scorepf
STY PF1
STA WSYNC
DEX
BEQ _RenderLoopExit
JMP _RenderLoop

_RenderLoopExit:
LDA #$42
STA VSYNC

LDY #30
JSR HBlankWait
JMP _GameLoop

.ORGA $FE00
N0Tiles:
.DB $00
.DB $07
.DB $05
.DB $05
.DB $07
N1Tiles:
.DB $00
.DB $07
.DB $02
.DB $02
.DB $06
N10Tiles:
.DB $00
.DB $77
.DB $25
.DB $25
.DB $67
NStressTiles:
.DB $ff
.DB $ff
.DB $ff
.DB $ff
.DB $ff

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
CPY #12
BCS _SkipBatBoundLower
LDY #12
_SkipBatBoundLower:
CPY #56
BCC _SkipBatBoundHigher
LDY #56
_SkipBatBoundHigher:
TYA
RTS

.ORGA $FFFA
.DW Entry
.DW Entry
.DW Entry
