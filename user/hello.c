// hello, world
#include <inc/lib.h>

#define asmcode(...) #__VA_ARGS__

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


void
umain(int argc, char **argv)
{
	cprintf("hello, world\n");
	cprintf("i am environment %08x\n", thisenv->env_id);
	cprintf("support of sysenter/sysexit: %s\n", syscall_support() ? "yes" : "no");
}
