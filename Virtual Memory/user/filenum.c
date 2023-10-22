#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"


int
main(int argc, char *argv[])
{  
  int files = getfilenum(getpid());
  fprintf(1, "%d\n", files);
  return files;
  exit(0);
}