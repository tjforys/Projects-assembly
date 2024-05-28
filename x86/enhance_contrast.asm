section .data

section .bss

section .text
    global enhance_contrast

enhance_contrast:
    ; void enhance_contrast(void *img, int width, int height)
    ; Arguments: 
    ; img:     [esp + 4]
    ; width:   [esp + 8]
    ; height:  [esp + 12]

    push ebp
    mov ebp, esp
    sub esp, 16               ; miejsce na zmienne lokalne

    mov esi, [ebp + 4]        ; img
    mov ecx, [ebp + 8]        ; width
    mov edx, [ebp + 12]       ; height

    ; oblicz całkowity rozmiar obrazu w bajtach
    mov eax, ecx
    imul eax, edx
    imul eax, 3
    mov [esp], eax

    ; Znajdowanie minimalnej i maksymalnej wartości
    mov ebx, 255              ; initial min
    xor edi, edi              ; initial max

find_min_max:
    mov al, byte [esi]
    cmp al, bl
    jb .update_min
    cmp al, di
    ja .update_max
    jmp .next_pixel

.update_min:
    mov bl, al

.update_max:
    mov di, al

.next_pixel:
    inc esi
    dec [esp]
    jnz find_min_max

    ; Przeskalowanie wartości
    ; new_value = ((old_value - min) * 255) / (max - min)

    mov ecx, [ebp + 8]        ; width
    mov edx, [ebp + 12]       ; height
    mov esi, [ebp + 4]        ; img
    movzx eax, di
    sub eax, ebx
    mov edi, eax              ; range = max - min
    test edi, edi
    jz .done                  ; unikaj dzielenia przez zero

scale:
    mov al, byte [esi]
    sub al, bl
    imul eax, 255
    cdq
    idiv edi
    mov [esi], al
    inc esi
    dec [esp]
    jnz scale

.done:
    add esp, 16
    pop ebp
    ret