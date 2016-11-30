;Mupen64plus - linkage_x86.asm                                           
;Copyright (C) 2009-2011 Ari64                                         
;                                                                      
;This program is free software; you can redistribute it and/or modify  
;it under the terms of the GNU General Public License as published by  
;the Free Software Foundation; either version 2 of the License, or     
;(at your option) any later version.                                   
;                                                                      
;This program is distributed in the hope that it will be useful,       
;but WITHOUT ANY WARRANTY; without even the implied warranty of        
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         
;GNU General Public License for more details.                          
;                                                                      
;You should have received a copy of the GNU General Public License     
;along with this program; if not, write to the                         
;Free Software Foundation, Inc.,                                       
;51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.          

%include "../../src/main/asm_defines.h"

%ifdef ELF_TYPE
    %macro  cglobal 1
      global  %1
    %endmacro
    
    %macro  cextern 1
      extern  %1
    %endmacro
%else
    %macro  cglobal 1
      global  _%1
      %define %1 _%1
    %endmacro

    %macro  cextern 1
      extern  _%1
      %define %1 _%1
    %endmacro
%endif

cglobal dyna_linker
cglobal dyna_linker_ds
cglobal jump_vaddr_eax
cglobal jump_vaddr_ecx
cglobal jump_vaddr_edx
cglobal jump_vaddr_ebx
cglobal jump_vaddr_ebp
cglobal jump_vaddr_edi
cglobal verify_code_ds
cglobal verify_code_vm
cglobal verify_code
cglobal cc_interrupt
cglobal do_interrupt
cglobal fp_exception
cglobal fp_exception_ds
cglobal jump_syscall
cglobal jump_eret
cglobal new_dyna_start
cglobal invalidate_block_eax
cglobal invalidate_block_ecx
cglobal invalidate_block_edx
cglobal invalidate_block_ebx
cglobal invalidate_block_ebp
cglobal invalidate_block_esi
cglobal invalidate_block_edi
cglobal write_rdram_new
cglobal write_rdramb_new
cglobal write_rdramh_new
cglobal write_rdramd_new
cglobal read_nomem_new
cglobal read_nomemb_new
cglobal read_nomemh_new
cglobal read_nomemd_new
cglobal write_nomem_new
cglobal write_nomemb_new
cglobal write_nomemh_new
cglobal write_nomemd_new
cglobal write_mi_new
cglobal write_mib_new
cglobal write_mih_new
cglobal write_mid_new
cglobal breakpoint

cextern base_addr
cextern jump_in
cextern add_link
cextern hash_table
cextern jump_dirty
cextern new_recompile_block
cextern get_addr_ht
cextern cycle_count
cextern get_addr
cextern branch_target
cextern memory_map
cextern pending_exception
cextern restore_candidate
cextern gen_interupt
cextern last_count
cextern pcaddr
cextern clean_blocks
cextern invalidate_block
cextern readmem_dword
cextern check_interupt
cextern get_addr_32
cextern write_mi
cextern write_mib
cextern write_mih
cextern write_mid
cextern TLB_refill_exception_new
cextern g_dev

section .bss
align 4

section .rodata
section .text

dyna_linker:
    ;eax = virtual target address
    ;ebx = instruction to patch
    mov     edi,    eax
    mov     ecx,    eax
    shr     edi,    12
    cmp     eax,    0C0000000h
    cmovge  ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_tlb + offsetof_struct_tlb_LUT_r+edi*4]
    test    ecx,    ecx
    cmovz   ecx,    eax
    xor     ecx,    080000000h
    mov     edx,    2047
    shr     ecx,    12
    and     edx,    ecx
    or      edx,    2048
    cmp     ecx,    edx
    cmova   ecx,    edx
    ;jump_in lookup
    mov     edx,    [jump_in+ecx*4]
_A1:
    test    edx,    edx
    je      _A3
    mov     edi,    [edx]
    xor     edi,    eax
    or      edi,    [4+edx]
    je      _A2
    mov     edx,    DWORD [12+edx]
    jmp     _A1
_A2:
    mov     edi,    [ebx]
    mov     ebp,    esi
    lea     esi,    [4+ebx+edi*1]
    mov     edi,    eax
    pusha
    call    add_link
    popa
    mov     edi,    [8+edx]
    mov     esi,    ebp
    lea     edx,    [-4+edi]
    sub     edx,    ebx
    mov     DWORD [ebx],    edx
    jmp     edi
_A3:
    ;hash_table lookup
    mov     edi,    eax
    mov     edx,    eax
    shr     edi,    16
    shr     edx,    12
    xor     edi,    eax
    and     edx,    2047
    movzx   edi,    di
    shl     edi,    4
    cmp     ecx,    2048
    cmovc   ecx,    edx
    cmp     eax,    [hash_table+edi]
    jne     _A5
_A4:
    mov     edx,    [hash_table+4+edi]
    jmp     edx
_A5:
    cmp     eax,    [hash_table+8+edi]
    lea     edi,    [8+edi]
    je      _A4
    ;jump_dirty lookup
    mov     edx,    [jump_dirty+ecx*4]
_A6:
    test    edx,    edx
    je      _A8
    mov     ecx,    [edx]
    xor     ecx,    eax
    or      ecx,    [4+edx]
    je      _A7
    mov     edx,    DWORD [12+edx]
    jmp     _A6
_A7:
    mov     edx,    [8+edx]
    ;hash_table insert
    mov     ebx,    [hash_table-8+edi]
    mov     ecx,    [hash_table-4+edi]
    mov     [hash_table-8+edi],    eax
    mov     [hash_table-4+edi],    edx
    mov     [hash_table+edi],      ebx
    mov     [hash_table+4+edi],    ecx
    jmp     edx
_A8:
    mov     edi,    eax
    pusha
    call    new_recompile_block
    test    eax,    eax
    popa
    je      dyna_linker
    ;pagefault
    mov     ebx,    eax
    mov     ecx,    008h

exec_pagefault:
    ;eax = instruction pointer
    ;ebx = fault address
    ;ecx = cause
    mov     edx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48]
    add     esp,    -12
    mov     edi,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+16]
    or      edx,    2
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+32],    ebx        ;BadVAddr
    and     edi,    0FF80000Fh
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48],    edx        ;Status
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+52],    ecx        ;Cause
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+56],    eax        ;EPC
    mov     ecx,    ebx
    shr     ebx,    9
    and     ecx,    0FFFFE000h
    and     ebx,    0007FFFF0h
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+40],    ecx        ;EntryHI
    or      edi,    ebx
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+16],    edi        ;Context
    push     080000000h
    call    get_addr_ht
    add     esp,    16
    jmp     eax

;Special dynamic linker for the case where a page fault
;may occur in a branch delay slot
dyna_linker_ds:
    mov     edi,    eax
    mov     ecx,    eax
    shr     edi,    12
    cmp     eax,    0C0000000h
    cmovge  ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_tlb + offsetof_struct_tlb_LUT_r+edi*4]
    test    ecx,    ecx
    cmovz   ecx,    eax
    xor     ecx,    080000000h
    mov     edx,    2047
    shr     ecx,    12
    and     edx,    ecx
    or      edx,    2048
    cmp     ecx,    edx
    cmova   ecx,    edx
    ;jump_in lookup
    mov     edx,    [jump_in+ecx*4]
_B1:
    test    edx,    edx
    je      _B3
    mov     edi,    [edx]
    xor     edi,    eax
    or      edi,    [4+edx]
    je      _B2
    mov     edx,    DWORD [12+edx]
    jmp     _B1
_B2:
    mov     edi,    [ebx]
    mov     ecx,    esi
    lea     esi,    [4+ebx+edi*1]
    mov     edi,    eax
    pusha
    call    add_link
    popa
    mov     edi,    [8+edx]
    mov     esi,    ecx
    lea     edx,    [-4+edi]
    sub     edx,    ebx
    mov     DWORD [ebx],    edx
    jmp     edi
_B3:
    ;hash_table lookup
    mov     edi,    eax
    mov     edx,    eax
    shr     edi,    16
    shr     edx,    12
    xor     edi,    eax
    and     edx,    2047
    movzx   edi,    di
    shl     edi,    4
    cmp     ecx,    2048
    cmovc   ecx,    edx
    cmp     eax,    [hash_table+edi]
    jne     _B5
_B4:
    mov     edx,    [hash_table+4+edi]
    jmp     edx
_B5:
    cmp     eax,    [hash_table+8+edi]
    lea     edi,    [8+edi]
    je      _B4
    ;jump_dirty lookup
    mov     edx,    [jump_dirty+ecx*4]
_B6:
    test    edx,    edx
    je      _B8
    mov     ecx,    [edx]
    xor     ecx,    eax
    or      ecx,    [4+edx]
    je      _B7
    mov     edx,    DWORD [12+edx]
    jmp     _B6
_B7:
    mov     edx,    [8+edx]
    ;hash_table insert
    mov     ebx,    [hash_table-8+edi]
    mov     ecx,    [hash_table-4+edi]
    mov     [hash_table-8+edi],    eax
    mov     [hash_table-4+edi],    edx
    mov     [hash_table+edi],      ebx
    mov     [hash_table+4+edi],    ecx
    jmp     edx
_B8:
    mov     edi,    eax
    and     edi,    0FFFFFFF8h
    inc     edi
    pusha
    call    new_recompile_block
    test    eax,    eax
    popa
    je      dyna_linker_ds
    ;pagefault
    and     eax,    0FFFFFFF8h
    mov     ecx,    080000008h    ;High bit set indicates pagefault in delay slot 
    mov     ebx,    eax
    sub     eax,    4
    jmp     exec_pagefault

jump_vaddr_eax:
    mov     edi,    eax
    jmp     jump_vaddr_edi

jump_vaddr_ecx:
    mov     edi,    ecx
    jmp     jump_vaddr_edi

jump_vaddr_edx:
    mov     edi,    edx
    jmp     jump_vaddr_edi

jump_vaddr_ebx:
    mov     edi,    ebx
    jmp     jump_vaddr_edi

jump_vaddr_ebp:
    mov     edi,    ebp

jump_vaddr_edi:
    mov     eax,    edi

jump_vaddr:
    ;Check hash table
    shr     eax,    16
    xor     eax,    edi
    movzx   eax,    ax
    shl     eax,    4
    cmp     edi,    [hash_table+eax]
    jne     _C2
_C1:
    mov     edi,    [hash_table+4+eax]
    jmp     edi
_C2:
    cmp     edi,    [hash_table+8+eax]
    lea     eax,    [8+eax]
    je      _C1
    ;No hit on hash table, call compiler
    add     esp,    -12
    push    edi
    mov     [cycle_count],    esi    ;CCREG
    call    get_addr
    mov     esi,    [cycle_count]
    add     esp,    16
    jmp     eax

verify_code_ds:
    mov     [branch_target],    ebp

verify_code_vm:
    ;eax = source (virtual address)
    ;ebx = target
    ;ecx = length
    cmp     eax,    0C0000000h
    jl      verify_code
    mov     edx,    eax
    lea     ebp,    [-1+eax+ecx*1]
    shr     edx,    12
    shr     ebp,    12
    mov     edi,    [memory_map+edx*4]
    test    edi,    edi
    js      _D5
    lea     eax,    [eax+edi*4]
_D1:
    xor     edi,    [memory_map+edx*4]
    shl     edi,    2
    jne     _D5
    mov     edi,    [memory_map+edx*4]
    inc     edx
    cmp     edx,    ebp
    jbe     _D1

verify_code:
    ;eax = source
    ;ebx = target
    ;ecx = length
    mov     edi,    [-4+eax+ecx*1]
    xor     edi,    [-4+ebx+ecx*1]
    jne     _D5
    mov     edx,    ecx
    add     ecx,    -4
    je      _D3
    test    edx,    4
    cmove   ecx,    edx
    mov     [cycle_count],    esi
_D2:
    mov     edx,    [-4+eax+ecx*1]
    mov     ebp,    [-4+ebx+ecx*1]
    mov     esi,    [-8+eax+ecx*1]
    xor     ebp,    edx
    mov     edi,    [-8+ebx+ecx*1]
    jne     _D4
    xor     edi,    esi
    jne     _D4
    add     ecx,    -8
    jne     _D2
    mov     esi,    [cycle_count]
    mov     ebp,    [branch_target]
_D3:
    ret
_D4:
    mov     esi,    [cycle_count]
_D5:
    mov     ebp,    [branch_target]
    push    esi           ;for stack alignment, unused
    push    DWORD [8+esp]
    call    get_addr
    add     esp,    16    ;pop stack
    jmp     eax

cc_interrupt:
    add     esi,    [last_count]
    add     esp,    -28                 ;Align stack
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36],    esi    ;Count
    shr     esi,    19
    mov     DWORD [pending_exception],    0
    and     esi,    01fch
    cmp     DWORD [restore_candidate+esi],    0
    jne     _E4
_E1:
    call    gen_interupt
    mov     esi,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36]
    mov     eax,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_next_interrupt]
    mov     ebx,    [pending_exception]
    mov     ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_stop]
    add     esp,    28
    mov     [last_count],    eax
    sub     esi,    eax
    test    ecx,    ecx
    jne     _E3
    test    ebx,    ebx
    jne     _E2
    ret
_E2:
    add     esp,    -8
    mov     edi,    [pcaddr]
    mov     [cycle_count],    esi    ;CCREG
    push    edi
    call    get_addr_ht
    mov     esi,    [cycle_count]
    add     esp,    16
    jmp     eax
_E3:
    add     esp,    16     ;pop stack
    pop     edi            ;restore edi
    pop     esi            ;restore esi
    pop     ebx            ;restore ebx
    pop     ebp            ;restore ebp
    ret                    ;exit dynarec
_E4:
    ;Move 'dirty' blocks to the 'clean' list
    mov     ebx,    DWORD [restore_candidate+esi]
    mov     DWORD [restore_candidate+esi],    0
    shl     esi,    3
    mov     ebp,    0
_E5:
    shr     ebx,    1
    jnc     _E6
    mov     ecx,    esi
    add     ecx,    ebp
    push    ecx
    call    clean_blocks
    pop     ecx
_E6:
    inc     ebp
    test    ebp,    31
    jne     _E5
    jmp     _E1

do_interrupt:
    mov     edi,    [pcaddr]
    add     esp,    -12
    push    edi
    call    get_addr_ht
    add     esp,    16
    mov     esi,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36]
    mov     ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_next_interrupt]
    mov     [last_count],    ebx
    sub     esi,    ebx
    add     esi,    2
    jmp     eax

fp_exception:
    mov     edx,    01000002ch
_E7:
    mov     ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48]
    add     esp,    -12
    or      ebx,    2
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48],    ebx     ;Status
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+52],    edx     ;Cause
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+56],    eax     ;EPC
    push    080000180h
    call    get_addr_ht
    add     esp,    16
    jmp     eax

fp_exception_ds:
    mov     edx,    09000002ch    ;Set high bit if delay slot
    jmp     _E7

jump_syscall:
    mov     edx,    020h
    mov     ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48]
    add     esp,    -12
    or      ebx,    2
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48],    ebx     ;Status
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+52],    edx     ;Cause
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+56],    eax     ;EPC
    push    080000180h
    call    get_addr_ht
    add     esp,    16
    jmp     eax

jump_eret:
    mov     ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48]        ;Status
    add     esi,    [last_count]
    and     ebx,    0FFFFFFFDh
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36],    esi        ;Count
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+48],    ebx        ;Status
    call    check_interupt
    mov     eax,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_next_interrupt]
    mov     esi,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36]
    mov     [last_count],    eax
    sub     esi,    eax
    mov     eax,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+56]        ;EPC
    jns     _E11
_E8:
    mov     ebx,    248
    xor     edi,    edi
_E9:
    mov     ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs + ebx]
    mov     edx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs + ebx + 4]
    sar     ecx,    31
    xor     edx,    ecx
    neg     edx
    adc     edi,    edi
    sub     ebx,    8
    jne     _E9
    mov     ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_hi + ebx]
    mov     edx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_hi + ebx + 4]
    sar     ecx,    31
    xor     edx,    ecx
    jne     _E10
    mov     ecx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_lo + ebx]
    mov     edx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_lo + ebx + 4]
    sar     ecx,    31
    xor     edx,    ecx
_E10:
    neg     edx
    adc     edi,    edi
    add     esp,    -8
    push    edi
    push    eax
    mov     [cycle_count],    esi
    call    get_addr_32
    mov     esi,    [cycle_count]
    add     esp,    16
    jmp     eax
_E11:
    mov     [pcaddr],    eax
    call    cc_interrupt
    mov     eax,    [pcaddr]
    jmp     _E8

new_dyna_start:
    push    ebp
    push    ebx
    push    esi
    push    edi
    add     esp,    -8    ;align stack
    push    0a4000040h
    call    new_recompile_block
    mov     edi,    DWORD [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_next_interrupt]
    mov     esi,    DWORD [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36]
    mov     DWORD [last_count],    edi
    sub     esi,    edi
    jmp     DWORD [base_addr]

invalidate_block_eax:
    push    eax
    push    ecx
    push    edx
    push    eax
    jmp     invalidate_block_call

invalidate_block_ecx:
    push    eax
    push    ecx
    push    edx
    push    ecx
    jmp     invalidate_block_call

invalidate_block_edx:
    push    eax
    push    ecx
    push    edx
    push    edx
    jmp     invalidate_block_call

invalidate_block_ebx:
    push    eax
    push    ecx
    push    edx
    push    ebx
    jmp     invalidate_block_call

invalidate_block_ebp:
    push    eax
    push    ecx
    push    edx
    push    ebp
    jmp     invalidate_block_call

invalidate_block_esi:
    push    eax
    push    ecx
    push    edx
    push    esi
    jmp     invalidate_block_call

invalidate_block_edi:
    push    eax
    push    ecx
    push    edx
    push    edi

invalidate_block_call:
    call    invalidate_block
    pop     eax ;Throw away
    pop     edx
    pop     ecx
    pop     eax
    ret

write_rdram_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    add     edi,    [g_dev + offsetof_struct_device_ri + offsetof_struct_ri_controller_rdram + offsetof_struct_rdram_dram]
    mov     ecx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wword]
    mov     [edi - 0x80000000],    ecx
    jmp     _E12

write_rdramb_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    xor     edi,    3
    add     edi,    [g_dev + offsetof_struct_device_ri + offsetof_struct_ri_controller_rdram + offsetof_struct_rdram_dram]
    mov     cl,     BYTE [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wbyte]
    mov     BYTE [edi - 0x80000000],    cl
    jmp     _E12

write_rdramh_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    xor     edi,    2
    add     edi,    [g_dev + offsetof_struct_device_ri + offsetof_struct_ri_controller_rdram + offsetof_struct_rdram_dram]
    mov     cx,     WORD [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_whword]
    mov     WORD [edi - 0x80000000],    cx
    jmp     _E12

write_rdramd_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    add     edi,    [g_dev + offsetof_struct_device_ri + offsetof_struct_ri_controller_rdram + offsetof_struct_rdram_dram]
    mov     ecx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wdword+4]
    mov     edx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wdword+0]
    mov     [edi - 0x80000000],         ecx
    mov     [edi - 0x80000000 + 4],     edx
    jmp     _E12


do_invalidate:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    mov     ebx,    edi    ;Return ebx to caller
_E12:
    shr     edi,    12
    cmp     BYTE [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cached_interp + offsetof_struct_cached_interp_invalid_code + edi],    1
    je      _E13
    push    edi
    call    invalidate_block
    pop     edi
_E13:
    ret

read_nomem_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    mov     ebx,    edi
    shr     edi,    12
    mov     edi,    [memory_map+edi*4]
    mov     eax,    00h
    test    edi,    edi
    js      tlb_exception
    mov     ecx,    [ebx+edi*4]
    mov     [readmem_dword],    ecx
    ret

read_nomemb_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    mov     ebx,    edi
    shr     edi,    12
    mov     edi,    [memory_map+edi*4]
    mov     eax,    00h
    test    edi,    edi
    js      tlb_exception
    xor     ebx,    3
    movzx   ecx,    BYTE [ebx+edi*4]
    mov     [readmem_dword],    ecx
    ret

read_nomemh_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    mov     ebx,    edi
    shr     edi,    12
    mov     edi,    [memory_map+edi*4]
    mov     eax,    00h
    test    edi,    edi
    js      tlb_exception
    xor     ebx,    2
    movzx   ecx,    WORD [ebx+edi*4]
    mov     [readmem_dword],    ecx
    ret

read_nomemd_new:
    mov     edi,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_address]
    mov     ebx,    edi
    shr     edi,    12
    mov     edi,    [memory_map+edi*4]
    mov     eax,    00h
    test    edi,    edi
    js      tlb_exception
    mov     ecx,    [4+ebx+edi*4]
    mov     edx,    [ebx+edi*4]
    mov     [readmem_dword],      ecx
    mov     [readmem_dword+4],    edx
    ret

write_nomem_new:
    call    do_invalidate
    mov     edi,    [memory_map+edi*4]
    mov     ecx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wword]
    mov     eax,    01h
    shl     edi,    2
    jc      tlb_exception
    mov     [ebx+edi],    ecx
    ret

write_nomemb_new:
    call    do_invalidate
    mov     edi,    [memory_map+edi*4]
    mov     cl,     BYTE [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wbyte]
    mov     eax,    01h
    shl     edi,    2
    jc      tlb_exception
    xor     ebx,    3
    mov     BYTE [ebx+edi],    cl
    ret

write_nomemh_new:
    call    do_invalidate
    mov     edi,    [memory_map+edi*4]
    mov     cx,     WORD [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_whword]
    mov     eax,    01h
    shl     edi,    2
    jc      tlb_exception
    xor     ebx,    2
    mov     WORD [ebx+edi],    cx
    ret

write_nomemd_new:
    call    do_invalidate
    mov     edi,    [memory_map+edi*4]
    mov     edx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wdword+4]
    mov     ecx,    [g_dev + offsetof_struct_device_mem + offsetof_struct_memory_wdword+0]
    mov     eax,    01h
    shl     edi,    2
    jc      tlb_exception
    mov     [ebx+edi],    edx
    mov     [4+ebx+edi],    ecx
    ret

write_mi_new:
    mov     ebx,    [024h+esp]
    add     ebx,    4
    mov     [pcaddr],    ebx
    mov     DWORD [pending_exception],    0
    call    write_mi
    mov     ebx,    [pending_exception]
    test    ebx,    ebx
    jne     mi_exception
    ret

write_mib_new:
    mov     ebx,    [024h+esp]
    add     ebx,    4
    mov     [pcaddr],    ebx
    mov     DWORD [pending_exception],    0
    call    write_mib
    mov     ebx,    [pending_exception]
    test    ebx,    ebx
    jne     mi_exception
    ret

write_mih_new:
    mov     ebx,    [024h+esp]
    add     ebx,    4
    mov     [pcaddr],    ebx
    mov     DWORD [pending_exception],    0
    call    write_mih
    mov     ebx,    [pending_exception]
    test    ebx,    ebx
    jne     mi_exception
    ret

write_mid_new:
    mov     ebx,    [024h+esp]
    add     ebx,    4
    mov     [pcaddr],    ebx
    mov     DWORD [pending_exception],    0
    call    write_mid
    mov     ebx,    [pending_exception]
    test    ebx,    ebx
    jne     mi_exception
    ret

mi_exception:
    ;ebx = mem addr
    ;ebp = instr addr + flags
    mov     ebp,    [024h+esp]
    mov     ebx,    [address]
    add     esp,    024h
    call    wb_base_reg
    jmp     do_interrupt

tlb_exception:
    ;eax = r/w
    ;ebx = mem addr
    ;ebp = instr addr + flags
    mov     ebp,    [024h+esp]
    add     esp,    024h
    call    wb_base_reg
    add     esp,    -4
    push    eax
    push    ebx
    push    ebp
    call    TLB_refill_exception_new
    add     esp,    16
    mov     edi,    DWORD [next_interupt]
    mov     esi,    DWORD [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_cp0 + offsetof_struct_cp0_regs+36]    ;Count
    mov     DWORD [last_count],    edi
    sub     esi,    edi
    jmp     eax

wb_base_reg:
    ;ebx = address
    ;ebp = instr addr + flags
    mov     ecx,    ebp
    mov     edx,    ebp
    shr     ecx,    12
    and     edx,    0FFFFFFFCh
    mov     ecx,    [memory_map+ecx*4]
    mov     ecx,    [edx+ecx*4]
    mov     edx,    06000022h
    mov     edi,    ecx
    movsx   esi,    cx
    shr     ecx,    26
    shr     edi,    21
    sub     ebx,    esi
    add     esi,    ebx
    and     edi,    01fh
    rcr     edx,    cl
    cmovc   ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs+edi*8]
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs+edi*8],    ebx
    sar     ebx,    31
    test    ebp,    2
    cmove   ebx,    [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs+4+edi*8]
    mov     [g_dev + offsetof_struct_device_r4300 + offsetof_struct_r4300_core_regs+4+edi*8],    ebx
    mov     ebx,    esi
    ret

breakpoint:
    int    3
    ret
