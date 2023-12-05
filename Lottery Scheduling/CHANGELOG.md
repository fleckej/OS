# Code Changes in Lottery Scheduling

## Added Code:

### `kernel/pstat.h`
### `kernel/random.c`
### `kernel/random.h`
### `kernel/useRandom.c`


### `Makefile`

```make
$K/random.o
$U/_ticketsnum
```

### `kernel/defs.h`

```c
struct pstat;

int             settickets(int, struct proc*);
int             getpinfo(void);
void            lottery_scheduler(void) __attribute__((noreturn));

// random.c
void            rand_init(int);
int             scaled_random(int, int);
```

### `kernel/proc.c`

```c
#include "pstat.h"
#include "random.h"
#include <stdlib.h>
#include "fcntl.h"
struct pstat s;
int totaltickets = 0;

allocproc() // initialize the fields of the new proccess in the pstat tables
    for (int i = 0; i < NPROC; i++){
        if ((&s)->inuse[i] == 0){
        totaltickets++;
        (&s)->tickets[i] = 1;
        (&s)->inuse[i] = 1;
        (&s)->pid[i] = p->pid;
        (&s)->ticks[i] = 0;
        break;
        }
    }

freeproc() // reset the fields of the freed process in the pstat tables
    for (int i = 0; i < NPROC; i++){
        if (p->pid == (&s)->pid[i]){
        totaltickets = totaltickets - (&s)->tickets[i];
        (&s)->tickets[i] = 0;
        (&s)->inuse[i] = 0;
        }
    }

lottery_scheduler():
    // select the ticket
    int chosenticket = scaled_random(0, totaltickets);
    int count = 0;

    for(int i = 0; i < NPROC; i++) {
        // increment count by the number of tickets at this index
        count += (&s)->tickets[i];

        // set the relevant process to schedule
        p = &proc[i];
        acquire(&p->lock);

        // schedule the process that contains the randomly chosen ticket
        if (count >= chosenticket && p->state == RUNNABLE){
            if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
                p = &proc[i];
                printf("pid: %d, tickets: %d, ticks: %d, proc: %s\n", (&s)->pid[i], (&s)->tickets[i], (&s)->ticks[i], p->name);
            }
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;

            // Increment the process ticks
            (&s)->ticks[i]++;        
            
            // Give the process more tickets if it is running for a long time
            if ((&s)->ticks[i] > 5){
                settickets((&s)->ticks[i] - 5, p);
            }
        }
    }

settickets()
    // passing in the process to change the tickets of (required in order to call settickets in scheduler)
    int
    settickets(int number, struct proc* p) 
    {
        // cap for number is 70; tickets > 70 cause the shell to stall or infinite loop
        for (int i = 0; i < NPROC; i++){
            if ((&s)->pid[i] == p->pid && number > 0 && number <= 70){
            (&s)->tickets[i] = number;
            totaltickets += number - 1; // it was previously set to one so subtract that and add number
            return 0;
            }
        }
        return -1;
    }

getpinfo()
    // print the pstat table
    int
    getpinfo()
    {
        struct proc *p;
        for(int i = 0; i < NPROC; i++){
            if ((&s)->pid[i] || (&s)->tickets[i] || (&s)->ticks[i] || (&s)->inuse[i]){
            p = &proc[i];
            printf("pid: %d, tickets: %d, ticks: %d, inuse: %d, proc: %s\n", 
            (&s)->pid[i], (&s)->tickets[i], (&s)->ticks[i], (&s)->inuse[i], p->name);
            }
        }
    return 0;
    }
```

### `kernel/syscall.c`

```c
#include "pstat.h"
#include "random.h"
extern uint64 sys_settickets(void);
extern uint64 sys_getpinfo(void);
[SYS_settickets]  sys_settickets,
[SYS_getpinfo]  sys_getpinfo,
```

### `kernel/syscall.h`

```c
#define SYS_getfilenum  22
#define SYS_settickets  23
#define SYS_getpinfo    24
```

### `kernel/sysproc.c`

```c
#include "pstat.h"
#include "random.h"

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
```

### `user/ticketsnum.c`

```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
#include "kernel/pstat.h"

// extern void test_settickets(char * number);
extern int test_getpinfo();
struct pstat p;

int
main(int argc, char *argv[])
{ 
int getpinfo = test_getpinfo();
if (getpinfo == -1){
    fprintf(2, "test_getpinfo() failed\n");
}
return 0;
exit(0);
}

int
test_getpinfo()
{
struct pstat p;
int works = getpinfo(&p);
if (works != 0){
    return -1;
}
return 0;
}
```

### `user/user.h`

```c
struct pstat;
struct proc;
int settickets(int, struct proc*);
int getpinfo(struct pstat*);
```

### `user/usys.pl`

```c
entry("getfilenum");
entry("settickets");
entry("getpinfo");

```

```perl
entry("getfilenum");
entry("settickets");
entry("getpinfo");
```

## Changed Code:

### `kernel/main.c`

Removed:

```c
scheduler();
```

Added:

```c
lottery_scheduler();
```

---
