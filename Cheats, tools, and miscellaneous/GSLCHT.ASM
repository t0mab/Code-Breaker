cr              equ     0dh                     ; line return
lf              equ     0ah                     ; line feed
paramarea       equ     80h                     ; parameter(s) area
repeatcounter   equ     200
memloc1         equ     31d0h
memloc2         equ     183bh
memloc3         equ     8e2h

cseg            segment
                assume  cs:cseg,ds:cseg,ss:cseg,es:cseg
                org     0
firstbyte       equ     $
		org	100h

trainer         proc    far

start:
                jmp     begin

found           db      0
redirect9       db      0
beginseg        dw      0
counter         dw      repeatcounter
saveds          dw      0
savekbseg       dw      0
savesp          dw      0
savesp2         dw      0
savess          dw      0
savess2         dw      0
savetempsp      dw      0
oldint9         dd      0
oldint92        dd      0
oldint1c        dd      0
foundloc        dw      0
foundloc2       dw      0

trainer         endp

;---------------------------------------------------------------
; Get address of interrupt 9h.
;---------------------------------------------------------------

getint9         proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint92
                push    word ptr es:[bx]
                pop     word ptr cs:oldint9
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint92+2
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint9+2
                push    offset newint9
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
getint9         endp

;---------------------------------------------------------------
; Set address of interrupt 9h back to original.
;---------------------------------------------------------------

unredirect9     proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr cs:oldint92
                pop     word ptr es:[bx]
                push    word ptr cs:oldint92+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect9     endp

searchfor       proc    near
                push    es
                push    di
                push    saveds
                pop     es
                mov     di,0ffffh
incdi:
                inc     di
                cmp     di,0fffeh
                je      exitsearchfor
                cmp     word ptr es:[di],013ch
                jne     incdi
                cmp     word ptr es:[di+2],0e74h
                jne     incdi
                cmp     word ptr es:[di+4],3b3ch
                jne     incdi
                push    ax
                mov     ax,di
                mov     word ptr foundloc,ax
                pop     ax
exitsearchfor:
                pop     di
                pop     es
                ret
searchfor       endp

searchfor2      proc    near
                push    es
                push    di
                push    saveds
                pop     es
                mov     di,0ffffh
incdi2:
                inc     di
                cmp     di,0fffeh
                je      exitsearchfor2
                cmp     word ptr es:[di],0ff25h
                jne     incdi2
                cmp     byte ptr es:[di+2],7fh
                jne     incdi2
                push    ax
                mov     ax,di
                mov     word ptr foundloc2,ax
                pop     ax
exitsearchfor2:
                pop     di
                pop     es
                ret
searchfor2      endp

;---------------------------------------------------------------
; New interrupt 9h.
;---------------------------------------------------------------

newint9         proc    near
                push    ax
                push    di
                push    ds
                cmp     byte ptr cs:found,1
                jne     exitnewint9
                push    cs
                pop     ds
                in      al,60h
                mov     di,offset key1
comparekeys:
                cmp     byte ptr cs:[di],0
                je      exitnewint9
                cmp     al,cs:[di]
                je      execkey
                inc     di
                inc     di
                inc     di
                jmp     short comparekeys
execkey:
                inc     di
                jmp     word ptr cs:[di]
exitnewint9:
                pop     ds
                pop     di
                pop     ax
                jmp     dword ptr cs:oldint9

exitnewint92:
                pop     ds
                pop     di
                pop     ax
                jmp     dword ptr cs:oldint9

key1            db      2
                dw      offset key1ofs
key2            db      3
                dw      offset key2ofs
key3            db      4
                dw      offset key3ofs
                db      0

key1ofs:
                push    es
                push    di
                call    searchfor
                mov     di,foundloc
                push    saveds
                pop     es
                mov     word ptr es:[di],3bb0h
                mov     word ptr es:[di+2],16ebh
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key2ofs:
                push    es
                push    di
                call    searchfor2
                mov     di,foundloc2
                push    saveds
                pop     es
                mov     word ptr es:[di],9090h
                mov     byte ptr es:[di+2],90h
                sub     saveds,12f2h
                mov     di,memloc3
                push    saveds
                pop     es
                mov     word ptr es:[di],9090h
                mov     word ptr es:[di+2],9090h
                mov     word ptr es:[di+0bh],9090h
                mov     word ptr es:[di+14h],9090h
                mov     word ptr es:[di+1ch],9090h
                mov     word ptr es:[di+24h],9090h
                add     saveds,12f2h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
key3ofs:
                push    es
                push    di
;               call    searchfor2
                mov     di,foundloc2
                push    saveds
                pop     es
                mov     word ptr es:[di],0ff25h
                mov     byte ptr es:[di+2],7fh
                sub     saveds,12f2h
                mov     di,memloc3
                push    saveds
                pop     es
                mov     word ptr es:[di],0effh
                mov     word ptr es:[di+2],37cbh
                mov     word ptr es:[di+0bh],0c133h
                mov     word ptr es:[di+14h],0c133h
                mov     word ptr es:[di+1ch],0c8d1h
                mov     word ptr es:[di+24h],0c8d1h
                add     saveds,12f2h
                call    beep
                pop     di
                pop     es
                jmp     exitnewint9
newint9         endp

;---------------------------------------------------------------
; Redirect interrupt 1ch.
;---------------------------------------------------------------

redirect1c      proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,70h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint1c
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint1c+2
                push    offset cs:newint1c
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
redirect1c      endp

;---------------------------------------------------------------
; Redirect interrupt 1ch back to original.
;---------------------------------------------------------------

unredirect1c    proc    near
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,70h
                push    word ptr cs:oldint1c
                pop     word ptr es:[bx]
                push    word ptr cs:oldint1c+2
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                ret
unredirect1c    endp

;---------------------------------------------------------------
; New interrupt 1ch.
;---------------------------------------------------------------

newint1c        proc    near
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp
		mov	bp,sp
                cmp     byte ptr found,1
                je      jmptoexit2
		sub	sp,2
                mov     ax,cs
		mov	ds,ax
		mov	ax,cs
		mov	[bp-2],ax
                mov     beginseg,ax
                dec     counter
                cmp     word ptr counter,0
                je      checkiffound
                jmp     execint2
checkiffound:
                cmp     byte ptr found,0
                je      search1
jmptoexit2:
                jmp     jmptoexit
search1:
                mov     ax,beginseg
                add     ax,0fffeh
                cmp     ax,[bp-2]
                jne     continues
                mov     ax,repeatcounter
                mov     word ptr counter,ax
                jmp     jmptoexit
continues:
                mov     ax,[bp-2]
		push	ax
                mov     di,memloc1
		pop	es
                cmp     word ptr es:[di],013ch
                je      search2
                jmp     incbase
search2:
                cmp     word ptr es:[di+2],0e74h
                je      search3
                jmp     incbase
search3:
                cmp     word ptr es:[di+4],3b3ch
                je      fixmem
                jmp     execint1
fixmem:
                mov     byte ptr found,1
                push    es
                pop     saveds
                push    bx
                push    es
                xor     bx,bx
                push    bx
                pop     es
                or      bx,24h
                push    word ptr es:[bx]
                pop     word ptr cs:oldint9
                push    word ptr es:[bx+2]
                pop     word ptr cs:oldint9+2
                push    offset newint9
                pop     word ptr es:[bx]
                push    cs
                pop     word ptr es:[bx+2]
                pop     es
                pop     bx
                call    beep
                jmp     short incbase
execint1:
                pushf
                call    dword ptr oldint1c
incbase:
		inc	word ptr [bp-2]
                jmp     checkiffound
jmptoexit:
                jmp     short exitnewint
execint2:
                pushf
                call    dword ptr oldint1c
exitnewint:
		mov	sp,bp
		pop	bp
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret
newint1c        endp

;---------------------------------------------------------------
; Make a simple beep.
;---------------------------------------------------------------

beep            proc    near
                push    bx
                push    cx
                mov     bx,100h
                mov     cx,70
                call    maketone
                pop     cx
                pop     bx
                ret
beep            endp

;---------------------------------------------------------------
; Make a tone according to frequency and duration.
;---------------------------------------------------------------

maketone        proc    near
                push    ax
                mov     word ptr cs:savess2,ss
                mov     word ptr cs:savesp2,sp
                mov     ax,cs
                cli
                mov     ss,ax
                mov     sp,offset userstack2ptr
                sti
                push    cx
                call    turnonspeaker
                pop     cx
                push    bx
                call    vrtretrace
                pop     bx
                call    turnoffspeaker
                cli
                mov     ss,word ptr cs:savess2
                mov     sp,word ptr cs:savesp2
                sti
                pop     ax
                retn
maketone        endp

;---------------------------------------------------------------
; Turn on speaker.
;---------------------------------------------------------------

turnonspeaker   proc    near
                push    bp
                mov     bp,sp
                push    ax
                push    bx
                push    dx
                mov     bx,[bp+4]
                mov     ax,34ddh
                mov     dx,12h
                cmp     dx,bx
                jge     exitturnonspeaker
                div     bx
                mov     bx,ax
                in      al,61h
                test    al,3
                jne     manual
                or      al,3
                out     61h,al
                mov     al,0b6h
                out     43h,al
manual:
                mov     al,bl
                out     42h,al
                mov     al,bh
                out     42h,al
exitturnonspeaker:
                pop     dx
                pop     bx
                pop     ax
                pop     bp
                retn
turnonspeaker   endp

;---------------------------------------------------------------
; Turn off speaker.
;---------------------------------------------------------------

turnoffspeaker  proc    near
                in      al,61h
                and     al,0fch
                out     61h,al
                mov     al,0b6h
                out     43h,al
                retn
turnoffspeaker  endp

;---------------------------------------------------------------
; Check until vertical retrace is finished.
;---------------------------------------------------------------

vrtretrace      proc    near
                push    bp
                mov     bp,sp
                push    bx
                push    ax
                push    dx
                mov     bx,[bp+4]
                mov     dx,3dah
vrtwait:
                in      al,dx
                and     al,8
                jz      vrtwait
                dec     bx
                jnz     vrtwait
                pop     dx
                pop     ax
                pop     bx
                pop     bp
                retn
vrtretrace      endp

;---------------------------------------------------------------
; Write a string.
;---------------------------------------------------------------

writestr        proc    near
                push    ax                              ; save registers
                push    dx
                push    bp
                mov     bp,sp
                push    [bp+8]                          ; set dx=[bp+8]
                pop     dx
                mov     ah,9                            ; write string
                int     21h
                pop     bp                              ; restore registers
                pop     dx
                pop     ax
                ret     2
writestr        endp

;---------------------------------------------------------------
; Show error(s) that occurred during execution of program.
;---------------------------------------------------------------

showerror       proc    near
                push    ax
                cmp     ax,2
                je      em2
                cmp     ax,8
                je      em8
                push    offset error0
                jmp     writeerror
em2:
                push    offset error2
                jmp     writeerror
em8:
                push    offset error8
writeerror:
                call    writestr
                pop     ax
                ret
showerror       endp

;---------------------------------------------------------------
; Main execution block.
;---------------------------------------------------------------

begin:
                mov     savesp,sp
                mov     savess,ss
                push    cs
                pop     ds
                push    offset credit
                call    writestr
                xor     ax,ax
                int     16h
                mov     sp,offset userstackptr
                push    cs
                push    cs
                push    cs
                pop     ds
                pop     es
                pop     ss
                call    getint9
                call    redirect1c
                push    bx
                push    cx
                push    si
                push    di
                xor     bx,bx
                or      cx,bx
                mov     cl,ds:paramarea[bx]
                or      cl,cl
                jz      changemem
                add     cx,2
                mov     si,offset paramarea
                mov     di,offset cmd_buf
                rep     movsb
changemem:
                pop     di
                pop     si
                pop     cx
                pop     bx
                mov     bx,(offset lastbyte - firstbyte + 15) shr 4
                mov     ah,4ah
                int     21h
                jnc     executeprog
                push    offset fail4a
                call    writestr
                jmp     error
executeprog:
                push    cs
                pop     fcb1
                push    cs
                pop     fcb2
                push    cs
                pop     envstr
                mov     dx,offset filename
                mov     bx,offset paramblock
                mov     savetempsp,sp
                mov     ax,4b00h
                int     21h
                push    cs
                pop     ss
                mov     sp,savetempsp
                push    cs
                pop     ds
                push    cs
                pop     es
                jnc     exitprog
                push    offset fail4b
                call    writestr
error:
                call    showerror
exitprog:
                call    unredirect9
                call    unredirect1c
                mov     ss,savess
                mov     sp,savesp
                mov     ax,4c00h
                int     21h

credit          db      '''Guy Spy'' level skip cheat by Code Breaker.',cr,lf,lf
                db      'Keys are : ',cr,lf,lf
                db      '1 - Skip level',cr,lf,lf
                db      'Greetings to all.',cr,lf,lf,'Strike a key....$'
fail4a          db      cr,lf,'Unable to modify allocated memory blocks.$'
fail4b          db      cr,lf,'Unable to load program overlay.$'
error0          db      cr,lf,'Unknown error code.$'
error2          db      cr,lf,'''Guyspy.exe'' - not found.$'
error8          db      cr,lf,'Not enough memory.$'
filename        db      'guyspy.exe',0
paramblock      label   word
                dw      0
                dw      offset cmd_buf
fcb1            dw      ?
                dw      5ch
fcb2            dw      ?
                dw      6ch
envstr          dw      ?
cmd_buf         db      0
                db      ' '
cmd_txt         db      80h dup (?)
userstack       db      8 dup ('stack   ')
userstackptr    equ     $-2
userstack2      db      8  dup ('stack   ')
userstack2ptr   equ     $-2
lastbyte        equ     $

cseg            ends
                end     start

