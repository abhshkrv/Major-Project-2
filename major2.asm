$mod186
NAME EG0_COMP
; CG2007		Microprocessor Systems
; Sem 2			AY2011-2012
;
; Author:       Mr. Niu Tianfang
; Address:      Department of Electrical Engineering 
;               National University of Singapore
;               4 Engineering Dr 3
;               Singapore 117576. 
; Date:         Jan 2012
;
; This file contains proprietory information and cannot be copied 
; or distributed without prior permission from the author.
; --------------------------------------------------------------------


;IO Setup for 80C188 
	UMCR    EQU    0FFA0H ; Upper Memory Control Register
	LMCR    EQU    0FFA2H ; Lower Memory control Register         
	PCSBA   EQU    0FFA4H ; Peripheral Chip Select Base Address
	MPCS    EQU    0FFA8H ; MMCS and PCS Alter Control Register
; DATA SEGMENT
DATA_SEG SEGMENT
DB 128 DUP(?)
STACK_TOP LABEL WORD
CURRENT DB 00H
TARGET DB 00H
DIFFER DB 00H
DIR DB 00H ;UP (2), DOWN (1), READY (0)
DATA_SEG ENDS

; RESET SEGMENT
Reset_Seg SEGMENT
MOV DX, UMCR
MOV AX, 03E07H
OUT DX, AX
JMP far PTR start
Reset_Seg ends

; MESSAGE SEGMENT
MESSAGE_SEG SEGMENT
MESSAGE_SEG ENDS

; CODE SEGMENT
CODE_SEG SEGMENT
PUBLIC START
ASSUME CS:CODE_SEG, DS:DATA_SEG, SS:DATA_SEG

START:
; Initialize MPCS to MAP peripheral to IO address
MOV DX, MPCS
MOV AX, 0083H
OUT DX, AL

; PCSBA initial, set the parallel port start from 00H
MOV DX, PCSBA ;(PCS Control Register)
MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
OUT DX, AL

; Initialize Lower Chip Select pin with 8k RAM
MOV DX, LMCR
MOV AX, 01C4H ; Starting address 1FFFH, 8K, No waits, last shoud be 5H for 1 waits
OUT DX, AX

; Initialize Stack
MOV AX, DATA_SEG
MOV SS, AX
MOV SP, OFFSET STACK_TOP

;Initialize ES for IVT at 0000H
MOV AX, 00H
MOV ES, AX

; YOUR CODE HERE ...

;initialize CWR, B-out, A-out, C low -in
MOV DX, 0083H
MOV AX, 0081H
OUT DX, AL


CLI ;clear interrupt flag
; Setup INT0

MOV DX, 0FF38H ; position of INT0 Control Register

MOV AX, 00H ;  cascade disabled, edge triggered, special fully nested mode disabled,


OUT DX, AL ; initialise INT0 with my settings

;set up INT0 interrupt vector
MOV DI, 30H ; base address of int 0 vector to DI
MOV WORD PTR ES:[DI], OFFSET OPERATE ; IP
MOV WORD PTR ES:[DI+2], SEG OPERATE ; cs
STI

MOV CURRENT, 00H
MOV TARGET, 00H
MOV DIR, 00H
MOV DIFFER, 00H
READY:

MOV AL, CURRENT
XOR AH, AH
MOV BH, 0AH
DIV BH 
SHL AL, 1
SHL AL, 1
SHL AL, 1
SHL AL, 1
ADD AL, AH
MOV DX, 0081H
OUT DX, AL



MOV BL, DIR ; check direction
CMP BL, 01H ; down?
JE MOVE_DOWN
CMP BL, 02H ; up?
JE MOVE_UP
; else stay
JMP READY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; go up 
MOVE_UP:
CLI
MOV BL, DIFFER
MOVING_UP:
MOV AL, TARGET
ADD AL, 080H
NOT AL
MOV DX, 0080H
OUT DX, AL

DISPLAY1:
MOV AL, CURRENT
XOR AH, AH
MOV BH, 0AH
DIV BH ;AH holds the remainder, AL holds quotient
SHL AL, 1
SHL AL, 1
SHL AL, 1
SHL AL, 1
ADD AL, AH
MOV DX, 0082H
OUT DX, AL
MOV CX, 08000H ;65535

DELAY1: ;10 PUSH/POP, 2 NOP
PUSH AX ;10 CLOCKS
POP AX ;10 CLOCKS
PUSH AX
POP AX
PUSH AX
POP AX
PUSH AX
POP AX

LOOP DELAY1 
; show my desired at LEDs

MOV AL, TARGET
NOT AL ; active low
MOV DX, 0080H
OUT DX, AL


MOV CX, 08000H ;65535
DELAY2: ;10 PUSH/POP, 2 NOP
PUSH AX ;10 CLOCKS
POP AX ;10 CLOCKS
PUSH AX
POP AX
PUSH AX
POP AX
PUSH AX
POP AX
LOOP DELAY2 

MOV AL, CURRENT ;increment storey
INC AL
MOV CURRENT, AL
DEC BL
CMP BL, 00H
JNE MOVING_UP
MOV DIR, 00H
MOV DIFFER, 00H
STI
JMP READY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;down
MOVE_DOWN:
CLI
MOV BL, DIFFER
MOVING_DOWN:
MOV AL, TARGET
ADD AL, 040H
NOT AL
MOV DX, 0080H
OUT DX, AL

DISP2:
MOV AL, CURRENT
XOR AH, AH
MOV BH, 0AH
DIV BH ;AH holds the remainder, AL holds quotient
SHL AL, 1
SHL AL, 1
SHL AL, 1
SHL AL, 1
ADD AL, AH
MOV DX, 0082H
OUT DX, AL
MOV CX, 08000H ;65535
DELAY3: ;10 PUSH/POP, 2 NOP
PUSH AX ;10 CLOCKS
POP AX ;10 CLOCKS
PUSH AX
POP AX
PUSH AX
POP AX
PUSH AX
POP AX
LOOP DELAY3 ;6/16 CLOCKS


MOV AL, TARGET
NOT AL
MOV DX, 0080H
OUT DX, AL
MOV CX, 08000H ;65535
DELAY4: ;10 PUSH/POP, 2 NOP
PUSH AX ;10 CLOCKS
POP AX ;10 CLOCKS
PUSH AX
POP AX
PUSH AX
POP AX
PUSH AX
POP AX
LOOP DELAY4 ;6/16 CLOCKs
MOV AL, CURRENT ;decrement current level
DEC AL
MOV CURRENT, AL
DEC BL
CMP BL, 00H
JNE MOVING_DOWN
MOV DIR, 00H
MOV DIFFER, 00H
STI
JMP READY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read inputs

OPERATE:
PUSH AX
PUSH BX
PUSH CX
PUSH DX
CLI
MOV DX, 0082H
IN AL, DX

AND AX, 0FH ;last 4 bits 0000 1111
MOV TARGET, AL
MOV BL, CURRENT
CMP AL, BL
; go up?
JA SET_UP ; move up
;else
CMP AL, BL
JB SET_DOWN ;AL<BL, go down
; AL = BL
JMP DONE

SET_UP:
;set DIR = 2
MOV DIR, 02H
SUB AL, BL
MOV DIFFER, AL
JMP DONE

SET_DOWN:
;set DIR = 1
MOV DIR, 01H
SUB BL, AL
MOV DIFFER, BL
; JMP DONE

DONE:
;  EOI call
MOV DX, 0FF22H ; address of EOI register
MOV AX, 12D ; my interrupt type number is 12
OUT DX, AL
POP DX
POP CX
POP BX
POP AX
STI
IRET

CODE_SEG ENDS
END