.model large
.stack 100h
.data
point struct
x dw ?
y dw ?
z dw ?
point ends
timed dw 0FFFFh; used to speed up or slow down game loop doesnt seem to work
temp dw 0
p1 point <> ; start point
p2 point <> ; end point
health db 7 ; hitpoints
can1h db 7
can2h db 7
score db 0
botdir db 2 ; 1 means right 2 means left redundant now
robot point <> ; coordinates and color
bullet1 point<>
c1dir db 1 ; 1 means right 2 means left
canon1 point <> ; coordintes and color
bullet2 point<> ; ammo for cannons one each for phase one
c2dir db 2 ; direction of travel
canon2 point <> ;
botasci db" /~~~\ " ;was 10x15
 	db" |O`O| " ; is now 4x7
 	db" | ^ | "
 	db" |~~~| "
canasci	db" #0|0# "; is now 3x7
	db" \#|#/ "
	db"  \|/  "; was 5X11
coalman db"PLAYER"
canstr1 db"CANNON1"
canstr2 db"CANNON2"
healthb db"||||||||"
scrstr db"Score:"
robofire point 5 Dup(<>) ; 5 bullets max at a time
mouseoldv dw 0
mork db 0 ; mouse or key board ?
pause db 0 ; game paused or not ?
interface0 db "welcome to cannon wars","$"
interface1 db "press m to use mouse","$"
interface2 db "press k to use keyboard","$"
interface3 db "click or space to fire","$"

mode db 0
.code

main proc
mov ax,@data
mov ds,ax
mov ah,0h
mov al,13h
int 10h
mov bullet1.z,0; 1 menas bullet is in mid air
mov bullet2.z,0; zero means bullet is out of air
mov bullet1.x,15;
mov bullet1.y,10;
mov bullet2.x,15;
mov bullet2.y,10;
mov robot.y,20; starting values
mov robot.x,13
mov robot.z,1
mov canon1.x,1
mov canon1.y,1
mov canon1.z,4
mov canon2.x,10
mov canon2.y,1
mov canon2.z,2
mov si,offset robofire
add si,4 
mov cx,5
mov ax,0
makezero:
mov [si],ax
add si,6
loop makezero
call drawconsole 
mov ax,02
int 33h ; hide cursor
mov p1.x,4
mov p1.y,7
mov p1.z,8 
mov p2.x,22 ; columns
mov p2.y,1 ; rows
mov si,offset interface0 ; start printing menu
call printascii
mov p1.x,6
mov p1.y,9
mov p1.z,8 
mov p2.x,20 ; columns
mov p2.y,1 ; rows
mov si,offset interface1
call printascii
mov p1.x,4
mov p1.y,11
mov p1.z,8 
mov p2.x,23 ; columns
mov p2.y,1 ; rows
mov si,offset interface2
call printascii
mov p1.x,4
mov p1.y,13
mov p1.z,8 
mov p2.x,22 ; columns
mov p2.y,1 ; rows
mov si,offset interface3
call printascii ; interface finished
mov ax,0
mov ah,0ch
int 21h ; clear buffer
mov al,0
mov ah,0h
int 16h
mov mode,al; get user choice
maingameloop:
mov ax,0h ; clear buffer
mov ah,0ch
int 21h
mov cx,00h
mov dx,timed
mov ah,86h
int 15h ; calls timer delay
mov ax,0h
mov ah,1
int 16h
cmp al,112
jne keepg1
mov pause,1
keepg1:
mov al,pause
cmp al,0
je keeprolling
checkpausestatus:
mov ax,0 ; clear buffer
mov ah,0ch
int 21h
mov ax,0
int 16h
cmp al,112
jne checkpausestatus
mov pause,0
keeprolling:
mov p1.x,0
mov p1.y,0
mov p1.z,0 ; black color
mov p2.x,319
mov p2.y,199
call drawrectangle
call drawconsole ; builds background
mov si, offset c1dir
call robotmove
mov bl,mode
cmp bl,109 ; m ascii
je moveon
call botcontrolkeyboard
jmp continueexe
moveon:
call botcontrolmouse
continueexe:
mov si,offset bullet1
call drawbullet
mov si,offset canasci
mov ax,canon1.x
mov p1.x,ax
mov ax,canon1.y
mov p1.y,ax
mov ax,canon1.z
mov p1.z,ax
mov p2.x,7; number of columns lenght of bot
mov p2.y,3 ;number of rows
call printascii
mov si,offset canasci
mov ax,canon2.x
mov p1.x,ax
mov ax,canon2.y
mov p1.y,ax
mov ax,canon2.z
mov p1.z,ax
mov p2.x,7; number of columns lenght of bot
mov p2.y,3 ;number of rows
call printascii
mov si,offset botasci
mov ax,robot.x
mov p1.x,ax
mov ax,robot.y
mov p1.y,ax
mov ax,robot.z
mov p1.z,ax
mov p2.x,7; number of columns lenght of bot
mov p2.y,4 ;number of rows
call printascii
mov cx,00h
mov dx,timed
mov ah,86h
int 15h ; calls timer delay
dec timed ; increase speed slowly and steady
jmp maingameloop
jmp endofexe
ret
main endp

bulletphysics proc; si contains address of cannons bullet 
push si
mov di,si 
add di,4 ;z variable
mov bx,[di]
cmp bx,0
je launchprojectile 
sub di,2
mov bx,[di]
inc bx
mov [di],bx
jmp checkedge
launchprojectile:
mov bx,1
mov [di],bx
add di,3
mov bx,[di]; get x coordinate
add bx,3; zero error
mov [si],bx
mov di,si
add di,2
mov bx,4
mov [di],bx; y coordinate
add di,2
mov bx,6
mov [di],bx
checkedge:
mov di,si
add di,2
mov bx,[di]
cmp bx,23
jb endofproc
add di,2
mov bx,0
mov [di],bx
call blip2
endofproc: ; damage detect
pop si
mov di,si 
add di,4
mov bx,[di]
cmp bx,0
je finish
sub di,2
mov bx,[di] ; y coordinate
mov cx,robot.y
cmp bx,cx
jb finish ; bullet above robot
sub di,2
mov bx,[di] ; x coordinate
mov cx,robot.x
inc cx ; zero error
cmp bx,cx
jb finish; bullet to left of robot
add cx,5 ; width of bot
cmp bx,cx
ja finish ; bullet to right of robot
dec health ; touch detected
add di,4
mov dx,0
mov [di],dx ; bullet is out of air
call blip4
finish: 
ret
bulletphysics endp

robbuletp proc
mov si,offset robofire
mov cx,5 ; for loop
add si,4 ; launched or un launched ?
checkinair: ; moves projectiles upwards
mov bx,[si]
cmp bx,0
je continue
sub si,2 ; y coordinate
mov dx,[si]
dec dx
mov [si],dx
add si,2
continue:
add si,6
loop checkinair
mov si ,offset robofire
mov cx,5
add si,4
detectc: ; detects collisions
mov bx,[si]
cmp bx,0 ; visibility 
je continue2  ; si+4
sub si,2 ; y coordinate
mov dx,[si] 
add si,2
cmp dx,2  
ja checkcano  ; si+4
mov bx,0
mov [si],bx; bullet out of scene
push cx
call blip2
pop cx
checkcano: ; detect canons
sub si,2  
mov bx,[si]
add si,2 
cmp bx,4 ;same level as canon
ja continue2  ; si+4
sub si,4 ; x coordinate
mov di, offset canon1
mov ax,[si]
mov bx,[di]
inc bx
add si,4 
cmp ax,bx
jb continue2 ; si+4
add bx,5
cmp ax,bx
ja continue2 ; collided with canon si+4
mov dl,can1h
dec dl
mov can1h,dl
mov dl,score
add dl,10
mov score,dl
push cx
call blip1
pop cx
mov dx,0
mov [si],dx ; make bullet invincible
continue2: ; time to check for 2nd canon
jmp crossover
breakpoint:
jmp detectc
crossover:
mov bx,[si]
cmp bx,0 ; visibility 
je continue22  ; si+4
sub si,2 ; y coordinate
mov dx,[si] 
add si,2
cmp dx,2  
ja checkcano2  ; si+4
mov bx,0
mov [si],bx; bullet out of scene ???
checkcano2: ; detect canons
sub si,2  
mov bx,[si]
add si,2 
cmp bx,4 ;same level as canon
ja continue22  ; si+4
sub si,4 ; x coordinate
mov di, offset canon2
mov ax,[si]
mov bx,[di]
inc bx
add si,4 
cmp ax,bx
jb continue22 ; si+4
add bx,5
cmp ax,bx
ja continue22 ; collided with canon si+4
mov dl,can2h
dec dl
mov can2h,dl
mov dl,score
add dl,10
mov score,dl
push cx
call blip1
pop cx
mov dx,0
mov [si],dx ; make bullet invincible
continue22:
add si,6
loop breakpoint
; check to see if opposing bullets collide and then cancel each otherout
mov si,offset robofire
add si,4 ; visibility
mov cx,5 ; 5 max bullets from robot at a time
iterator1:
mov ax,[si]
cmp ax,0
jne checkcfs
returnpoint:
add si,6
loop iterator1
jmp endofp
checkcfs:
mov di,offset bullet1
add di,4
mov ax,[di]
cmp ax,0
je checkc2f ; +4
sub di,4 ;x of b1
sub si,4 ; x of robot fires 
mov ax,[di]
mov bx,[si]
add si,4
cmp ax,bx
jne checkc2f ;+4
add di,2
sub si,2 ;y coordinates
mov ax,[di]
mov bx,[si]
add si,2
cmp ax,bx
jne checkc2f ; bullets overlapping ie same place +4
mov dl,score
add dl,1
mov score,dl
add di,2 ; visibility
mov dx,0
mov [si],dx
mov [di],dx
checkc2f: ; reapeat for b2
mov di,offset bullet2
add di,4
mov ax,[di]
cmp ax,0
je returnpoint
sub di,4 ;x of b2
sub si,4 ; x of robot fires
mov ax,[di]
mov bx,[si]
add si,4
cmp ax,bx
jne returnpoint
add di,2
sub si,2 ;y coordinates
mov ax,[di]
mov bx,[si]
add si,2
cmp ax,bx
jne returnpoint ; bullets overlapping ie same place
mov dl,score
add dl,1
mov score,dl
call blip3 ; sound
add di,2 ; visibility
mov dx,0
mov [si],dx
mov [di],dx
jmp returnpoint
endofp:
ret
robbuletp endp

drawbullet proc ; si contains bullet, first cover old bullet with spaces then draw new ones
push si
mov si,offset robofire
mov cx,5
firstlop: 
mov di,si
add di,4
mov bx,[di]
cmp bx,0
je endofl1
mov di,si
mov ah,02h
mov dl,byte ptr [di]
add di,2
mov dh,byte ptr [di]
int 10h
mov al,32
mov ah,09
mov bh,0
int 10h ;covered old with spaces
endofl1:
add si,6
loop firstlop
pop si
mov cx,2; two bullets for phase one
iterater:
mov di,si
mov ah,02h
mov dl,byte ptr [di]
add di,2
mov dh,byte ptr [di]
int 10h
mov al,32
mov ah,09
mov bh,0
push cx
mov cx,1
int 10h ;covered old with spaces
call bulletphysics
mov di,si
mov ah,02h
mov dl,byte ptr [di]
add di,2
mov dh,byte ptr [di]
int 10h
mov al,79
mov ah,09
mov bh,0
mov cx,1
int 10h
pop cx
add si,13
loop iterater
call robbuletp
mov cx,5 ;max five bullets for bot
mov si,offset robofire
secondit:
push cx
mov di,si
add di,4
mov bx,[di]
cmp bx,0
je eoflop
mov di,si
mov ah,02h
mov dl,byte ptr [di]
add di,2
mov dh,byte ptr [di]
int 10h
mov al,94
mov ah,09
mov bh,0
mov cx,1
int 10h
eoflop:
add si,6
pop cx
loop secondit
ret
drawbullet endp

drawrectangle proc ; start point p1 till +(end point p2) relative
mov si,0
mov cx,p1.x
mov dx,p1.y
mov ax,p1.z
mov di,0
lop:
mov bx,p2.y
mov ah,0ch
int 10h
inc dx
inc di
cmp di,bx
jne lop
inc p1.x
mov cx,p1.x
mov dx,p1.y
mov ax,p1.z
mov di,0
inc si
mov bx,p2.x
cmp si,bx
jne lop
ret
drawrectangle endp

fireback proc ; check if available bullet slots and fire upwards
mov si,offset robofire
add si,4 
mov cx,5
makezero:
mov ax,[si]
cmp ax,0
je launchatak
add si,6
loop makezero
jmp endofp ; 5 bullets already in air
launchatak:
mov ax,1
mov [si],ax
sub si,4; x coordinate
mov bx,robot.x
add bx,3 ; zero error
mov [si],bx
add si,2; y coordinate
mov bx,robot.y
dec bx
mov [si],bx
endofp:
ret
fireback endp

botcontrolkeyboard proc ; manipulate bot with key board
mov ah,01h
int 16h
cmp ah,4bh
je checkleft
cmp ah,4dh
je checkright
cmp ah,39h
jne endofp
call fireback
jmp endofp
checkleft:
mov ax,robot.x; xcoordinate
cmp ax,1
ja subx
jmp endofp
subx:
dec ax
mov robot.x,ax
jmp endofp
checkright:
mov ax,robot.x; xcoordinate
cmp ax,25
jb addx
jmp endofp
addx:
inc ax
mov robot.x,ax
endofp:
mov ax,0 ; needed to prevent lock ups with movement
mov ah,0ch
int 21h
ret
botcontrolkeyboard endp

botcontrolmouse proc ; manipulate bot with mouse
mov ax,03h
int 33h     ; get mouse info
mov ax,mouseoldv
cmp cx,ax
ja checkright
jb checkleft
jmp endofp
checkleft:
mov ax,robot.x; xcoordinate
cmp ax,1
ja subx
jmp endofp
subx:
dec ax
mov robot.x,ax
jmp endofp
checkright:
mov ax,robot.x; xcoordinate
cmp ax,25
jb addx
jmp endofp
addx:
inc ax
mov robot.x,ax
endofp:
cmp bx,0
je exit
call fireback
exit:
mov cx,robot.x
mov mouseoldv,cx
mov dx,100
mov ax,04
int 33h
ret
botcontrolmouse endp

robotmove proc; si has address of direction next address is of point(coordinates) followed c2 in same order generic code
mov cx,2 ; 2 times for phase1
mover:
mov al,[si]; direction of robot
cmp al,1 ;right ?
je checkright ; check right for clear path and inc val
jmp checkleft ; check left for clear path and dec val
returnpoint:
loop mover
jmp endofpro
checkright:
mov di,si
inc di ; x axis location
mov bx,[di]
cmp bx,24
ja reversedir ; change direction of travel
inc bx
mov [di],bx
jmp incsival; for next bot and return to loop
reversedir:
mov dl,[si]
cmp dl,1
je puttwo
mov dl,1
mov [si],dl
jmp incsival
puttwo:
mov dl,2
mov [si],dl
jmp incsival
checkleft:
mov di,si
inc di ; x axis location
mov bx,[di]
cmp bx,2
jb reversedir ; change direction of travel
dec bx
mov [di],bx
jmp incsival; for next bot and return to loop
incsival:
add si,13
jmp returnpoint
endofpro:
ret
robotmove endp

printascii proc ;prints asci pointed to by si at p1&color, p2 times(rxc) 
mov dh,byte ptr p1.y
mov dl,byte ptr p1.x
mov di,p2.x;
printinglop:
mov bh,0
mov ah,02
int 10h
mov ah,0Eh
mov al,[si]
mov bh,0
mov bl,byte ptr p1.z
mov cx,0
int 10h
inc dl
dec di
inc si
cmp di,0
ja printinglop
mov dl,byte ptr p1.x
mov di,p2.x;
inc dh
mov ax,p2.y
dec ax
mov p2.y,ax
cmp ax,0
ja printinglop
ret
printascii endp

drawconsole proc
mov p1.x,0
mov p1.y,0
mov p1.z,9 ; light blue color
mov p2.x,320
mov p2.y,5
call drawrectangle ; top bar
mov p1.x,0
mov p1.y,5
mov p2.x,5
mov p2.y,195
call drawrectangle ; left bar
mov p1.x,5
mov p1.y,195
mov p2.x,315
mov p2.y,5 
call drawrectangle ; bottom bar
mov p1.x,260
mov p1.y,5
mov p2.x,60
mov p2.y,190
call drawrectangle ; right bar
mov si,offset coalman ;prints asci pointed to by si at p1&color, p2 times(rxc)
mov p1.x,33
mov p1.y,5
mov p1.z,15
mov p2.x,6
mov p2.y,1
call printascii
mov si,offset healthb ;
mov p1.x,33
mov p1.y,7
mov p1.z,15
mov dx,0
mov dl,health
mov p2.x,dx ; hp of player
mov p2.y,1
call printascii
mov si,offset canstr1 
mov p1.x,33
mov p1.y,9
mov p1.z,15
mov p2.x,7
mov p2.y,1
call printascii
mov si,offset healthb ;
mov p1.x,33
mov p1.y,11
mov p1.z,15
mov dx,0
mov dl,can1h
mov p2.x,dx ; replace 7 with hp of cannon1
mov p2.y,1
call printascii
mov si,offset canstr2
mov p1.x,33
mov p1.y,13
mov p1.z,15
mov p2.x,7
mov p2.y,1
call printascii
mov si,offset healthb ;
mov p1.x,33
mov p1.y,15
mov p1.z,15
mov dx,0
mov dl,can2h
mov p2.x,dx ; can2
mov p2.y,1
call printascii
mov si,offset scrstr ;
mov p1.x,33
mov p1.y,17
mov p1.z,15
mov p2.x,6 
mov p2.y,1
call printascii ; add code here to print multi digit number on screen for score
mov ax,0
mov al,score
mov cx,0
stacker:
mov bl,10
div bl
mov dx,0
mov dl,ah
push dx
inc cx
mov ah,0
cmp al,0
jne stacker
mov si,cx
mov dh,19
mov dl,32
destacker:
mov ah,02
inc dl
int 10h
pop ax
mov ah,09
add al,48
mov bl,0fh
mov cx,1
mov bh,0
int 10h
dec si
cmp si,0
jne destacker
ret
drawconsole endp

blip1 proc ; creates a blip noise used for collisions with bots 
mov     al, 182         ; meaning that we're about to load
out     43h, al         ; a new countdown value
mov bx,5000

    mov     ax, bx       ; countdown value is stored in ax. It is calculated by 
                            ; dividing 1193180 by the desired frequency (with the
                            ; number being the frequency at which the main system
                            ; oscillator runs
    out     42h, al         ; Output low byte.
    mov     al, ah          ; Output high byte.
    out     42h, al               
    in      al, 61h         ; to connect the speaker to timer 2
    or      al, 00000011b  
    out     61h, al         ; Send the new value
   mov cx,0
   mov dx,0ffffh
   mov ah,86h
   int 15h
  add bx,50 ; frequency
   in      al, 61h  
   and     al, 00000000b 
   out     61h, al  
ret
blip1 endp

blip2 proc ;with walls
mov     al, 182         ; meaning that we're about to load
out     43h, al         ; a new countdown value
mov bx,800

    mov     ax, bx       ; countdown value is stored in ax. It is calculated by 
                            ; dividing 1193180 by the desired frequency (with the
                            ; number being the frequency at which the main system
                            ; oscillator runs
    out     42h, al         ; Output low byte.
    mov     al, ah          ; Output high byte.
    out     42h, al               
    in      al, 61h         ; to connect the speaker to timer 2
    or      al, 00000011b  
    out     61h, al         ; Send the new value
   mov cx,0
   mov dx,0ffffh
   mov ah,86h
   int 15h
  add bx,50 ; frequency
   in      al, 61h  
   and     al, 00000000b 
   out     61h, al  
ret
blip2 endp

blip3 proc ; with projectiles
mov     al, 182         ; meaning that we're about to load
out     43h, al         ; a new countdown value
mov bx,1000

    mov     ax, bx       ; countdown value is stored in ax. It is calculated by 
                            ; dividing 1193180 by the desired frequency (with the
                            ; number being the frequency at which the main system
                            ; oscillator runs
    out     42h, al         ; Output low byte.
    mov     al, ah          ; Output high byte.
    out     42h, al               
    in      al, 61h         ; to connect the speaker to timer 2
    or      al, 00000011b  
    out     61h, al         ; Send the new value
   mov cx,0
   mov dx,0ffffh
   mov ah,86h
   int 15h
  add bx,50 ; frequency
   in      al, 61h  
   and     al, 00000000b 
   out     61h, al  
ret
blip3 endp

blip4 proc ;with robot
mov     al, 182         ; meaning that we're about to load
out     43h, al         ; a new countdown value
mov bx,3000

    mov     ax, bx       ; countdown value is stored in ax. It is calculated by 
                            ; dividing 1193180 by the desired frequency (with the
                            ; number being the frequency at which the main system
                            ; oscillator runs
    out     42h, al         ; Output low byte.
    mov     al, ah          ; Output high byte.
    out     42h, al               
    in      al, 61h         ; to connect the speaker to timer 2
    or      al, 00000011b  
    out     61h, al         ; Send the new value
   mov cx,0
   mov dx,0ffffh
   mov ah,86h
   int 15h
  add bx,50 ; frequency
   in      al, 61h  
   and     al, 00000000b 
   out     61h, al  
ret
blip4 endp

endofexe::
mov ah,4ch
int 21h
end
