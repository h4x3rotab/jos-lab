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

/*
             n
    +----------------- N
    |     0   0   0
    | x   a11 a12 a13
  w | y   a21 a22 a23
    | z   a31 a32 a33
    |     x'  y'  z'
    M         s
 
 */

#define M 5
#define N 4
#define SharedPage ((uint32_t)UTEMP + PGSIZE)
#define EnvIndex(i,j) ((i)*N + (j))

int vect[M] = { 0, 2, 3, 4 };

int A[M][M] = {
    {0,0,0,0,0},
    {0,1,2,3,0},
    {0,4,5,6,0},
    {0,7,8,9,0},
    {0,0,0,0,0},
};

envid_t* cenv;

void getEnvIndex(envid_t* index, envid_t envid, int* row, int* col)
{
    int i;
    for(i=0; i<M*N; i++)
    {
        if(index[i] == envid)
        {
            if(col) *col = i % N;
            if(row) *row = i / N;
            return;
        }
    }
}

void west_main(int row, int col)
{
    ipc_send(cenv[EnvIndex(row, col+1)], vect[row], NULL, 0);
}

void north_main(int row, int col)
{
    ipc_send(cenv[EnvIndex(row+1, col)], 0, NULL, 0);
}

void center_main(int row, int col)
{
    bool gotNorth = false;
    bool gotWest = false;
    int x = -1, sum = -1;
    
    while (!(gotNorth && gotWest))
    {
        envid_t from;
        int from_row, from_col, value;
        
        value = ipc_recv(&from, NULL, NULL);
        getEnvIndex(cenv, from, &from_row, &from_col);
        
        if(from_col == col-1)
        {
            // from west
            x = value;
            gotWest = true;
            
            // pass to east
            if(col+1 < N)
                ipc_send(cenv[EnvIndex(row, col+1)], x, NULL, 0);
        }
        else if(from_row == row-1)
        {
            // from north
            sum = value;
            gotNorth = true;
        }
    }
    
    int prefixSum = sum + A[row][col] * x;
    cprintf("prefixSum[%d,%d] = %d\n", row, col, prefixSum);
    
    ipc_send(cenv[EnvIndex(row+1, col)], prefixSum, NULL, 0);
}

void south_main(int row, int col)
{
    int sum = ipc_recv(NULL, NULL, NULL);
    cprintf("vect[%d] = %d\n", col, sum);
}

void child_main()
{
    envid_t self = sys_getenvid();
    
    int perm;
    envid_t* sharedPage = (envid_t*)SharedPage;
    
    // receive shared envid table form controller
    ipc_recv(NULL, sharedPage, &perm);
    cenv = sharedPage;
    
    // memory fence
    ipc_recv(NULL, NULL, NULL);
    
    int row, col;
    getEnvIndex(sharedPage, self, &row, &col);
    
    if(col == 0 && (1 <= row && row < 4))
        west_main(row, col);
    else if(row == 0 && (1 <= col && col < N))
        north_main(row, col);
    else if((1 <= row && row < M-1) && (1 <= col && col < N))
        center_main(row, col);
    else if(row == M-1 && (1 <= col && col < N))
        south_main(row, col);
}

void controller()
{
    int i;
    envid_t childs[20];

    for(i=0; i<20; i++)
    {
        int pid = fork();
        if(pid != 0)
            childs[i] = pid;
        else
        {
            child_main();
            return;
        }
    }
    
    int perm = PTE_P | PTE_W | PTE_U;
    envid_t* sharedPage = (envid_t*)SharedPage;
    
    int result = sys_page_alloc(0, sharedPage, perm);
    if(result < 0) panic("sys_page_alloc: %e", result);
    
    memcpy(sharedPage, childs, sizeof(childs));
    
    for(i=0; i<20; i++)
    {
        ipc_send(childs[i], 0, sharedPage, perm);
        
        int col = i % N;
        int row = i / N;
        //cprintf("controller: page sent to env(%d,%d)\n", row, col);
    }
    
    // memory fence
    for(i=0; i<20; i++)
        ipc_send(childs[i], 0, NULL, 0);
}

void parallel_multiply()
{
    cprintf("Parallel Matrix-vector Multiplier Demo\n");
    
    cprintf("We will calculate (x * A),\n\n"
            "where x = [%2d %2d %2d],\n\n", vect[1], vect[2], vect[3]);
    cprintf("          |%2d %2d %2d|\n"
            "  and A = |%2d %2d %2d|.\n"
            "          |%2d %2d %2d|\n\n",
                A[1][1], A[1][2], A[1][3],
                A[2][1], A[2][2], A[2][3],
                A[3][1], A[3][2], A[3][3]
            );
    
    controller();
}

void
umain(int argc, char **argv)
{
	cprintf("hello, world\n");
	cprintf("i am environment %08x\n", thisenv->env_id);
    
	cprintf("support of sysenter/sysexit: %s\n\n", syscall_support() ? "yes" : "no");
    
    parallel_multiply();
    while (1);
}
