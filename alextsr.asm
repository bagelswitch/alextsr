; Video mode TSR for Bell Alex v0.01 - by: Nate Cohen, 2025
align 0x01, db 0x90     	; Defines alignment.
bits 16                 	; Defines the data size used by this program.
org 0x0100              	; Indicates that all relative pointers to data are moved forward by 0x0100 bytes.

REDIRECTED_FROM equ 0x09  	; Defines the interrupt to be redirected.
REDIRECTED_TO equ 0xFF    	; Defines the redirected interrupt's new vector.
PSP_ADDRESS equ 0x9999		; variable to hold pre-resident segment address

jmp near Main             	; Jumps to the main entry point.

TSR:
pusha                     	; Saves the registers.
push ds                   	;
push es                   	;

push cs                   	; Restores the data segment register.
pop ds                    	;

mov word bx, [0x0000]    	; Skips everything if either the critical error or InDOS flag are set.
mov word es, [0x0000]    	;
es                              ;
cmp byte [bx - 0x01], 0x00      ;
jne Done                        ;
es                              ;
cmp byte [bx], 0x00             ;
jne Done                        ;

in al, 0x60             	; Check if Ctrl-Alt-/ is being pressed. If not, done.
cmp al, 0x35            	;
jne Done                	;
mov ax, 0x0040			;
mov ds, ax			;
mov al, [ds: 0x17]		;
and al, 0x0c			;
cmp al, 0x0c			;
jne Done			;

mov     ax, 0xb800		; copy VRAM from B800 to temp memory reserved by TSR
mov     es, ax			;
mov	si, 0x0000		;
mov	ax, [PSP_ADDRESS]	;
mov	ds, ax			;
mov	di, EndTSR		;
add	di, 0x000f		;
mov     cx, 0x1000		;
Vramtotemp:			;
mov 	al, [es: si]		;
inc	si			;
mov	[ds: di], al		;
inc	di			;
loop	Vramtotemp		;

mov  ax, 0x0040       		; BIOS.SetVideoMode 80x25 text
mov  ds, ax			;
mov  [ds: 0x87], byte 0xfd	;
mov  [ds: 0x10], byte 0xcf	;
mov  [ds: 0x10], byte 0x20	;
mov  ah, 0x00			;
mov  al, 0x03			;
int  10h			;

mov     ax, 0xb800		; copy temp memory reserved by TSR to VRAM at B800 
mov     es, ax			;
mov	di, 0x0000		;
mov	ax, [PSP_ADDRESS]	;
mov	ds, ax			;
mov	si, EndTSR		;
add	si, 0x000f		;
mov     cx, 0x1000		;
Temptovram:			;
mov 	al, [ds: si]		;
inc	si			;
mov	[es: di], al		;
inc	di			;
loop	Temptovram		;

Done:
pop es                    	; Restores the registers.
pop ds                    	;
popa                      	;
int REDIRECTED_TO         	; Calls the redirected interrupt.
iret                      	; Returns.
EndTSR:				;

Main:
mov ah, 0x09              	; Displays the TSR "start" message.
mov dx, TSR_Start_Msg     	;
int 0x21                  	;

mov ah, 0x62 			; Call INT 21h function 62h (Get PSP) to store segment address
mov al, 0x00			;
int 0x21         		; 
mov [PSP_ADDRESS], bx		;

mov ah, 0x34              	; Retrieves the address of the critical error and InDOS flags.
int 0x21                  	;
mov [0x0000], bx          	;
mov [0x0000], es          	;

mov ah, 0x35              	; Retrieves vector the vector for the interrupt to be redirected.
mov al, REDIRECTED_FROM   	;
int 0x21                  	;

mov dx, bx                	; Places the retrieved vector at another interrupt.
push es                   	;
pop ds                    	;
mov ah, 0x25              	;
mov al, REDIRECTED_TO     	;
int 0x21                  	;

push cs                   	; Sets this TSR's interrupt vector.
pop ds                    	;
mov dx, TSR               	;
mov ah, 0x25              	;
mov al, REDIRECTED_FROM   	;
int 0x21                  	;

mov ah, 0x09              	; Displays the TSR "activated" message.
mov dx, TSR_Activated_Msg 	;
int 0x21                  	;

push cs				; Terminates and stays resident.
pop ds				;
mov ax, 0x3100            	; 
mov dx, EndTSR            	;
add dx, 0x1000            	; add 4k for temp video ram storage
add dx, 0x000F            	;
shr dx, 0x0004            	;
int 0x21                  	;

TSR_Activated_Msg DB "TSR activated", 0x0D, 0x0A, "$"
TSR_Start_Msg DB "Video mode TSR for Bell Alex v0.01 - by: Nate Cohen, 2025", 0x0D, 0x0A, "Ctrl+Alt+/ forces Video mode 03h (co80)", 0x0D, 0x0A, "$"