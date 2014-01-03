// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>


// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

static void print_regs(struct PushRegs *regs)
{
	cprintf("   edi 0x%08x\n", regs->reg_edi);
	cprintf("   esi 0x%08x\n", regs->reg_esi);
	cprintf("   ebp 0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("   ebx 0x%08x\n", regs->reg_ebx);
	cprintf("   edx 0x%08x\n", regs->reg_edx);
	cprintf("   ecx 0x%08x\n", regs->reg_ecx);
	cprintf("   eax 0x%08x\n", regs->reg_eax);
}

static void print_utrapframe(struct UTrapframe* utf)
{
	cprintf("USER TRAP frame at %p from CPU %d\n", utf, thisenv->env_cpunum);
	print_regs(&utf->utf_regs);
	cprintf("  trap 0x%08x %s\n", T_PGFLT, "Page Fault");
    cprintf("    va 0x%08x\n", utf->utf_fault_va);
	cprintf("   err 0x%08x", utf->utf_err);
    cprintf(" [%s, %s, %s]\n",
            utf->utf_err & 4 ? "user" : "kernel",
            utf->utf_err & 2 ? "write" : "read",
            utf->utf_err & 1 ? "protection" : "not-present");
	cprintf("   eip 0x%08x\n", utf->utf_eip);
	cprintf("  flag 0x%08x\n", utf->utf_eflags);
    cprintf("   esp 0x%08x\n", utf->utf_esp);
}

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
    
        
	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
    
    addr = ROUNDDOWN(addr, PGSIZE);
    
    if(!(err & FEC_WR))
    {
        print_utrapframe(utf);
        panic("pgfault: page fault beyond copy-on-write (utf_err = %d, va = %p, eip = %p)",
              err, utf->utf_fault_va, utf->utf_eip);
    }
    
    if(!(uvpd[PDX(addr)] & PTE_P) || !(uvpt[PGNUM(addr)] & PTE_P))
    {
        print_utrapframe(utf);
        panic("pgfault: genreal page fault");
    }
    
    pte_t pte = uvpt[PGNUM(addr)];
    if(!(pte & PTE_COW))
    {
        print_utrapframe(utf);
        panic("pgfault: page of va %p is not a copy-on-write page (pte = %p)", addr, pte);
    }

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
    
    r = sys_page_alloc(0, PFTEMP, PTE_W | PTE_U | PTE_P);
    if(r < 0) panic("pgfault: sys_page_alloc error - %e", r);
    
    memcpy((void*)PFTEMP, addr, PGSIZE);
    
    r = sys_page_map(0, (void*)PFTEMP, 0, addr, PTE_W | PTE_U | PTE_P);
    if(r < 0) panic("pgfault: sys_page_map error - %e", r);
    
    r = sys_page_unmap(0, (void*)PFTEMP);
    if(r < 0) panic("pgfault: sys_page_unmap error - %e", r);
    
    //cprintf("Read-on-write handler: returning to %p\n", utf->utf_eip);
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
    
	// LAB 4: Your code here.
    
    uintptr_t vaddr = pn << PGSHIFT;
    void* va = (void*)vaddr;
    
    assert(uvpd[PDX(vaddr)] & PTE_P);   // page existed at pgdir
    assert(uvpt[PGNUM(vaddr)] & PTE_P); // page existed at pgtable
    
    pte_t pte = uvpt[PGNUM(vaddr)];
    int oldPerm = pte & PTE_SYSCALL;
    int newPerm = oldPerm;
    
    newPerm &= ~PTE_W;
    newPerm |= PTE_COW;
    
    if(((pte & PTE_W) || (pte & PTE_COW)) && !(pte & PTE_SHARE))
    {
        r = sys_page_map(0, va, envid, va, newPerm);
        if(r < 0) panic("duppage: sys_page_map target error - %e", r);
        
        // set self perm
        r = sys_page_map(0, va, 0, va, newPerm);
        if(r < 0) panic("duppage: sys_page_map self - %e", r);
    }
    else
    {
        // in case of the read-only page
        // (e.g. user-text segment loaded by shell)
        r = sys_page_map(0, va, envid, va, oldPerm);
    }

	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
    
    int r;
    envid_t pid;
    
    set_pgfault_handler(&pgfault);
    pid = sys_exofork();
    
    if(pid < 0)
    {
        panic("fork: sys_exofork error - %e", pid);
    }
    else if (pid == 0)
    {
        // child
        thisenv = &envs[ENVX(sys_getenvid())];
        return 0;
    }
    else
    {
        // parent
        envid_t childEnv = pid;
        int pn;
        
        for(pn = 0; pn < PGNUM(USTACKTOP); pn++)
        {
            uintptr_t vaddr = pn << PGSHIFT;
            if(!(uvpd[PDX(vaddr)] & PTE_P))
                continue;
            
            pte_t pte = uvpt[pn];
            if(pte & PTE_P)
            {
                // it's reasonable that we should handle the read-only and readwrite pages
                // in different ways. but the implementation just works. god knows.
                
                r = duppage(childEnv, pn);
                if(r < 0) panic("fork: duppage error - %e", r);
            }
        }
        
        sys_page_alloc(childEnv, (void*)(UXSTACKTOP-PGSIZE), PTE_U | PTE_W | PTE_P);
        
        sys_env_set_pgfault_upcall(childEnv, thisenv->env_pgfault_upcall);
        r = sys_env_set_status(childEnv, ENV_RUNNABLE);
        if(r < 0) panic("fork: sys_env_set_status error - %e", r);
        
        return childEnv;
    }
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
