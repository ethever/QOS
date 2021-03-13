 org 0x7c00                         ; 该命令表示程序将被装在到偏移地址为0x7C00的地方
        jmp start
   start:
        mov ax,cs      
        mov ss,ax                          ;设置堆栈段和栈指针 
        mov sp,0x7c00
     
        ;计算GDT所在的逻辑段地址 
        mov ax,[cs:gdt_base]        ;低16位 gdt_base是段内偏移标志，不是一个变量
        mov dx,[cs:gdt_base+0x02]   ;高16位 
        mov bx,16        
        div bx                             ;实模式下段基址x16+偏移地址,其实就是将0x7e00除以16
        mov ds,ax                          ;令DS指向该段以进行操作
        mov bx,dx                          ;段内起始偏移地址 
    
        mov dword [bx+0x00],0x00           ;创建0#描述符，它是空描述符，这是处理器的要求
        mov dword [bx+0x04],0x00  

                                           ;创建#1描述符，保护模式下的代码段描述符
        mov dword [bx+0x08],0x7c0001ff     ; 7c00为段基址15~0，01ff为段界限
                                                    
        mov dword [bx+0x0c],0x00409800     ;0040 00为段基址31~24 40:0100_0000B


                                           ;创建#2描述符，保护模式下的数据段描述符
                                          
        mov dword [bx+0x10],0x8000ffff     ;64KB 数据段基址 0xb8000显存地址
        mov dword [bx+0x14],0x0040920b     ;92表示TYPE=2读写

                                           ;创建#3描述符，保护模式下的堆栈段描述符
        mov dword [bx+0x18],0x00007a00
        mov dword [bx+0x1c],0x00409600     ;96表示type=6可读可写

                                           ;初始化描述符表寄存器GDTR
        mov word [cs: gdt_size],31  ;描述符表的界限（总字节数减一）   
                                            
        lgdt [cs: gdt_size]         ;载入6个字节，先载入gdt_size也就是31，
                                             
     
        in al,0x92                         ;南桥芯片内的端口 
        or al,0000_0010B
        out 0x92,al                        ;打开A20

        cli                                ;保护模式下中断机制尚未建立，应 
        mov eax,cr0
        or eax,1
        mov cr0,eax                        ;设置PE位，打开了保护模式标志
     
        ;以下进入保护模式... ...
        jmp dword 0x0008:(flush-0x7c00)             ;16位的描述符选择子：32位偏移，
                                       
   flush:
        mov cx,00000000000_10_000B         ;加载数据段选择子(0x10)
        mov ds,cx

        ;以下在屏幕上显示"Protect mode OK." 
        mov byte [0x00],'P'  
        mov byte [0x02],'r'
        mov byte [0x04],'o'
        mov byte [0x06],'t'
        mov byte [0x08],'e'
        mov byte [0x0a],'c'
        mov byte [0x0c],'t'
        mov byte [0x0e],' '
        mov byte [0x10],'m'
        mov byte [0x12],'o'
        mov byte [0x14],'d'
        mov byte [0x16],'e'
        mov byte [0x18],' '
        mov byte [0x1a],'O'
        mov byte [0x1c],'K'

         
        mov cx,00000000000_11_000B         ;加载堆栈段选择子
        mov ss,cx
        mov esp,0x7c00

        mov ebp,esp                        ;保存堆栈指针 
        push byte '.'                      ;压入立即数（字节）
        
        sub ebp,4
        cmp ebp,esp                        ;判断压入立即数时，ESP是否减4 
        jnz ghalt                          
        pop eax
        mov [0x1e],al                      ;显示句点 
     
 ghalt:     
        hlt                                ;已经禁止中断，将不会被唤醒 

        gdt_size         dw 0
        gdt_base         dd 0x00007e00     ;GDT的物理地址, 这个是自定义的，
                              
            
                            
        times 510-($-$$) db 0
                        db 0x55,0xaa