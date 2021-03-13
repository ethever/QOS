
;;初始化相关寄存器
mov ax, 0x0820   ;初始化寄存器
mov ds, ax       ;初始化数据段寄存器
   
;;栈设置在0x500-0x7bff共30k的空间中
; 8.  push 指令的执行步骤：
;     (1) SP = SP - 2 (偏移地址减少，即往低地址处偏移[栈顶方向])
;     (2) 向SS:SP指向的字单元中送入数据 
; 9. pop 指令的执行步骤：
;     (1) 从SS:SP指向的字单元中读取数据
;     (2) SP = SP + 2       (偏移地址增加，即往高地址处偏移[栈低方向]) 
mov ax, 0x00  
mov ss, ax      ;初始化栈底寄存器
mov ax, 0x7bff
mov sp, ax      ;初始化栈顶寄存器


mov si, welcom_msg
call display
mov si, username_msg
call display
jmp input

display:
    mov al, [si]
    add si, 1
    cmp al, 0x00
    je _ret
    cmp al, 0x0a
    je swap_line
    mov ah, 0x0e
    int 0x10
    jmp display
        swap_line:
            mov ah, 0x03
            mov bh, 0x00
            int 0x10
            mov ah, 0x02
            inc dh
            mov dl, 0
            int 0x10
            jmp display
_ret:
    ret

;;接受输入程序
input:
    mov ah, 0
    int 0x16
    push ax
    cmp al, 0x0d        ;回车键
    je _return_key
    mov ah, 0x0e
    int 0x10
    cmp al, 100
    je _view_memory
    jmp input
    _view_memory:
        mov ax, 0x00
        mov ds, ax
        mov si, 0x7bff
        call view_memory
        mov ax, 0x820
        mov ds, ax
        jmp input
    _return_key:
        jmp input

        
        

;;显示内存数据子程序
;;si 待显示的内存地址的起始位置
view_memory:
    mov cx, [si]
    sub si, 0x0002
    mov dx, cx
    shr dx, 12
    call dis    ;显示第一个4位
    mov dx, cx
    shl dx, 4
    shr dx, 12
    call dis    ;显示第二个4位
    mov dx, cx
    shl dx, 8
    shr dx, 12
    call dis    ;显示第三个4位
    mov dx, cx
    shl dx, 12
    shr dx, 12
    call dis    ;显示第四个4位
    cmp si, 0x7bef
    jae view_memory
    jmp _ret
    ;;位映射到ascii表
    ;;待显示数据在dl低四位中
    dis:
        cmp dl, 10
        jae above9
        add dl, 48
        mov ah, 0x0e
        mov al, dl
        int 0x10   
        ret
        above9:
            add dl, 55
            mov ah, 0x0e
            mov al, dl
            int 0x10
            ret



fin: 
    hlt 
    jmp fin

username_msg:
    db "QOS:"
    db 0x00

welcom_msg:
    db 0x0a
    db "QOS init SUCCESS!"
    db 0x0a, 0x00

debug_msg:
    db "debug"
    db 0x00
debug_param_msg:
    db "-e"
    db 0x00