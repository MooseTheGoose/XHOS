BITS 16
ORG 0x7C00


JMP 0:boot_entry

%define BOOT_DRIVE_NO 0x80
boot_entry:
  XOR AX, AX
  MOV ES, AX
  MOV DS, AX
  MOV SS, AX
  MOV SP, 0x7C00 ; Place SP at first sector location
  MOV AH, 2
  MOV AL, 63
  MOV CH, 0
  MOV CL, 2
  MOV DH, 0
  MOV DL, BOOT_DRIVE_NO
  MOV BX, 0x7E00 ; Read from disk ahead of first sector end
  INT 0x13
  JC boot_entry
  JMP boot_main
 

; Fix up MBR footer in utility program
mbr_footer:
  TIMES 510 - ($ - $$) db 0x00
  DB 0x55
  DB 0xAA

boot_main:
  MOV AX, 0x800 ; Use 0x8000 - 0x17FFF as a scratch area for parsing ISO files
  MOV DS, AX
  MOV AX, 4
  XOR BX, BX
  MOV DX, 64
  MOV SI, 0x8000
  CALL read_iso
  
hang:
  JMP hang
  
; AX = Number of blocks
; DS:BX = Buffer address
; DX = LBA number
; DS:SI = Disk address packet
; All registers are non-volatile
read_iso:
  PUSH AX
  PUSH DX
  
  MOV BYTE [SI], 16
  MOV BYTE [SI + 1], 0
  MOV WORD [SI + 2], AX
  MOV WORD [SI + 4], BX
  MOV WORD [SI + 6], DS
  MOV WORD [SI + 8], DX
  MOV WORD [SI + 10], 0
  MOV WORD [SI + 12], 0
  MOV WORD [SI + 14], 0

.try_read:
  MOV AH, 42
  MOV DL, BOOT_DRIVE_NO
  INT 0x13
  JC .try_read
  
  POP DX
  POP AX  
  RET

boot_excess:
  TIMES 0x8000 - ($ - $$) db 0x00
