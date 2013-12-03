/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */










/*
    0   "Divide error",
        "Debug",
        "Non-Maskable Interrupt",
        "Breakpoint",
        "Overflow",
        "BOUND Range Exceeded",
        "Invalid Opcode",
        "Device Not Available",
        "Double Fault",
        "Coprocessor Segment Overrun",
   10   "Invalid TSS",
        "Segment Not Present",
        "Stack Fault",
        "General Protection",
        "Page Fault",
        "(unknown trap)",
        "x87 FPU Floating-Point Error",
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"*/
TRAPHANDLER_NOEC(trap_divide_zero,  T_DIVIDE);
TRAPHANDLER_NOEC(trap_debug,        T_DEBUG);
TRAPHANDLER_NOEC(trap_nmi,          T_NMI);
TRAPHANDLER_NOEC(trap_breakpoint,   T_BRKPT);
TRAPHANDLER_NOEC(trap_overflow,     T_OFLOW);
TRAPHANDLER_NOEC(trap_bound,        T_BOUND);
TRAPHANDLER_NOEC(trap_opcode,       T_ILLOP);
TRAPHANDLER_NOEC(trap_device,       T_DEVICE);
     TRAPHANDLER(trap_double_fault, T_DBLFLT);
     //reserver
     TRAPHANDLER(trap_invalid_tss,  T_TSS);
     TRAPHANDLER(trap_segment,      T_SEGNP);
     TRAPHANDLER(trap_stack,        T_STACK);
     TRAPHANDLER(trap_general,      T_GPFLT);
     TRAPHANDLER(trap_page_fault,   T_PGFLT);
     //reserve
TRAPHANDLER_NOEC(trap_fpuerr,       T_FPERR);
     TRAPHANDLER(trap_alignment,    T_ALIGN);
TRAPHANDLER_NOEC(trap_machine,      T_MCHK);
TRAPHANDLER_NOEC(trap_simd,         T_SIMDERR);
TRAPHANDLER_NOEC(trap_syscall,      T_SYSCALL); //?
TRAPHANDLER_NOEC(trap_default,      T_DEFAULT); //?













_alltraps:

    pushl   %ds     // push DS
    pushl   %es     // push ES
    pushal          // push all regs

    // set DS&ES
    movw    $(GD_KD), %ax
    movw    %ax, %ds
    movw    %ax, %es

    // call trap(ESP)
    pushl   %esp
    call    trap

    jmp _never_reach_here


.global fastsyscall_entry
fastsyscall_entry:

    // fastsyscall_handler(orig_esp)
    push    %ebp
    call    fastsyscall_handler

    jmp _never_reach_here


_never_reach_here:
    int3
    jmp _never_reach_here
