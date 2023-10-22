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
