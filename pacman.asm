.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "pacman",0
area_width EQU 540
area_height EQU 360
area DD 0
x dd 0
y dd 0


counter DD 0 ; numara evenimentele de tip timer
movctr dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

var1 EQU 4
var2 EQU 8


symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

include models.inc 
include map.inc
model_W EQU 20
model_H EQU 20
pacman_XY DD 260,280

red_XY DD 260, 120
blue_XY DD 260, 140
pink_XY DD 300,120
yellow_XY DD 220, 140
red_mov_dir dd 1
blue_mov_dir dd 3
pink_mov_dir dd 4
orange_mov_dir dd 2
red_dir_vec db 0,0,0,0
blue_dir_vec db 0,0,0,0
pink_dir_vec db 0,0,0,0
orange_dir_vec db 0,0,0,0

direction db 1,1,1,1
dir_mdl dd 0; 5-> right, 6 -> left, 7 -> up, 8 -> down 
ghettoW equ 27
ghettoH equ 18

ghetto	DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		DB 7,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,9
		DB 8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,8
		DB 8,1,7,10,9,1,4,10,6,1,4,10,10,10,10,10,6,1,7,10,9,1,7,10,9,1,8
		DB 8,1,8,0,8,1,1,1,1,1,1,1,1,1,1,1,1,1,8,0,8,1,8,0,8,1,8
		DB 8,1,8,0,8,2,7,10,9,1,7,10,10,0,10,10,9,1,8,0,8,2,8,0,8,1,8
		DB 8,1,5,10,3,1,8,0,8,1,8,0,0,0,0,0,0,1,8,0,8,1,8,0,8,1,8
		DB 8,1,1,1,1,1,8,0,8,1,0,0,0,0,0,0,8,1,8,0,8,1,8,0,8,1,8
		DB 8,1,4,10,6,1,5,10,3,1,5,10,10,0,10,10,3,1,5,10,3,1,5,10,3,1,8
		DB 8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,8
		DB 8,1,7,10,10,10,9,1,13,1,4,10,10,14,10,10,6,1,13,1,7,10,10,10,9,1,8
		DB 8,1,8,0,0,0,8,1,8,1,1,1,1,8,1,1,1,1,8,1,8,0,0,0,8,1,8
		DB 8,1,8,0,0,0,8,1,8,1,1,1,1,8,1,1,1,1,8,1,8,0,0,0,8,1,8
		DB 8,1,8,0,0,0,8,1,15,10,10,6,2,12,2,4,10,10,16,1,8,0,0,0,8,1,8
		DB 8,1,8,0,0,0,8,1,8,1,1,1,1,0,1,1,1,1,8,1,8,0,0,0,8,1,8
		DB 8,1,5,10,10,10,3,1,12,1,4,10,10,10,10,10,6,1,12,1,5,10,10,10,3,1,8
		DB 8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,8
		DB 5,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,3

score dd 0
lives dd 3
pwr_ctr dd 0
ghetto_ghost_coord dd 60,0,0,0 ;red blue pink yellow
ghost_dir db 0,2,3,1
sss db 0
;ghost_lives db 1,1,1,1

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, 0
	jl make_space
	cmp eax, 9
	jg make_space
	;sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function for drawing characters;
;arg1 - drawing area pointer
;arg2 - model type --> 0 is pacman, 1 is red ghost, 2 is blue ghost, 3 is pink ghost, 4 is yellow ghost, 5 is second pacman 
;uses already defined constants: model_w, model_H and variables model_x and model_y
;var1 - x, var2 - y
make_model proc
	push ebp
	mov ebp, esp
	pusha
	
	lea esi, models
	mov eax, [ebp + arg2] ;which model to print
	mov ebx, model_H
	mul ebx
	mov ebx, model_W
	mul ebx
	;shl eax, 2
	add esi, eax ; now esi points at the model matrix beginning
	
	;choose x,y according to model type
	sub esp, 8
	mov eax, [ebp + arg2] 
	cmp eax, 0
	je pmnxy
	cmp eax, 5
	jge pmnxy 
	cmp eax,1
	je redxy
	cmp eax,2
	je bluexy
	cmp eax,3
	je pinkxy
	jmp yellowxy
	
	pmnxy: 
	mov ecx, pacman_XY[0]
	mov [ebp-var1], ecx
	mov ecx, pacman_XY[4]
	mov [ebp-var2], ecx
	jmp after_color

	redxy:
	mov ecx, red_XY[0]
	mov [ebp-var1], ecx
	mov ecx, red_XY[4]
	mov [ebp-var2], ecx
	jmp after_color
	
	bluexy:
	mov ecx, blue_XY[0]
	mov [ebp-var1], ecx
	mov ecx, blue_XY[4]
	mov [ebp-var2], ecx
	jmp after_color
	
	pinkxy:
	mov ecx, pink_XY[0]
	mov [ebp-var1], ecx
	mov ecx, pink_XY[4]
	mov [ebp-var2], ecx
	jmp after_color
	
	yellowxy:
	mov ecx, yellow_XY[0]
	mov [ebp-var1], ecx
	mov ecx, yellow_XY[4]
	mov [ebp-var2], ecx
	
	after_color:
	mov ecx, model_H
	model_rows:
	mov edi, [ebp + arg1]; pointer to drawing area
	mov eax, [ebp-var2] 
	add eax, model_H
	sub eax, ecx
	mov ebx, area_width 
	mul ebx
	add eax, [ebp-var1]
	shl eax, 2
	add edi, eax 
	push ecx
	mov ecx, model_W
	model_columns:
	;color check 
	xor edx, edx
	mov dl, byte ptr [esi]
	cmp dl, 1; pacman 
	jne nu_pacman
	mov dword ptr [edi], 0f9fc21h ;yellow pacman
	jmp fnl
	nu_pacman:
	cmp dl, 2;red
	jne nu_red
	mov dword ptr [edi], 0f00722h
	jmp fnl
	nu_red:
	cmp dl, 3;blue 
	jne nu_blue
	mov dword ptr [edi], 0760f0h
	jmp fnl 
	nu_blue:
	cmp dl, 4; pink 
	jne nu_pink
	mov dword ptr [edi], 0e81ee1h
	jmp fnl 
	nu_pink:
	cmp dl, 5; orange
	jne nu_yellow
	mov dword ptr [edi], 0f7801eh
	jmp fnl
	nu_yellow:
	mov dword ptr [edi],0
	
	fnl:
	inc esi  
	add edi, 4
	loop model_columns
	pop ecx
	loop model_rows
	
	add esp, 8
	popa
	mov esp, ebp
	pop ebp
	ret
make_model endp

make_model_macro macro area, n
	push n
	push area
	call make_model
	add esp, 8
endm 

formula_ind macro x,y
	push eax
	mov ebx, y
	mov eax, area_width
	imul ebx, eax
	mov eax, x
	add ebx, eax 
	shl ebx, 2
	pop eax
endm 


; pacman_XY DD 20,40
; red_XY DD 220, 120
; blue_XY DD 300, 120
; pink_XY DD 220, 140
; yellow_XY DD 300, 140
compute_ghetto_ghost_coord proc
	pusha
	
	mov eax, red_XY[4]
	mov ebx, 20
	xor edx, edx
	div ebx
	mov ebx, ghettoW
	mul ebx
	mov ebx, eax
	mov eax, red_XY[0]
	mov ecx, 20
	div ecx 
	add ebx, eax 
	mov ghetto_ghost_coord[0],ebx
	;log ghetto_ghost_coord[0]
	;log ebx 
	mov eax, blue_XY[4]
	mov ebx, 20
	xor edx, edx
	div ebx
	mov ebx, ghettoW
	mul ebx
	mov ebx, eax
	mov eax, blue_XY[0]
	mov ecx, 20
	div ecx 
	add ebx, eax 
	mov ghetto_ghost_coord[4],ebx


	mov eax, pink_XY[4]
	mov ebx, 20
	xor edx, edx
	div ebx
	mov ebx, ghettoW
	mul ebx
	mov ebx, eax
	mov eax, pink_XY[0]
	mov ecx, 20
	div ecx 
	add ebx, eax 
	mov ghetto_ghost_coord[8],ebx


	mov eax, yellow_XY[4]
	mov ebx, 20
	xor edx, edx
	div ebx
	mov ebx, ghettoW
	mul ebx
	mov ebx, eax
	mov eax, yellow_XY[0]
	mov ecx, 20
	div ecx 
	add ebx, eax 
	mov ghetto_ghost_coord[12],ebx
	

	popa 
	ret
compute_ghetto_ghost_coord endp
; arg1 - x
; arg2 - y
; arg3 - direction vector (0 up, 1 down, 2 left, 4 right)
; arg4 - draw area
collision_check proc
	push ebp
	mov ebp, esp
	pusha
	
	;init dir vec
	mov esi, [ebp+arg3]; need offset
	mov al, 1 
	mov byte ptr[esi], al 
	mov byte ptr[esi+1], al
	mov byte ptr[esi+2], al
	mov byte ptr[esi+3], al
	
	mov eax, [ebp + arg2]
	;sub eax, 2
	mov ebx, 20
	xor edx, edx
	div ebx 
	mov ebx, ghettoW
	mul ebx
	mov ebx, eax
	mov eax, [ebp + arg1]
	;sub eax, 2
	mov ecx, 20
	div ecx 
	add ebx, eax; ebx are ind in mat ghetto a lui pacman
	

	mov al, ghetto[ebx-1];stanga
	cmp al,  2
	jle chk_rhgt
	mov byte ptr[esi+1], 0
	; mov movctr, -1
	chk_rhgt:
	mov al, ghetto[ebx+1]
	cmp al,  2
	jle chk_up
	mov byte ptr[esi+3], 0
	; mov movctr, -1
	chk_up: 
	mov al, ghetto[ebx-ghettoW]
	cmp al,  2
	jle chk_dwn
	mov byte ptr[esi], 0
	; mov movctr, -1
	chk_dwn:
	mov al, ghetto[ebx+ghettoW]
	cmp al,  2
	jle cnmv
	mov byte ptr[esi+2], 0
	; mov movctr, -1
	cnmv:
	
	mov al, ghetto[ebx]
	cmp al, 1
	jne chk_pwr_up
	mov ghetto[ebx], 0
	add score, 10
	inc sss
	chk_pwr_up: 
	cmp al, 2
	jne chk_ghst
	mov ghetto[ebx], 0
	add score, 50
	inc sss
	mov pwr_ctr,75
	
	chk_ghst:
	
	call compute_ghetto_ghost_coord
	 
	mov ecx, 3
	pusha
	popa
	kill_or_be_killed:
	cmp ebx, ghetto_ghost_coord[ecx*4]
	jne safe
	cmp pwr_ctr, 0
	jle be_killed
	add score, 100
	
	cmp ecx, 0
	jg not_red
	mov red_XY[0], 220
	mov red_XY[4], 120
	jmp safe
	not_red:

	cmp ecx, 1
	jg not_blue
	mov blue_XY[0], 300
	mov blue_XY[4], 120
	jmp safe
	not_blue:
	
	cmp ecx, 2
	jg not_pink
	mov pink_XY[0], 220
	mov pink_XY[4], 140
	jmp safe
	not_pink:
	
	cmp ecx, 3
	jg not_yellow
	mov yellow_XY[0], 20
	mov yellow_XY[4], 40
	not_yellow:
	
	jmp safe 
	be_killed:
	dec lives
	mov pacman_XY[0], 260
	mov pacman_XY[4], 280
	safe:
	dec ecx
	cmp ecx, 0
	jge kill_or_be_killed	
	
	popa
	mov esp, ebp
	pop ebp
	ret
collision_check endp

ghost_movement_macro macro ghostXY, gh_mov_dir, dir_vec, gh_id

	push gh_id
	push offset dir_vec
	push gh_mov_dir
	push offset ghostXY
	call ghost_movement
	add esp, 16

endm
;arg1 - ghostXY -> offset
;arg2 - ghost_mov_dir (0 is up, 1 is left, 2 is down, 3 is right)
;arg3 - direction vector for ghost
;arg4 - ghost id( 0 is red, 1 is blue, 2 is pink, 3 is orange)
ghost_movement proc
	push ebp
	mov ebp, esp
	pusha

	;init dir vec
	mov esi, [ebp+arg3]; need offset
	mov al, 1
	mov byte ptr[esi], al 
	mov byte ptr[esi+1], al
	mov byte ptr[esi+2], al
	mov byte ptr[esi+3], al
	
	
	mov ecx, [ebp + arg4]
	mov ebx, ghetto_ghost_coord[ecx * 4]
	
	sub esp, 4
	mov eax, 0
	
	
	mov al, ghetto[ebx-1];stanga
	cmp al,  2
	jle gh_chk_rhgt
	mov byte ptr[esi+1], 0
	
	
	gh_chk_rhgt:
	mov al, ghetto[ebx+1]
	cmp al,  2
	jle gh_chk_up
	mov byte ptr[esi+3], 0
	
	gh_chk_up: 
	mov al, ghetto[ebx-ghettoW]
	cmp al,  2
	jle gh_chk_dwn
	mov byte ptr[esi], 0
	
	gh_chk_dwn:
	mov al, ghetto[ebx+ghettoW]
	cmp al,  2
	jle gh_cnmv
	mov byte ptr[esi+2], 0
	
	
	gh_cnmv:
	rdtsc
	xor edx, edx
	mov ebx, 4
	div ebx
	xor ebx, ebx 
	mov bl, byte ptr [esi+edx]
	cmp ebx,0 
	jz gh_cnmv
	inc edx 
	mov eax, edx 
	mul ebx 
	
	
	no_collisions:
	mov esi, [ebp+arg1];GhostXY
	mov [ebp + arg2], eax
	cmp eax, 1
	jne nup
	sub dword ptr[esi+4], 20 
	nup:
	cmp eax, 2
	jne nlft
	sub dword ptr[esi], 20
	
	nlft:
	cmp eax, 3
	jne ndwn
	add dword ptr[esi+4], 20
	ndwn:
	cmp eax, 4
	jne nrt
	add dword ptr[esi], 20
	nrt:
	;mov byte ptr[esi+3], 0
	add esp, 4
	popa
	mov esp, ebp
	pop ebp
	ret
ghost_movement endp
cc macro x,y,dir_vec,drarea
	push drarea
	push dir_vec
	push y
	push x
	call collision_check
	add esp, 16
endm

make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

pwr_tmr proc 
	pusha
	
	cmp pwr_ctr, 0
	je no_pwr
	
	make_text_macro 'P', area, 410, 0
	make_text_macro 'O', area, 420, 0
	make_text_macro 'W', area, 430, 0
	make_text_macro 'E', area, 440, 0
	make_text_macro 'R', area, 450, 0
	make_text_macro 'U', area, 460, 0
	make_text_macro 'P', area, 470, 0
	
	mov eax, pwr_ctr
	mov ebx, 10
	xor edx,edx
	div ebx

	make_text_macro eax, area, 500, 0
	make_text_macro edx, area, 510, 0
	
	dec pwr_ctr
	
	no_pwr:
	
	popa
	ret
pwr_tmr endp

show_lives proc
	pusha
	
	make_text_macro 'S', area, 210, 0
	make_text_macro 'C', area, 220, 0
	make_text_macro 'O', area, 230, 0
	make_text_macro 'R', area, 240, 0
	make_text_macro 'E', area, 250, 0
	
	mov ebx, 10
	mov eax, score
	mov edx, 0
	div ebx
	;add edx, '0'
	make_text_macro edx, area, 300, 0
	mov edx, 0
	div ebx
	;add edx, '0'
	make_text_macro edx, area, 290, 0
	mov edx, 0
	div ebx
	;add edx, '0'
	make_text_macro edx, area, 280, 0
	mov edx, 0
	div ebx
	;add edx, '0'
	make_text_macro edx, area, 270, 0
	
	make_text_macro 'L', area, 0, 0
	make_text_macro 'I', area, 10, 0
	make_text_macro 'F', area, 20, 0
	make_text_macro 'E', area, 30, 0
	
	cmp lives, 0
	je dead
	mov ecx, lives
	mov edx, 50
	prt:
	make_text_macro 'O', area, edx, 0
	
	add edx, 10
	loop prt
	
	dead:
	
	popa 
	ret
show_lives endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; un macro ca sa apelam mai usor desenarea simbolului


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x ( in caz ca se apasa tasta- x are ascii pt tasta aia)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	cmp lives, 0
	jne alive
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	make_text_macro 'G', area, 180, 180
	make_text_macro 'A', area, 200, 180
	make_text_macro 'M', area, 220, 180
	make_text_macro 'E', area, 240, 180
	make_text_macro 'O', area, 280, 180
	make_text_macro 'V', area, 300, 180
	make_text_macro 'E', area, 320, 180
	make_text_macro 'R', area, 340, 180
	;pop eax
	jmp final_draw
	alive:
	cmp sss,178
	jne still_playing
	make_text_macro 'Y', area, 180, 180
	make_text_macro 'O', area, 200, 180
	make_text_macro 'U', area, 220, 180
	make_text_macro 'W', area, 280, 180
	make_text_macro 'O', area, 300, 180
	make_text_macro 'N', area, 320, 180
	;pop eax
	jmp final_draw
	still_playing:
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz clrmov ; nu s-a efectuat click pe nimic
	push eax
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	pop eax
	cmp eax, 3
	jz movement	
	
evt_click:
	jmp afisare_litere
	
	
movement:

	mov eax, movctr
	mov ebx, 5
	xor edx, edx 
	div ebx 
	cmp edx, 0
	jne afisare_litere 
	ghost_movement_macro yellow_XY, orange_mov_dir, orange_dir_vec, 3
	cc pacman_XY[0], pacman_XY[4],offset direction, area
	ghost_movement_macro red_XY, red_mov_dir, red_dir_vec, 0
	ghost_movement_macro blue_XY, blue_mov_dir, blue_dir_vec, 1
	ghost_movement_macro pink_XY, pink_mov_dir, pink_dir_vec, 2
	mov eax, [ebp+arg2]
	cmp eax, 'A'
	je left
	cmp eax, 'S'
	je down
	cmp eax, 'D'
	je right
	cmp eax, 'W'
	jne clrmov
	up:
	cmp byte ptr[direction], 0
	mov dir_mdl, 7
	;int 3
	je clrmov
	sub pacman_XY[4], 20
	inc movctr
	jmp afisare_litere
	right:
	cmp byte ptr[direction+3], 0
	mov dir_mdl, 5
	je clrmov
	add pacman_XY[0], 20
	inc movctr
	jmp afisare_litere
	left:
	cmp byte ptr[direction+1], 0
	mov dir_mdl, 6
	je clrmov 
	sub pacman_XY[0], 20
	inc movctr
	jmp afisare_litere
	down:
	cmp byte ptr[direction+2], 0
	mov dir_mdl, 8
	je clrmov
	add pacman_XY[4], 20
	inc movctr
	jmp afisare_litere
	
clrmov:
	mov movctr, -1
	
evt_timer:
	
	inc counter
	
afisare_litere:
	
	inc movctr
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	
	
	mov ecx, 0
	map1:	
	mov edx, 0
	mpa:
	mov ebx, ecx
	imul ebx, ghettoW
	lea esi, map
	add ebx, edx
	xor eax, eax
	mov al, byte ptr ghetto[ebx]
	mov ebx, 400
	push edx 
	mul ebx 
	pop edx 
	add esi, eax 
	push ecx
	push edx
	mov ebx, 20
	imul ecx, ebx
	imul edx, ebx 
	mov y, ecx
	mov x, edx
	mov ecx, model_H
	;ebx si eax sunt libere
	map2:
	mov edi, area
	mov eax, y 
	add eax, model_H
	sub eax, ecx
	mov ebx, area_width 
	mul ebx
	add eax, x
	shl eax, 2
	add edi, eax 
	push ecx
	mov ecx, model_W
	map3:
	mov dl, byte ptr [esi]	
	cmp dl, 0
	jne nu_negru
	mov edx, 0
	jmp clr
	nu_negru:
	cmp dl, 8
	jne albatrsu
	mov edx,0FFFFFFh
	jmp clr 
	albatrsu:
	mov edx, 00000FFh ;map color
	clr:
	mov dword ptr [edi], edx 
	add edi, 4
	inc esi 
	loop map3
	pop ecx
	loop map2
	pop edx
	pop ecx
	inc edx
	cmp edx, ghettoW
	jnz mpa
	inc ecx
	cmp ecx, ghettoH
	jne map1
	
	make_model_macro area, 1
	make_model_macro area, 2
	make_model_macro area, 3
	make_model_macro area, 4
	mov eax, counter
	clc
	shr eax, 1
	jc secmdl
	make_model_macro area, 0
	jmp frstmdl
	secmdl: 
	make_model_macro area, dir_mdl
	frstmdl:
	call pwr_tmr 
	call show_lives

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	;int 3
	mov area, eax
	; apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
