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
#include <kern/sched.h>
#include <kern/spinlock.h>

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
	env_destroy(e);
	return 0;
}

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
}

// Allocate a new environment.
// Returns envid of new environment, or < 0 on error.  Errors are:
//	-E_NO_FREE_ENV if no free environment is available.
//	-E_NO_MEM on memory exhaustion.
static envid_t
sys_exofork(void)
{
	// Create the new environment with env_alloc(), from kern/env.c.
	// It should be left as env_alloc created it, except that
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.
    
    
    {
//        // for test
//        
//        pte_t* uvpt = (pte_t*)UVPT;
//        //kernlog("uvpt[0xef401000] = %p\n", uvpt[0xef401000]);
//        
//        int vaddr = 0;
//        for(vaddr = 0; vaddr < ULIM; vaddr += PGSIZE)
//        {
//            pte_t* ptePtr = pgdir_walk(curenv->env_pgdir, (const void*)vaddr, false);
//            if(ptePtr && (*ptePtr & PTE_P))
//                kernlog("exofork: vaddr %08p - %x / %x\n", vaddr, *ptePtr & 0xeff, uvpt[PGNUM(vaddr)] & 0xeff);
//            if(vaddr == UVPT)
//                kernlog("orzorzorz\n");
//        }
    }
    
    int result;
    struct Env* newEnv = NULL;
    envid_t parentId = curenv->env_id;
    
    // create env and setup vm
    result = env_alloc(&newEnv, parentId);
    if(result < 0) return result;
    
    newEnv->env_tf = curenv->env_tf;
    newEnv->env_tf.tf_regs.reg_eax = 0;
    newEnv->env_status = ENV_NOT_RUNNABLE;
    
    //kernlog("new env's id: %d\n", newEnv->env_id);
    
    return newEnv->env_id;
}

// Set envid's env_status to status, which must be ENV_RUNNABLE
// or ENV_NOT_RUNNABLE.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if status is not a valid status for an environment.
static int
sys_env_set_status(envid_t envid, int status)
{
	// Hint: Use the 'envid2env' function from kern/env.c to translate an
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
    
    int result;
    struct Env* env = NULL;
    
    result = envid2env(envid, &env, true);
    if(result < 0) return result;
    
    if(status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
    {
        env->env_status = status;
        return 0;
    }
    else return -E_INVAL;
}

// Set envid's trap frame to 'tf'.
// tf is modified to make sure that user environments always run at code
// protection level 3 (CPL 3) with interrupts enabled.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_set_trapframe(envid_t envid, struct Trapframe *tf)
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
    
    int result;
    
    struct Env* env;
    result = envid2env(envid, &env, true);
    if(result < 0) return result;
    
    tf->tf_cs = GD_UT | 3;  // cpl = 3
    tf->tf_eflags |= FL_IF; // enable interrupts
    
    env->env_tf = *tf;
    
    return 0;
}

// Set the page fault upcall for 'envid' by modifying the corresponding struct
// Env's 'env_pgfault_upcall' field.  When 'envid' causes a page fault, the
// kernel will push a fault record onto the exception stack, then branch to
// 'func'.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
    
    int result;
    struct Env* env = NULL;
    
    result = envid2env(envid, &env, true);
    if(result < 0) return result;
    
    env->env_pgfault_upcall = func;
    return 0;
}

// Allocate a page of memory and map it at 'va' with permission
// 'perm' in the address space of 'envid'.
// The page's contents are set to 0.
// If a page is already mapped at 'va', that page is unmapped as a
// side effect.
//
// perm -- PTE_U | PTE_P must be set, PTE_AVAIL | PTE_W may or may not be set,
//         but no other bits may be set.  See PTE_SYSCALL in inc/mmu.h.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
//	-E_INVAL if perm is inappropriate (see above).
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	// Hint: This function is a wrapper around page_alloc() and
	//   page_insert() from kern/pmap.c.
	//   Most of the new code you write should be to check the
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
    
	// LAB 4: Your code here.
    uint32_t vaddr = (uint32_t)va;
    if((vaddr & (PGSIZE-1) || vaddr >= UTOP))
        return -E_INVAL;
       
    if(!(perm & PTE_U) || !(perm & PTE_P))
        return -E_INVAL;
    
    if(perm & ~(PTE_AVAIL | PTE_W | PTE_U | PTE_P))
        return -E_INVAL;
    
    int result;
    struct Env* env = NULL;
    struct PageInfo* pageInfo = NULL;
    
    result = envid2env(envid, &env, true);
    if(result < 0) return result;
    if(!env) return -E_BAD_ENV;
    
    pageInfo = page_alloc(ALLOC_ZERO);
    if(!pageInfo) return -E_NO_MEM;
    
    result = page_insert(env->env_pgdir, pageInfo, va, perm);
    if(result < 0) return result;
    
    return 0;
}

// Map the page of memory at 'srcva' in srcenvid's address space
// at 'dstva' in dstenvid's address space with permission 'perm'.
// Perm has the same restrictions as in sys_page_alloc, except
// that it also must not grant write access to a read-only
// page.
//
// Return 0 on success, < 0 on error.  Errors are:
//*	-E_BAD_ENV if srcenvid and/or dstenvid doesn't currently exist,
//		or the caller doesn't have permission to change one of them.
//*	-E_INVAL if srcva >= UTOP or srcva is not page-aligned,
//		or dstva >= UTOP or dstva is not page-aligned.
//*	-E_INVAL is srcva is not mapped in srcenvid's address space.
//*	-E_INVAL if perm is inappropriate (see sys_page_alloc).
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate any necessary page tables.
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	// Hint: This function is a wrapper around page_lookup() and
	//   page_insert() from kern/pmap.c.
	//   Again, most of the new code you write should be to check the
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.
    
	// LAB 4: Your code here.
    int result;
    struct PageInfo* pageInfo = NULL;
    struct Env* srcEnv = NULL;
    struct Env* dstEnv = NULL;
    uint32_t srcVaddr = (uint32_t)srcva;
    uint32_t dstVaddr = (uint32_t)dstva;
    
    if(srcVaddr >= UTOP || (srcVaddr & (PGSIZE-1)))
        return -E_INVAL;
    
    if(dstVaddr >= UTOP || (dstVaddr & (PGSIZE-1)))
        return -E_INVAL;
    
    if(!(perm & PTE_U) || !(perm & PTE_P))
        return -E_INVAL;
    
    if(perm & ~(PTE_AVAIL | PTE_W | PTE_U | PTE_P))
        return -E_INVAL;
    
    
    result = envid2env(srcenvid, &srcEnv, true);
    if(result < 0) return result;
    if(!srcEnv) return -E_BAD_ENV;
    
    result = envid2env(dstenvid, &dstEnv, true);
    if(result < 0) return result;
    if(!dstEnv) return -E_BAD_ENV;
    
    pte_t* pte;
    pageInfo = page_lookup(srcEnv->env_pgdir, srcva, &pte);
    if(!pageInfo) return -E_INVAL;
    if((perm & PTE_W) && !(*pte & PTE_W)) return -E_INVAL;  // allow non-user page?
    
    result = page_insert(dstEnv->env_pgdir, pageInfo, dstva, perm);
    if(result < 0) return result;
    
    return 0;
}

// Unmap the page of memory at 'va' in the address space of 'envid'.
// If no page is mapped, the function silently succeeds.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
    int result;
    uint32_t vaddr = (uint32_t)va;
    struct Env* env = NULL;
    
    if(vaddr >= UTOP || (vaddr & (PGSIZE-1)))
        return -E_INVAL;
    
    result = envid2env(envid, &env, true);
    if(result < 0) return result;
    if(!env) return -E_BAD_ENV;
    
    page_remove(env->env_pgdir, va);
    
    return 0;
}

// Try to send 'value' to the target env 'envid'.
// If srcva < UTOP, then also send page currently mapped at 'srcva',
// so that receiver gets a duplicate mapping of the same page.
//
// The send fails with a return value of -E_IPC_NOT_RECV if the
// target is not blocked, waiting for an IPC.
//
// The send also can fail for the other reasons listed below.
//
// Otherwise, the send succeeds, and the target's ipc fields are
// updated as follows:
//    env_ipc_recving is set to 0 to block future sends;
//    env_ipc_from is set to the sending envid;
//    env_ipc_value is set to the 'value' parameter;
//    env_ipc_perm is set to 'perm' if a page was transferred, 0 otherwise.
// The target environment is marked runnable again, returning 0
// from the paused sys_ipc_recv system call.  (Hint: does the
// sys_ipc_recv function ever actually return?)
//
// If the sender wants to send a page but the receiver isn't asking for one,
// then no page mapping is transferred, but no error occurs.
// The ipc only happens when no errors occur.
//
// Returns 0 on success, < 0 on error.
// Errors are:
//*	-E_BAD_ENV if environment envid doesn't currently exist.
//		(No need to check permissions.)
//*	-E_IPC_NOT_RECV if envid is not currently blocked in sys_ipc_recv,
//		or another environment managed to send first.
//*	-E_INVAL if srcva < UTOP but srcva is not page-aligned.
//*	-E_INVAL if srcva < UTOP and perm is inappropriate
//		(see sys_page_alloc).
//*	-E_INVAL if srcva < UTOP but srcva is not mapped in the caller's
//		address space.
//*	-E_INVAL if (perm & PTE_W), but srcva is read-only in the
//		current environment's address space.
//*	-E_NO_MEM if there's not enough memory to map srcva in envid's
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
    
    int result;
    struct Env* dstEnv;
    uint32_t srcVaddr = (uintptr_t)srcva;
    
    result = envid2env(envid, &dstEnv, false);
    if(result < 0) return result;
    
    if(!dstEnv->env_ipc_recving)
        return -E_IPC_NOT_RECV;
    
    if(srcVaddr < UTOP)
    {
        // check align
        if(srcVaddr % PGSIZE != 0)
            return -E_INVAL;
        
        // check perm
        if(perm & (~PTE_SYSCALL)) return -E_INVAL;
        
        // check exist & perm
        pte_t* srcPtePtr;
        struct PageInfo* page;
        page = page_lookup(curenv->env_pgdir, srcva, &srcPtePtr);
    
        if(!page) return -E_INVAL;
        if((perm & PTE_W) && !(*srcPtePtr & PTE_W)) return -E_INVAL;
        
        // set perm & map page
        if((uint32_t)dstEnv->env_ipc_dstva < UTOP)
        {
            dstEnv->env_ipc_perm = perm;
            result = page_insert(dstEnv->env_pgdir, page, dstEnv->env_ipc_dstva, perm);
            if(result < 0) return result;
        }
    }
    else
    {
        dstEnv->env_ipc_perm = 0;
    }
    
    // set data
    dstEnv->env_ipc_from = curenv->env_id;
    dstEnv->env_ipc_value = value;
    
    // resume dest env
    dstEnv->env_ipc_recving = false;
    dstEnv->env_status = ENV_RUNNABLE;
    
    if(srcVaddr < UTOP) return 1;
    else return 0;
}

// Block until a value is ready.  Record that you want to receive
// using the env_ipc_recving and env_ipc_dstva fields of struct Env,
// mark yourself not runnable, and then give up the CPU.
//
// If 'dstva' is < UTOP, then you are willing to receive a page of data.
// 'dstva' is the virtual address at which the sent page should be mapped.
//
// This function only returns on error, but the system call will eventually
// return 0 on success.
// Return < 0 on error.  Errors are:
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
    
    uintptr_t dstVaddr = (uintptr_t)dstva;
    
    if(dstVaddr < UTOP)
    {
        if(dstVaddr % PGSIZE != 0)
            return -E_INVAL;
        
        curenv->env_ipc_dstva = dstva;
    }
    
    // block event
    curenv->env_ipc_recving = true;
    curenv->env_status = ENV_NOT_RUNNABLE;
    
    curenv->env_tf.tf_regs.reg_eax = 0;
    sched_yield();
    
    // never reach here
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
        case SYS_yield:         sys_yield(); return 0;
        case SYS_exofork:       return sys_exofork();
        case SYS_env_set_status:    return sys_env_set_status(a1, a2);
        case SYS_page_alloc:    return sys_page_alloc(a1, (void*)a2, a3);
        case SYS_page_map:      return sys_page_map(a1, (void*)a2, a3, (void*)a4, a5);
        case SYS_page_unmap:    return sys_page_unmap(a1, (void*)a2);
        case SYS_env_set_pgfault_upcall:    return sys_env_set_pgfault_upcall(a1, (void*)a2);
        case SYS_ipc_recv:      return sys_ipc_recv((void*)a1);
        case SYS_ipc_try_send:  return sys_ipc_try_send(a1, a2, (void*)a3, a4);
        case SYS_env_set_trapframe: return sys_env_set_trapframe(a1, (struct Trapframe*)a2);
        default:
            kernlog("undefined syscall %lu: (%lu, %lu, %lu, %lu, %lu)\n",
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
fastsyscall_init(struct Taskstate* tss)
{
    // load msr(cs, eip, esp)

    // SYSENTER_CS_MSR  <- GD_KT
    // SYSENTER_ESP_MSR <- TSS0
    // SYSENTER_EIP_MSR <- fastsyscall_handler

    //extern struct Taskstate *tss0ptr;   // defined at kern/trap.c
    extern void fastsyscall_entry();    // defined at kern/trapentry.S

    wrmsr(SYSENTER_CS_MSR,  0, GD_KT);
    wrmsr(SYSENTER_ESP_MSR, 0, tss->ts_esp0);
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
    
	extern char *panicstr;
	if (panicstr)
		asm volatile("hlt");
    
    lock_kernel();
//    kernlog("SYSCALL[%d]\n", num);
    
    //kernlog("Incoming fast-syscall: %d(%p, %p, %p, %p)\n", num, arg1, arg2, arg3, arg4);
    //kernlog("         Original eps: %p\n", orig_esp);
    result = syscall(num, arg1, arg2, arg3, arg4, 0);
    
//    kernlog("SYSCALL[%d]end\n", num);
    unlock_kernel();
    
    
    asm volatile
    (
        asmcode
        (
            mov 12(%0), %%edx;
            mov %0, %%ecx;
         sti;
            sysexit;
        )
        :: "b"(orig_esp), "a"(result)
    );
}
