; pcat - primitive concat (cat) for windows
; could be used as an alternative to `type` using `pcat.exe < file`
; a poor man's alternative to this program could be `findstr`
; `findstr /V /L AL0NGSTR1NGW1THN0H1TS file`
; that is, if you're cool with the edge case :)
; compile:
; nasm -fwin32 pcat.asm
; link:
; link /entry:main pcat.obj /subsystem:console /nodefaultlib kernel32.lib
; TOOD:
;   * error indication
;   * smaller stack
;   * cli arguments? (probably sucks)
;   * aslr?
; I thank Peter Kolfer (Code-Cop) for his wonderful article
; http://blog.code-cop.org/2015/07/hello-world-windows-32-assembly.html

; This program is free software. It comes without any warranty, to
; the extent permitted by applicable law. You can redistribute it
; and/or modify it under the terms of the Do What The Fuck You Want
; To Public License, Version 2, as published by Sam Hocevar. See
; http://www.wtfpl.net/ for more details.

STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
%define NULL    dword 0

    extern  _GetStdHandle@4
    extern  _WriteFile@20
    extern  _ReadFile@20
    extern  _ExitProcess@4

    global _main

    section .text

_main:
    ; local variable
read_handle  equ 4
write_handle equ read_handle+4
buffer_used  equ write_handle+4
buffer       equ buffer_used+2048
    mov     ebp, esp
    sub     esp, buffer

    push    STD_INPUT_HANDLE
    call    _GetStdHandle@4
    mov     [ebp-read_handle], eax
    
    push    STD_OUTPUT_HANDLE
    call    _GetStdHandle@4
    mov     [ebp-write_handle], eax

loop_start:
    ; lpOverlapped
    push NULL
    ; lpNumberOfBytesRead
    lea eax, [ebp-buffer_used]
    push eax
    ; nNumberOfBytesToRead
    push buffer-buffer_used
    ; lpBuffer
    lea eax, [ebp-buffer]
    push eax
    ; hFile
    mov eax, [ebp-read_handle]
    push eax
    call _ReadFile@20
    
    ; retval == 0
    test eax, eax
    je prog_exit
    ; bytes read == 0 EOF mark
    mov ebx, [ebp-buffer_used]
    test ebx, ebx
    je prog_exit
    
    ; lpOverlapped
    push NULL
    ; lpNumberOfBytesWritten
    lea eax, [ebp-buffer_used]
    push eax
    ; nNumberOfBytesToWrite
    push ebx
    ; lpBuffer
    lea eax, [ebp-buffer]
    push eax
    ; hFile
    mov eax, [ebp-write_handle]
    push eax
    call _WriteFile@20
    
    ; retval == 0
    test eax, eax
    je prog_exit
    
    ; next
    jmp loop_start

prog_exit:
    push    0
    call    _ExitProcess@4

    ; never here
    hlt