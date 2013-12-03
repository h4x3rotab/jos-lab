/* See COPYRIGHT for copyright information. */

#include <inc/x86.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/console.h>

static bool
check_user_accessable(void* va, size_t len)
{
    uint32_t begin = ROUNDDOWN((uint32_t)va, PGSIZE);
    uint32_t end = ROUNDUP((uint32_t)va + len, PGSIZE);

    for(; begin<end; begin+=PGSIZE)
    {
        pte_t* ptePtr = NULL;
        if(!page_lookup(curenv->env_pgdir, (void*)begin, &ptePtr) || !(*ptePtr & PTE_U))
            return false;
    }
    return true;
}

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
//    if(!check_user_accessable((void*)s, len))
//    {
//        cprintf("sys_cputs: user has no permission to access the memroy (%p, size:%lu)\n", s, len);
//        env_destroy(curenv);
//    }
    user_mem_assert(curenv, s, len, PTE_U);

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
}

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
}

// Destroy a given environment (possibly the currently running environment).
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
		return r;
	if (e == curenv)
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
	env_destroy(e);
	return 0;
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

    switch(syscallno)
    {
        case SYS_cputs:         sys_cputs((const char*)a1, (size_t)a2); return 0;
        case SYS_cgetc:         return sys_cgetc();
        case SYS_getenvid:      return sys_getenvid();
        case SYS_env_destroy:   return sys_env_destroy((envid_t)a1);
        case SYS_sysenter:      return syscall_support();
        default:
            kernlog("undefined syscall %lu: (%lu, %lu, %lu, %lu, %lu)",
                    syscallno, a1, a2, a3, a4, a5);
            return -E_INVAL;
    }
}


bool syscall_support()
{
    uint32_t edx = 0;
    asm
    (
        "mov $1, %%eax\n"
        "cpuid\n"
        : "=d" (edx)
        :
        : "eax"
    );
    return !!(edx & (1 << 11));
}

//
// Fast System Call
//

// utility making asm code pretty
#define asmcode(...) #__VA_ARGS__

// constants from IA32 manual
#define SYSENTER_CS_MSR     0x174
#define SYSENTER_ESP_MSR    0x175
#define SYSENTER_EIP_MSR    0x176

#define rdmsr(msr,hi,lo)            \
    asm volatile                    \
    (                               \
        "rdmsr"                     \
            : "=d" (hi), "=d" (lo)  \
            : "c" (msr)             \
    )

#define wrmsr(msr,hi,lo)            \
    asm volatile(                   \
        "wrmsr"                     \
            :: "c" (msr),           \
               "d" (hi), "a" (lo)   \
    )

void
fastsyscall_init(void)
{
    // load msr(cs, eip, esp)

    // SYSENTER_CS_MSR  <- GD_KT
    // SYSENTER_ESP_MSR <- TSS0
    // SYSENTER_EIP_MSR <- fastsyscall_handler

    extern struct Taskstate *tss0ptr;   // defined at kern/trap.c
    extern void fastsyscall_entry();    // defined at kern/trapentry.S

    wrmsr(SYSENTER_CS_MSR,  0, GD_KT);
    wrmsr(SYSENTER_ESP_MSR, 0, tss0ptr->ts_esp0);
    wrmsr(SYSENTER_EIP_MSR, 0, &fastsyscall_entry);
}

// called by fastsyscall_entry (kern/trapentry.S)
void
fastsyscall_handler(uint32_t orig_esp)
{
    /*
                   eax - syscall number
    edx, ecx, ebx, edi - arg1, arg2, arg3, arg4
                   esi - return esp
                   ebp - return pc
                   esp - trashed by sysenter

    */

    uint32_t num, arg1, arg2, arg3, arg4, result;
    asm volatile ("" : "=a"(num), "=d"(arg1), "=c"(arg2), "=b"(arg3), "=D"(arg4));


    kernlog("Incoming fast-syscall: %d(%p, %p, %p, %p)\n", num, arg1, arg2, arg3, arg4);
    kernlog("         Original eps: %p\n", orig_esp);
    result = syscall(num, arg1, arg2, arg3, arg4, 0);

    asm volatile
    (
        asmcode
        (
            mov 12(%0), %%edx;
            mov %0, %%ecx;
            sysexit;
        )
        :: "b"(orig_esp), "a"(result)
    );
}
