#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "pstat.h"
#include "random.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

uint64
sys_getfilenum(void)
{
  int pid;
  argint(0, &pid);
  return getfilenum(pid);
}
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_settickets(void)
{
  int number;
  struct proc *p = 0;
  argint(0, &number);
  return settickets(number, p);
}

uint64
sys_getpinfo(void)
{
  return getpinfo();
}

uint64
sys_pgaccess(void)
{
  uint64 start_va; // starting virtual address of the first user page to check
  int num_pages; // number of pages to check
  uint64 bitmap; // user address to store the results into a bitmask

  argaddr(0, &start_va);
  argint(1, &num_pages);
  argaddr(2, &bitmap);
  
  return pgaccess((char*)start_va, num_pages, (int*)bitmap, myproc()->pagetable);
}