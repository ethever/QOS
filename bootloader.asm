org 0x7c00      ;指明程序的装载地址
jmp entry
;以下标记用于标准fat12格式的硬盘
db 0x90
db "QOSONISM"   ;启动扇区名字。8字节
dw 0x0200       ;没个扇区的大小，必须为512字节
db 0x01         ;簇大小，必须为一个扇区
dw 0x0001       ;fat的起始位置，一般从第一个扇区开始
db 0x02         ;fat的个数，必须为2个
dw 0x00e0       ;根目录的大小，一般设成224项
dw 2880         ;该磁盘的大小，必须是2880个扇区（2880*512/1024=1440k）
db 0xf0         ;磁盘的种类，必须是0xf0
dw 9            ;fat的长度，必须是9个扇区
dw 18           ;1个磁道有几个扇区，必须是18个
dw 2            ;磁头数目，必须是2个
dd 0            ;不使用分区，必须是0
dd 2880         ;重写一次磁盘大小
db 0,0,0x29     ;固定
dd 0xffffffff   ;可能是卷标号码
db "QOS-ONISM  ";磁盘名字，11字节
db "FAT12   "   ;磁盘格式名字，8字节
;程序核心
entry:
    mov ax, 0   ;初始化寄存器
    mov ss, ax 
    mov sp, 0x7c00
    mov ds, ax
    mov es, ax
    ;;显示bios欢迎信息
    mov si, init_msg
    call display
;;加载硬盘内容到内存中
;;读取磁盘信息到es * 16 + bx 内存处
;;AL＝扇区数
; CH＝柱面
; CL＝扇区
; DH＝磁头
; DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘
; ES:BX＝缓冲区的地址
; 出口参数：CF＝0——操作成功，AH＝00H，AL＝传输的扇区数，否则，AH＝状态代码，参见功能号01H中的说明
initdisk:
    mov ax, 0x0820
    mov es, ax
    mov ch, 0       ;柱面0
    mov cl, 2       ;扇区2
    mov dh, 0       ;磁头0
    mov dl, 0x00    ;a驱动器
    mov ah, 0x02    ;读磁盘
    mov al, 1       ;1个扇区
    mov bx, 0
    
    int 0x13        
    jnc initdisk_success     ;无错误跳转
    jmp initdisk_error       ;失败时显示错误信息


fin: 
    hlt
    jmp fin

initdisk_success:
    mov si, initdisk_success_msg
    call display
    jmp 0x8200
    jmp fin

    

;;显示错误信息
initdisk_error: 
    mov si, initdisk_error_msg
    call display 
    mov al, ah
    add al, 65
    mov ah, 0x0e
    int 0x10
    jmp fin


            
;;显示一行字符串
display:
    mov ax, 0
    mov es, ax
    mov al, [si]
    add si, 1
    cmp al, 0
    je _ret
    cmp al, 0x0a
    je swap_line
    mov ah, 0x0e
    int 0x10
    jmp display
swap_line:              ;遇到回车换行
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

initdisk_success_msg:
    db "Initdisk Success!"
    db 0x0a, 0x00

initdisk_error_msg: 
    db "Initdisk Error :)"
    db 0x0a, 0x00

init_msg:
    db "Welcome to QOS"
    db 0x0a
    db "Loading..."
    db 0x0a
    db "Wait for Readding Disk..."
    db 0x0a, 0x00
no_error_msg: 
    db "No ERROR in reading disk"
    db 0x0a, 0x00
readdisk_error: 
    db "READ DISK ERROR"
    db 0x0a, 0x00


times 510-($-$$) db 0    ;填写00，直到510字节处
db 0x55, 0xaa