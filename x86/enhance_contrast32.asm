BITS 32
SECTION .data
essa: dd 1
SECTION .text

global enhance_contrast
global essa
enhance_contrast:
    ;prolog
    push ebp
    mov ebp, esp
    sub esp, 12

    push ebx
    push esi
    push edi

    mov esi, [ebp + 8]  ; esi = img
    mov ecx, [esi + 18]  ; ecx = width
    mov edi, [esi + 22]  ; edi = height  
    
    ; ebp-4 = height
    ; -8 = width
    ; -9 = padding

    ;esi - image pointer
    ;ecx - width iterator
    ;edi - height iterator
    ;edx - contrast multiplier
    ;bl - min
    ;bh - max
    
    ;setup image start
    add esi, 54
    mov [ebp + 8], esi
    
    lea ecx, [ecx+ecx*2]

    mov [ebp-4], edi
    mov [ebp-8], ecx

    ;move row pixel counter to start

    ;calculate the correct padding
    mov ebx, ecx
    and ebx, 3
    jz loop_minmax
    mov al, 4
    sub al, bl
    mov [ebp-9], al


    mov ebx, 0xFF

loop_minmax_rows:
    mov ecx, [ebp-8]

loop_minmax:

    mov al, [esi]

    cmp  al, bl
    jnb check_max
    mov bl, al
    
check_max:
    cmp al, bh
    jna next_minmax
    mov bh, al

next_minmax:
    inc esi
    dec ecx
    jnz loop_minmax

add_row_minmax:
    mov al, [ebp-9]
    movzx eax, al
    add esi, eax

    dec edi

    jnz loop_minmax_rows



calculate_contrast:
    mov eax, 0xFF0000
    cdq

    sub bh, bl
    movzx ecx, bh  
    div ecx
 
    mov [essa], cl

    mov edx, eax
    mov edi, [ebp-4]
    mov esi, [ebp+8]

;loop 2, changing contrast

loop_contrast_rows:
    mov ecx, [ebp-8]


loop_change_contrast:

    mov al, [esi]

    sub al, bl
    movzx eax, al
    imul eax, edx
    sar eax, 16
    mov [esi], al

    inc esi
    dec ecx
   jnz loop_change_contrast

add_row_contrast:
    mov al, [ebp-9]
    movzx eax, al
    add esi, eax
    dec edi
    jnz loop_contrast_rows
    

end:
    ;epilog
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret